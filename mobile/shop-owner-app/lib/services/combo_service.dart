import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_config.dart';
import '../models/combo_model.dart';

class ComboService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<Map<String, String>> _getAuthHeaders() async {
    final headers = Map<String, String>.from(_defaultHeaders);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }
    return headers;
  }

  /// Get all combos for a shop
  static Future<List<Combo>> getShopCombos(int shopId, {String? status}) async {
    try {
      String url = '$baseUrl/shops/$shopId/combos?size=100';
      if (status != null && status.isNotEmpty) {
        url += '&status=$status';
      }

      final response = await http
          .get(Uri.parse(url), headers: await _getAuthHeaders())
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == '0000' && data['data'] != null) {
          final content = data['data']['content'] as List? ?? data['data'] as List?;
          if (content != null) {
            return content.map((e) => Combo.fromJson(e)).toList();
          }
        }
      }
      print('Error fetching combos: ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching combos: $e');
      return [];
    }
  }

  /// Get combo by ID
  static Future<Combo?> getComboById(int shopId, int comboId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/shops/$shopId/combos/$comboId'),
            headers: await _getAuthHeaders(),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == '0000' && data['data'] != null) {
          return Combo.fromJson(data['data']);
        }
      }
      print('Error fetching combo: ${response.body}');
      return null;
    } catch (e) {
      print('Error fetching combo: $e');
      return null;
    }
  }

  /// Create a new combo
  static Future<Map<String, dynamic>> createCombo(
      int shopId, Map<String, dynamic> comboData) async {
    try {
      print('Creating combo for shop $shopId: ${json.encode(comboData)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/shops/$shopId/combos'),
            headers: await _getAuthHeaders(),
            body: json.encode(comboData),
          )
          .timeout(timeout);

      final data = json.decode(response.body);
      print('Create combo response: $data');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['statusCode'] == '0000') {
          return {
            'success': true,
            'data': data['data'] != null ? Combo.fromJson(data['data']) : null,
            'message': data['message'] ?? 'Combo created successfully',
          };
        }
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to create combo',
      };
    } catch (e) {
      print('Error creating combo: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Update a combo
  static Future<Map<String, dynamic>> updateCombo(
      int shopId, int comboId, Map<String, dynamic> comboData) async {
    try {
      print('Updating combo $comboId: ${json.encode(comboData)}');

      final response = await http
          .put(
            Uri.parse('$baseUrl/shops/$shopId/combos/$comboId'),
            headers: await _getAuthHeaders(),
            body: json.encode(comboData),
          )
          .timeout(timeout);

      final data = json.decode(response.body);
      print('Update combo response: $data');

      if (response.statusCode == 200) {
        if (data['statusCode'] == '0000') {
          return {
            'success': true,
            'data': data['data'] != null ? Combo.fromJson(data['data']) : null,
            'message': data['message'] ?? 'Combo updated successfully',
          };
        }
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update combo',
      };
    } catch (e) {
      print('Error updating combo: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Delete a combo
  static Future<Map<String, dynamic>> deleteCombo(int shopId, int comboId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/shops/$shopId/combos/$comboId'),
            headers: await _getAuthHeaders(),
          )
          .timeout(timeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['statusCode'] == '0000') {
          return {
            'success': true,
            'message': data['message'] ?? 'Combo deleted successfully',
          };
        }
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete combo',
      };
    } catch (e) {
      print('Error deleting combo: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Toggle combo active status
  static Future<Map<String, dynamic>> toggleComboStatus(
      int shopId, int comboId) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/shops/$shopId/combos/$comboId/toggle-status'),
            headers: await _getAuthHeaders(),
          )
          .timeout(timeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['statusCode'] == '0000') {
          return {
            'success': true,
            'data': data['data'] != null ? Combo.fromJson(data['data']) : null,
            'message': data['message'] ?? 'Status updated',
          };
        }
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to toggle status',
      };
    } catch (e) {
      print('Error toggling combo status: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get shop products for selection
  static Future<List<Map<String, dynamic>>> getShopProducts(int shopId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/shops/$shopId/products?size=500'),
            headers: await _getAuthHeaders(),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == '0000' && data['data'] != null) {
          final content =
              data['data']['content'] as List? ?? data['data'] as List?;
          if (content != null) {
            return content.cast<Map<String, dynamic>>();
          }
        }
      }
      return [];
    } catch (e) {
      print('Error fetching shop products: $e');
      return [];
    }
  }

  /// Upload combo banner image
  static Future<Map<String, dynamic>> uploadComboImage(
      int shopId, File imageFile, {int? comboId}) async {
    try {
      String url = '$baseUrl/shops/$shopId/combos/upload-image';
      if (comboId != null) {
        url += '?comboId=$comboId';
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      print('Upload combo image response: $data');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['statusCode'] == '0000') {
          return {
            'success': true,
            'imageUrl': data['imageUrl'],
            'message': data['message'] ?? 'Image uploaded successfully',
          };
        }
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to upload image',
      };
    } catch (e) {
      print('Error uploading combo image: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
