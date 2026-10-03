import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/language_provider.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../services/transport_gps_task.dart';
import '../../services/transport_service.dart';
import '../../services/transport_timetable.dart';

/// Driver mode: pick the assigned vehicle, start a trip, and the phone shares
/// GPS through an Android foreground service until the trip is ended.
class TransportDriverScreen extends StatefulWidget {
  const TransportDriverScreen({super.key});

  @override
  State<TransportDriverScreen> createState() => _TransportDriverScreenState();
}

class _TransportDriverScreenState extends State<TransportDriverScreen> {
  static const _accent = Color(0xFF1565C0);
  final _svc = TransportService.instance;
  bool _loading = true;
  String? _error;
  String _driverName = '';
  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic>? _openTrip;
  int? _selectedVehicle;
  String _direction = 'AB';
  int? _scheduleId;
  bool _busy = false;
  Map<String, dynamic> _live = {};
  bool _serviceRunning = false;

  String _t(String en, String ta) => Provider.of<LanguageProvider>(context, listen: false).getText(en, ta);
  int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    TransportGpsService.init();
    if (kIsWeb) { TransportGpsService.webListener = _onTaskData; } else { FlutterForegroundTask.addTaskDataCallback(_onTaskData); }
    _load();
  }

  @override
  void dispose() {
    if (kIsWeb) { TransportGpsService.webListener = null; } else { FlutterForegroundTask.removeTaskDataCallback(_onTaskData); }
    super.dispose();
  }

  void _onTaskData(Object data) {
    if (data is Map && mounted) {
      setState(() => _live = Map<String, dynamic>.from(data));
      if (data['tripEnded'] == true && _openTrip != null) {
        _openTrip = null;
        TransportGpsService.stop();
        _load();
      }
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final r = await _svc.driverContext();
    _serviceRunning = await TransportGpsService.isRunning;
    if (!mounted) return;
    if (r['success'] != true) { setState(() { _loading = false; _error = r['message']?.toString(); }); return; }
    final d = Map<String, dynamic>.from(r['data'] ?? {});
    _driverName = d['driverName']?.toString() ?? '';
    _vehicles = List<Map<String, dynamic>>.from((d['vehicles'] ?? []).map((e) => Map<String, dynamic>.from(e)));
    _openTrip = d['openTrip'] is Map ? Map<String, dynamic>.from(d['openTrip']) : null;
    if (_openTrip != null) _selectedVehicle = _i(_openTrip!['vehicleId']);
    _selectedVehicle ??= _vehicles.isNotEmpty ? _i(_vehicles.first['id']) : null;
    _pickDefaultDeparture();
    setState(() => _loading = false);
    // A trip is open on the server but the service died (phone restart etc.) → restart it.
    if (_openTrip != null && !_serviceRunning) _startService(_openTrip!);
  }

  void _pickDefaultDeparture() {
    final v = _vehicle(_selectedVehicle);
    final rows = (v?['schedules'] is List) ? v!['schedules'] as List : const [];
    final near = TransportTimetable.nearest(rows);
    _scheduleId = near == null ? null : _i(near['id']);
    _direction = near?['direction']?.toString() ?? _direction;
  }

  Future<bool> _ensurePermissions() async {
    // Location
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      _msg(_t('Location permission is required to share the trip', 'பயணத்தை பகிர இருப்பிட அனுமதி தேவை'));
      return false;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      _msg(_t('Please turn on GPS / Location', 'GPS ஐ இயக்கவும்'));
      await Geolocator.openLocationSettings();
      return false;
    }
    // Notification (Android 13+) so the foreground service can show its notice
    try { await Permission.notification.request(); } catch (_) {}
    // Battery optimisation: ask once so the service isn't killed on cheap phones
    if (kIsWeb) return true;
    try {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    } catch (_) {}
    return true;
  }

  Map<String, dynamic>? _vehicle(int? id) => _vehicles.cast<Map<String, dynamic>?>().firstWhere((v) => v!['id'] == id, orElse: () => null);

  Future<void> _startTrip() async {
    if (_selectedVehicle == null) return;
    if (!await _ensurePermissions()) return;
    setState(() => _busy = true);
    final r = await _svc.startTrip(_selectedVehicle!, direction: _direction, scheduleId: _scheduleId);
    if (!mounted) return;
    if (r['success'] != true) { setState(() => _busy = false); _msg(r['message']?.toString() ?? ''); return; }
    final d = Map<String, dynamic>.from(r['data'] ?? {});
    _openTrip = d['trip'] is Map ? Map<String, dynamic>.from(d['trip']) : null;
    final interval = _i(d['gpsIntervalSec']) == 0 ? 5 : _i(d['gpsIntervalSec']);
    if (_openTrip != null) {
      _openTrip!['gpsIntervalSec'] = interval;
      await _startService(_openTrip!);
    }
    setState(() => _busy = false);
  }

  Future<void> _startService(Map<String, dynamic> trip) async {
    final token = await SecureStorage.getAuthToken() ?? '';
    final v = _vehicle(_i(trip['vehicleId']));
    final interval = _i(trip['gpsIntervalSec']) != 0 ? _i(trip['gpsIntervalSec']) : (_i(v?['gpsIntervalSec']) != 0 ? _i(v?['gpsIntervalSec']) : 5);
    final ok = await TransportGpsService.start(
      token: token, tripId: _i(trip['id']), vehicleId: _i(trip['vehicleId']),
      vehicleName: v?['name']?.toString() ?? 'Vehicle', intervalSec: interval,
    );
    _serviceRunning = ok;
    if (!ok) _msg(_t('Could not start location sharing. Check notification permission.', 'இருப்பிட பகிர்வை தொடங்க முடியவில்லை.'));
    if (mounted) setState(() {});
  }

  Future<void> _endTrip() async {
    if (_openTrip == null) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_t('End trip?', 'பயணத்தை முடிக்கவா?')),
        content: Text(_t('Location sharing will stop.', 'இருப்பிட பகிர்வு நிறுத்தப்படும்.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_t('Cancel', 'ரத்து'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(_t('End trip', 'முடி'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (sure != true) return;
    setState(() => _busy = true);
    await TransportGpsService.stop();
    final km = (_live['distanceKm'] as num?)?.toDouble();
    final r = await _svc.endTrip(_i(_openTrip!['id']), distanceKm: km);
    if (!mounted) return;
    _msg(r['message']?.toString() ?? '');
    _openTrip = null;
    _live = {};
    setState(() => _busy = false);
    _load();
  }

  void _msg(String s) {
    if (mounted && s.isNotEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(backgroundColor: _accent, foregroundColor: Colors.white, title: Text(_t('Driver mode', 'ஓட்டுநர் முறை')), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.no_accounts_outlined, size: 44, color: Colors.grey), const SizedBox(height: 10),
                    Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 6),
                    Text(_t('Ask the bus owner to add your mobile number as a driver.', 'உங்கள் எண்ணை ஓட்டுநராக சேர்க்க உரிமையாளரிடம் கேளுங்கள்.'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
                    TextButton(onPressed: _load, child: Text(_t('Retry', 'மீண்டும்')))])))
                : _openTrip != null ? _runningView() : _idleView(),
    );
    return kIsWeb ? scaffold : WithForegroundTask(child: scaffold);
  }

  Widget _idleView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${_t('Hello', 'வணக்கம்')}, $_driverName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(_t('Choose your vehicle and start the trip. Keep the phone charged; you can lock the screen.', 'வாகனத்தை தேர்ந்தெடுத்து பயணத்தை தொடங்குங்கள். போனை சார்ஜில் வைக்கவும்; திரையை பூட்டலாம்.'), style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 16),
        if (_vehicles.isEmpty)
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Text(_t('No vehicle is assigned to you yet.', 'உங்களுக்கு வாகனம் ஒதுக்கப்படவில்லை.')))
        else
          ..._vehicles.map((v) {
            final id = _i(v['id']);
            final sel = _selectedVehicle == id;
            final route = v['route'] is Map ? v['route'] as Map : null;
            return Card(
              elevation: 0, margin: const EdgeInsets.only(bottom: 10),
              color: sel ? _accent.withOpacity(0.08) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: sel ? _accent : Colors.grey.shade200, width: sel ? 1.5 : 1)),
              child: ListTile(
                onTap: () => setState(() { _selectedVehicle = id; _pickDefaultDeparture(); }),
                leading: Icon(Icons.directions_bus, color: sel ? _accent : Colors.grey, size: 30),
                title: Text('${v['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${v['regNo']} · ${v['vehicleType']}${v['ownerName'] != null ? ' · ${v['ownerName']}' : ''}${route != null ? '\n${route['source']} → ${route['destination']}' : ''}', style: const TextStyle(fontSize: 12)),
                isThreeLine: route != null,
                trailing: sel ? const Icon(Icons.check_circle, color: _accent) : null,
              ),
            );
          }),
        if (_selectedVehicle != null) _directionPicker(),
        const SizedBox(height: 16),
        SizedBox(
          height: 58,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _busy || _selectedVehicle == null ? null : _startTrip,
            icon: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow, size: 28),
            label: Text(_t('START TRIP', 'பயணத்தை தொடங்கு'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _directionPicker() {
    final v = _vehicle(_selectedVehicle);
    final route = v?['route'] is Map ? v!['route'] as Map : null;
    final rows = (v?['schedules'] is List) ? TransportTimetable.todays(v!['schedules'] as List) : <Map<String, dynamic>>[];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_t('Which way?', '\u0b8e\u0ba8\u0bcd\u0ba4 \u0ba4\u0bbf\u0b9a\u0bc8?'), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(children: [
          for (final d in ['AB', 'BA'])
            Expanded(child: Padding(
              padding: EdgeInsets.only(right: d == 'AB' ? 6 : 0),
              child: ChoiceChip(
                label: Text(TransportTimetable.dirLabel(route, d), overflow: TextOverflow.ellipsis),
                selected: _direction == d,
                selectedColor: _accent.withOpacity(0.15),
                onSelected: (_) => setState(() { _direction = d; _scheduleId = null; }),
              ),
            )),
        ]),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(_t("Today's departures", '\u0b87\u0ba9\u0bcd\u0bb1\u0bc8\u0baf \u0baa\u0bc1\u0bb1\u0baa\u0bcd\u0baa\u0bbe\u0b9f\u0bc1\u0b95\u0bb3\u0bcd'), style: TextStyle(fontSize: 12.5, color: Colors.grey[700], fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final r in rows)
              ChoiceChip(
                label: Text('${TransportTimetable.h12(r['departTime'])} ${r['direction'] == 'BA' ? 'B\u2192A' : 'A\u2192B'}'),
                selected: _scheduleId == _i(r['id']),
                selectedColor: const Color(0xFFE8F5E9),
                onSelected: (_) => setState(() { _scheduleId = _i(r['id']); _direction = r['direction']?.toString() ?? 'AB'; }),
              ),
          ]),
        ],
      ]),
    );
  }

  Widget _runningView() {
    final v = _vehicle(_i(_openTrip!['vehicleId']));
    final status = _live['status']?.toString() ?? (_serviceRunning ? _t('Starting…', 'தொடங்குகிறது…') : _t('Service not running', 'சேவை இயங்கவில்லை'));
    final speed = (_live['speedKmh'] as num?)?.round() ?? 0;
    final km = (_live['distanceKm'] as num?)?.toDouble() ?? 0;
    final sent = _i(_live['sent']);
    final buffered = _i(_live['buffered']);
    final liveOk = status == 'Live';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [liveOk ? const Color(0xFF2E7D32) : Colors.orange.shade800, liveOk ? const Color(0xFF43A047) : Colors.orange.shade600]), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 8),
              Text(liveOk ? _t('TRIP RUNNING · LIVE', 'பயணம் · நேரலை') : status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: .5)),
            ]),
            const SizedBox(height: 10),
            Text(v?['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            Text(v?['regNo']?.toString() ?? '', style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _tile(_t('Speed', 'வேகம்'), '$speed', 'km/h'),
          _tile(_t('Distance', 'தூரம்'), km.toStringAsFixed(1), 'km'),
          _tile(_t('Sent', 'அனுப்பியது'), '$sent', buffered > 0 ? '+$buffered ${_t('waiting', 'காத்திருக்கு')}' : _t('points', 'புள்ளிகள்')),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t('Keep this in mind', 'நினைவில் கொள்ளுங்கள்'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('• ${_t('You can lock the screen or use other apps. The notification keeps sharing running.', 'திரையை பூட்டலாம். அறிவிப்பு பகிர்வை தொடரும்.')}\n'
                '• ${_t('Do not swipe the app away from recent apps.', 'சமீபத்திய ஆப்ஸிலிருந்து ஆப்பை நீக்க வேண்டாம்.')}\n'
                '• ${_t('No network? Points are stored and sent when signal returns.', 'நெட்வொர்க் இல்லையா? சிக்னல் வந்ததும் அனுப்பப்படும்.')}',
                style: TextStyle(fontSize: 12.5, color: Colors.grey[800], height: 1.5)),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 58,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _busy ? null : _endTrip,
            icon: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.stop, size: 28),
            label: Text(_t('END TRIP', 'பயணத்தை முடி'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ),
        if (!_serviceRunning) ...[
          const SizedBox(height: 10),
          TextButton(onPressed: () => _startService(_openTrip!), child: Text(_t('Restart location sharing', 'இருப்பிட பகிர்வை மீண்டும் தொடங்கு'))),
        ],
      ],
    );
  }

  Widget _tile(String label, String value, String unit) => Expanded(child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _accent)),
          Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ));
}
