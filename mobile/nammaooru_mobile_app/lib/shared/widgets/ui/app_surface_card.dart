import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';

/// White surface card with consistent radius, border, and shadow.
class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.radius = VillageTheme.cardRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(VillageTheme.spacingM),
      decoration: BoxDecoration(
        color: color ?? VillageTheme.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: VillageTheme.borderLight),
        boxShadow: VillageTheme.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}
