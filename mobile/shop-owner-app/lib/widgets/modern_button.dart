import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Modern Button Widget with Multiple Variants
///
/// Supports:
/// - Primary, Secondary, Accent, Outline, Text variants
/// - Small, Medium, Large sizes
/// - Loading state
/// - Icon support
/// - Gradient backgrounds
/// - Fully responsive

enum ButtonVariant {
  primary,
  secondary,
  accent,
  outline,
  text,
  success,
  warning,
  error,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final bool useGradient;

  const ModernButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.useGradient = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Size configurations
    double fontSize;
    double horizontalPadding;
    double verticalPadding;
    double iconSize;

    switch (size) {
      case ButtonSize.small:
        fontSize = 12;
        horizontalPadding = 16;
        verticalPadding = 8;
        iconSize = 16;
        break;
      case ButtonSize.medium:
        fontSize = 14;
        horizontalPadding = 24;
        verticalPadding = 12;
        iconSize = 20;
        break;
      case ButtonSize.large:
        fontSize = 16;
        horizontalPadding = 32;
        verticalPadding = 16;
        iconSize = 24;
        break;
    }

    Widget buttonChild = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(),
              ),
            ),
          )
        else if (icon != null)
          Icon(icon, size: iconSize, color: _getTextColor()),
        if ((isLoading || icon != null) && text.isNotEmpty)
          SizedBox(width: AppTheme.space8),
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: _getTextColor(),
            ),
          ),
      ],
    );

    Widget button;

    switch (variant) {
      case ButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            side: BorderSide(
              color: _getButtonColor(),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.roundedMedium,
            ),
          ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.roundedMedium,
            ),
          ),
          child: buttonChild,
        );
        break;

      default:
        // Filled buttons (primary, secondary, accent, success, warning, error)
        if (useGradient && variant == ButtonVariant.primary) {
          button = Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: AppTheme.roundedMedium,
              boxShadow: AppTheme.shadowMedium,
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.roundedMedium,
                ),
              ),
              child: buttonChild,
            ),
          );
        } else {
          button = ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(),
              foregroundColor: _getTextColor(),
              elevation: 2,
              shadowColor: _getButtonColor().withOpacity(0.4),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.roundedMedium,
              ),
            ),
            child: buttonChild,
          );
        }
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: button,
    );
  }

  Color _getButtonColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return AppTheme.primary;
      case ButtonVariant.secondary:
        return AppTheme.secondary;
      case ButtonVariant.accent:
        return AppTheme.accent;
      case ButtonVariant.success:
        return AppTheme.success;
      case ButtonVariant.warning:
        return AppTheme.warning;
      case ButtonVariant.error:
        return AppTheme.error;
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return AppTheme.primary;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return _getButtonColor();
      default:
        return AppTheme.textWhite;
    }
  }
}

/// Icon Button with Badge Support
class ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final String? badge;

  const ModernIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size = 48,
    this.badge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget iconButton = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: iconColor ?? AppTheme.primary,
        iconSize: size * 0.5,
        padding: EdgeInsets.zero,
      ),
    );

    if (badge != null && badge!.isNotEmpty) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconButton,
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: AppTheme.roundedRound,
                border: Border.all(color: AppTheme.surface, width: 2),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return iconButton;
  }
}

/// Floating Action Button with Modern Design
class ModernFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final bool useGradient;

  const ModernFAB({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.useGradient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nice green gradient for FAB
    final greenGradient = LinearGradient(
      colors: [Colors.green.shade600, Colors.green.shade800],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    if (label != null) {
      // Extended FAB with green gradient
      return Container(
        decoration: BoxDecoration(
          gradient: useGradient ? greenGradient : null,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: useGradient ? Colors.transparent : Colors.green.shade700,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Regular FAB with green gradient
      return Container(
        decoration: BoxDecoration(
          gradient: useGradient ? greenGradient : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: useGradient ? Colors.transparent : Colors.green.shade700,
          elevation: 0,
          child: Icon(icon, color: Colors.white),
        ),
      );
    }
  }
}

/// Chip Button for Tags/Filters
class ModernChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;

  const ModernChip({
    Key? key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppTheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.roundedRound,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: AppTheme.roundedRound,
          border: Border.all(
            color: selected ? color : color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? AppTheme.textWhite : color,
              ),
              const SizedBox(width: AppTheme.space8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.textWhite : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
