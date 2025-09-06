import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class LocalStorage {
  static late SharedPreferences _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  static String? getString(String key) {
    return _prefs.getString(key);
  }
  
  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }
  
  static int? getInt(String key) {
    return _prefs.getInt(key);
  }
  
  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
  
  static Future<void> clear() async {
    await _prefs.clear();
  }
  
  static Future<void> setSecureString(String key, String value) async {
    if (kIsWeb) {
      // On web, use SharedPreferences as FlutterSecureStorage has issues
      await _prefs.setString('secure_$key', value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }
  
  static Future<String?> getSecureString(String key) async {
    if (kIsWeb) {
      // On web, use SharedPreferences as FlutterSecureStorage has issues
      return _prefs.getString('secure_$key');
    } else {
      return await _secureStorage.read(key: key);
    }
  }
  
  static Future<void> removeSecureString(String key) async {
    if (kIsWeb) {
      await _prefs.remove('secure_$key');
    } else {
      await _secureStorage.delete(key: key);
    }
  }
  
  static Future<void> clearSecureStorage() async {
    if (kIsWeb) {
      final keys = _prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('secure_')) {
          await _prefs.remove(key);
        }
      }
    } else {
      await _secureStorage.deleteAll();
    }
  }

  // Additional methods for map and list operations
  static Future<void> setMap(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }
  
  static Map<String, dynamic> getMap(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    } catch (e) {
      return {};
    }
  }
  
  static Future<void> setList(String key, List<dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }
  
  static List<dynamic> getList(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return [];
    try {
      return List<dynamic>.from(jsonDecode(jsonString));
    } catch (e) {
      return [];
    }
  }
  
  // User preferences methods
  static Future<Map<String, dynamic>> getUserPreferences() async {
    return getMap('user_preferences');
  }
  
  static Future<void> setUserPreference(String key, dynamic value) async {
    final prefs = getUserPreferences();
    final currentPrefs = await prefs;
    currentPrefs[key] = value;
    await setMap('user_preferences', currentPrefs);
  }
  
  // Clear all data
  static Future<void> clearAll() async {
    await clear();
    await clearSecureStorage();
  }
}