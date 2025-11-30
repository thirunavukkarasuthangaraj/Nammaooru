import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class LocalStorageImpl {
  static late SharedPreferences prefs;
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Mobile implementation - use FlutterSecureStorage for sensitive data
  static Future<void> setSecureString(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecureString(String key) async {
    return await secureStorage.read(key: key);
  }

  static Future<void> removeSecureString(String key) async {
    await secureStorage.delete(key: key);
  }

  static Future<void> clearSecureStorage() async {
    await secureStorage.deleteAll();
  }
}
