import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class StorageServiceImpl {
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

  // Mobile implementation - use FlutterSecureStorage for sensitive data
  static Future<void> saveAuthData(AuthResponse authResponse) async {
    try {
      await _storage.write(key: _keyAccessToken, value: authResponse.accessToken);

      final prefs = await SharedPreferences.getInstance();
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
      return await _storage.read(key: _keyAccessToken);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveUserData(User user) async {
    try {
      await _storage.write(key: _keyUserData, value: jsonEncode(user.toJson()));
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

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
