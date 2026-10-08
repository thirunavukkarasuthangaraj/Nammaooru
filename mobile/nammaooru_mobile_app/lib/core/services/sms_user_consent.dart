import 'dart:io';

import 'package:flutter/services.dart';

/// OTP auto-read through Google's SMS User Consent API (MainActivity.kt).
///
/// Works with any SMS template (no app hash needed): Play services shows a
/// one-tap "allow" sheet when an OTP SMS arrives and hands over the body.
/// No SMS permission is declared - Google Play rejects RECEIVE_SMS for
/// non-default SMS apps. Complements sms_autofill's SMS Retriever path,
/// which reads silently when the SMS ends with the app hash.
class SmsUserConsent {
  SmsUserConsent._();

  static const MethodChannel _channel = MethodChannel('nammaooru/sms_consent');
  static void Function(String message)? _onSms;
  static bool _handlerBound = false;

  /// Start waiting for the next OTP SMS (Play services times out after 5 min).
  /// Safe to call again on resend; the previous wait is replaced.
  static Future<void> start(void Function(String message) onSms) async {
    if (!Platform.isAndroid) return;
    _onSms = onSms;
    if (!_handlerBound) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onSms') {
          final msg = call.arguments;
          if (msg is String && msg.isNotEmpty) _onSms?.call(msg);
        }
      });
      _handlerBound = true;
    }
    try {
      await _channel.invokeMethod<void>('start');
    } catch (_) {
      // Older build or no Play services - user types the code manually.
    }
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    _onSms = null;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }
}
