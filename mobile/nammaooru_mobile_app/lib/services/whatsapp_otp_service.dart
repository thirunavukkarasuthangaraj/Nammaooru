import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class WhatsAppOTPService {
  static const String _baseUrl = AppConstants.apiBaseUrl;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  /// Send OTP via WhatsApp or SMS
  static Future<Map<String, dynamic>> sendOTP({
    required String mobileNumber,
    String channel = 'whatsapp',
    String? name,
    String purpose = 'login',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/whatsapp/send-otp');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'channel': channel,
          'name': name,
          'purpose': purpose,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'OTP sent successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }
  
  /// Verify OTP
  static Future<Map<String, dynamic>> verifyOTP({
    required String mobileNumber,
    required String otp,
    String? deviceToken,
    String? deviceType,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/whatsapp/verify-otp');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'otp': otp,
          'deviceToken': deviceToken,
          'deviceType': deviceType ?? (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'),
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Save token and user data if verification successful
        if (data['data'] != null && data['data']['token'] != null) {
          await _saveAuthData(data['data']);
        }
        
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'OTP verified successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Invalid OTP',
          'attemptsLeft': error['data']?['attemptsLeft'],
        };
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }
  
  /// Resend OTP
  static Future<Map<String, dynamic>> resendOTP({
    required String mobileNumber,
    String channel = 'whatsapp',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/whatsapp/resend-otp');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'channel': channel,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'OTP resent successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to resend OTP',
        };
      }
    } catch (e) {
      debugPrint('Error resending OTP: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }
  
  /// Check OTP status
  static Future<Map<String, dynamic>> checkOTPStatus(String mobileNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/whatsapp/status/$mobileNumber');
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to check OTP status',
        };
      }
    } catch (e) {
      debugPrint('Error checking OTP status: $e');
      return {
        'success': false,
        'message': 'Network error',
      };
    }
  }
  
  /// Save authentication data to local storage
  static Future<void> _saveAuthData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save token
      if (data['token'] != null) {
        await prefs.setString(_tokenKey, data['token']);
      }
      
      // Save user data
      final userData = {
        'userId': data['userId'],
        'userType': data['userType'],
        'isNewUser': data['isNewUser'],
      };
      await prefs.setString(_userKey, jsonEncode(userData));
      
    } catch (e) {
      debugPrint('Error saving auth data: $e');
    }
  }
  
  /// Get saved token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  /// Get saved user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }
  
  /// Clear authentication data (logout)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
  
  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}