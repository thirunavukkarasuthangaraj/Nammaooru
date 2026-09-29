import 'package:flutter/material.dart';
import '../../core/theme/village_theme.dart';

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
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 36, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VillageTheme.primaryGreen.withOpacity(0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFECEFF1), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: Image.asset(
                      'assets/icons/logo-new.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
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
        ),
      ],
    );
  }
}
