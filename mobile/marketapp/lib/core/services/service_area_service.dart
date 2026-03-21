import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class ServiceAreaService {
  static final ServiceAreaService _instance = ServiceAreaService._internal();
  factory ServiceAreaService() => _instance;
  ServiceAreaService._internal();

  /// Check if user location is within the service area.
  /// Returns null on any error (fail-open).
  Future<Map<String, dynamic>?> checkServiceArea(double lat, double lng) async {
    try {
      final baseUrl = EnvConfig.baseUrl;
      final uri = Uri.parse('$baseUrl/api/service-area/check').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('Service area check timed out'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('ServiceAreaService error: $e');
      return null; // fail-open
    }
  }
}
