import '../../../core/services/api_service.dart';
import '../../../core/utils/logger.dart';

class FeatureConfigService {
  final ApiService _apiService = ApiService();

  /// Get visible features based on user location
  Future<List<Map<String, dynamic>>> getVisibleFeatures(double lat, double lng) async {
    try {
      Logger.api('Fetching visible features at lat=$lat, lng=$lng');

      final response = await _apiService.get(
        '/feature-config/visible',
        queryParams: {
          'lat': lat.toString(),
          'lng': lng.toString(),
        },
        includeAuth: false,
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      return [];
    } catch (e) {
      Logger.e('Failed to fetch visible features', 'FEATURE_CONFIG', e);
      return [];
    }
  }
}
