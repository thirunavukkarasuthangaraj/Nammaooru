import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class AddressApiService {
  static const String _baseUrl = '/customer';

  /// Get all addresses for current user
  static Future<Map<String, dynamic>> getUserAddresses() async {
    try {
      final response = await ApiClient.get('$_baseUrl/delivery-locations');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final statusCode = responseData['statusCode']?.toString();
          if (statusCode == '0000') {
            return {
              'success': true,
              'data': responseData['data'] ?? [],
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to load addresses',
              'data': [],
            };
          }
        } else if (responseData is List) {
          return {
            'success': true,
            'data': responseData,
          };
        }
      }

      return {
        'success': false,
        'message': 'Invalid response format',
        'data': [],
      };
    } catch (e) {
      print('Error loading addresses: $e');
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
    String? city,
    String? state,
    String? pincode,
    String? flatHouse,
    String? floor,
    String? street,
    String? village,
  }) async {
    try {
      final requestData = {
        'addressType': label,
        'flatHouse': flatHouse ?? '',
        'floor': floor ?? '',
        'street': street ?? '',
        'area': fullAddress,
        'village': village ?? '',
        'landmark': details,
        'city': city ?? 'Tirupattur', // Use actual detected city
        'state': state ?? 'Tamil Nadu', // Use actual detected state
        'pincode': pincode != null && pincode.isNotEmpty ? pincode : '635601', // Must be 6-digit pincode
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };

      print('Sending address request: $requestData');

      final response = await ApiClient.post('$_baseUrl/delivery-locations', data: requestData);

      print('Add address response status: ${response.statusCode}');
      print('Add address response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final statusCode = responseData['statusCode']?.toString();
          if (statusCode == '0000') {
            print('Address added successfully with statusCode 0000');
            return {
              'success': true,
              'data': responseData['data'],
              'message': responseData['message'] ?? 'Address added successfully',
            };
          } else {
            print('Address add failed with statusCode: $statusCode, message: ${responseData['message']}');
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to add address',
            };
          }
        }
      }

      print('Unexpected response format or status code');
      return {
        'success': false,
        'message': 'Failed to add address - unexpected response format',
      };
    } catch (e) {
      print('Exception in addAddress: $e');
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
      // Note: Update endpoint may need to be implemented in backend
      final response = await ApiClient.put('$_baseUrl/delivery-locations/$addressId', data: {
        'addressType': label,
        'flatHouse': '',
        'area': fullAddress,
        'landmark': details,
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'pincode': '600001',
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
      print('Deleting address with ID: $addressId');
      final response = await ApiClient.delete('$_baseUrl/delivery-locations/$addressId');

      print('Delete address response status: ${response.statusCode}');
      print('Delete address response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final statusCode = responseData['statusCode']?.toString();
          if (statusCode == '0000') {
            return {
              'success': true,
              'message': responseData['message'] ?? 'Address deleted successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to delete address',
            };
          }
        } else {
          // For 204 No Content or other successful responses without body
          return {
            'success': true,
            'message': 'Address deleted successfully',
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to delete address - unexpected response',
      };
    } catch (e) {
      print('Exception in deleteAddress: $e');
      return {
        'success': false,
        'message': 'Failed to delete address: $e',
      };
    }
  }

  /// Set address as default
  static Future<Map<String, dynamic>> setDefaultAddress(int addressId) async {
    try {
      // Note: Set default endpoint may need to be implemented in backend
      final response = await ApiClient.put('$_baseUrl/delivery-locations/$addressId/default');
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
      final response = await ApiClient.get('$_baseUrl/delivery-locations');
      final addresses = response.data as List<dynamic>? ?? [];
      final defaultAddress = addresses.firstWhere(
        (addr) => addr['isDefault'] == true,
        orElse: () => null,
      );
      return {
        'success': true,
        'data': defaultAddress,
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