import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import '../core/auth/auth_service.dart';
import '../shared/models/notification_model.dart';

class NotificationApiService {
  static final NotificationApiService _instance = NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  static NotificationApiService get instance => _instance;

  final String _baseUrl = EnvConfig.apiBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all notifications for the current user
  Future<Map<String, dynamic>> getNotifications({
    int page = 0,
    int size = 20,
    String? type,
    bool? isRead,
  }) async {
    try {
      final headers = await _getHeaders();

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (isRead != null) queryParams['isRead'] = isRead.toString();

      final uri = Uri.parse('$_baseUrl/api/customer/notifications')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'statusCode': '0000',
          'message': 'Success',
          'data': data,
        };
      } else {
        return {
          'statusCode': response.statusCode.toString(),
          'message': 'Failed to load notifications',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'statusCode': '9999',
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Mark a notification as read
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$_baseUrl/api/customer/notifications/$notificationId/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'statusCode': '0000',
          'message': 'Notification marked as read',
          'data': null,
        };
      } else {
        return {
          'statusCode': response.statusCode.toString(),
          'message': 'Failed to mark notification as read',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'statusCode': '9999',
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$_baseUrl/api/customer/notifications/mark-all-read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'statusCode': '0000',
          'message': 'All notifications marked as read',
          'data': null,
        };
      } else {
        return {
          'statusCode': response.statusCode.toString(),
          'message': 'Failed to mark all notifications as read',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'statusCode': '9999',
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Delete a notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/customer/notifications/$notificationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'statusCode': '0000',
          'message': 'Notification deleted',
          'data': null,
        };
      } else {
        return {
          'statusCode': response.statusCode.toString(),
          'message': 'Failed to delete notification',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'statusCode': '9999',
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Get unread notification count
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/api/customer/notifications/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'statusCode': '0000',
          'message': 'Success',
          'data': data,
        };
      } else {
        return {
          'statusCode': response.statusCode.toString(),
          'message': 'Failed to get unread count',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'statusCode': '9999',
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Convert API response to NotificationModel list
  List<NotificationModel> parseNotifications(List<dynamic> jsonList) {
    return jsonList
        .map((json) => NotificationModel.fromJson(json))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Latest first
  }
}