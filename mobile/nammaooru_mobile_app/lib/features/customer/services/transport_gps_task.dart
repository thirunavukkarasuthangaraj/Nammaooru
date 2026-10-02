import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/env_config.dart';

/// Keys used to hand trip details to the foreground isolate.
class TransportGpsKeys {
  static const token = 'tr_gps_token';
  static const tripId = 'tr_gps_trip_id';
  static const vehicleId = 'tr_gps_vehicle_id';
  static const vehicleName = 'tr_gps_vehicle_name';
  static const intervalSec = 'tr_gps_interval_sec';
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

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _token = await FlutterForegroundTask.getData<String>(key: TransportGpsKeys.token);
    _tripId = await FlutterForegroundTask.getData<int>(key: TransportGpsKeys.tripId);
    _vehicleId = await FlutterForegroundTask.getData<int>(key: TransportGpsKeys.vehicleId);
    _vehicleName = await FlutterForegroundTask.getData<String>(key: TransportGpsKeys.vehicleName) ?? '';
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
      _notifyUi(status: p == null ? 'Waiting for GPS…' : 'Buffered');
      return;
    }
    try {
      final batch = List<Map<String, dynamic>>.from(_buffer);
      final r = await _dio!.post('/transport/driver/positions', data: {'tripId': _tripId, 'points': batch});
      final data = r.data is Map ? (r.data['data'] ?? {}) : {};
      _buffer.clear();
      _sent += batch.length;
      _fails = 0;
      if (data is Map && data['tripEnded'] == true) {
        _tripEnded = true;
        _notifyUi(status: 'Trip ended from server');
        FlutterForegroundTask.updateService(notificationTitle: 'Trip ended', notificationText: 'Location sharing stopped');
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
    if (data is Map && data['cmd'] == 'end') _tripEnded = true;
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
class TransportGpsService {
  static bool _inited = false;

  static void init() {
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
  }) async {
    init();
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.token, value: token);
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.tripId, value: tripId);
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.vehicleId, value: vehicleId);
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.vehicleName, value: vehicleName);
    await FlutterForegroundTask.saveData(key: TransportGpsKeys.intervalSec, value: intervalSec);
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
    try {
      FlutterForegroundTask.sendDataToTask({'cmd': 'end'});
    } catch (_) {}
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  static Future<bool> get isRunning => FlutterForegroundTask.isRunningService;
}
