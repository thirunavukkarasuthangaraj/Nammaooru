import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/language_provider.dart';
import '../../../../core/theme/village_theme.dart';
import '../../services/transport_service.dart';
import '../../services/transport_timetable.dart';
import 'transport_driver_screen.dart';
import 'transport_owner_screen.dart';
import 'transport_register_sheet.dart';

/// Public live bus tracker. No login needed to watch buses.
/// Logged-in users also get entry points to Owner / Driver / Register.
class WhereIsBusScreen extends StatefulWidget {
  const WhereIsBusScreen({super.key});

  @override
  State<WhereIsBusScreen> createState() => _WhereIsBusScreenState();
}

class _WhereIsBusScreenState extends State<WhereIsBusScreen> {
  static const _accent = Color(0xFF1565C0);
  static const _defaultCenter = LatLng(12.4966, 78.5729);

  final _svc = TransportService.instance;
  GoogleMapController? _map;
  Timer? _poll;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _buses = [];
  final Map<int, Map<String, dynamic>> _pos = {};
  int _staleAfter = 120;
  int? _selected;
  int? _stopIndex;
  String _search = '';
  Map<String, dynamic>? _me;
  bool _follow = true;
  bool _showMap = false; // details first; map only after 'Show on map'
  final Map<String, BitmapDescriptor> _labelIcons = {};
  final Set<String> _labelPending = {};
  int? _routeSel;        // passenger picks a route first
  String _dirSel = 'AB';  // then a direction (A->B or B->A)

  String _t(String en, String ta) => Provider.of<LanguageProvider>(context, listen: false).getText(en, ta);

