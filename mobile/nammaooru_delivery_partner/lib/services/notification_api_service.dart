import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/storage/local_storage.dart';

class NotificationApiService {
  static final NotificationApiService _instance = NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  static NotificationApiService get instance => _instance;

  /// Update FCM token for delivery partner
  Future<Map<String, dynamic>> updateDeliveryPartnerFcmToken(String fcmToken) async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        debugPrint('No auth token found');
        return {
          'success': false,
          'message': 'Not authenticated',
          'data': null,
        };
      }

      final response = await http.post(
        Uri.parse('${AppConfig.mobileApiUrl}/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'deviceType': _getDeviceType(),
          'deviceId': await _getDeviceId(),
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Convert backend response format to include success field
        return {
          'success': body['success'] ?? false,
          'message': body['message'] ?? 'Unknown',
          'data': body['data'],
        };
      } else {
        debugPrint('Failed to update FCM token: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to update FCM token (HTTP ${response.statusCode})',
          'data': null,
        };
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'data': null,
      };
    }
  }

  /// Remove FCM token
  Future<Map<String, dynamic>> removeFcmToken(String fcmToken) async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        return {
          'statusCode': '4001',
          'message': 'Not authenticated',
          'data': null,
        };
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.mobileApiUrl}/notifications/fcm-token?token=$fcmToken'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'statusCode': '5000',
          'message': 'Failed to remove FCM token',
          'data': null,
        };
      }
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
      return {
        'statusCode': '5000',
        'message': 'Error: $e',
        'data': null,
      };
    }
  }

  /// Test push notification
  Future<Map<String, dynamic>> testPushNotification() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        return {
          'statusCode': '4001',
          'message': 'Not authenticated',
          'data': null,
        };
      }

      final response = await http.get(
        Uri.parse('${AppConfig.mobileApiUrl}/notifications/test-push'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'statusCode': '5000',
          'message': 'Failed to send test notification',
          'data': null,
        };
      }
    } catch (e) {
      debugPrint('Error testing push notification: $e');
      return {
        'statusCode': '5000',
        'message': 'Error: $e',
        'data': null,
      };
    }
  }

  /// Update delivery partner availability for notifications
  Future<Map<String, dynamic>> updateAvailabilityStatus(bool isAvailable) async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        return {
          'statusCode': '4001',
          'message': 'Not authenticated',
          'data': null,
        };
      }

      final response = await http.post(
        Uri.parse('${AppConfig.mobileApiUrl}/availability'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'isAvailable': isAvailable,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'statusCode': '5000',
          'message': 'Failed to update availability',
          'data': null,
        };
      }
    } catch (e) {
      debugPrint('Error updating availability: $e');
      return {
        'statusCode': '5000',
        'message': 'Error: $e',
        'data': null,
      };
    }
  }

  /// Get notification history
  Future<Map<String, dynamic>> getNotificationHistory() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        return {
          'statusCode': '4001',
          'message': 'Not authenticated',
          'data': null,
        };
      }

      final response = await http.get(
        Uri.parse('${AppConfig.mobileApiUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'statusCode': '5000',
          'message': 'Failed to get notifications',
          'data': null,
        };
      }
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return {
        'statusCode': '5000',
        'message': 'Error: $e',
        'data': null,
      };
    }
  }

  /// Mark notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        return {
          'statusCode': '4001',
          'message': 'Not authenticated',
          'data': null,
        };
      }

      final response = await http.put(
        Uri.parse('${AppConfig.mobileApiUrl}/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'statusCode': '5000',
          'message': 'Failed to mark as read',
          'data': null,
        };
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return {
        'statusCode': '5000',
        'message': 'Error: $e',
        'data': null,
      };
    }
  }

  /// Get device type
  String _getDeviceType() {
    // You can use Platform.isAndroid and Platform.isIOS
    // For now, returning android as default
    return 'android';
  }

  /// Get device ID
  Future<String> _getDeviceId() async {
    // You can use device_info_plus package to get actual device ID
    // For now, returning a placeholder
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
}