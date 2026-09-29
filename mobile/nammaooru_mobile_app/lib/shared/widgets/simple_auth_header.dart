import 'package:flutter/material.dart';

/// Minimal auth header: logo centered, title directly below it, language
/// toggle as a small button in the top-right corner. Used on the phone-entry
/// and OTP screens instead of the green-banner CustomerAuthHeader.
class SimpleAuthHeader extends StatelessWidget {
  final String title;
  final String languageLabel;
  final VoidCallback onLanguageChanged;

  const SimpleAuthHeader({
    super.key,
    required this.title,
    required this.languageLabel,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: TextButton(
              onPressed: onLanguageChanged,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2C3E50),
                backgroundColor: const Color(0xFFECEFF1),
              ),
              child: Text(languageLabel),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 8),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icons/logo-new.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
