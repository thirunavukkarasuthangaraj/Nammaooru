import 'package:shared_preferences/shared_preferences.dart';

/// Mobile implementation using SharedPreferences only
/// Removed flutter_secure_storage to avoid package_info_plus transitive dependency (QUERY_ALL_PACKAGES)
class LocalStorageImpl {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Use SharedPreferences with 'secure_' prefix (flutter_secure_storage removed)
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
