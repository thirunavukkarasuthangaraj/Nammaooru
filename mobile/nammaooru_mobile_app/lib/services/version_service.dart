import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nammaooru_mobile_app/core/config/env_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class VersionService {
  static const String _lastVersionCheckKey = 'last_version_check';
  static const Duration _checkInterval = Duration(hours: 6); // Check every 6 hours

  /// Check if the app version needs to be updated
  static Future<Map<String, dynamic>?> checkVersion(String currentVersion) async {
    try {
      print('🔍 VersionService: Checking version for $currentVersion');

      // TEMPORARY: Always check for testing (removed 6-hour interval)
      // if (!await _shouldCheckVersion()) {
      //   print('⏰ VersionService: Skipping check - too soon (check every 6 hours)');
      //   return null;
      // }

      // Determine platform - default to ANDROID for web testing
      final platform = _getPlatform();
      print('📱 VersionService: Platform detected: $platform');

      // Get base URL without /api suffix
      final baseUrl = kIsWeb
          ? 'http://localhost:8080'
          : EnvConfig.baseUrl; // Uses hardcoded production URL: https://api.nammaoorudelivary.in
      final uri = Uri.parse('$baseUrl/api/app-version/check')
          .replace(queryParameters: {
        'appName': 'CUSTOMER_APP',
        'platform': platform,
        'currentVersion': currentVersion,
      });

      print('🌐 VersionService: API URL: $uri');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Version check timed out');
        },
      );

      print('📡 VersionService: Response status: ${response.statusCode}');
      print('📄 VersionService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Save last check time
        await _saveLastCheckTime();

        print('✅ VersionService: API called successfully! Response: $data');
        print('   updateAvailable=${data['updateAvailable']}, isMandatory=${data['isMandatory']}');

        // Only return data if update is actually required or available
        if (data['updateRequired'] == true || data['updateAvailable'] == true) {
          print('✅ VersionService: Update available! Returning data');
          return data;
        } else {
          print('ℹ️ VersionService: No update needed');
          return null;
        }
      }

      print('❌ VersionService: Bad response status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ VersionService Error: $e');
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

  /// Get platform name - handles web platform
  static String _getPlatform() {
    if (kIsWeb) {
      // For web, default to ANDROID for testing
      return 'ANDROID';
    }

    // For mobile, check the actual platform
    try {
      // Use dart:io Platform only on mobile
      final io = Uri.base.scheme == 'file' || Uri.base.scheme == 'http';
      if (io) {
        // This will be resolved at compile time
        return const String.fromEnvironment('dart.library.io') == 'true' ? 'ANDROID' : 'IOS';
      }
    } catch (e) {
      // If error, default to ANDROID
      return 'ANDROID';
    }

    return 'ANDROID';
  }
}
