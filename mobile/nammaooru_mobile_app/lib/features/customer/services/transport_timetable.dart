/// Timetable helpers shared by the Where is Bus and Driver screens.
/// A schedule row: {id, direction: 'AB'|'BA', departTime: 'HH:mm', arriveTime: 'HH:mm', days: 'DAILY'|'MON,TUE,...'}
class TransportTimetable {
  static const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  static int minOf(String? hhmm) {
    final p = (hhmm ?? '0:0').split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 + (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  static double nowMin([DateTime? d]) {
    final n = d ?? DateTime.now();
    return n.hour * 60 + n.minute + n.second / 60.0;
  }

  static bool runsToday(Map<String, dynamic> s, [DateTime? d]) {
    final days = (s['days'] ?? 'DAILY').toString().toUpperCase();
    if (days == 'DAILY') return true;
    final today = _days[(d ?? DateTime.now()).weekday - 1];
    return days.split(',').map((x) => x.trim()).contains(today);
  }

  static List<Map<String, dynamic>> todays(List rows, [DateTime? d]) {
    final out = rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e))
        .where((r) => r['isActive'] != false && runsToday(r, d)).toList();
    out.sort((a, b) => minOf(a['departTime']).compareTo(minOf(b['departTime'])));
    return out;
  }

  /// Row the bus is on right now, or null.
  static Map<String, dynamic>? currentLeg(List rows, [DateTime? d]) {
    final n = nowMin(d);
    for (final r in todays(rows, d)) {
      if (minOf(r['departTime']) <= n && n <= minOf(r['arriveTime'])) return r;
    }
    return null;
  }

  /// Next departure after now, or the first of the day.
  static Map<String, dynamic>? nextDeparture(List rows, [DateTime? d]) {
    final n = nowMin(d);
    final t = todays(rows, d);
    for (final r in t) {
      if (minOf(r['departTime']) >= n) return r;
    }
    return t.isEmpty ? null : t.first;
  }

  /// Departure closest to now (for the driver's default pick), within 90 min.
  static Map<String, dynamic>? nearest(List rows, [DateTime? d]) {
    final n = nowMin(d);
    Map<String, dynamic>? best; double bestDiff = 1e9;
    for (final r in todays(rows, d)) {
      final diff = (minOf(r['departTime']) - n).abs();
      if (diff < bestDiff) { bestDiff = diff; best = r; }
    }
    return bestDiff <= 90 ? best : null;
  }

  static double legProgress(Map<String, dynamic> leg, [DateTime? d]) {
    final a = minOf(leg['departTime']), b = minOf(leg['arriveTime']);
    if (b <= a) return 0;
    return ((nowMin(d) - a) / (b - a)).clamp(0.0, 1.0);
  }

  static String dirLabel(Map? route, String? dir, {String arrow = ' \u2192 '}) {
    if (route == null) return dir == 'BA' ? 'B$arrow' 'A' : 'A$arrow' 'B';
    return dir == 'BA' ? '${route['destination']}$arrow${route['source']}' : '${route['source']}$arrow${route['destination']}';
  }
}
