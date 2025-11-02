import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nammaooru_delivery_partner/core/config/app_config.dart';
import 'dart:io' show Platform;

class VersionService {
  static const String _lastVersionCheckKey = 'last_version_check';
  static const Duration _checkInterval = Duration(hours: 6); // Check every 6 hours

  /// Check if the app version needs to be updated
  static Future<Map<String, dynamic>?> checkVersion(String currentVersion) async {
    try {
      // Check if we should perform version check (not too frequent)
      if (!await _shouldCheckVersion()) {
        return null;
      }

      final platform = Platform.isAndroid ? 'ANDROID' : 'IOS';
      final uri = Uri.parse('${AppConfig.baseUrl}/api/app-version/check')
          .replace(queryParameters: {
        'appName': 'DELIVERY_PARTNER_APP',
        'platform': platform,
        'currentVersion': currentVersion,
      });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Version check timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Save last check time
        await _saveLastCheckTime();

        // Return version info if update is required or available
        if (data['updateRequired'] == true || data['updateAvailable'] == true) {
          return data;
        }
      }

      return null;
    } catch (e) {
      print('Error checking version: $e');
      return null;
    }
  }

  /// Check if enough time has passed since last version check
  static Future<bool> _shouldCheckVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString(_lastVersionCheckKey);

      if (lastCheckStr == null) {
        return true; // Never checked before
      }

      final lastCheck = DateTime.parse(lastCheckStr);
      final now = DateTime.now();

      return now.difference(lastCheck) >= _checkInterval;
    } catch (e) {
      return true; // On error, allow check
    }
  }

  /// Save the last version check timestamp
  static Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastVersionCheckKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving version check time: $e');
    }
  }

  /// Force a version check (ignore time interval)
  static Future<Map<String, dynamic>?> forceCheckVersion(String currentVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastVersionCheckKey);
    return checkVersion(currentVersion);
  }
}
