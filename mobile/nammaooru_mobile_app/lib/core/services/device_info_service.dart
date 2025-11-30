import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Simple device UUID service without device_info_plus to avoid Google Play permission issues
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  static const String _deviceUuidKey = 'device_uuid';
  String? _cachedDeviceUuid;

  /// Get or generate device UUID
  /// This UUID persists across app installations using SharedPreferences
  /// and is used for promo code tracking
  /// NOTE: Simplified to avoid QUERY_ALL_PACKAGES permission - uses random UUID
  Future<String> getDeviceUuid() async {
    // Return cached value if available
    if (_cachedDeviceUuid != null) {
      return _cachedDeviceUuid!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we have a stored UUID
      String? storedUuid = prefs.getString(_deviceUuidKey);

      if (storedUuid != null && storedUuid.isNotEmpty) {
        _cachedDeviceUuid = storedUuid;
        return storedUuid;
      }

      // Generate new random UUID (no device info to avoid permissions)
      String deviceUuid;
      if (Platform.isAndroid) {
        deviceUuid = 'android_${const Uuid().v4()}';
      } else if (Platform.isIOS) {
        deviceUuid = 'ios_${const Uuid().v4()}';
      } else {
        deviceUuid = 'web_${const Uuid().v4()}';
      }

      // Store the UUID
      await prefs.setString(_deviceUuidKey, deviceUuid);
      _cachedDeviceUuid = deviceUuid;

      print('Generated new device UUID: $deviceUuid');
      return deviceUuid;
    } catch (e) {
      print('Error getting device UUID: $e');
      // Fallback: generate and store random UUID
      final fallbackUuid = 'fallback_${const Uuid().v4()}';
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_deviceUuidKey, fallbackUuid);
      } catch (_) {}
      _cachedDeviceUuid = fallbackUuid;
      return fallbackUuid;
    }
  }

  /// Get device information for logging/debugging
  /// Simplified version without device_info_plus
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return {'platform': 'Android'};
      } else if (Platform.isIOS) {
        return {'platform': 'iOS'};
      } else {
        return {'platform': 'Web'};
      }
    } catch (e) {
      print('Error getting device info: $e');
      return {'platform': 'Unknown'};
    }
  }

  /// Clear cached device UUID (for testing purposes)
  Future<void> clearDeviceUuid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceUuidKey);
      _cachedDeviceUuid = null;
    } catch (e) {
      print('Error clearing device UUID: $e');
    }
  }
}
