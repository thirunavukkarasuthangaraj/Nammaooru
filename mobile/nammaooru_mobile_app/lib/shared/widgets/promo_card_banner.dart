import 'package:flutter/material.dart';
import '../../core/services/promo_code_service.dart';

class PromoCardBanner extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? badgeText;
  final Color? badgeColor;
  final PromoCode? promoCode;

  const PromoCardBanner({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.backgroundColor = const Color(0xFF4CAF50),
    this.textColor = Colors.white,
    this.icon,
    this.onTap,
    this.badgeText,
    this.badgeColor,
    this.promoCode,
  });

  @override
  State<PromoCardBanner> createState() => _PromoCardBannerState();
}

class _PromoCardBannerState extends State<PromoCardBanner> {
  late PromoCode _promoCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.promoCode != null) {
      _promoCode = widget.promoCode!;
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && widget.promoCode == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            height: 30,
            width: 30,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final promo = widget.promoCode ?? _promoCode;
    final displayTitle = widget.title ?? promo?.title ?? 'Special Offer';
    final displaySubtitle = widget.subtitle ?? promo?.formattedDiscount ?? 'Limited Time';
    final displayDescription = widget.description ?? promo?.description ?? promo?.formattedMinOrder ?? '';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.backgroundColor,
              widget.backgroundColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.backgroundColor.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: widget.backgroundColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background element
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Icon (optional)
                  if (widget.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Icon(
                        widget.icon,
                        size: 48,
                        color: widget.textColor,
                      ),
                    ),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.textColor.withOpacity(0.95),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displaySubtitle,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: widget.textColor,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (displayDescription.isNotEmpty)
                          Text(
                            displayDescription,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: widget.textColor.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // Show promo code if available
                        if (promo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              'Code: ${promo.code}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: widget.textColor,
                                decoration: TextDecoration.underline,
                                decorationThickness: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Badge (optional)
                  if (widget.badgeText != null || promo?.isFirstTimeOnly == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.badgeColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.badgeText ?? 'FIRST TIME',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.backgroundColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
