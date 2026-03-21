import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/env_config.dart';
import '../models/combo_model.dart';

class CustomerComboService {
  static String get baseUrl => EnvConfig.apiUrl;
  static const Duration timeout = Duration(seconds: 30);

  /// Get all active combos across all shops (for dashboard)
  static Future<List<CustomerCombo>> getAllActiveCombos() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/customer/combos'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == '0000' && data['data'] != null) {
          final List<dynamic> combosList = data['data'];
          return combosList.map((e) => CustomerCombo.fromJson(e)).toList();
        }
      }
      print('Error fetching all combos: ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching all combos: $e');
      return [];
    }
  }

  /// Get active combos for a shop
  static Future<List<CustomerCombo>> getActiveCombos(int shopId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/customer/shops/$shopId/combos'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == '0000' && data['data'] != null) {
          final List<dynamic> combosList = data['data'];
          return combosList.map((e) => CustomerCombo.fromJson(e)).toList();
        }
      }
      print('Error fetching combos: ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching combos: $e');
      return [];
    }
  }

  /// Get combo details
  static Future<CustomerCombo?> getComboDetails(int comboId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/customer/combos/$comboId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == '0000' && data['data'] != null) {
          return CustomerCombo.fromJson(data['data']);
        }
      }
      print('Error fetching combo details: ${response.body}');
      return null;
    } catch (e) {
      print('Error fetching combo details: $e');
      return null;
    }
  }
}
