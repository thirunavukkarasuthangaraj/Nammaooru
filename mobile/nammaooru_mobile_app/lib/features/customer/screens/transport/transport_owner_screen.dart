import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/language_provider.dart';
import '../../services/transport_service.dart';

/// Fleet owner dashboard: live map of all vehicles, plus vehicles / drivers /
/// routes management and trip history. Works for any vehicle type.
class TransportOwnerScreen extends StatefulWidget {
  const TransportOwnerScreen({super.key});

  @override
  State<TransportOwnerScreen> createState() => _TransportOwnerScreenState();
}

class _TransportOwnerScreenState extends State<TransportOwnerScreen> with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF1565C0);
  static const _types = ['BUS', 'LORRY', 'VAN', 'AUTO', 'CAR', 'BIKE', 'TRACTOR', 'OTHER'];

  final _svc = TransportService.instance;
  late final TabController _tabs = TabController(length: 5, vsync: this);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _transporter;
  List<Map<String, dynamic>> _vehicles = [], _drivers = [], _routes = [], _trips = [];
  final Map<int, Map<String, dynamic>> _pos = {};
  int _staleAfter = 120;
  Timer? _poll;
  GoogleMapController? _map;
  int? _selectedVehicle;

  String _t(String en, String ta) => Provider.of<LanguageProvider>(context, listen: false).getText(en, ta);
  double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
  int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tabs.dispose();
    _map?.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _list(dynamic v) =>
      v is List ? List<Map<String, dynamic>>.from(v.map((e) => Map<String, dynamic>.from(e))) : [];

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final r = await _svc.ownerBootstrap();
    if (!mounted) return;
    if (r['success'] != true) { setState(() { _loading = false; _error = r['message']?.toString(); }); return; }
    final d = Map<String, dynamic>.from(r['data'] ?? {});
    _transporter = d['transporter'] is Map ? Map<String, dynamic>.from(d['transporter']) : null;
    _vehicles = _list(d['vehicles']);
    _drivers = _list(d['drivers']);
    _routes = _list(d['routes']);
    _staleAfter = _i(d['settings']?['staleAfterSec']) == 0 ? 120 : _i(d['settings']?['staleAfterSec']);
    _applyPositions(d['positions']);
    setState(() => _loading = false);
    _poll?.cancel();
    final pollSec = (_i(d['settings']?['pollIntervalSec']) == 0 ? 5 : _i(d['settings']?['pollIntervalSec'])).clamp(2, 60);
    _poll = Timer.periodic(Duration(seconds: pollSec), (_) => _refreshLive());
    _loadTrips();
  }

  Future<void> _refreshLive() async {
    final r = await _svc.ownerLive();
    if (!mounted || r['success'] != true) return;
    _applyPositions(r['data']);
    setState(() {});
  }

  Future<void> _loadTrips({int? vehicleId}) async {
    final r = await _svc.ownerTrips(vehicleId: vehicleId, size: 50);
    if (!mounted || r['success'] != true) return;
    final d = r['data'];
    setState(() => _trips = _list(d is Map ? d['content'] : d));
  }

  void _applyPositions(dynamic list) {
    if (list is! List) return;
    for (final e in list) {
      final m = Map<String, dynamic>.from(e);
      _pos[_i(m['vehicleId'])] = m;
    }
  }

  String _state(int id) {
    final p = _pos[id];
    if (p == null) return 'OFFLINE';
    if (_i(p['ageSec']) > _staleAfter) return 'OFFLINE';
    return (p['state'] ?? 'STOPPED').toString();
  }

  Color _stateColor(String s) => s == 'MOVING' ? const Color(0xFF2E7D32) : s == 'STOPPED' ? _accent : Colors.grey;

  IconData _typeIcon(String? t) {
    switch (t) {
      case 'BUS': return Icons.directions_bus;
      case 'LORRY': return Icons.local_shipping;
      case 'VAN': return Icons.airport_shuttle;
      case 'AUTO': return Icons.electric_rickshaw;
      case 'CAR': return Icons.directions_car;
      case 'BIKE': return Icons.two_wheeler;
      case 'TRACTOR': return Icons.agriculture;
      default: return Icons.commute;
    }
  }

  Future<void> _snack(Map<String, dynamic> r) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message']?.toString() ?? '')));
  }

  Future<bool> _confirm(String msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_t('Cancel', 'ரத்து'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(_t('Remove', 'நீக்கு'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    return ok == true;
  }

  // =====================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _accent, foregroundColor: Colors.white,
        title: Text(_transporter?['companyName']?.toString() ?? _t('My fleet', 'என் வாகனங்கள்')),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        bottom: TabBar(
          controller: _tabs, isScrollable: true, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: _t('Live', 'நேரலை')),
            Tab(text: _t('Vehicles', 'வாகனங்கள்')),
            Tab(text: _t('Drivers', 'ஓட்டுநர்கள்')),
            Tab(text: _t('Routes', 'வழிகள்')),
            Tab(text: _t('Trips', 'பயணங்கள்')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock_outline, size: 40, color: Colors.grey), const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center), TextButton(onPressed: _load, child: Text(_t('Retry', 'மீண்டும்')))])))
              : TabBarView(controller: _tabs, children: [_liveTab(), _vehiclesTab(), _driversTab(), _routesTab(), _tripsTab()]),
    );
  }

  List<LatLng> _routePathFor(Map<String, dynamic>? route) {
    if (route == null) return [];
    final pts = <LatLng>[];
    if (route['sourceLat'] != null && route['sourceLng'] != null) pts.add(LatLng(_d(route['sourceLat']), _d(route['sourceLng'])));
    for (final st in _list(route['stops'])) {
      if (st['lat'] != null && st['lng'] != null) pts.add(LatLng(_d(st['lat']), _d(st['lng'])));
    }
    if (route['destLat'] != null && route['destLng'] != null) pts.add(LatLng(_d(route['destLat']), _d(route['destLng'])));
    return pts;
  }

  // ---------------- LIVE ----------------
  Widget _liveTab() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};
    if (_selectedVehicle != null) {
      final v = _vehicles.cast<Map<String, dynamic>?>().firstWhere((x) => _i(x!['id']) == _selectedVehicle, orElse: () => null);
      final route = v == null || v['routeId'] == null ? null : _routes.cast<Map<String, dynamic>?>().firstWhere((r) => _i(r!['id']) == _i(v['routeId']), orElse: () => null);
      final pts = _routePathFor(route);
      if (pts.length > 1) {
        polylines.add(Polyline(polylineId: const PolylineId('route'), points: pts, color: _accent.withOpacity(0.6), width: 4, patterns: [PatternItem.dash(20), PatternItem.gap(12)]));
        markers.add(Marker(markerId: const MarkerId('route_from'), position: pts.first, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), infoWindow: InfoWindow(title: 'A: ${route?['source']}')));
        markers.add(Marker(markerId: const MarkerId('route_to'), position: pts.last, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), infoWindow: InfoWindow(title: 'B: ${route?['destination']}')));
      }
    }
    for (final v in _vehicles) {
      final id = _i(v['id']);
      final p = _pos[id];
      if (p == null || p['lat'] == null) continue;
      final st = _state(id);
      markers.add(Marker(
        markerId: MarkerId('v$id'),
        position: LatLng(_d(p['lat']), _d(p['lng'])),
        rotation: _d(p['heading']), flat: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(st == 'MOVING' ? BitmapDescriptor.hueGreen : st == 'STOPPED' ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(title: v['name']?.toString(), snippet: '$st · ${_d(p['speedKmh']).round()} km/h'),
        onTap: () => setState(() => _selectedVehicle = id),
      ));
    }
    final moving = _vehicles.where((v) => _state(_i(v['id'])) == 'MOVING').length;
    final stopped = _vehicles.where((v) => _state(_i(v['id'])) == 'STOPPED').length;
    final offline = _vehicles.length - moving - stopped;
    return Column(children: [
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Stack(children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(12.4966, 78.5729), zoom: 11),
            onMapCreated: (c) { _map = c; _fitAll(); },
            markers: markers, polylines: polylines, myLocationButtonEnabled: false, zoomControlsEnabled: false, mapToolbarEnabled: false,
          ),
          Positioned(right: 10, bottom: 10, child: FloatingActionButton.small(heroTag: 'fit', backgroundColor: Colors.white, foregroundColor: _accent, onPressed: _fitAll, child: const Icon(Icons.fit_screen))),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Row(children: [
          _stat(_t('Moving', 'ஓடுகிறது'), moving, const Color(0xFF2E7D32)),
          _stat(_t('Stopped', 'நின்றுள்ளது'), stopped, _accent),
          _stat(_t('Offline', 'ஆஃப்லைன்'), offline, Colors.grey),
        ]),
      ),
      Expanded(
        child: _vehicles.isEmpty
            ? Center(child: Text(_t('Add your first vehicle in the Vehicles tab.', 'வாகனங்கள் தாவலில் முதல் வாகனத்தை சேர்க்கவும்.'), style: const TextStyle(color: Colors.grey)))
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                children: _vehicles.map((v) {
                  final id = _i(v['id']);
                  final st = _state(id);
                  final p = _pos[id];
                  return Card(
                    elevation: 0, margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _selectedVehicle == id ? _accent : Colors.grey.shade200)),
                    child: ListTile(
                      onTap: () {
                        setState(() => _selectedVehicle = id);
                        if (p != null && p['lat'] != null) _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(_d(p['lat']), _d(p['lng'])), 15));
                      },
                      leading: CircleAvatar(backgroundColor: _stateColor(st).withOpacity(0.15), child: Icon(_typeIcon(v['vehicleType']?.toString()), color: _stateColor(st))),
                      title: Text('${v['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text([
                        if (v['driverName'] != null) '${_t('Driver', 'ஓட்டுநர்')}: ${v['driverName']}',
                        if (p != null && st != 'OFFLINE') '${_d(p['speedKmh']).round()} km/h',
                        p != null ? '${_i(p['ageSec'])}s ${_t('ago', 'முன்')}' : _t('no signal yet', 'சிக்னல் இல்லை'),
                      ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: _chip(st),
                    ),
                  );
                }).toList(),
              ),
      ),
    ]);
  }

  Widget _stat(String label, int n, Color c) => Expanded(child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [Text('$n', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)), Text(label, style: TextStyle(fontSize: 11, color: c))]),
      ));

  Widget _chip(String st) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: _stateColor(st).withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
        child: Text(st, style: TextStyle(color: _stateColor(st), fontSize: 11, fontWeight: FontWeight.w700)),
      );

  void _fitAll() {
    final pts = _pos.values.where((p) => p['lat'] != null).map((p) => LatLng(_d(p['lat']), _d(p['lng']))).toList();
    if (pts.isEmpty || _map == null) return;
    if (pts.length == 1) { _map!.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 14)); return; }
    double minLat = pts.first.latitude, maxLat = minLat, minLng = pts.first.longitude, maxLng = minLng;
    for (final p in pts) { minLat = math.min(minLat, p.latitude); maxLat = math.max(maxLat, p.latitude); minLng = math.min(minLng, p.longitude); maxLng = math.max(maxLng, p.longitude); }
    _map!.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 60));
  }

  // ---------------- VEHICLES ----------------
  Widget _vehiclesTab() => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(heroTag: 'addV', backgroundColor: _accent, foregroundColor: Colors.white, onPressed: () => _editVehicle(null), icon: const Icon(Icons.add), label: Text(_t('Add vehicle', 'வாகனம் சேர்'))),
        body: _vehicles.isEmpty
            ? Center(child: Text(_t('No vehicles yet', 'வாகனங்கள் இல்லை'), style: const TextStyle(color: Colors.grey)))
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: _vehicles.map((v) => Card(
                      elevation: 0, margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        onTap: () => _editVehicle(v),
                        leading: CircleAvatar(backgroundColor: _accent.withOpacity(0.1), child: Icon(_typeIcon(v['vehicleType']?.toString()), color: _accent)),
                        title: Text('${v['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text([
                          '${v['vehicleType']} · ${v['regNo']}',
                          if (v['routeName'] != null) '${v['routeName']}',
                          if (v['driverName'] != null) '${_t('Driver', 'ஓட்டுநர்')}: ${v['driverName']}' else _t('No driver assigned', 'ஓட்டுநர் இல்லை'),
                          if (v['isPublic'] == true) _t('Public on Where is Bus', 'பொதுவில் காட்டப்படும்'),
                        ].join('\n'), style: const TextStyle(fontSize: 12)),
                        isThreeLine: true,
                        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () async {
                          if (await _confirm('${_t('Remove vehicle', 'வாகனத்தை நீக்கு')} ${v['name']}?')) { _snack(await _svc.deleteVehicle(_i(v['id']))); _load(); }
                        }),
                      ),
                    )).toList(),
              ),
      );

  Future<void> _editVehicle(Map<String, dynamic>? v) async {
    final name = TextEditingController(text: v?['name']?.toString() ?? '');
    final reg = TextEditingController(text: v?['regNo']?.toString() ?? '');
    String type = v?['vehicleType']?.toString() ?? 'BUS';
    int? routeId = v?['routeId'] == null ? null : _i(v!['routeId']);
    int? driverId = v?['driverId'] == null ? null : _i(v!['driverId']);
    bool isPublic = v?['isPublic'] == true;
    final saved = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => _sheet(ctx, v == null ? _t('Add vehicle', 'வாகனம் சேர்') : _t('Edit vehicle', 'வாகனம் திருத்து'), [
        DropdownButtonFormField<String>(
          value: type, decoration: InputDecoration(labelText: _t('Vehicle type', 'வாகன வகை'), border: const OutlineInputBorder()),
          items: _types.map((t) => DropdownMenuItem(value: t, child: Row(children: [Icon(_typeIcon(t), size: 18), const SizedBox(width: 8), Text(t)]))).toList(),
          onChanged: (x) => setS(() { type = x ?? 'BUS'; if (type != 'BUS') isPublic = false; }),
        ),
        const SizedBox(height: 12),
        TextField(controller: reg, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: _t('Registration number *', 'பதிவு எண் *'), hintText: 'TN23AB1234', border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: name, decoration: InputDecoration(labelText: _t('Display name', 'காட்சி பெயர்'), hintText: _t('e.g. Route 7 Morning', 'எ.கா. வழி 7'), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          value: routeId, decoration: InputDecoration(labelText: _t('Route', 'வழி'), border: const OutlineInputBorder()),
          items: [DropdownMenuItem<int?>(value: null, child: Text(_t('No route', 'வழி இல்லை'))), ..._routes.map((r) => DropdownMenuItem<int?>(value: _i(r['id']), child: Text('${r['name']}', overflow: TextOverflow.ellipsis)))],
          onChanged: (x) => setS(() => routeId = x),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          value: driverId, decoration: InputDecoration(labelText: _t('Driver', 'ஓட்டுநர்'), border: const OutlineInputBorder()),
          items: [DropdownMenuItem<int?>(value: null, child: Text(_t('No driver', 'ஓட்டுநர் இல்லை'))), ..._drivers.map((d) => DropdownMenuItem<int?>(value: _i(d['id']), child: Text('${d['name']} · ${d['phone']}', overflow: TextOverflow.ellipsis)))],
          onChanged: (x) => setS(() => driverId = x),
        ),
        if (type == 'BUS')
          SwitchListTile(
            contentPadding: EdgeInsets.zero, activeColor: _accent,
            value: isPublic, onChanged: (x) => setS(() => isPublic = x),
            title: Text(_t('Show to public on Where is Bus', 'பொதுமக்களுக்கு காட்டு')),
            subtitle: Text(_t('Passengers can see this bus live', 'பயணிகள் இந்த பஸ்ஸை நேரலையில் பார்க்கலாம்'), style: const TextStyle(fontSize: 12)),
          ),
        const SizedBox(height: 8),
        _saveBtn(ctx, () async {
          final r = await _svc.saveVehicle({'id': v?['id'], 'vehicleType': type, 'regNo': reg.text, 'name': name.text, 'routeId': routeId, 'driverId': driverId, 'isPublic': isPublic});
          _snack(r); return r['success'] == true;
        }),
      ])),
    );
    if (saved == true) _load();
  }

  // ---------------- DRIVERS ----------------
  Widget _driversTab() => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(heroTag: 'addD', backgroundColor: _accent, foregroundColor: Colors.white, onPressed: () => _editDriver(null), icon: const Icon(Icons.person_add_alt), label: Text(_t('Add driver', 'ஓட்டுநர் சேர்'))),
        body: Column(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
            child: Text(_t('The driver installs this same app, logs in with the mobile number you add here, and opens Where is Bus → Driver mode to start a trip.',
                'ஓட்டுநர் இதே ஆப்பை நிறுவி, இங்கு சேர்த்த எண்ணில் உள்நுழைந்து, பஸ் எங்கே → ஓட்டுநர் முறையில் பயணத்தை தொடங்குவார்.'), style: const TextStyle(fontSize: 12.5)),
          ),
          Expanded(
            child: _drivers.isEmpty
                ? Center(child: Text(_t('No drivers yet', 'ஓட்டுநர்கள் இல்லை'), style: const TextStyle(color: Colors.grey)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    children: _drivers.map((d) {
                      final assigned = _vehicles.where((v) => v['driverId'] != null && _i(v['driverId']) == _i(d['id'])).map((v) => v['name']).join(', ');
                      return Card(
                        elevation: 0, margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                        child: ListTile(
                          onTap: () => _editDriver(d),
                          leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.person, color: _accent)),
                          title: Text('${d['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${d['phone']}${assigned.isNotEmpty ? '\n$assigned' : ''}', style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () async {
                            if (await _confirm('${_t('Remove driver', 'ஓட்டுநரை நீக்கு')} ${d['name']}?')) { _snack(await _svc.deleteDriver(_i(d['id']))); _load(); }
                          }),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ]),
      );

  Future<void> _editDriver(Map<String, dynamic>? d) async {
    final name = TextEditingController(text: d?['name']?.toString() ?? '');
    final phone = TextEditingController(text: d?['phone']?.toString() ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _sheet(ctx, d == null ? _t('Add driver', 'ஓட்டுநர் சேர்') : _t('Edit driver', 'ஓட்டுநர் திருத்து'), [
        TextField(controller: name, decoration: InputDecoration(labelText: _t('Driver name *', 'ஓட்டுநர் பெயர் *'), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: _t('Mobile number (10 digits) *', 'மொபைல் எண் (10 இலக்கம்) *'), border: const OutlineInputBorder())),
        const SizedBox(height: 16),
        _saveBtn(ctx, () async { final r = await _svc.saveDriver({'id': d?['id'], 'name': name.text, 'phone': phone.text}); _snack(r); return r['success'] == true; }),
      ]),
    );
    if (saved == true) _load();
  }

  // ---------------- ROUTES ----------------
  Widget _routesTab() => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(heroTag: 'addR', backgroundColor: _accent, foregroundColor: Colors.white, onPressed: () => _editRoute(null), icon: const Icon(Icons.add_road), label: Text(_t('Add route', 'வழி சேர்'))),
        body: _routes.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_t('Routes are optional. Add one with stops so passengers can pick their stop and see arrival time.', 'வழிகள் விருப்பத்திற்குரியவை. நிறுத்தங்களுடன் சேர்த்தால் பயணிகள் வருகை நேரத்தை பார்க்கலாம்.'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))))
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: _routes.map((r) {
                  final stops = _list(r['stops']);
                  return Card(
                    elevation: 0, margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      onTap: () => _editRoute(r),
                      leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.route, color: Color(0xFF2E7D32))),
                      title: Text('${r['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${r['source']} → ${r['destination']} · ${stops.length} ${_t('stops', 'நிறுத்தங்கள்')}', style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () async {
                        if (await _confirm('${_t('Remove route', 'வழியை நீக்கு')} ${r['name']}?')) { _snack(await _svc.deleteRoute(_i(r['id']))); _load(); }
                      }),
                    ),
                  );
                }).toList(),
              ),
      );

  Future<void> _editRoute(Map<String, dynamic>? r) async {
    final name = TextEditingController(text: r?['name']?.toString() ?? '');
    final src = TextEditingController(text: r?['source']?.toString() ?? '');
    final dst = TextEditingController(text: r?['destination']?.toString() ?? '');
    final srcLat = TextEditingController(text: r?['sourceLat']?.toString() ?? '');
    final srcLng = TextEditingController(text: r?['sourceLng']?.toString() ?? '');
    final dstLat = TextEditingController(text: r?['destLat']?.toString() ?? '');
    final dstLng = TextEditingController(text: r?['destLng']?.toString() ?? '');
    Future<void> fillHere(TextEditingController la, TextEditingController ln, void Function(void Function()) setS) async {
      try {
        final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)));
        setS(() { la.text = p.latitude.toStringAsFixed(6); ln.text = p.longitude.toStringAsFixed(6); });
      } catch (_) {}
    }
    Widget pointRow(String tag, Color c, TextEditingController nameC, String label, TextEditingController la, TextEditingController ln, void Function(void Function()) setS) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        CircleAvatar(radius: 11, backgroundColor: c, child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
        const SizedBox(width: 6),
        Expanded(flex: 3, child: TextField(controller: nameC, decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()))),
        const SizedBox(width: 6),
        Expanded(flex: 2, child: TextField(controller: la, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Lat', isDense: true, border: OutlineInputBorder()))),
        const SizedBox(width: 6),
        Expanded(flex: 2, child: TextField(controller: ln, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Lng', isDense: true, border: OutlineInputBorder()))),
        IconButton(visualDensity: VisualDensity.compact, tooltip: _t('Use my location', '\u0b8e\u0ba9\u0bcd \u0b87\u0bb0\u0bc1\u0baa\u0bcd\u0baa\u0bbf\u0b9f\u0bae\u0bcd'), icon: const Icon(Icons.my_location, size: 20, color: _accent), onPressed: () => fillHere(la, ln, setS)),
      ]),
    );
    final stops = _list(r?['stops']).map((s) => {
      'name': TextEditingController(text: s['name']?.toString() ?? ''),
      'lat': TextEditingController(text: s['lat']?.toString() ?? ''),
      'lng': TextEditingController(text: s['lng']?.toString() ?? ''),
    }).toList();
    final saved = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => _sheet(ctx, r == null ? _t('Add route', 'வழி சேர்') : _t('Edit route', 'வழி திருத்து'), [
        TextField(controller: name, decoration: InputDecoration(labelText: _t('Route name', 'வழி பெயர்'), hintText: _t('e.g. Route 7', 'எ.கா. வழி 7'), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        pointRow('A', const Color(0xFF2E7D32), src, _t('From *', '\u0b87\u0bb0\u0bc1\u0ba8\u0bcd\u0ba4\u0bc1 *'), srcLat, srcLng, setS),
        pointRow('B', const Color(0xFFC62828), dst, _t('To *', '\u0bb5\u0bb0\u0bc8 *'), dstLat, dstLng, setS),
        const SizedBox(height: 14),
        Row(children: [
          Text(_t('Stops (in order)', 'நிறுத்தங்கள் (வரிசையில்)'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton.icon(onPressed: () => setS(() => stops.add({'name': TextEditingController(), 'lat': TextEditingController(), 'lng': TextEditingController()})), icon: const Icon(Icons.add, size: 18), label: Text(_t('Add stop', 'நிறுத்தம் சேர்'))),
        ]),
        for (var i = 0; i < stops.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Expanded(flex: 3, child: TextField(controller: stops[i]['name'], decoration: InputDecoration(labelText: _t('Stop', 'நிறுத்தம்'), isDense: true, border: const OutlineInputBorder()))),
              const SizedBox(width: 6),
              Expanded(flex: 2, child: TextField(controller: stops[i]['lat'], keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Lat', isDense: true, border: OutlineInputBorder()))),
              const SizedBox(width: 6),
              Expanded(flex: 2, child: TextField(controller: stops[i]['lng'], keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Lng', isDense: true, border: OutlineInputBorder()))),
              IconButton(visualDensity: VisualDensity.compact, tooltip: _t('Use my location', 'என் இருப்பிடம்'), icon: const Icon(Icons.my_location, size: 20, color: _accent), onPressed: () async {
                try {
                  final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)));
                  setS(() { stops[i]['lat']!.text = p.latitude.toStringAsFixed(6); stops[i]['lng']!.text = p.longitude.toStringAsFixed(6); });
                } catch (_) {}
              }),
              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close, size: 18), onPressed: () => setS(() => stops.removeAt(i))),
            ]),
          ),
        Text(_t('Tip: stand at the stop and tap the location icon to fill coordinates.', 'குறிப்பு: நிறுத்தத்தில் நின்று இருப்பிட ஐகானை தட்டவும்.'), style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
        const SizedBox(height: 12),
        _saveBtn(ctx, () async {
          final r2 = await _svc.saveRoute({
            'id': r?['id'], 'name': name.text, 'source': src.text, 'destination': dst.text,
            'sourceLat': double.tryParse(srcLat.text), 'sourceLng': double.tryParse(srcLng.text),
            'destLat': double.tryParse(dstLat.text), 'destLng': double.tryParse(dstLng.text),
            'stops': stops.map((s) => {'name': s['name']!.text, 'lat': double.tryParse(s['lat']!.text), 'lng': double.tryParse(s['lng']!.text)}).toList(),
          });
          _snack(r2); return r2['success'] == true;
        }),
      ])),
    );
    if (saved == true) _load();
  }

  // ---------------- TRIPS ----------------
  Widget _tripsTab() {
    String vname(int id) => _vehicles.cast<Map<String, dynamic>?>().firstWhere((v) => _i(v!['id']) == id, orElse: () => null)?['name']?.toString() ?? '#$id';
    String dname(int id) => _drivers.cast<Map<String, dynamic>?>().firstWhere((d) => _i(d!['id']) == id, orElse: () => null)?['name']?.toString() ?? '';
    return RefreshIndicator(
      onRefresh: () => _loadTrips(),
      child: _trips.isEmpty
          ? ListView(children: [Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(_t('No trips yet', 'பயணங்கள் இல்லை'), style: const TextStyle(color: Colors.grey))))])
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: _trips.map((t) {
                final running = t['status'] == 'RUNNING';
                return Card(
                  elevation: 0, margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                  child: ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _TripTrailScreen(tripId: _i(t['id']), title: vname(_i(t['vehicleId'])), transporterName: _transporter?['companyName']?.toString()))),
                    leading: CircleAvatar(backgroundColor: running ? const Color(0xFFE8F5E9) : Colors.grey.shade100, child: Icon(running ? Icons.play_arrow : Icons.flag, color: running ? const Color(0xFF2E7D32) : Colors.grey)),
                    title: Text(vname(_i(t['vehicleId'])), style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${dname(_i(t['driverId']))}\n${_fmt(t['startedAt'])} → ${running ? _t('running', 'ஓடுகிறது') : _fmt(t['endedAt'])}${t['distanceKm'] != null ? ' · ${t['distanceKm']} km' : ''}', style: const TextStyle(fontSize: 12)),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _fmt(dynamic iso) {
    if (iso == null) return '—';
    final d = DateTime.tryParse(iso.toString());
    if (d == null) return iso.toString();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  // ---------------- shared sheet widgets ----------------
  Widget _sheet(BuildContext ctx, String title, List<Widget> children) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            ...children,
          ]),
        ),
      );

  Widget _saveBtn(BuildContext ctx, Future<bool> Function() onSave) => StatefulBuilder(builder: (ctx2, setS) {
        bool busy = false;
        return SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: busy ? null : () async {
              setS(() => busy = true);
              final ok = await onSave();
              if (ctx.mounted) { if (ok) Navigator.pop(ctx, true); else setS(() => busy = false); }
            },
            child: Text(_t('Save', 'சேமி'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        );
      });
}

