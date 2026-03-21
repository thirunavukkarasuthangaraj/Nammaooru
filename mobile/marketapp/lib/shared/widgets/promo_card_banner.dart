import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/promo_code_service.dart';
import '../../core/utils/image_url_helper.dart';

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
  final String? imageUrl;

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
    this.imageUrl,
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
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final promo = widget.promoCode ?? _promoCode;
    // Extract just the discount value without "OFF" suffix
    String rawDiscount = widget.subtitle ?? promo.formattedDiscount;
    final discountText = rawDiscount.replaceAll(' OFF', '').replaceAll('OFF', '');
    final description = widget.description ?? promo.description ?? 'Exclusive weekend savings on your favorite groceries.';
    final shopName = promo.shopName ?? 'THIRU';
    final shopNameTamil = promo.shopNameTamil;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAF0),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left content
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop name with Tamil on next line
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.storefront,
                          size: 14,
                          color: widget.backgroundColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shopName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: widget.backgroundColor,
                                  height: 1.2,
                                ),
                              ),
                              if (shopNameTamil != null && shopNameTamil.isNotEmpty)
                                Text(
                                  shopNameTamil,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: widget.backgroundColor.withOpacity(0.8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Discount row
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: discountText,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1a1a1a),
                              height: 1,
                            ),
                          ),
                          TextSpan(
                            text: ' OFF',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: widget.backgroundColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Code button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Code: ${promo.code}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right content - Image and tag
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Tag icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.backgroundColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_offer,
                        size: 22,
                        color: widget.backgroundColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3436),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildPromoImage(promo),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoImage(PromoCode promo) {
    // Try promo image first, then shop image based on shopId
    String? imageUrl = promo.bannerUrl ?? promo.imageUrl ?? widget.imageUrl;

    // If no promo image, try to construct shop logo URL from shopId
    if ((imageUrl == null || imageUrl.isEmpty) && promo.shopId != null) {
      // Use shop logo endpoint
      imageUrl = '/api/shops/${promo.shopId}/logo';
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFF2D3436),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackImage(),
      );
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/gorceries.webp',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF2D3436),
              child: const Icon(Icons.shopping_basket, size: 40, color: Colors.white54),
            );
          },
        ),
        // Dark overlay for better visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
