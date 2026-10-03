import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/config/env_config.dart';

/// Passenger-side "Track this bus": a persistent notification (like train
/// trackers) that keeps showing the followed bus, its distance and arrival time
/// at the chosen stop, and rings once when the bus is about to arrive.
///
/// Runs in an Android foreground service (dataSync type, no location permission
/// needed) so it keeps updating while the app is in the background.
class TransportTrackKeys {
  static const busId = 'tr_track_bus_id';
  static const busName = 'tr_track_bus_name';
  static const operator = 'tr_track_operator';
  static const stopName = 'tr_track_stop_name';
  static const stopLat = 'tr_track_stop_lat';
  static const stopLng = 'tr_track_stop_lng';
  static const staleAfter = 'tr_track_stale_after';
  static const serviceId = 7332;
}

@pragma('vm:entry-point')
void transportTrackCallback() {
  FlutterForegroundTask.setTaskHandler(TransportTrackTaskHandler());
}

class TransportTrackTaskHandler extends TaskHandler {
  int? _busId;
  String _busName = '';
  String _operator = '';
  String? _stopName;
  double? _stopLat, _stopLng;
  int _staleAfter = 120;
  Dio? _dio;
  bool _alerted = false;
  int _fails = 0;
  final _notif = FlutterLocalNotificationsPlugin();
  bool _notifReady = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _busId = await FlutterForegroundTask.getData<int>(key: TransportTrackKeys.busId);
    _busName = await FlutterForegroundTask.getData<String>(key: TransportTrackKeys.busName) ?? '';
    _operator = await FlutterForegroundTask.getData<String>(key: TransportTrackKeys.operator) ?? '';
    _stopName = await FlutterForegroundTask.getData<String>(key: TransportTrackKeys.stopName);
    _stopLat = await FlutterForegroundTask.getData<double>(key: TransportTrackKeys.stopLat);
    _stopLng = await FlutterForegroundTask.getData<double>(key: TransportTrackKeys.stopLng);
    _staleAfter = await FlutterForegroundTask.getData<int>(key: TransportTrackKeys.staleAfter) ?? 120;
    _dio = Dio(BaseOptions(baseUrl: EnvConfig.fullApiUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
    try {
      await _notif.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      _notifReady = true;
    } catch (_) {}
    FlutterForegroundTask.updateService(notificationTitle: _title('Tracking'), notificationText: 'Waiting for the bus position...');
    _tick();
  }

  String _title(String st) => '$_busName${_operator.isNotEmpty ? ' ($_operator)' : ''} - $st';

  @override
  void onRepeatEvent(DateTime timestamp) { _tick(); }

  Future<void> _tick() async {
    if (_busId == null || _dio == null) return;
    try {
      final r = await _dio!.get('/transport/public/positions', queryParameters: {'ids': _busId});
      final list = (r.data is Map && r.data['data'] is List) ? r.data['data'] as List : const [];
      _fails = 0;
      if (list.isEmpty) {
        FlutterForegroundTask.updateService(notificationTitle: _title('Offline'), notificationText: 'The bus is not sharing its location right now');
        _send({'state': 'OFFLINE'});
        return;
      }
      final p = Map<String, dynamic>.from(list.first);
      final age = (p['ageSec'] as num?)?.toInt() ?? 9999;
      final state = age > _staleAfter ? 'OFFLINE' : (p['state'] ?? 'STOPPED').toString();
      final speed = ((p['speedKmh'] as num?)?.toDouble() ?? 0).round();
      String text;
      double? km; int? min;
      if (_stopLat != null && _stopLng != null && p['lat'] != null && state != 'OFFLINE') {
        km = _haversine((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble(), _stopLat!, _stopLng!) * 1.3;
        min = math.max(1, (km / math.max(20, speed) * 60).round());
        text = '$_stopName in ~$min min (${km.toStringAsFixed(1)} km) - $speed km/h - updated ${age}s ago';
        if (!_alerted && (min <= 2 || km <= 0.5)) {
          _alerted = true;
          await _alert('$_busName is arriving at $_stopName', 'About $min min away. Get ready!');
        }
        if (_alerted && km > 2.0) _alerted = false; // bus passed and went away: allow a new alert next lap
      } else if (state == 'OFFLINE') {
        text = 'Not sharing location right now (last seen ${age}s ago)';
      } else {
        text = '${state == 'MOVING' ? 'Moving' : 'Stopped'} - $speed km/h - updated ${age}s ago';
      }
      FlutterForegroundTask.updateService(notificationTitle: _title(state == 'MOVING' ? 'Moving' : state == 'STOPPED' ? 'Stopped' : 'Offline'), notificationText: text);
      _send({'state': state, 'speedKmh': speed, 'ageSec': age, 'km': km, 'min': min, 'lat': p['lat'], 'lng': p['lng']});
    } catch (_) {
      _fails++;
      if (_fails >= 3) FlutterForegroundTask.updateService(notificationTitle: _title('No network'), notificationText: 'Retrying...');
    }
  }

  Future<void> _alert(String title, String body) async {
    if (!_notifReady) return;
    try {
      await _notif.show(
        9001, title, body,
        const NotificationDetails(android: AndroidNotificationDetails(
          'transport_arrival', 'Bus arrival alerts',
          channelDescription: 'Rings when a tracked bus is about to reach your stop',
          importance: Importance.max, priority: Priority.high, playSound: true, enableVibration: true,
        )),
      );
    } catch (_) {}
  }

  void _send(Map<String, dynamic> m) {
    try { FlutterForegroundTask.sendDataToMain({'track': true, 'busId': _busId, ...m}); } catch (_) {}
  }

  double _haversine(double la1, double lo1, double la2, double lo2) {
    const r = 6371.0;
    final dLat = (la2 - la1) * math.pi / 180, dLon = (lo2 - lo1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(la1 * math.pi / 180) * math.cos(la2 * math.pi / 180) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
  @override
  void onReceiveData(Object data) {}
  @override
  void onNotificationButtonPressed(String id) { if (id == 'stop') FlutterForegroundTask.stopService(); }
  @override
  void onNotificationPressed() { FlutterForegroundTask.launchApp('/customer/transport'); }
  @override
  void onNotificationDismissed() {}
}

/// Start / stop passenger tracking from the UI.
class TransportTrackService {
  static Timer? _webTimer;
  static int? _activeBusId;
  static int? get activeBusId => _activeBusId;
  static void Function(Map<String, dynamic>)? listener;

  static Future<bool> start({
    required int busId, required String busName, String? operator,
    String? stopName, double? stopLat, double? stopLng, int staleAfter = 120,
  }) async {
    _activeBusId = busId;
    if (kIsWeb) { _webTimer?.cancel(); _webTimer = Timer.periodic(const Duration(seconds: 10), (_) => listener?.call({'track': true, 'busId': busId, 'web': true})); return true; }
    await FlutterForegroundTask.saveData(key: TransportTrackKeys.busId, value: busId);
    await FlutterForegroundTask.saveData(key: TransportTrackKeys.busName, value: busName);
    await FlutterForegroundTask.saveData(key: TransportTrackKeys.operator, value: operator ?? '');
    if (stopName != null) await FlutterForegroundTask.saveData(key: TransportTrackKeys.stopName, value: stopName); else await FlutterForegroundTask.removeData(key: TransportTrackKeys.stopName);
    if (stopLat != null) await FlutterForegroundTask.saveData(key: TransportTrackKeys.stopLat, value: stopLat); else await FlutterForegroundTask.removeData(key: TransportTrackKeys.stopLat);
    if (stopLng != null) await FlutterForegroundTask.saveData(key: TransportTrackKeys.stopLng, value: stopLng); else await FlutterForegroundTask.removeData(key: TransportTrackKeys.stopLng);
    await FlutterForegroundTask.saveData(key: TransportTrackKeys.staleAfter, value: staleAfter);
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'transport_track',
        channelName: 'Bus tracking',
        channelDescription: 'Shows the bus you are tracking and its arrival time',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(10000),
        autoRunOnBoot: false, autoRunOnMyPackageReplaced: false, allowWakeLock: true, allowWifiLock: true,
      ),
    );
    if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
    final result = await FlutterForegroundTask.startService(
      serviceId: TransportTrackKeys.serviceId,
      notificationTitle: '$busName - Tracking',
      notificationText: 'Waiting for the bus position...',
      notificationButtons: [const NotificationButton(id: 'stop', text: 'Stop tracking')],
      callback: transportTrackCallback,
    );
    final ok = result is ServiceRequestSuccess;
    if (!ok) _activeBusId = null;
    return ok;
  }

  static Future<void> stop() async {
    _activeBusId = null;
    if (kIsWeb) { _webTimer?.cancel(); _webTimer = null; return; }
    if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
  }

  static Future<bool> get isRunning async => kIsWeb ? _webTimer != null : await FlutterForegroundTask.isRunningService;
}
