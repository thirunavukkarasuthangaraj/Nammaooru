import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../common_buttons.dart';

/// Consistent empty / error / login-prompt states across customer screens.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool compact;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? VillageTheme.primaryGreen;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 72 : 96,
              height: compact ? 72 : 96,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 36 : 44,
                color: color.withOpacity(0.65),
              ),
            ),
            SizedBox(height: compact ? 12 : 20),
            Text(
              title,
              style: VillageTheme.headingSmall.copyWith(
                color: VillageTheme.modernDark,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: VillageTheme.bodyMedium.copyWith(
                  color: VillageTheme.modernGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: actionLabel!,
                onPressed: onAction,
                borderRadius: VillageTheme.buttonRadius,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
