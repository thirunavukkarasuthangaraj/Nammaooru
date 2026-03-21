import '../api/api_client.dart';
import '../storage/local_storage.dart';

class DeliveryLocationService {
  static final DeliveryLocationService _instance = DeliveryLocationService._internal();
  factory DeliveryLocationService() => _instance;
  DeliveryLocationService._internal();

  /// Save delivery location to backend
  Future<Map<String, dynamic>> saveDeliveryLocation({
    required String address,
    required String city,
    required String state,
    required String pincode,
    required double latitude,
    required double longitude,
    String? landmark,
    String? nickname,
    bool isDefault = false,
  }) async {
    try {
      final locationData = {
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'landmark': landmark,
        'nickname': nickname ?? 'Home',
        'isDefault': isDefault,
        'isActive': true,
      };

      final response = await ApiClient.post(
        '/customer/delivery-locations',
        data: locationData,
              );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final statusCode = responseData['statusCode']?.toString();
          final data = responseData['data'];
          final message = responseData['message'] ?? 'Location saved successfully';

          if (statusCode == '0000') {
            // Cache the saved location locally
            await _cacheLocation(data ?? locationData);

            return {
              'success': true,
              'data': data,
              'message': message
            };
          } else {
            return {
              'success': false,
              'message': message ?? 'Failed to save location'
            };
          }
        }
      }

      return {
        'success': false,
        'message': 'Failed to save location'
      };
    } catch (e) {
      print('Error saving delivery location: $e');

      // Save locally as fallback
      await _saveLocationLocally({
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'landmark': landmark,
        'nickname': nickname ?? 'Home',
        'isDefault': isDefault,
        'isActive': true,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'savedAt': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Location saved locally',
        'error': e.toString()
      };
    }
  }

  /// Get all saved delivery locations
  Future<Map<String, dynamic>> getDeliveryLocations() async {
    try {
      final response = await ApiClient.get(
        '/customer/delivery-locations',
              );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final statusCode = responseData['statusCode']?.toString();
          final data = responseData['data'];
          final message = responseData['message'] ?? 'Locations loaded';

          if (statusCode == '0000' && data != null) {
            // Cache locations locally
            await _cacheAllLocations(data);

            return {
              'success': true,
              'data': data,
              'message': message
            };
          }
        }
      }

      // Fallback to cached locations
      final cachedLocations = await _getCachedLocations();
      return {
        'success': true,
        'data': cachedLocations,
        'message': 'Using cached locations'
      };
    } catch (e) {
      print('Error loading delivery locations: $e');

      // Fallback to cached locations
      final cachedLocations = await _getCachedLocations();
      return {
        'success': false,
        'data': cachedLocations,
        'message': 'Using cached locations',
        'error': e.toString()
      };
    }
  }

  /// Update delivery location
  Future<Map<String, dynamic>> updateDeliveryLocation({
    required String locationId,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required double latitude,
    required double longitude,
    String? landmark,
    String? nickname,
    bool isDefault = false,
  }) async {
    try {
      final locationData = {
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'landmark': landmark,
        'nickname': nickname,
        'isDefault': isDefault,
        'isActive': true,
      };

      final response = await ApiClient.put(
        '/customer/delivery-locations/$locationId',
        data: locationData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final statusCode = responseData['statusCode']?.toString();
          final data = responseData['data'];
          final message = responseData['message'] ?? 'Location updated successfully';

          if (statusCode == '0000') {
            return {
              'success': true,
              'data': data,
              'message': message
            };
          }
        }
      }

      return {
        'success': false,
        'message': 'Failed to update location'
      };
    } catch (e) {
      print('Error updating delivery location: $e');
      return {
        'success': false,
        'message': 'Failed to update location',
        'error': e.toString()
      };
    }
  }

  /// Delete delivery location
  Future<Map<String, dynamic>> deleteDeliveryLocation(String locationId) async {
    try {
      final response = await ApiClient.delete(
        '/customer/delivery-locations/$locationId',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final statusCode = responseData['statusCode']?.toString();
          final message = responseData['message'] ?? 'Location deleted successfully';

          if (statusCode == '0000') {
            return {
              'success': true,
              'message': message
            };
          }
        }
      }

      return {
        'success': false,
        'message': 'Failed to delete location'
      };
    } catch (e) {
      print('Error deleting delivery location: $e');
      return {
        'success': false,
        'message': 'Failed to delete location',
        'error': e.toString()
      };
    }
  }

  /// Set default delivery location
  Future<Map<String, dynamic>> setDefaultLocation(String locationId) async {
    try {
      final response = await ApiClient.post(
        '/customer/delivery-locations/$locationId/set-default',
              );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final statusCode = responseData['statusCode']?.toString();
          final message = responseData['message'] ?? 'Default location updated';

          if (statusCode == '0000') {
            return {
              'success': true,
              'message': message
            };
          }
        }
      }

      return {
        'success': false,
        'message': 'Failed to set default location'
      };
    } catch (e) {
      print('Error setting default location: $e');
      return {
        'success': false,
        'message': 'Failed to set default location',
        'error': e.toString()
      };
    }
  }

  /// Get geocoding suggestions for address search
  Future<Map<String, dynamic>> searchAddresses(String query) async {
    try {
      final response = await ApiClient.get(
        '/customer/delivery-locations/search',
        queryParameters: {'q': query},
              );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final statusCode = responseData['statusCode']?.toString();
          final data = responseData['data'];
          final message = responseData['message'] ?? 'Search results';

          if (statusCode == '0000' && data != null) {
            return {
              'success': true,
              'data': data,
              'message': message
            };
          }
        }
      }

      return {
        'success': false,
        'data': [],
        'message': 'No results found'
      };
    } catch (e) {
      print('Error searching addresses: $e');
      return {
        'success': false,
        'data': [],
        'message': 'Search failed',
        'error': e.toString()
      };
    }
  }

  // Local caching methods
  Future<void> _cacheLocation(Map<String, dynamic> location) async {
    try {
      final cachedLocations = await _getCachedLocations();
      final existingIndex = cachedLocations.indexWhere(
        (cached) => cached['id'] == location['id']
      );

      if (existingIndex >= 0) {
        cachedLocations[existingIndex] = location;
      } else {
        cachedLocations.insert(0, location);
      }

      await LocalStorage.setList('delivery_locations', cachedLocations);
    } catch (e) {
      print('Error caching location: $e');
    }
  }

  Future<void> _cacheAllLocations(List<dynamic> locations) async {
    try {
      await LocalStorage.setList('delivery_locations', locations);
    } catch (e) {
      print('Error caching all locations: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getCachedLocations() async {
    try {
      final cachedData = await LocalStorage.getList('delivery_locations');
      return cachedData
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      print('Error loading cached locations: $e');
      return [];
    }
  }

  Future<void> _saveLocationLocally(Map<String, dynamic> location) async {
    try {
      final cachedLocations = await _getCachedLocations();
      cachedLocations.insert(0, location);

      // Keep only last 10 locations
      if (cachedLocations.length > 10) {
        cachedLocations.removeRange(10, cachedLocations.length);
      }

      await LocalStorage.setList('delivery_locations', cachedLocations);
    } catch (e) {
      print('Error saving location locally: $e');
    }
  }

  /// Clear all cached locations
  Future<void> clearCache() async {
    try {
      await LocalStorage.remove('delivery_locations');
    } catch (e) {
      print('Error clearing location cache: $e');
    }
  }
}