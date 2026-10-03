import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/env_config.dart';
import 'transport_service.dart';

/// Keys used to hand trip details to the foreground isolate.
class TransportGpsKeys {
  static const token = 'tr_gps_token';
  static const tripId = 'tr_gps_trip_id';
  static const vehicleId = 'tr_gps_vehicle_id';
  static const vehicleName = 'tr_gps_vehicle_name';
  static const intervalSec = 'tr_gps_interval_sec';
  static const idleIntervalSec = 'tr_gps_idle_interval_sec';
  static const serviceId = 7331;
}

/// Entry point for the foreground service isolate. Must be top-level.
@pragma('vm:entry-point')
void transportGpsCallback() {
  FlutterForegroundTask.setTaskHandler(TransportGpsTaskHandler());
}

/// Runs in its own isolate while the Android foreground service is alive, so
/// GPS keeps flowing with the screen locked or the app in the background.
///
/// Every tick: read GPS, buffer it, and post the buffer to the backend. If the
/// network is down the buffer grows (capped) and flushes on the next success.
class TransportGpsTaskHandler extends TaskHandler {
  String? _token;
  int? _tripId;
  int? _vehicleId;
  String _vehicleName = '';
  Dio? _dio;
  final List<Map<String, dynamic>> _buffer = [];
  Position? _last;
  double _distanceKm = 0;
  int _sent = 0;
  int _fails = 0;
  bool _tripEnded = false;
  int _intervalSec = 5;
  int _idleIntervalSec = 30;
  DateTime? _lastSentAt;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _token = await FlutterForegroundTask.getData<String>(key: TransportGpsKeys.token);
    _tripId = await FlutterForegroundTask.getData<int>(key: TransportGpsKeys.tripId);
    _vehicleId = await FlutterForegroundTask.getData<int>(key: TransportGpsKeys.vehicleId);
    _vehicleName = await FlutterForegroundTask.getData<String>(key: TransportGpsKeys.vehicleName) ?? '';
    _intervalSec = await FlutterForegroundTask.getData<int>(key: TransportGpsKeys.intervalSec) ?? 5;
    _idleIntervalSec = await FlutterForegroundTask.getData<int>(key: TransportGpsKeys.idleIntervalSec) ?? 30;
    _dio = Dio(BaseOptions(
      baseUrl: EnvConfig.fullApiUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Authorization': 'Bearer ${_token ?? ''}', 'Content-Type': 'application/json'},
    ));
    FlutterForegroundTask.updateService(
      notificationTitle: 'Trip running · $_vehicleName',
      notificationText: 'Sharing live location',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _tick();
  }

  Future<void> _tick() async {
    if (_tripId == null || _tripEnded) return;
    Position? p;
    try {
      p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
    } catch (_) {
      p = null;
    }
    if (p != null) {
      if (_last != null) {
        final d = Geolocator.distanceBetween(_last!.latitude, _last!.longitude, p.latitude, p.longitude);
        // ignore GPS jitter below 5 m
        if (d > 5) _distanceKm += d / 1000.0;
      }
      _last = p;
      _buffer.add({
        'lat': p.latitude,
        'lng': p.longitude,
        'speedKmh': (p.speed.isFinite && p.speed >= 0) ? p.speed * 3.6 : 0,
        'heading': p.heading.isFinite ? p.heading : null,
        'accuracyM': p.accuracy.isFinite ? p.accuracy : null,
        'ts': p.timestamp.millisecondsSinceEpoch,
      });
      if (_buffer.length > 600) _buffer.removeRange(0, _buffer.length - 600);
    }
    if (_buffer.isEmpty) {
      _notifyUi(status: p == null ? 'Waiting for GPS' : 'Buffered');
      return;
    }
    // Battery: when stationary (speed < 1 km/h and barely moved) send only every
    // idle interval (default 30 s) instead of every tick. Moving buses keep full rate.
    final stationary = p != null && (p.speed.isFinite ? p.speed * 3.6 : 0) < 1.0 && _buffer.length == 1;
    if (stationary && _lastSentAt != null && DateTime.now().difference(_lastSentAt!).inSeconds < _idleIntervalSec) {
      _buffer.clear(); // drop the duplicate point; the live row already shows this spot
      _notifyUi(status: 'Live (parked, saving battery)');
      return;
    }
    try {
      final batch = List<Map<String, dynamic>>.from(_buffer);
      final r = await _dio!.post('/transport/driver/positions', data: {'tripId': _tripId, 'points': batch});
      final data = r.data is Map ? (r.data['data'] ?? {}) : {};
      _buffer.clear();
      _sent += batch.length;
      _fails = 0;
      _lastSentAt = DateTime.now();
      if (data is Map && data['tripEnded'] == true) {
        _tripEnded = true;
        _notifyUi(status: 'Trip ended from server');
        FlutterForegroundTask.updateService(notificationTitle: 'Trip ended', notificationText: 'Location sharing stopped');
        // The trip is closed on the server: shut this service down so nothing more is sent.
        try { await FlutterForegroundTask.stopService(); } catch (_) {}
        return;
      }
      _notifyUi(status: 'Live');
      FlutterForegroundTask.updateService(
        notificationTitle: 'Trip running · $_vehicleName',
        notificationText: '${_distanceKm.toStringAsFixed(1)} km · ${_last != null ? (_last!.speed * 3.6).round() : 0} km/h',
      );
    } catch (_) {
      _fails++;
      _notifyUi(status: 'No network, buffering (${_buffer.length})');
    }
  }

