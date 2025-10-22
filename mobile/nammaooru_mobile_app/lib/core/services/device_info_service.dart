import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  static const String _deviceUuidKey = 'device_uuid';
  String? _cachedDeviceUuid;

  /// Get or generate device UUID
  /// This UUID persists across app installations using SharedPreferences
  /// and is used for promo code tracking
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

      // Generate new UUID based on device info
      final deviceInfo = DeviceInfoPlugin();
      String deviceUuid;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Use Android ID as base, but generate UUID if not available
        deviceUuid = androidInfo.id.isNotEmpty
            ? 'android_${androidInfo.id}'
            : 'android_${const Uuid().v4()}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Use identifierForVendor as base
        deviceUuid = iosInfo.identifierForVendor != null && iosInfo.identifierForVendor!.isNotEmpty
            ? 'ios_${iosInfo.identifierForVendor}'
            : 'ios_${const Uuid().v4()}';
      } else {
        // For web or other platforms, generate random UUID
        deviceUuid = 'other_${const Uuid().v4()}';
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
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return {'platform': 'Unknown'};
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
