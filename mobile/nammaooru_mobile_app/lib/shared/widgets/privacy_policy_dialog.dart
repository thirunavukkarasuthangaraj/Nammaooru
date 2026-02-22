import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/localization/language_provider.dart';

class PrivacyPolicyDialog extends StatefulWidget {
  const PrivacyPolicyDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PrivacyPolicyDialog(),
    );
  }

  @override
  State<PrivacyPolicyDialog> createState() => _PrivacyPolicyDialogState();
}

class _PrivacyPolicyDialogState extends State<PrivacyPolicyDialog> {
  String? _content;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPrivacyPolicy();
  }

  Future<void> _fetchPrivacyPolicy() async {
    try {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      final key = langProvider.showTamil ? 'PRIVACY_POLICY_TA' : 'PRIVACY_POLICY_EN';

      final response = await ApiClient.get(
        '/settings/public/$key',
        includeAuth: false,
        options: Options(responseType: ResponseType.plain),
      );

      if (mounted) {
        setState(() {
          _content = response.data?.toString() ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    langProvider.getText('Privacy Policy', '\u0BA4\u0BA9\u0BBF\u0BAF\u0BC1\u0BB0\u0BBF\u0BAE\u0BC8 \u0B95\u0BCA\u0BB3\u0BCD\u0B95\u0BC8'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              langProvider.getText(
                                'Failed to load privacy policy. Please try again later.',
                                '\u0BA4\u0BA9\u0BBF\u0BAF\u0BC1\u0BB0\u0BBF\u0BAE\u0BC8 \u0B95\u0BCA\u0BB3\u0BCD\u0B95\u0BC8\u0BAF\u0BC8 \u0B8F\u0BB1\u0BCD\u0BB1 \u0BAE\u0BC1\u0B9F\u0BBF\u0BAF\u0BB5\u0BBF\u0BB2\u0BCD\u0BB2\u0BC8. \u0BAA\u0BBF\u0BA9\u0BCD\u0BA9\u0BB0\u0BCD \u0BAE\u0BC1\u0BAF\u0BB1\u0BCD\u0B9A\u0BBF\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _content ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
          ),
          // Close button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                langProvider.getText('Close', '\u0BAE\u0BC2\u0B9F\u0BC1'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