  void _notifyUi({required String status}) {
    FlutterForegroundTask.sendDataToMain({
      'status': status,
      'lat': _last?.latitude,
      'lng': _last?.longitude,
      'speedKmh': _last == null ? 0 : _last!.speed * 3.6,
      'distanceKm': _distanceKm,
      'sent': _sent,
      'buffered': _buffer.length,
      'fails': _fails,
      'tripEnded': _tripEnded,
      'tripId': _tripId,
      'vehicleId': _vehicleId,
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Best-effort final flush so the trail does not lose the last minute.
    if (_buffer.isNotEmpty && _dio != null && _tripId != null && !_tripEnded) {
      try {
        await _dio!.post('/transport/driver/positions', data: {'tripId': _tripId, 'points': _buffer});
      } catch (_) {}
    }
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map && data['cmd'] == 'end') {
      _tripEnded = true;
      _buffer.clear();
      try { FlutterForegroundTask.stopService(); } catch (_) {}
    }
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/customer/transport/driver');
  }

  @override
  void onNotificationDismissed() {}
}

/// Helper used by the driver screen to control the service.
///
/// On Android this drives the foreground service. On the web (Chrome) there is
/// no background service, so a plain timer in the page reads the browser's
/// geolocation and posts it while the tab stays open. Good for testing.
class TransportGpsService {
  static bool _inited = false;

  // ---- web fallback state ----
  static Timer? _webTimer;
  static int? _webTripId;
  static double _webKm = 0;
  static int _webSent = 0;
  static Position? _webLast;
  /// Driver screen registers this to receive the same status maps as the service sends.
  static void Function(Map<String, dynamic>)? webListener;

  static void init() {
    if (kIsWeb) return;
    if (_inited) return;
    _inited = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'transport_gps',
        channelName: 'Trip location sharing',
        channelDescription: 'Shows while a trip is running and location is being shared',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> start({
    required String token,
    required int tripId,
    required int vehicleId,
    required String vehicleName,
    required int intervalSec,
    int idleIntervalSec = 30,
  }) async {
    if (kIsWeb) return _startWeb(tripId: tripId, vehicleId: vehicleId, vehicleName: vehicleName, intervalSec: intervalSec);
    init();
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.token, value: token);
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.tripId, value: tripId);
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.vehicleId, value: vehicleId);
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.vehicleName, value: vehicleName);
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.intervalSec, value: intervalSec);
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.idleIntervalSec, value: idleIntervalSec);
    // Re-init with the requested interval (repeat events are configured here).
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'transport_gps',
        channelName: 'Trip location sharing',
        channelDescription: 'Shows while a trip is running and location is being shared',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(intervalSec.clamp(2, 120) * 1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    final result = await FlutterForegroundTask.startService(
      serviceId: TransportGpsKeys.serviceId,
      notificationTitle: 'Trip running · $vehicleName',
      notificationText: 'Starting location sharing…',
      callback: transportGpsCallback,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<void> stop() async {
    if (kIsWeb) { _webTimer?.cancel(); _webTimer = null; _webTripId = null; return; }
    try {
      FlutterForegroundTask.sendDataToTask({'cmd': 'end'});
    } catch (_) {}
    // Stop unconditionally: isRunningService can report false while the service is still alive.
    try { await FlutterForegroundTask.stopService(); } catch (_) {}
    try { if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService(); } catch (_) {}
  }

  static Future<bool> get isRunning async => kIsWeb ? _webTimer != null : await FlutterForegroundTask.isRunningService;

  static Future<bool> _startWeb({required int tripId, required int vehicleId, required String vehicleName, required int intervalSec}) async {
    _webTimer?.cancel();
    _webTripId = tripId; _webKm = 0; _webSent = 0; _webLast = null;
    Future<void> tick() async {
      if (_webTripId != tripId) return;
      Position? p;
      try {
        p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)));
      } catch (_) { p = null; }
      if (p == null) { webListener?.call({'status': 'Waiting for browser location...', 'tripId': tripId, 'vehicleId': vehicleId, 'distanceKm': _webKm, 'sent': _webSent, 'buffered': 0, 'fails': 0, 'tripEnded': false}); return; }
      if (_webLast != null) {
        final d = Geolocator.distanceBetween(_webLast!.latitude, _webLast!.longitude, p.latitude, p.longitude);
        if (d > 5) _webKm += d / 1000.0;
      }
      _webLast = p;
      final r = await TransportService.instance.sendPositions(tripId, [{
        'lat': p.latitude, 'lng': p.longitude,
        'speedKmh': (p.speed.isFinite && p.speed >= 0) ? p.speed * 3.6 : 0,
        'heading': p.heading.isFinite ? p.heading : null,
        'accuracyM': p.accuracy.isFinite ? p.accuracy : null,
        'ts': DateTime.now().millisecondsSinceEpoch,
      }]);
      final ok = r['success'] == true;
      if (ok) _webSent++;
      final ended = r['data'] is Map && r['data']['tripEnded'] == true;
      webListener?.call({
        'status': ended ? 'Trip ended from server' : (ok ? 'Live' : 'No network, retrying'),
        'lat': p.latitude, 'lng': p.longitude, 'speedKmh': p.speed * 3.6, 'distanceKm': _webKm,
        'sent': _webSent, 'buffered': 0, 'fails': ok ? 0 : 1, 'tripEnded': ended, 'tripId': tripId, 'vehicleId': vehicleId,
      });
      if (ended) { _webTimer?.cancel(); _webTimer = null; _webTripId = null; }
    }
    _webTimer = Timer.periodic(Duration(seconds: intervalSec.clamp(2, 120)), (_) => tick());
    tick();
    return true;
  }
}
