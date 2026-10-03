import 'dart:async';
import 'dart:convert';
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
  static const pathJson = 'tr_track_path';      // [{name,lat,lng}] in travel order (A .. B)
  static const legDep = 'tr_track_leg_dep';      // HH:mm
  static const legArr = 'tr_track_leg_arr';      // HH:mm
  static const fromName = 'tr_track_from';
  static const toName = 'tr_track_to';
  static const stopIdx = 'tr_track_stop_idx';    // index into path of my stop (-1 none)
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
  List<Map<String, dynamic>> _path = [];
  List<double> _cum = [];
  String? _legDep, _legArr;
  String _from = '', _to = '';
  int _stopIdx = -1;
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
    try {
      final raw = await FlutterForegroundTask.getData<String>(key: TransportTrackKeys.pathJson);
      if (raw != null && raw.isNotEmpty) _path = List<Map<String, dynamic>>.from((jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) { _path = []; }
    _cum = [0];
    for (var i = 1; i < _path.length; i++) {
      _cum.add(_cum.last + _haversine(_d(_path[i - 1]['lat']), _d(_path[i - 1]['lng']), _d(_path[i]['lat']), _d(_path[i]['lng'])));
    }
    _legDep = await FlutterForegroundTask.getData<String>(key: TransportTrackKeys.legDep);
    _legArr = await FlutterForegroundTask.getData<String>(key: TransportTrackKeys.legArr);
    _from = await FlutterForegroundTask.getData<String>(key: TransportTrackKeys.fromName) ?? '';
    _to = await FlutterForegroundTask.getData<String>(key: TransportTrackKeys.toName) ?? '';
    _stopIdx = await FlutterForegroundTask.getData<int>(key: TransportTrackKeys.stopIdx) ?? -1;
    _dio = Dio(BaseOptions(baseUrl: EnvConfig.fullApiUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
    try {
      await _notif.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      _notifReady = true;
    } catch (_) {}
    FlutterForegroundTask.updateService(notificationTitle: _title('Tracking'), notificationText: 'Waiting for the bus position...');
    _tick();
  }

  String _title(String st) {
    final route = (_from.isNotEmpty && _to.isNotEmpty) ? ' \u00b7 $_from \u2192 $_to' : '';
    return '$_busName$route';
  }

  double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
  static String _h12(String? hhmm) {
    if (hhmm == null) return '';
    final p = hhmm.split(':'); if (p.length < 2) return hhmm;
    final h = int.tryParse(p[0]) ?? 0, m = int.tryParse(p[1]) ?? 0;
    return '${h % 12 == 0 ? 12 : h % 12}:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
  }
  static int _min(String? hhmm) { if (hhmm == null) return 0; final p = hhmm.split(':'); return (int.tryParse(p[0]) ?? 0) * 60 + (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0); }
  static String _fmtMin(double m) { final mm = m.round() % 1440; return _h12('${mm ~/ 60}:${(mm % 60).toString().padLeft(2, '0')}'); }
  double get _nowMin { final n = DateTime.now(); return n.hour * 60 + n.minute + n.second / 60.0; }

  /// Fraction 0..1 of the path covered by the nearest point on the path to (lat,lng).
  double _progress(double lat, double lng) {
    if (_path.length < 2) return 0;
    var best = double.infinity, bestAcc = 0.0;
    for (var i = 1; i < _path.length; i++) {
      final ax = _d(_path[i - 1]['lat']), ay = _d(_path[i - 1]['lng']), bx = _d(_path[i]['lat']), by = _d(_path[i]['lng']);
      final seg = _cum[i] - _cum[i - 1];
      final den = (bx - ax) * (bx - ax) + (by - ay) * (by - ay);
      final t = den == 0 ? 0.0 : (((lat - ax) * (bx - ax) + (lng - ay) * (by - ay)) / den).clamp(0.0, 1.0);
      final qx = ax + (bx - ax) * t, qy = ay + (by - ay) * t;
      final dq = _haversine(lat, lng, qx, qy);
      if (dq < best) { best = dq; bestAcc = _cum[i - 1] + seg * t; }
    }
    return _cum.last == 0 ? 0 : bestAcc / _cum.last;
  }

  /// Name of the path point just behind / nearest to a progress fraction.
  String _nearName(double frac) {
    if (_path.isEmpty) return '';
    final target = frac * _cum.last;
    var bestI = 0, bestD = double.infinity;
    for (var i = 0; i < _path.length; i++) { final d = (_cum[i] - target).abs(); if (d < bestD) { bestD = d; bestI = i; } }
    return '${_path[bestI]['name']}';
  }

  /// Scheduled clock time at path index i for the current leg.
  String _timeAt(int i) {
    if (_legDep == null || _legArr == null || _cum.isEmpty || _cum.last == 0) return '';
    final dep = _min(_legDep), arr = _min(_legArr);
    return _fmtMin(dep + (arr - dep) * (_cum[i] / _cum.last));
  }

  @override
  void onRepeatEvent(DateTime timestamp) { _tick(); }

  Future<void> _tick() async {
    if (_busId == null || _dio == null) return;
    try {
      final r = await _dio!.get('/transport/public/positions', queryParameters: {'ids': _busId});
      final list = (r.data is Map && r.data['data'] is List) ? r.data['data'] as List : const [];
      _fails = 0;
      final p = list.isEmpty ? null : Map<String, dynamic>.from(list.first);
      final age = p == null ? 9999 : (p['ageSec'] as num?)?.toInt() ?? 9999;
      final live = p != null && p['lat'] != null && age <= _staleAfter;
      final state = !live ? 'OFFLINE' : (p['state'] ?? 'STOPPED').toString();
      final speed = p == null ? 0 : ((p['speedKmh'] as num?)?.toDouble() ?? 0).round();
      final myStop = _stopIdx >= 0 && _stopIdx < _path.length ? '${_path[_stopIdx]['name']}' : null;
      final parts = <String>[];
      double? km; int? min;

      if (live) {
        final frac = _path.length >= 2 ? _progress(_d(p['lat']), _d(p['lng'])) : 0.0;
        if (_path.length >= 2) parts.add('Near ${_nearName(frac)} \u00b7 $speed km/h');
        else parts.add('${state == 'MOVING' ? 'Moving' : 'Stopped'} \u00b7 $speed km/h');
        if (myStop != null) {
          final stopFrac = _cum.last == 0 ? 0.0 : _cum[_stopIdx] / _cum.last;
          if (stopFrac < frac - 0.01) {
            parts.add('Bus has passed $myStop');
          } else {
            km = (stopFrac - frac) * _cum.last;
            min = math.max(1, (km / math.max(20, speed) * 60).round());
            parts.add('$myStop in ~$min min (${km.toStringAsFixed(1)} km)');
            if (!_alerted && (min <= 2 || km <= 0.5)) { _alerted = true; await _alert('$_busName is arriving at $myStop', 'About $min min away. Get ready!'); }
            if (_alerted && km > 2.0) _alerted = false;
          }
        }
        if (_to.isNotEmpty && _legArr != null) parts.add('$_to ${_h12(_legArr)}');
      } else {
        // GPS off: fall back to the timetable position
        final dep = _min(_legDep), arr = _min(_legArr), now = _nowMin;
        if (_legDep != null && _legArr != null && arr > dep && now >= dep && now <= arr && _path.length >= 2) {
          final frac = (now - dep) / (arr - dep);
          parts.add('GPS off \u00b7 by timetable near ${_nearName(frac)}');
          if (myStop != null) parts.add('$myStop ~${_timeAt(_stopIdx)}');
          if (_to.isNotEmpty) parts.add('$_to ${_h12(_legArr)}');
        } else if (_legDep != null && now < dep) {
          parts.add('Departs $_from at ${_h12(_legDep)}');
          if (myStop != null) parts.add('$myStop ~${_timeAt(_stopIdx)}');
          if (_to.isNotEmpty) parts.add('$_to ${_h12(_legArr)}');
        } else if (_legArr != null && now > arr) {
          parts.add('Trip reached $_to at ${_h12(_legArr)}');
        } else {
          parts.add('Not sharing location right now${p != null ? ' (last seen ${age}s ago)' : ''}');
        }
      }
      final text = parts.join(' \u00b7 ');
      FlutterForegroundTask.updateService(notificationTitle: _title(state), notificationText: text);
      _send({'state': state, 'speedKmh': speed, 'ageSec': age, 'km': km, 'min': min, 'lat': p?['lat'], 'lng': p?['lng'], 'text': text});
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
    List<Map<String, dynamic>> path = const [], String? legDep, String? legArr, String from = '', String to = '', int stopIdx = -1,
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
    await FlutterForegroundTask.saveData(key: TransportTrackKeys.pathJson, value: jsonEncode(path.map((q) => {'name': q['name'], 'lat': q['lat'], 'lng': q['lng']}).toList()));
    if (legDep != null) await FlutterForegroundTask.saveData(key: TransportTrackKeys.legDep, value: legDep); else await FlutterForegroundTask.removeData(key: TransportTrackKeys.legDep);
    if (legArr != null) await FlutterForegroundTask.saveData(key: TransportTrackKeys.legArr, value: legArr); else await FlutterForegroundTask.removeData(key: TransportTrackKeys.legArr);
    await FlutterForegroundTask.saveData(key: TransportTrackKeys.fromName, value: from);
    await FlutterForegroundTask.saveData(key: TransportTrackKeys.toName, value: to);
    await FlutterForegroundTask.saveData(key: TransportTrackKeys.stopIdx, value: stopIdx);
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
      notificationTitle: '$busName${from.isNotEmpty ? ' \u00b7 $from \u2192 $to' : ''}',
      notificationText: 'Starting tracking...',
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
