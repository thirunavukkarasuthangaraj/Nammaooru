import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

/// Mobile implementation using SharedPreferences only (no flutter_secure_storage)
/// Removed flutter_secure_storage to avoid package_info_plus transitive dependency
class StorageServiceImpl {
  // Storage keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // Mobile implementation - use SharedPreferences (flutter_secure_storage removed to avoid QUERY_ALL_PACKAGES)
  static Future<void> saveAuthData(AuthResponse authResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, authResponse.accessToken);
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString('user_email', authResponse.email);

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

  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAccessToken);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  static Future<User?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_keyUserData);
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyAccessToken);
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      return isLoggedIn && token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserData);
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove('registration_email');
    } catch (e) {
      throw Exception('Failed to clear authentication data: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }
}
