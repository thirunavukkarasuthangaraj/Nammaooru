import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceTap;
  final bool showVoiceButton;
  final bool autofocus;

  const AppSearchField({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.onVoiceTap,
    this.showVoiceButton = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VillageTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VillageTheme.borderLight),
        boxShadow: VillageTheme.cardShadow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        style: VillageTheme.bodyMedium.copyWith(color: VillageTheme.modernDark),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: VillageTheme.bodyMedium.copyWith(color: VillageTheme.modernLight),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: VillageTheme.modernGray,
            size: 22,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClear != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: VillageTheme.modernGray,
                  onPressed: onClear,
                ),
              if (showVoiceButton && onVoiceTap != null)
                IconButton(
                  icon: const Icon(Icons.mic_rounded, size: 22),
                  color: VillageTheme.primaryGreen,
                  onPressed: onVoiceTap,
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        ),
      ),
    );
  }
}
