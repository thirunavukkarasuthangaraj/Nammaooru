import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String fullName,
    required String phone,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/auth/register');
      
      final body = {
        'username': username,
        'email': email,
        'fullName': fullName,
        'phoneNumber': phone,
        'password': password,
        'role': 'CUSTOMER',
      };

      print('🚀 Making API call to: $url');
      print('📤 Request payload: ${jsonEncode(body)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Registration successful!',
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Registration failed',
          'message': responseData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('❌ API Error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/auth/login');
      
      final body = {
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      };

      print('🚀 Making login API call to: $url');
      print('📤 Request payload: ${jsonEncode(body)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Login successful!',
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Login failed',
          'message': responseData['message'] ?? 'Invalid credentials',
        };
      }
    } catch (e) {
      print('❌ Login API Error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }
}