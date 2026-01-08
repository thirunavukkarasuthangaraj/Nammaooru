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
    final displayDescription = widget.description ?? promo?.description ?? '';
    final shopName = promo?.shopName ?? 'Platform Offer';

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
          boxShadow: [],
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon (optional)
                  if (widget.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(
                        widget.icon,
                        size: 40,
                        color: widget.textColor,
                      ),
                    ),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Shop Name with store icon
                        Row(
                          children: [
                            Icon(
                              Icons.store,
                              size: 14,
                              color: widget.textColor.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shopName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: widget.textColor.withOpacity(0.95),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Title
                        Text(
                          displayTitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: widget.textColor.withOpacity(0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Discount amount - prominent
                        Text(
                          displaySubtitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: widget.textColor,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Description/Min order
                        if (displayDescription.isNotEmpty)
                          Text(
                            displayDescription,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.textColor.withOpacity(0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // Min order if description is empty
                        if (displayDescription.isEmpty && promo?.formattedMinOrder != null)
                          Text(
                            promo!.formattedMinOrder,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.textColor.withOpacity(0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // Show promo code with copy hint
                        if (promo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Code: ${promo.code}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: widget.textColor,
                                ),
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
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.badgeColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.badgeText ?? 'NEW USER',
                        style: TextStyle(
                          fontSize: 10,
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