/// Trip history: trail on a map with start / end markers.
class _TripTrailScreen extends StatefulWidget {
  final int tripId;
  final String title;
  final String? transporterName;
  const _TripTrailScreen({required this.tripId, required this.title, this.transporterName});

  @override
  State<_TripTrailScreen> createState() => _TripTrailScreenState();
}

class _TripTrailScreenState extends State<_TripTrailScreen> {
  List<LatLng> _pts = [];
  Map<String, dynamic>? _trip;
  bool _loading = true;
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    TransportService.instance.ownerTripTrail(widget.tripId).then((r) {
      if (!mounted) return;
      if (r['success'] == true) {
        final d = Map<String, dynamic>.from(r['data'] ?? {});
        _trip = d['trip'] is Map ? Map<String, dynamic>.from(d['trip']) : null;
        _pts = ((d['points'] ?? []) as List).map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble())).toList();
      }
      setState(() => _loading = false);
      _fit();
    });
  }

  void _fit() {
    if (_map == null || _pts.isEmpty) return;
    if (_pts.length == 1) { _map!.animateCamera(CameraUpdate.newLatLngZoom(_pts.first, 14)); return; }
    double minLat = _pts.first.latitude, maxLat = minLat, minLng = _pts.first.longitude, maxLng = minLng;
    for (final p in _pts) { minLat = math.min(minLat, p.latitude); maxLat = math.max(maxLat, p.latitude); minLng = math.min(minLng, p.longitude); maxLng = math.max(maxLng, p.longitude); }
    _map!.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _pts.isNotEmpty ? _pts.first : const LatLng(12.4966, 78.5729), zoom: 12),
                  onMapCreated: (c) { _map = c; _fit(); },
                  polylines: _pts.length > 1 ? {Polyline(polylineId: const PolylineId('trail'), points: _pts, color: const Color(0xFF1565C0), width: 5)} : {},
                  markers: {
                    if (_pts.isNotEmpty) Marker(markerId: const MarkerId('start'), position: _pts.first, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), infoWindow: const InfoWindow(title: 'Start')),
                    if (_pts.length > 1) Marker(markerId: const MarkerId('end'), position: _pts.last, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), infoWindow: const InfoWindow(title: 'End')),
                  },
                  zoomControlsEnabled: false, mapToolbarEnabled: false,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14), color: Colors.white,
                child: Row(children: [
                  Expanded(child: Text('${_trip?['status'] ?? ''} · ${_pts.length} points', style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(_trip?['distanceKm'] != null ? '${_trip!['distanceKm']} km' : ''),
                ]),
              ),
            ]),
    );
  }
}
