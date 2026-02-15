import '../../../core/services/api_service.dart';
import '../../../core/utils/logger.dart';

class FeatureConfigService {
  final ApiService _apiService = ApiService();

  // Cache for effective limits
  static Map<String, int>? _cachedLimits;
  static DateTime? _cacheTime;

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

      Logger.api('Feature config response: success=${response['success']}, hasData=${response['data'] != null}, statusCode=${response['statusCode']}');

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        Logger.api('Feature config: got ${data.length} features from API');
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      Logger.api('Feature config: API returned no data or not success. message=${response['message']}');
      return [];
    } catch (e) {
      Logger.e('Failed to fetch visible features', 'FEATURE_CONFIG', e);
      return [];
    }
  }

  /// Get effective post limits for the current user (cached for 5 minutes)
  Future<Map<String, int>> getMyPostLimits() async {
    // Return cache if fresh (within 5 minutes)
    if (_cachedLimits != null && _cacheTime != null &&
        DateTime.now().difference(_cacheTime!).inMinutes < 5) {
      return _cachedLimits!;
    }

    try {
      final response = await _apiService.get('/post-limits/my');
      if (response['success'] == true && response['data'] != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response['data']);
        _cachedLimits = data.map((key, value) => MapEntry(key, (value as num).toInt()));
        _cacheTime = DateTime.now();
        return _cachedLimits!;
      }
      return {};
    } catch (e) {
      Logger.e('Failed to fetch post limits', 'FEATURE_CONFIG', e);
      return {};
    }
  }

  /// Get effective limit for a specific feature (0 = unlimited)
  Future<int> getEffectiveLimit(String featureName) async {
    final limits = await getMyPostLimits();
    return limits[featureName] ?? 0;
  }

  /// Clear the cached limits (e.g., after login/logout)
  static void clearCache() {
    _cachedLimits = null;
    _cacheTime = null;
  }
}
