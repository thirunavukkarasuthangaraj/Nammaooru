import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  final bool showLabel;

  const LanguageSelector({
    Key? key,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabel) ...[
                Icon(Icons.language, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
              ],
              DropdownButton<String>(
                value: languageProvider.currentLanguage,
                underline: const SizedBox(),
                isDense: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.green.shade700),
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'en',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('English'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ta',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('தமிழ்'),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    languageProvider.setLanguage(newValue);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
