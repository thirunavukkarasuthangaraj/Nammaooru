import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

class ServiceAreaService {
  static final ServiceAreaService _instance = ServiceAreaService._internal();
  factory ServiceAreaService() => _instance;
  ServiceAreaService._internal();

  static const _cacheKey = 'service_area_config';

  /// Check if user is within service area using cached config first (instant),
  /// then refresh cache from server in background.
  /// Returns true if blocked, false if allowed.
  Future<bool> checkAndBlock(double lat, double lng) async {
    final cached = await _getCachedConfig();

    // Instant local check using cached config
    if (cached != null) {
      final blocked = _isBlocked(cached, lat, lng);
      // Refresh cache in background (don't await)
      _refreshCache(lat, lng);
      return blocked;
    }

    // No cache yet — fetch from server (first launch)
    final result = await _fetchFromServer(lat, lng);
    if (result != null) {
      await _saveCache(result);
      return result['allowed'] != true;
    }

    return false; // fail-open
  }

  bool _isBlocked(Map<String, dynamic> config, double lat, double lng) {
    final enabled = config['enabled'] == true;
    if (!enabled) return false;

    final centerLat = (config['centerLat'] as num?)?.toDouble();
    final centerLng = (config['centerLng'] as num?)?.toDouble();
    final radiusKm = (config['radiusKm'] as num?)?.toDouble();

    if (centerLat == null || centerLng == null || radiusKm == null) return false;

    final dist = _haversineKm(lat, lng, centerLat, centerLng);
    return dist > radiusKm;
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * pi / 180;

  Future<void> _refreshCache(double lat, double lng) async {
    try {
      final result = await _fetchFromServer(lat, lng);
      if (result != null) await _saveCache(result);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _fetchFromServer(double lat, double lng) async {
    try {
      final uri = Uri.parse('${EnvConfig.baseUrl}/api/service-area/check').replace(
        queryParameters: {'lat': lat.toString(), 'lng': lng.toString()},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _getCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(config));
    } catch (_) {}
  }

  /// Legacy method kept for compatibility
  Future<Map<String, dynamic>?> checkServiceArea(double lat, double lng) async {
    return _fetchFromServer(lat, lng);
  }
}
