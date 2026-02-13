import '../../../core/services/api_service.dart';
import '../../../core/utils/logger.dart';

class BusTimingService {
  final ApiService _apiService = ApiService();

  /// Get active bus timings (public)
  Future<Map<String, dynamic>> getActiveBusTimings({
    String? location,
    String? search,
  }) async {
    try {
      Logger.api('Fetching bus timings - location: $location, search: $search');

      final queryParams = <String, String>{};

      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiService.get(
        '/bus-timings',
        queryParams: queryParams,
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch bus timings', 'BUS_TIMING', e);
      rethrow;
    }
  }
}
