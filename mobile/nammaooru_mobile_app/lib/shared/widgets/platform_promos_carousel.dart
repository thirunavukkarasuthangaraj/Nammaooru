import 'package:flutter/material.dart';
import '../../core/services/promo_code_service.dart';
import 'promo_card_banner.dart';

class PlatformPromosCarousel extends StatefulWidget {
  final Color? primaryColor;
  final VoidCallback? onPromoTap;

  const PlatformPromosCarousel({
    super.key,
    this.primaryColor,
    this.onPromoTap,
  });

  @override
  State<PlatformPromosCarousel> createState() => _PlatformPromosCarouselState();
}

class _PlatformPromosCarouselState extends State<PlatformPromosCarousel> {
  late Future<List<PromoCode>> _promosFuture;
  final PromoCodeService _promoService = PromoCodeService();

  @override
  void initState() {
    super.initState();
    _promosFuture = _promoService.getActivePromotions();
  }

  Color _getColorForPromo(int index) {
    const colors = [
      Color(0xFF4CAF50), // Green
      Color(0xFFFF9800), // Orange
      Color(0xFF2196F3), // Blue
      Color(0xFFE53935), // Red
      Color(0xFF9C27B0), // Purple
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PromoCode>>(
      future: _promosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            height: 140,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final promos = snapshot.data!;

        if (promos.length == 1) {
          return PromoCardBanner(
            promoCode: promos[0],
            backgroundColor: _getColorForPromo(0),
            icon: Icons.local_offer,
            onTap: widget.onPromoTap,
          );
        }

        // Show carousel for multiple promos
        return SizedBox(
          height: 160,
          child: PageView.builder(
            padEnds: false,
            pageSnapping: true,
            itemCount: promos.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: PromoCardBanner(
                  promoCode: promos[index],
                  backgroundColor: _getColorForPromo(index),
                  icon: Icons.local_offer,
                  onTap: widget.onPromoTap,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
