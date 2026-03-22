import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

class ContactRequestService {
  static final ContactRequestService _instance = ContactRequestService._internal();
  factory ContactRequestService() => _instance;
  ContactRequestService._internal();

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Send a contact request to view a locked phone number
  static Future<Map<String, dynamic>?> sendRequest({
    required String postType,
    required dynamic postId,
    required String postTitle,
    required dynamic postOwnerUserId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      final res = await http.post(
        Uri.parse('${EnvConfig.baseUrl}/api/contact-requests'),
        headers: _headers(token),
        body: json.encode({
          'postType': postType,
          'postId': int.tryParse(postId.toString()) ?? 0,
          'postTitle': postTitle,
          'postOwnerUserId': int.tryParse(postOwnerUserId.toString()) ?? 0,
        }),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return json.decode(res.body)['data'];
      }
    } catch (_) {}
    return null;
  }

  /// Check if I already sent a request for this post and what its status is
  static Future<Map<String, dynamic>?> checkStatus({
    required String postType,
    required dynamic postId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      final uri = Uri.parse('${EnvConfig.baseUrl}/api/contact-requests/check')
          .replace(queryParameters: {'postType': postType, 'postId': postId.toString()});
      final res = await http.get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return json.decode(res.body)['data'];
      }
    } catch (_) {}
    return null;
  }

  /// Get incoming contact requests (for post owner)
  static Future<List<Map<String, dynamic>>> getIncoming() async {
    try {
      final token = await _getToken();
      if (token == null) return [];
      final res = await http.get(
        Uri.parse('${EnvConfig.baseUrl}/api/contact-requests/incoming'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'] as List? ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Approve a contact request
  static Future<bool> approve(dynamic requestId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      final res = await http.put(
        Uri.parse('${EnvConfig.baseUrl}/api/contact-requests/$requestId/approve'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Deny a contact request
  static Future<bool> deny(dynamic requestId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      final res = await http.put(
        Uri.parse('${EnvConfig.baseUrl}/api/contact-requests/$requestId/deny'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Get pending count for badge
  static Future<int> getPendingCount() async {
    try {
      final token = await _getToken();
      if (token == null) return 0;
      final res = await http.get(
        Uri.parse('${EnvConfig.baseUrl}/api/contact-requests/pending-count'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return (json.decode(res.body)['data'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }
}
