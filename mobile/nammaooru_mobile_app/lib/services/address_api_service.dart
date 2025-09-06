import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class AddressApiService {
  static const String _baseUrl = '/addresses';

  /// Get all addresses for current user
  static Future<Map<String, dynamic>> getUserAddresses() async {
    try {
      final response = await ApiClient.get('$_baseUrl/user');
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load addresses: $e',
        'data': [],
      };
    }
  }

  /// Add new address for current user
  static Future<Map<String, dynamic>> addAddress({
    required String label,
    required String fullAddress,
    required String details,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) async {
    try {
      final response = await ApiClient.post(_baseUrl, data: {
        'label': label,
        'fullAddress': fullAddress,
        'addressDetails': details,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      });
      
      return {
        'success': true,
        'data': response.data,
        'message': 'Address added successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add address: $e',
      };
    }
  }

  /// Update existing address
  static Future<Map<String, dynamic>> updateAddress({
    required int addressId,
    required String label,
    required String fullAddress,
    required String details,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) async {
    try {
      final response = await ApiClient.put('$_baseUrl/$addressId', data: {
        'label': label,
        'fullAddress': fullAddress,
        'addressDetails': details,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      });
      
      return {
        'success': true,
        'data': response.data,
        'message': 'Address updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update address: $e',
      };
    }
  }

  /// Delete address
  static Future<Map<String, dynamic>> deleteAddress(int addressId) async {
    try {
      await ApiClient.delete('$_baseUrl/$addressId');
      return {
        'success': true,
        'message': 'Address deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete address: $e',
      };
    }
  }

  /// Set address as default
  static Future<Map<String, dynamic>> setDefaultAddress(int addressId) async {
    try {
      final response = await ApiClient.put('$_baseUrl/$addressId/default');
      return {
        'success': true,
        'data': response.data,
        'message': 'Default address updated',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update default address: $e',
      };
    }
  }

  /// Get default address for current user
  static Future<Map<String, dynamic>> getDefaultAddress() async {
    try {
      final response = await ApiClient.get('$_baseUrl/default');
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get default address: $e',
        'data': null,
      };
    }
  }
}