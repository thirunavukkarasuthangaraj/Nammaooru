import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PromoCodeService {
  static const String baseUrl = 'http://10.187.95.46:8080/api/shop-owner/promotions';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all promo codes for shop owner's shop
  Future<List<Map<String, dynamic>>> getPromoCodes({int page = 0, int size = 20}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl?page=$page&size=$size'),
        headers: headers,
      );

      print('Get promo codes response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == '0000') {
          final content = data['data']['content'] as List;
          return content.map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting promo codes: $e');
      return [];
    }
  }

  // Create new promo code
  Future<Map<String, dynamic>> createPromoCode(Map<String, dynamic> promoData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(promoData),
      );

      print('Create promo code response: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error creating promo code: $e');
      return {
        'statusCode': 'ERROR',
        'message': 'Failed to create promo code: $e'
      };
    }
  }

  // Update promo code
  Future<Map<String, dynamic>> updatePromoCode(int id, Map<String, dynamic> promoData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: json.encode(promoData),
      );

      print('Update promo code response: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error updating promo code: $e');
      return {
        'statusCode': 'ERROR',
        'message': 'Failed to update promo code: $e'
      };
    }
  }

  // Delete promo code
  Future<Map<String, dynamic>> deletePromoCode(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      print('Delete promo code response: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error deleting promo code: $e');
      return {
        'statusCode': 'ERROR',
        'message': 'Failed to delete promo code: $e'
      };
    }
  }

  // Toggle promo code status (ACTIVE/INACTIVE)
  Future<Map<String, dynamic>> togglePromoStatus(int id, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/$id/status?status=$status'),
        headers: headers,
      );

      print('Toggle promo status response: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error toggling promo status: $e');
      return {
        'statusCode': 'ERROR',
        'message': 'Failed to toggle promo status: $e'
      };
    }
  }

  // Get promo code statistics
  Future<Map<String, dynamic>> getPromoStats(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id/stats'),
        headers: headers,
      );

      print('Get promo stats response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == '0000') {
          return data['data'];
        }
      }
      return {};
    } catch (e) {
      print('Error getting promo stats: $e');
      return {};
    }
  }
}