  @override
  void initState() {
    super.initState();
    _load();
    _loadMe();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    final r = await _svc.me();
    if (!mounted) return;
    if (r['success'] == true && r['data'] is Map) setState(() => _me = Map<String, dynamic>.from(r['data']));
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final r = await _svc.publicBuses();
    if (!mounted) return;
    if (r['success'] != true) {
      setState(() { _loading = false; _error = r['message']?.toString() ?? 'Could not load buses'; });
      return;
    }
    final data = Map<String, dynamic>.from(r['data'] ?? {});
    _buses = List<Map<String, dynamic>>.from((data['buses'] ?? []).map((e) => Map<String, dynamic>.from(e)));
    _staleAfter = (data['settings']?['staleAfterSec'] as num?)?.toInt() ?? 120;
    _applyPositions(data['positions']);
    setState(() => _loading = false);
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refreshPositions());
    _fitAll();
  }

  Future<void> _refreshPositions() async {
    if (_buses.isEmpty) return;
    final r = await _svc.publicPositions(_buses.map((b) => (b['id'] as num).toInt()).toList());
    if (!mounted || r['success'] != true) return;
    _applyPositions(r['data']);
    setState(() {});
    if (_follow && _selected != null && _pos[_selected] != null) {
      final p = _pos[_selected]!;
      _map?.animateCamera(CameraUpdate.newLatLng(LatLng(_d(p['lat']), _d(p['lng']))));
    }
  }

  void _applyPositions(dynamic list) {
    if (list is! List) return;
    for (final e in list) {
      final m = Map<String, dynamic>.from(e);
      _pos[(m['vehicleId'] as num).toInt()] = m;
    }
  }

  double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

  String _state(int id) {
    final p = _pos[id];
    if (p == null) return 'OFFLINE';
    final age = (p['ageSec'] as num?)?.toInt() ?? 9999;
    if (age > _staleAfter) return 'OFFLINE';
    return (p['state'] ?? 'STOPPED').toString();
  }

  Color _stateColor(String s) => s == 'MOVING' ? const Color(0xFF2E7D32) : s == 'STOPPED' ? _accent : Colors.grey;

  void _fitAll() {
    final pts = _pos.values.where((p) => p['lat'] != null).map((p) => LatLng(_d(p['lat']), _d(p['lng']))).toList();
    if (pts.isEmpty || _map == null) return;
    if (pts.length == 1) { _map!.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 14)); return; }
    double minLat = pts.first.latitude, maxLat = minLat, minLng = pts.first.longitude, maxLng = minLng;
    for (final p in pts) {
      minLat = math.min(minLat, p.latitude); maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude); maxLng = math.max(maxLng, p.longitude);
    }
    _map!.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 60));
  }

  void _select(int id) {
    setState(() { _selected = id; _stopIndex = null; _follow = true; });
    if (_map != null) {
      final p = _pos[id];
      if (p != null && p['lat'] != null && _state(id) != 'OFFLINE') _centerOnSelected(); else _fitRoute();
    }
  }

  Map<String, dynamic>? _bus(int id) => _buses.cast<Map<String, dynamic>?>().firstWhere((b) => b!['id'] == id, orElse: () => null);

  String _dirOf(int id) {
    final p = _pos[id];
    if (p != null && p['direction'] != null && _state(id) != 'OFFLINE') return p['direction'].toString();
    final leg = TransportTimetable.currentLeg(_schedules(id));
    if (leg != null) return leg['direction']?.toString() ?? 'AB';
    return _routeSel != null ? _dirSel : 'AB';
  }

  List _schedules(int id) {
    final b = _bus(id);
    return b?['schedules'] is List ? b!['schedules'] as List : const [];
  }

  List<Map<String, dynamic>> _stops(int id) {
    final r = _bus(id)?['route'];
    if (r is! Map || r['stops'] is! List) return [];
    final list = List<Map<String, dynamic>>.from((r['stops'] as List).map((e) => Map<String, dynamic>.from(e)))
        .where((s) => s['lat'] != null && s['lng'] != null).toList();
    final dir = _routeSel != null ? _dirSel : _dirOf(id);
    return dir == 'BA' ? list.reversed.toList() : list;
  }

  /// Scheduled ("should be here") position along the straight route path for a bus with no live GPS.
  LatLng? _scheduledPos(int id) {
    final leg = TransportTimetable.currentLeg(_schedules(id));
    if (leg == null) return null;
    var path = _routePath(id).map((q) => LatLng(_d(q['lat']), _d(q['lng']))).toList();
    if (path.length < 2) return null;
    if (leg['direction'] == 'BA') path = path.reversed.toList();
    final t = TransportTimetable.legProgress(leg);
    final segs = <double>[]; var total = 0.0;
    for (var i = 1; i < path.length; i++) {
      final d = _haversine(path[i - 1].latitude, path[i - 1].longitude, path[i].latitude, path[i].longitude);
      segs.add(d); total += d;
    }
    var target = total * t, acc = 0.0;
    for (var i = 0; i < segs.length; i++) {
      if (acc + segs[i] >= target || i == segs.length - 1) {
        final f = segs[i] == 0 ? 0.0 : (target - acc) / segs[i];
        final a = path[i], b = path[i + 1];
        return LatLng(a.latitude + (b.latitude - a.latitude) * f, a.longitude + (b.longitude - a.longitude) * f);
      }
      acc += segs[i];
    }
    return path.last;
  }

  /// Marker drawn as a small pill with text, e.g. "18:20  Madavalam". Cached per text+colour.
  BitmapDescriptor? _labelIcon(String text, Color bg) {
    final key = '$text|${bg.value}';
    final cached = _labelIcons[key];
    if (cached != null) return cached;
    if (_labelPending.add(key)) _buildLabelIcon(key, text, bg);
    return null;
  }

  Future<void> _buildLabelIcon(String key, String text, Color bg) async {
    try {
      const scale = 2.5;
      final tp = TextPainter(
        text: TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 13 * scale, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = tp.width + 20 * scale, h = tp.height + 10 * scale, tail = 8 * scale;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(h / 2));
      c.drawShadow(Path()..addRRect(rect), Colors.black54, 3 * scale, false);
      c.drawRRect(rect, Paint()..color = bg);
      c.drawRRect(rect, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2 * scale);
      // small pointer under the pill
      final tri = Path()..moveTo(w / 2 - tail, h)..lineTo(w / 2, h + tail)..lineTo(w / 2 + tail, h)..close();
      c.drawPath(tri, Paint()..color = bg);
      tp.paint(c, Offset(10 * scale, 5 * scale));
      final img = await rec.endRecording().toImage(w.ceil(), (h + tail).ceil());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final icon = BitmapDescriptor.bytes(bytes.buffer.asUint8List(), imagePixelRatio: scale);
      if (!mounted) return;
      setState(() => _labelIcons[key] = icon);
    } catch (_) {
      _labelPending.remove(key);
    }
  }

  /// Scheduled clock time at every point of the chosen route for the selected (or first) bus:
  /// depart at A, arrive at B, stops interpolated by distance along the path.
  List<String?> _timesAlongRoute(List<Map<String, dynamic>> path) {
    if (path.length < 2) return List.filled(path.length, null);
    Map<String, dynamic>? leg;
    final candidates = _selected != null ? [_bus(_selected!)] : _busesOnRoute();
    for (final b in candidates) {
      if (b == null) continue;
      final id = (b['id'] as num).toInt();
      final cur = TransportTimetable.currentLeg(_schedules(id));
      if (cur != null && cur['direction'] == _dirSel) { leg = cur; break; }
      leg ??= _nextInDir(id, _dirSel);
    }
    if (leg == null) return List.filled(path.length, null);
    final dep = TransportTimetable.minOf(leg['departTime']), arr = TransportTimetable.minOf(leg['arriveTime']);
    if (arr <= dep) return List.filled(path.length, null);
    final cum = <double>[0];
    for (var i = 1; i < path.length; i++) {
      cum.add(cum.last + _haversine(_d(path[i - 1]['lat']), _d(path[i - 1]['lng']), _d(path[i]['lat']), _d(path[i]['lng'])));
    }
    final total = cum.last == 0 ? 1 : cum.last;
    String fmt(double m) { final mm = m.round() % 1440; return '${(mm ~/ 60).toString().padLeft(2, '0')}:${(mm % 60).toString().padLeft(2, '0')}'; }
    return [for (var i = 0; i < path.length; i++) fmt(dep + (arr - dep) * (cum[i] / total))];
  }

  Map? _routeById(int? routeId) {
    if (routeId == null) return null;
    for (final b in _buses) {
      final r = b['route'];
      if (r is Map && (r['id'] as num?)?.toInt() == routeId) return r;
    }
    return null;
  }

  /// A, stops, B for a route id, in the direction the passenger chose.
  List<Map<String, dynamic>> _routePathR(int? routeId) {
    final r = _routeById(routeId);
    if (r == null) return [];
    final out = <Map<String, dynamic>>[];
    if (r['sourceLat'] != null && r['sourceLng'] != null) out.add({'name': r['source'], 'lat': r['sourceLat'], 'lng': r['sourceLng'], 'kind': 'from'});
    if (r['stops'] is List) {
      for (final e in r['stops'] as List) {
        final st = Map<String, dynamic>.from(e);
        if (st['lat'] != null && st['lng'] != null) out.add({'name': st['name'], 'lat': st['lat'], 'lng': st['lng'], 'kind': 'stop'});
      }
    }
    if (r['destLat'] != null && r['destLng'] != null) out.add({'name': r['destination'], 'lat': r['destLat'], 'lng': r['destLng'], 'kind': 'to'});
    return _dirSel == 'BA' ? out.reversed.toList() : out;
  }

  /// Route path as drawn on the map: From (A), stops, To (B). Only points with coordinates.
  List<Map<String, dynamic>> _routePath(int id) {
    final r = _bus(id)?['route'];
    if (r is! Map) return [];
    final out = <Map<String, dynamic>>[];
    if (r['sourceLat'] != null && r['sourceLng'] != null) {
      out.add({'name': r['source'], 'lat': r['sourceLat'], 'lng': r['sourceLng'], 'kind': 'from'});
    }
    if (r['stops'] is List) {
      for (final e in r['stops'] as List) {
        final st = Map<String, dynamic>.from(e);
        if (st['lat'] != null && st['lng'] != null) out.add({'name': st['name'], 'lat': st['lat'], 'lng': st['lng'], 'kind': 'stop'});
      }
    }
    if (r['destLat'] != null && r['destLng'] != null) {
      out.add({'name': r['destination'], 'lat': r['destLat'], 'lng': r['destLng'], 'kind': 'to'});
    }
    return out;
  }

  /// Distinct routes among public buses: {id, name, source, destination, buses}.
  List<Map<String, dynamic>> _routes() {
    final out = <int, Map<String, dynamic>>{};
    for (final b in _buses) {
      final r = b['route'];
      if (r is! Map || r['id'] == null) continue;
      final id = (r['id'] as num).toInt();
      out.putIfAbsent(id, () => {'id': id, 'name': r['name'], 'source': r['source'], 'destination': r['destination'], 'buses': 0});
      out[id]!['buses'] = (out[id]!['buses'] as int) + 1;
    }
    final list = out.values.toList();
    list.sort((x, y) => '${x['source']}'.compareTo('${y['source']}'));
    return list;
  }

  /// Next departure of this bus in the chosen direction (today), or null.
  Map<String, dynamic>? _nextInDir(int id, String dir) {
    final rows = TransportTimetable.todays(_schedules(id)).where((r) => r['direction'] == dir).toList();
    if (rows.isEmpty) return null;
    final n = TransportTimetable.nowMin();
    for (final r in rows) {
      if (TransportTimetable.minOf(r['departTime']) >= n) return r;
    }
    return rows.first;
  }

  /// Buses on the selected route, soonest departure first; live ones on top.
  List<Map<String, dynamic>> _busesOnRoute() {
    final list = _buses.where((b) => b['route'] is Map && (b['route']['id'] as num?)?.toInt() == _routeSel).toList();
    int key(Map<String, dynamic> b) {
      final id = (b['id'] as num).toInt();
      final live = _state(id) != 'OFFLINE' && _dirOf(id) == _dirSel;
      final nx = _nextInDir(id, _dirSel);
      final n = TransportTimetable.nowMin();
      final mins = nx == null ? 100000 : ((TransportTimetable.minOf(nx['departTime']) - n + 1440) % 1440).round();
      return (live ? 0 : 100000) + mins;
    }
    list.sort((x, y) => key(x).compareTo(key(y)));
    return list;
  }

  /// Rough ETA: straight line × 1.3 road factor at max(current speed, 20 km/h).
  String? _eta(int id) {
    final p = _pos[id];
    final stops = _stops(id);
    if (p == null || _stopIndex == null || _stopIndex! >= stops.length || _state(id) == 'OFFLINE') return null;
    final s = stops[_stopIndex!];
    final km = _haversine(_d(p['lat']), _d(p['lng']), _d(s['lat']), _d(s['lng'])) * 1.3;
    final sp = math.max(20.0, _d(p['speedKmh']));
    final min = (km / sp * 60).round();
    return '${_t('About', 'சுமார்')} ${min < 1 ? 1 : min} ${_t('min', 'நிமிடம்')} · ${km.toStringAsFixed(1)} km';
  }

  double _haversine(double la1, double lo1, double la2, double lo2) {
    const r = 6371.0;
    final dLat = (la2 - la1) * math.pi / 180, dLon = (lo2 - lo1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1 * math.pi / 180) * math.cos(la2 * math.pi / 180) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  String _ago(int id) {
    final p = _pos[id];
    if (p == null) return _t('not yet today', 'இன்று இல்லை');
    final s = (p['ageSec'] as num?)?.toInt() ?? 0;
    if (s < 5) return _t('just now', 'இப்போது');
    if (s < 60) return '$s ${_t('s ago', 'வி முன்')}';
    if (s < 3600) return '${(s / 60).round()} ${_t('min ago', 'நிமிடம் முன்')}';
    return '${(s / 3600).round()} ${_t('h ago', 'மணி முன்')}';
  }

  Set<Marker> _markers() {
    final out = <Marker>{};
    for (final b in _buses) {
      final id = (b['id'] as num).toInt();
      if (_routeSel != null && (b['route'] is! Map || (b['route']['id'] as num?)?.toInt() != _routeSel)) continue;
      final p = _pos[id];
      if (p == null || p['lat'] == null) continue;
      final st = _state(id);
      out.add(Marker(
        markerId: MarkerId('bus_$id'),
        position: LatLng(_d(p['lat']), _d(p['lng'])),
        rotation: _d(p['heading']),
        flat: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(st == 'MOVING' ? BitmapDescriptor.hueGreen : st == 'STOPPED' ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(title: b['name']?.toString(), snippet: st),
        onTap: () => _select(id),
        zIndex: _selected == id ? 2 : 1,
      ));
    }
    if (_selected != null && _state(_selected!) == 'OFFLINE') {
      final g = _scheduledPos(_selected!);
      if (g != null) {
        out.add(Marker(
          markerId: const MarkerId('scheduled'),
          position: g,
          alpha: 0.55,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(title: _t('Scheduled position', '\u0b85\u0b9f\u0bcd\u0b9f\u0bb5\u0ba3\u0bc8 \u0b87\u0b9f\u0bae\u0bcd'), snippet: _t('By timetable, GPS off', '\u0b85\u0b9f\u0bcd\u0b9f\u0bb5\u0ba3\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0bbf, GPS \u0b87\u0bb2\u0bcd\u0bb2\u0bc8')),
          zIndex: 2,
        ));
      }
    }
    final path = _routePathR(_routeSel);
    final times = _timesAlongRoute(path);
    var n = 0;
    for (var i = 0; i < path.length; i++) {
      final pt = path[i];
      final isEnd = pt['kind'] != 'stop';
      if (!isEnd) n++;
      final stopIdx = n - 1;
      final isFirst = i == 0, isLast = i == path.length - 1;
      final selectedStop = !isEnd && _stopIndex != null && _stopIndex == stopIdx;
      final bg = isFirst ? const Color(0xFF2E7D32) : isLast ? const Color(0xFFC62828) : selectedStop ? const Color(0xFFEF6C00) : const Color(0xFF1565C0);
      final t = times[i];
      final text = t == null ? '${pt['name']}' : '$t  ${pt['name']}';
      final icon = _labelIcon(text, bg) ?? BitmapDescriptor.defaultMarkerWithHue(isFirst ? BitmapDescriptor.hueGreen : isLast ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure);
      out.add(Marker(
        markerId: MarkerId(isEnd ? 'route_${pt['kind']}' : 'stop_$n'),
        position: LatLng(_d(pt['lat']), _d(pt['lng'])),
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(title: text),
        onTap: isEnd ? null : () => setState(() => _stopIndex = stopIdx),
        zIndex: isEnd ? 3 : 1,
      ));
    }
    return out;
  }

  Set<Polyline> _polylines() {
    final path = _routePathR(_routeSel);
    if (path.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: path.map((q) => LatLng(_d(q['lat']), _d(q['lng']))).toList(),
        color: const Color(0xFF0D47A1),
        width: 5,
      ),
    };
  }

  List<Map<String, dynamic>> _filtered() {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _buses;
    return _buses.where((b) {
      final r = b['route'] is Map ? b['route'] as Map : {};
      return [b['name'], b['regNo'], b['operator'], r['name'], r['source'], r['destination']]
          .where((e) => e != null).join(' ').toLowerCase().contains(q);
    }).toList();
  }

  // ---------- actions ----------

  Future<void> _openRegister() async {
    if (_me == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('Please log in to register as a transporter', 'போக்குவரத்து உரிமையாளராக பதிவு செய்ய உள்நுழையவும்'))));
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => TransportRegisterSheet(existing: _me?['transporter'] is Map ? Map<String, dynamic>.from(_me!['transporter']) : null),
    );
    if (ok == true) _loadMe();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _me?['isOwner'] == true;
    final isDriver = _me?['isDriver'] == true;
    final transporter = _me?['transporter'];
    final pendingOwner = transporter is Map && transporter['status'] == 'PENDING';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Text(_t('Where is Bus', 'பஸ் எங்கே')),
        actions: [
          if (isDriver)
            IconButton(
              tooltip: _t('Driver mode', 'ஓட்டுநர்'),
              icon: const Icon(Icons.sports_motorsports_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportDriverScreen())),
            ),
          if (isOwner)
            IconButton(
              tooltip: _t('My fleet', 'என் வாகனங்கள்'),
              icon: const Icon(Icons.dashboard_customize_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportOwnerScreen())),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'register') _openRegister();
              if (v == 'refresh') _load();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'refresh', child: Text(_t('Refresh', 'புதுப்பி'))),
              PopupMenuItem(
                value: 'register',
                child: Text(isOwner
                    ? _t('Edit transporter profile', 'உரிமையாளர் விவரம் திருத்து')
                    : pendingOwner
                        ? _t('Transporter approval pending', 'ஒப்புதல் நிலுவையில்')
                        : _t('Register as bus / lorry owner', 'பஸ் / லாரி உரிமையாளராக பதிவு')),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _routeSel == null
                  ? _panel()
                  : _routeView(pendingOwner),
    );
  }

  /// Route screen: header, map with every bus on this route, bus list / compact card below.
  Widget _routeView(bool pendingOwner) {
    final route = _routeById(_routeSel);
    final src = route == null ? '' : '${route['source']}';
    final dst = route == null ? '' : '${route['destination']}';
    final from = _dirSel == 'AB' ? src : dst;
    final to = _dirSel == 'AB' ? dst : src;
    final list = _busesOnRoute();
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back, color: _accent), onPressed: () => setState(() { _routeSel = null; _selected = null; _stopIndex = null; _map = null; })),
            Expanded(child: Text('$from \u2192 $to', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
            TextButton.icon(
              onPressed: () => setState(() { _dirSel = _dirSel == 'AB' ? 'BA' : 'AB'; _stopIndex = null; _fitRoute(); }),
              icon: const Icon(Icons.swap_horiz, size: 18), label: Text(_t('Swap', '\u0bae\u0bbe\u0bb1\u0bcd\u0bb1\u0bc1')),
            ),
          ]),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.40,
          child: Stack(children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _initialTarget(), zoom: 12),
              onMapCreated: (c) { _map = c; _fitRoute(); },
              markers: _markers(),
              polylines: _polylines(),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onCameraMoveStarted: () { if (_follow) setState(() => _follow = false); },
            ),
            Positioned(
              right: 10, bottom: 10,
              child: Column(children: [
                _mapBtn(Icons.fit_screen, _fitRoute),
                if (_selected != null) ...[const SizedBox(height: 6), _mapBtn(_follow ? Icons.gps_fixed : Icons.gps_not_fixed, () { setState(() => _follow = true); _centerOnSelected(); })],
              ]),
            ),
            if (pendingOwner)
              Positioned(left: 10, right: 10, top: 10, child: _banner(_t('Your transporter registration is waiting for approval.', '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0baa\u0ba4\u0bbf\u0bb5\u0bc1 \u0b92\u0baa\u0bcd\u0baa\u0bc1\u0ba4\u0bb2\u0bc1\u0b95\u0bcd\u0b95\u0bbe\u0b95 \u0b95\u0bbe\u0ba4\u0bcd\u0ba4\u0bbf\u0bb0\u0bc1\u0b95\u0bcd\u0b95\u0bbf\u0bb1\u0ba4\u0bc1.'), Colors.orange.shade800)),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text(_t('No buses on this route yet', '\u0b87\u0ba8\u0bcd\u0ba4 \u0bb5\u0bb4\u0bbf\u0baf\u0bbf\u0bb2\u0bcd \u0baa\u0bb8\u0bcd \u0b87\u0bb2\u0bcd\u0bb2\u0bc8'), style: const TextStyle(color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                  children: [
                    if (_selected != null) _compactCard(),
                    for (final b in list) if (_selected == null || _selected != (b['id'] as num).toInt()) _busTile(b),
                  ],
                ),
        ),
      ],
    );
  }

  /// Compact card for the selected bus: status, next departure, my stop, ETA.
  Widget _compactCard() {
    final id = _selected!;
    final b = _bus(id);
    if (b == null) return const SizedBox.shrink();
    final st = _state(id);
    final liveThisWay = st != 'OFFLINE' && _dirOf(id) == _dirSel;
    final nx = _nextInDir(id, _dirSel);
    final stops = _stops(id);
    final eta = _eta(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _accent, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${b['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          if (liveThisWay) _chip(st) else if (nx != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
            child: Text('${_t('Next', '\u0b85\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1')} ${nx['departTime']}', style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() { _selected = null; _stopIndex = null; })),
        ]),
        const SizedBox(height: 4),
        if (liveThisWay)
          Text('${_t('Live', '\u0ba8\u0bc7\u0bb0\u0bb2\u0bc8')} \u00b7 ${_d(_pos[id]?['speedKmh']).round()} km/h \u00b7 ${_ago(id)}', style: TextStyle(color: Colors.grey[700], fontSize: 12.5))
        else if (nx != null)
          Text('${_t('Departs', '\u0baa\u0bc1\u0bb1\u0baa\u0bcd\u0baa\u0b9f\u0bc1\u0bae\u0bcd')} ${nx['departTime']} \u00b7 ${_t('arrives', '\u0bb5\u0bb0\u0bc1\u0b95\u0bc8')} ${nx['arriveTime']} \u00b7 ${_t('GPS off, showing timetable', 'GPS \u0b87\u0bb2\u0bcd\u0bb2\u0bc8, \u0b85\u0b9f\u0bcd\u0b9f\u0bb5\u0ba3\u0bc8')}', style: TextStyle(color: Colors.grey[700], fontSize: 12.5))
        else
          Text(_t('No timetable for this direction', '\u0b87\u0ba8\u0bcd\u0ba4 \u0ba4\u0bbf\u0b9a\u0bc8\u0b95\u0bcd\u0b95\u0bc1 \u0b85\u0b9f\u0bcd\u0b9f\u0bb5\u0ba3\u0bc8 \u0b87\u0bb2\u0bcd\u0bb2\u0bc8'), style: TextStyle(color: Colors.grey[700], fontSize: 12.5)),
        if (stops.isNotEmpty) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _stopIndex,
            isDense: true,
            decoration: InputDecoration(labelText: _t('My stop', '\u0b8e\u0ba9\u0bcd \u0ba8\u0bbf\u0bb1\u0bc1\u0ba4\u0bcd\u0ba4\u0bae\u0bcd'), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: [for (var i = 0; i < stops.length; i++) DropdownMenuItem(value: i, child: Text('${i + 1}. ${stops[i]['name']}', overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => _stopIndex = v),
          ),
          if (eta != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('\u{1F552} $eta', style: const TextStyle(fontWeight: FontWeight.w700, color: _accent))),
          if (_stopIndex != null && !liveThisWay && nx != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${_t('By timetable: departs', '\u0b85\u0b9f\u0bcd\u0b9f\u0bb5\u0ba3\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0bbf: \u0baa\u0bc1\u0bb1\u0baa\u0bcd\u0baa\u0b9f\u0bc1\u0bae\u0bcd')} ${nx['departTime']}', style: TextStyle(color: Colors.grey[700], fontSize: 12))),
        ],
      ]),
    );
  }

  void _fitRoute() {
    if (_map == null) return;
    final pts = _routePathR(_routeSel).map((q) => LatLng(_d(q['lat']), _d(q['lng']))).toList();
    for (final b in _busesOnRoute()) {
      final p = _pos[(b['id'] as num).toInt()];
      if (p != null && p['lat'] != null) pts.add(LatLng(_d(p['lat']), _d(p['lng'])));
    }
    if (pts.isEmpty) return;
    if (pts.length == 1) { _map!.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 13)); return; }
    double minLat = pts.first.latitude, maxLat = minLat, minLng = pts.first.longitude, maxLng = minLng;
    for (final q in pts) {
      minLat = math.min(minLat, q.latitude); maxLat = math.max(maxLat, q.latitude);
      minLng = math.min(minLng, q.longitude); maxLng = math.max(maxLng, q.longitude);
    }
    _map!.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 50));
  }

  /// Shown right after a bus is tapped: details only, with a "Show on map" button.
  Widget _detailsView(bool pendingOwner) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() { _selected = null; _stopIndex = null; _map = null; _showMap = false; }),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(_t('All buses', '\u0b8e\u0bb2\u0bcd\u0bb2\u0bbe \u0baa\u0bb8\u0bcd\u0b95\u0bb3\u0bcd')),
              style: TextButton.styleFrom(foregroundColor: _accent),
            ),
          ),
        ),
        if (pendingOwner)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: _banner(_t('Your transporter registration is waiting for approval.', '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0baa\u0ba4\u0bbf\u0bb5\u0bc1 \u0b92\u0baa\u0bcd\u0baa\u0bc1\u0ba4\u0bb2\u0bc1\u0b95\u0bcd\u0b95\u0bbe\u0b95 \u0b95\u0bbe\u0ba4\u0bcd\u0ba4\u0bbf\u0bb0\u0bc1\u0b95\u0bcd\u0b95\u0bbf\u0bb1\u0ba4\u0bc1.'), Colors.orange.shade800),
          ),
        _selectedCard(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => setState(() { _showMap = true; _follow = true; }),
              icon: const Icon(Icons.map_outlined, size: 24),
              label: Text(_t('Show on map', '\u0bb5\u0bb0\u0bc8\u0baa\u0b9f\u0ba4\u0bcd\u0ba4\u0bbf\u0bb2\u0bcd \u0b95\u0bbe\u0b9f\u0bcd\u0b9f\u0bc1'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            _state(_selected!) == 'OFFLINE'
                ? _t('This bus is not sharing its location right now. The map will show its route stops.', '\u0b87\u0ba8\u0bcd\u0ba4 \u0baa\u0bb8\u0bcd \u0b87\u0baa\u0bcd\u0baa\u0bcb\u0ba4\u0bc1 \u0b87\u0bb0\u0bc1\u0baa\u0bcd\u0baa\u0bbf\u0b9f\u0ba4\u0bcd\u0ba4\u0bc8 \u0baa\u0b95\u0bbf\u0bb0\u0bb5\u0bbf\u0bb2\u0bcd\u0bb2\u0bc8.')
                : _t('Live position updates every few seconds.', '\u0ba8\u0bc7\u0bb0\u0bb2\u0bc8 \u0b87\u0bb0\u0bc1\u0baa\u0bcd\u0baa\u0bbf\u0b9f\u0bae\u0bcd \u0b9a\u0bbf\u0bb2 \u0bb5\u0bbf\u0ba8\u0bbe\u0b9f\u0bbf\u0b95\u0bb3\u0bc1\u0b95\u0bcd\u0b95\u0bc1 \u0b92\u0bb0\u0bc1\u0bae\u0bc1\u0bb1\u0bc8 \u0baa\u0bc1\u0ba4\u0bc1\u0baa\u0bcd\u0baa\u0bbf\u0b95\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0b9f\u0bc1\u0bae\u0bcd.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  /// Map view: big map on top, details below, back to details.
  Widget _mapView(bool pendingOwner) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _initialTarget(), zoom: 13),
                onMapCreated: (c) { _map = c; _centerOnSelected(); },
                markers: _markers(),
                polylines: _polylines(),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onCameraMoveStarted: () { if (_follow) setState(() => _follow = false); },
              ),
              Positioned(
                left: 10, top: 10,
                child: Material(
                  color: Colors.white, elevation: 2, borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() { _showMap = false; _map = null; }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.arrow_back, size: 18, color: _accent),
                        const SizedBox(width: 6),
                        Text(_t('Details', 'விவரங்கள்'), style: const TextStyle(color: _accent, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10, bottom: 10,
                child: Column(children: [
                  _mapBtn(Icons.fit_screen, _fitSelected),
                  const SizedBox(height: 6),
                  _mapBtn(_follow ? Icons.gps_fixed : Icons.gps_not_fixed, () { setState(() => _follow = true); _centerOnSelected(); }),
                ]),
              ),
              if (pendingOwner)
                Positioned(
                  left: 10, right: 10, bottom: 10,
                  child: _banner(_t('Your transporter registration is waiting for approval.', 'உங்கள் பதிவு ஒப்புதலுக்காக காத்திருக்கிறது.'), Colors.orange.shade800),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: _selectedCard(),
          ),
        ),
      ],
    );
  }

  LatLng _initialTarget() {
    final rp = _routePathR(_routeSel);
    if (rp.isNotEmpty) return LatLng(_d(rp.first['lat']), _d(rp.first['lng']));
    if (_selected != null) {
      final p = _pos[_selected];
      if (p != null && p['lat'] != null) return LatLng(_d(p['lat']), _d(p['lng']));
      final path = _routePath(_selected!);
      if (path.isNotEmpty) return LatLng(_d(path.first['lat']), _d(path.first['lng']));
    }
    return _defaultCenter;
  }

  void _centerOnSelected() {
    if (_selected == null || _map == null) return;
    final p = _pos[_selected];
    if (p != null && p['lat'] != null) {
      _map!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(_d(p['lat']), _d(p['lng'])), 15));
    } else {
      _fitSelected();
    }
  }

  /// Fit the bus position plus all its route stops.
  void _fitSelected() {
    if (_selected == null || _map == null) return;
    final pts = <LatLng>[];
    final p = _pos[_selected];
    if (p != null && p['lat'] != null) pts.add(LatLng(_d(p['lat']), _d(p['lng'])));
    for (final s in _routePath(_selected!)) pts.add(LatLng(_d(s['lat']), _d(s['lng'])));
    if (pts.isEmpty) return;
    if (pts.length == 1) { _map!.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 14)); return; }
    double minLat = pts.first.latitude, maxLat = minLat, minLng = pts.first.longitude, maxLng = minLng;
    for (final q in pts) {
      minLat = math.min(minLat, q.latitude); maxLat = math.max(maxLat, q.latitude);
      minLng = math.min(minLng, q.longitude); maxLng = math.max(maxLng, q.longitude);
    }
    _map!.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 60));
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.white, elevation: 2, borderRadius: BorderRadius.circular(10),
        child: InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap, child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: _accent))),
      );

  Widget _banner(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
      );

  Widget _errorView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _load, child: Text(_t('Retry', 'மீண்டும் முயற்சி'))),
        ]),
      );

  Widget _panel() {
    if (_buses.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(
          _t('No buses are being tracked yet. Bus owners can register from the menu above.', '\u0b87\u0ba9\u0bcd\u0ba9\u0bc1\u0bae\u0bcd \u0baa\u0bb8\u0bcd\u0b95\u0bb3\u0bcd \u0b87\u0bb2\u0bcd\u0bb2\u0bc8.'),
          textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))));
    }
    return _routeSel == null ? _routesPanel() : _busesPanel();
  }

  /// Step 1: where do you want to go?
  Widget _routesPanel() {
    final q = _search.trim().toLowerCase();
    final routes = _routes().where((r) => q.isEmpty || '${r['name']} ${r['source']} ${r['destination']}'.toLowerCase().contains(q)).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Align(alignment: Alignment.centerLeft, child: Text(_t('Where do you want to go?', '\u0b8e\u0b99\u0bcd\u0b95\u0bc7 \u0baa\u0bcb\u0b95 \u0bb5\u0bc7\u0ba3\u0bcd\u0b9f\u0bc1\u0bae\u0bcd?'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: _t('Town or route\u2026', '\u0b8a\u0bb0\u0bcd \u0b85\u0bb2\u0bcd\u0bb2\u0ba4\u0bc1 \u0bb5\u0bb4\u0bbf\u2026'),
            prefixIcon: const Icon(Icons.search), isDense: true, filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          itemCount: routes.length,
          itemBuilder: (_, i) {
            final r = routes[i];
            return Card(
              elevation: 0, margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                onTap: () => setState(() { _routeSel = r['id'] as int; _dirSel = 'AB'; _search = ''; }),
                leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.alt_route, color: _accent)),
                title: Text('${r['source']} \u2194 ${r['destination']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${r['buses']} ${_t('buses', '\u0baa\u0bb8\u0bcd\u0b95\u0bb3\u0bcd')}'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    ]);
  }

  /// Step 2: buses on this route in the chosen direction.
  Widget _busesPanel() {
    final route = _routes().cast<Map<String, dynamic>?>().firstWhere((r) => r!['id'] == _routeSel, orElse: () => null);
    final src = route == null ? '' : '${route['source']}';
    final dst = route == null ? '' : '${route['destination']}';
    final from = _dirSel == 'AB' ? src : dst;
    final to = _dirSel == 'AB' ? dst : src;
    final list = _busesOnRoute();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: _accent), onPressed: () => setState(() { _routeSel = null; _selected = null; })),
          Expanded(child: Text('$from \u2192 $to', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
          TextButton.icon(
            onPressed: () => setState(() => _dirSel = _dirSel == 'AB' ? 'BA' : 'AB'),
            icon: const Icon(Icons.swap_horiz, size: 18), label: Text(_t('Swap', '\u0bae\u0bbe\u0bb1\u0bcd\u0bb1\u0bc1')),
          ),
        ]),
      ),
      Expanded(
        child: list.isEmpty
            ? Center(child: Text(_t('No buses on this route yet', '\u0b87\u0ba8\u0bcd\u0ba4 \u0bb5\u0bb4\u0bbf\u0baf\u0bbf\u0bb2\u0bcd \u0baa\u0bb8\u0bcd \u0b87\u0bb2\u0bcd\u0bb2\u0bc8'), style: const TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                itemCount: list.length,
                itemBuilder: (_, i) => _busTile(list[i]),
              ),
      ),
    ]);
  }

  Widget _busTile(Map<String, dynamic> b) {
    final id = (b['id'] as num).toInt();
    final st = _state(id);
    final liveThisWay = st != 'OFFLINE' && _dirOf(id) == _dirSel;
    final nx = _nextInDir(id, _dirSel);
    final leg = TransportTimetable.currentLeg(_schedules(id));
    final onLegThisWay = leg != null && leg['direction'] == _dirSel;
    String line;
    if (liveThisWay) {
      line = '${_t('Live now', '\u0ba8\u0bc7\u0bb0\u0bb2\u0bc8')} \u00b7 ${_d(_pos[id]?['speedKmh']).round()} km/h \u00b7 ${_ago(id)}';
    } else if (onLegThisWay) {
      line = '${_t('On the way by timetable', '\u0b85\u0b9f\u0bcd\u0b9f\u0bb5\u0ba3\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0bbf \u0bb5\u0bb0\u0bc1\u0b95\u0bbf\u0bb1\u0ba4\u0bc1')} ${leg['departTime']}-${leg['arriveTime']}';
    } else if (nx != null) {
      line = '${_t('Next departure', '\u0b85\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4 \u0baa\u0bc1\u0bb1\u0baa\u0bcd\u0baa\u0bbe\u0b9f\u0bc1')} ${nx['departTime']} \u00b7 ${_t('arrives', '\u0bb5\u0bb0\u0bc1\u0b95\u0bc8')} ${nx['arriveTime']}';
    } else {
      line = _t('No timetable', '\u0b85\u0b9f\u0bcd\u0b9f\u0bb5\u0ba3\u0bc8 \u0b87\u0bb2\u0bcd\u0bb2\u0bc8');
    }
    final sel = _selected == id;
    return Card(
      elevation: 0,
      color: sel ? _accent.withOpacity(0.08) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: sel ? _accent : Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _select(id),
        leading: CircleAvatar(backgroundColor: _stateColor(liveThisWay ? st : 'OFFLINE').withOpacity(0.15), child: Icon(Icons.directions_bus, color: _stateColor(liveThisWay ? st : 'OFFLINE'))),
        title: Text(b['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(line, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (liveThisWay) _chip(st) else if (nx != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
            child: Text(nx['departTime'].toString(), style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 4), const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
    );
  }

  /// "Scheduled 10:00-11:00 Tirupattur -> Alangayam" or "Next 11:20 ...".
  String? _ttText(int id) {
    final rows = _schedules(id);
    if (rows.isEmpty) return null;
    final route = _bus(id)?['route'] is Map ? _bus(id)!['route'] as Map : null;
    final leg = TransportTimetable.currentLeg(rows);
    if (leg != null) return '${_t('Scheduled', '\u0b85\u0b9f\u0bcd\u0b9f\u0bb5\u0ba3\u0bc8')} ${leg['departTime']}-${leg['arriveTime']} ${TransportTimetable.dirLabel(route, leg['direction']?.toString())}';
    final nx = TransportTimetable.nextDeparture(rows);
    return nx == null ? null : '${_t('Next', '\u0b85\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1')} ${nx['departTime']} ${TransportTimetable.dirLabel(route, nx['direction']?.toString())}';
  }

  Widget _chip(String st) {
    final label = st == 'MOVING' ? _t('Moving', 'ஓடுகிறது') : st == 'STOPPED' ? _t('Stopped', 'நின்றுள்ளது') : _t('Offline', 'ஆஃப்லைன்');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _stateColor(st).withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: _stateColor(st), fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }

  Widget _selectedCard() {
    final b = _bus(_selected!);
    if (b == null) return const SizedBox.shrink();
    final id = _selected!;
    final st = _state(id);
    final p = _pos[id];
    final stops = _stops(id);
    final r = b['route'] is Map ? b['route'] as Map : null;
    final eta = _eta(id);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('${b['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            _chip(st),
            IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() { _selected = null; _stopIndex = null; _map = null; _showMap = false; })),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 14, runSpacing: 4, children: [
            _kv(Icons.route, r != null ? (_dirOf(id) == 'BA' ? '${r['destination']} \u2192 ${r['source']}' : '${r['source']} \u2192 ${r['destination']}') : '\u2014'),
            _kv(Icons.speed, st == 'OFFLINE' ? '—' : '${_d(p?['speedKmh']).round()} km/h'),
            _kv(Icons.schedule, _ago(id)),
          ]),
          if (_ttText(id) != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_ttText(id)!, style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 12.5))),
          if (_schedules(id).isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final sc in TransportTimetable.todays(_schedules(id)))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: TransportTimetable.currentLeg([sc]) != null ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${sc['departTime']} ${sc['direction'] == 'BA' ? 'B\u2192A' : 'A\u2192B'} ${sc['arriveTime']}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
            ]),
          ],
          if (stops.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _stopIndex,
              isDense: true,
              decoration: InputDecoration(labelText: _t('My stop', 'என் நிறுத்தம்'), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: [for (var i = 0; i < stops.length; i++) DropdownMenuItem(value: i, child: Text('${i + 1}. ${stops[i]['name']}', overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _stopIndex = v),
            ),
            if (eta != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('🕒 $eta', style: const TextStyle(fontWeight: FontWeight.w700, color: _accent))),
            if (_stopIndex != null && st == 'OFFLINE') Padding(padding: const EdgeInsets.only(top: 6), child: Text(_t('This bus is not sharing its location right now.', 'இந்த பஸ் இப்போது இருப்பிடத்தை பகிரவில்லை.'), style: TextStyle(color: Colors.grey[700], fontSize: 12))),
          ],
        ],
      ),
    );
  }

  Widget _kv(IconData i, String v) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 15, color: Colors.grey[600]), const SizedBox(width: 4), Text(v, style: const TextStyle(fontSize: 12.5))]);
}
