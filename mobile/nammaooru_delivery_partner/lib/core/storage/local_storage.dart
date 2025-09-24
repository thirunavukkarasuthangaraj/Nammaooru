import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> setToken(String token) async {
    return await _prefs?.setString('auth_token', token) ?? false;
  }

  static Future<String?> getToken() async {
    return _prefs?.getString('auth_token');
  }

  static Future<bool> removeToken() async {
    return await _prefs?.remove('auth_token') ?? false;
  }

  static Future<bool> setUserId(String userId) async {
    return await _prefs?.setString('user_id', userId) ?? false;
  }

  static Future<String?> getUserId() async {
    return _prefs?.getString('user_id');
  }

  static Future<bool> setUserRole(String role) async {
    return await _prefs?.setString('user_role', role) ?? false;
  }

  static Future<String?> getUserRole() async {
    return _prefs?.getString('user_role');
  }

  static Future<bool> clearAll() async {
    return await _prefs?.clear() ?? false;
  }
}