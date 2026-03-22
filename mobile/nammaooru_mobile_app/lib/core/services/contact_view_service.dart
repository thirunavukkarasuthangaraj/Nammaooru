import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

/// Logs when a user taps "Call" on any post — records who viewed whose phone number.
/// Fire-and-forget: call without awaiting so it doesn't block the UI.
class ContactViewService {
  static final ContactViewService _instance = ContactViewService._internal();
  factory ContactViewService() => _instance;
  ContactViewService._internal();

  /// Call this when user taps the call/show-number button on any post.
  /// [postType] — e.g. MARKETPLACE, LABOUR, JOBS, RENTAL, WOMENS_CORNER, FARMER, TRAVEL, PARCEL
  /// [postId] — the post's numeric ID
  /// [postTitle] — title of the post (for display in history)
  /// [sellerPhone] — the phone number that was revealed
  /// [ownerUserId] — user ID of the post owner (to send push notification)
  static Future<void> log({
    required String postType,
    required dynamic postId,
    required String postTitle,
    required String sellerPhone,
    int? ownerUserId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return; // Not logged in — skip

      final uri = Uri.parse('${EnvConfig.baseUrl}/api/contact-views');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'postType': postType,
          'postId': int.tryParse(postId.toString()) ?? 0,
          'postTitle': postTitle,
          'sellerPhone': sellerPhone,
          if (ownerUserId != null) 'ownerUserId': ownerUserId,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silent fail — logging should never block the call action
    }
  }
}
