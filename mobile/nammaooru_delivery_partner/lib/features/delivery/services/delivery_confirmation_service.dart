import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/services/api_service.dart';

class DeliveryConfirmationService {
  final ApiService _apiService = ApiService();

  /// Generate pickup OTP
  Future<Map<String, dynamic>> generatePickupOTP(String orderId) async {
    try {
      final response = await _apiService.post(
        '/api/delivery/pickup/generate-otp',
        {'orderId': orderId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'otp': data['otp'], // For demo purposes - in production, this should not be returned
          'message': 'OTP generated successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to generate OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Generate delivery OTP
  Future<Map<String, dynamic>> generateDeliveryOTP(String orderId) async {
    try {
      final response = await _apiService.post(
        '/api/delivery/delivery/generate-otp',
        {'orderId': orderId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'otp': data['otp'], // For demo purposes - in production, this should not be returned
          'message': 'OTP generated successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to generate OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Validate OTP
  Future<bool> validateOTP(String orderId, String otp, String type) async {
    try {
      final response = await _apiService.post(
        '/api/delivery/$type/validate-otp',
        {
          'orderId': orderId,
          'otp': otp,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error validating OTP: $e');
      return false;
    }
  }

  /// Confirm pickup with OTP and photo
  Future<Map<String, dynamic>> confirmPickup({
    required String orderId,
    required String otp,
    required File photoFile,
  }) async {
    try {
      var uri = Uri.parse('${_apiService.baseUrl}/api/delivery/pickup/confirm');
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);

      // Add fields
      request.fields['orderId'] = orderId;
      request.fields['otp'] = otp;

      // Add photo file
      var photoStream = http.ByteStream(photoFile.openRead());
      var photoLength = await photoFile.length();
      var multipartFile = http.MultipartFile(
        'pickupPhoto',
        photoStream,
        photoLength,
        filename: 'pickup_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Pickup confirmed successfully',
          'photoUrl': data['photoUrl'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to confirm pickup',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Confirm delivery with OTP, photo, and signature
  Future<Map<String, dynamic>> confirmDelivery({
    required String orderId,
    required String otp,
    File? deliveryPhoto,
    File? signatureFile,
    String? customerName,
    String? deliveryNotes,
    double? latitude,
    double? longitude,
  }) async {
    try {
      var uri = Uri.parse('${_apiService.baseUrl}/api/delivery/delivery/confirm');
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);

      // Add fields
      request.fields['orderId'] = orderId;
      request.fields['otp'] = otp;
      if (customerName != null) request.fields['customerName'] = customerName;
      if (deliveryNotes != null) request.fields['deliveryNotes'] = deliveryNotes;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();

      // Add delivery photo if provided
      if (deliveryPhoto != null) {
        var photoStream = http.ByteStream(deliveryPhoto.openRead());
        var photoLength = await deliveryPhoto.length();
        var multipartFile = http.MultipartFile(
          'deliveryPhoto',
          photoStream,
          photoLength,
          filename: 'delivery_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      // Add signature if provided
      if (signatureFile != null) {
        var signatureStream = http.ByteStream(signatureFile.openRead());
        var signatureLength = await signatureFile.length();
        var multipartFile = http.MultipartFile(
          'signature',
          signatureStream,
          signatureLength,
          filename: 'signature_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Delivery confirmed successfully',
          'photoUrl': data['photoUrl'],
          'signatureUrl': data['signatureUrl'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to confirm delivery',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Get delivery proof for an order
  Future<Map<String, dynamic>?> getDeliveryProof(String orderId) async {
    try {
      final response = await _apiService.get('/api/delivery/proof/$orderId');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching delivery proof: $e');
      return null;
    }
  }

  /// Resend OTP
  Future<Map<String, dynamic>> resendOTP(String orderId, String type) async {
    try {
      final response = await _apiService.post(
        '/api/delivery/resend-otp',
        {
          'orderId': orderId,
          'type': type,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'OTP resent successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to resend OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}