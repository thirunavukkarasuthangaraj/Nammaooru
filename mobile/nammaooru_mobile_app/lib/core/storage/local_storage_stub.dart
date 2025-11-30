import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageImpl {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Web implementation - use SharedPreferences for all storage
  static Future<void> setSecureString(String key, String value) async {
    await prefs.setString('secure_$key', value);
  }

  static Future<String?> getSecureString(String key) async {
    return prefs.getString('secure_$key');
  }

  static Future<void> removeSecureString(String key) async {
    await prefs.remove('secure_$key');
  }

  static Future<void> clearSecureStorage() async {
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('secure_')) {
        await prefs.remove(key);
      }
    }
  }
}
