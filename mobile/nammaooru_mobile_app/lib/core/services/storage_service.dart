import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      // accessibility: KeychainItemAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUserEmail = 'user_email';

  // Save authentication data
  static Future<void> saveAuthData(AuthResponse authResponse) async {
    try {
      await _storage.write(key: _keyAccessToken, value: authResponse.accessToken);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserEmail, authResponse.email);
      
      // Save user basic info to preferences for quick access
      final userData = {
        'username': authResponse.username,
        'email': authResponse.email,
        'role': authResponse.role,
      };
      await prefs.setString(_keyUserData, jsonEncode(userData));
      
    } catch (e) {
      throw Exception('Failed to save authentication data: $e');
    }
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (e) {
      return null;
    }
  }

  // Save user data
  static Future<void> saveUserData(User user) async {
    try {
      await _storage.write(key: _keyUserData, value: jsonEncode(user.toJson()));
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  // Get user data
  static Future<User?> getUserData() async {
    try {
      final userData = await _storage.read(key: _keyUserData);
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _storage.read(key: _keyAccessToken);
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      return isLoggedIn && token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Save remember me preference
  static Future<void> saveRememberMe(bool remember, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, remember);
      if (remember) {
        await prefs.setString(_keyUserEmail, email);
      } else {
        await prefs.remove(_keyUserEmail);
      }
    } catch (e) {
      throw Exception('Failed to save remember me preference: $e');
    }
  }

  // Get remember me preference
  static Future<Map<String, dynamic>> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_keyRememberMe) ?? false;
      final email = prefs.getString(_keyUserEmail) ?? '';
      
      return {
        'remember': remember,
        'email': email,
      };
    } catch (e) {
      return {
        'remember': false,
        'email': '',
      };
    }
  }

  // Save registration email for OTP verification
  static Future<void> saveRegistrationEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('registration_email', email);
    } catch (e) {
      throw Exception('Failed to save registration email: $e');
    }
  }

  // Get registration email
  static Future<String?> getRegistrationEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('registration_email');
    } catch (e) {
      return null;
    }
  }

  // Clear registration email
  static Future<void> clearRegistrationEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('registration_email');
    } catch (e) {
      // Ignore error
    }
  }

  // Clear all authentication data
  static Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserData);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyUserData);
      await prefs.remove('registration_email');
    } catch (e) {
      throw Exception('Failed to clear authentication data: $e');
    }
  }

  // Clear all app data
  static Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }
}