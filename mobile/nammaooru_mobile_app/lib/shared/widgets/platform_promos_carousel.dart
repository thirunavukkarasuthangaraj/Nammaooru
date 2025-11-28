import 'package:flutter/material.dart';
import 'dart:async';
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
  late PageController _pageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _promosFuture = _promoService.getActivePromotions();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide(int itemCount) {
    if (itemCount <= 1) return;

    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_pageController.page ?? 0).toInt() + 1;
        _pageController.animateToPage(
          nextPage % itemCount,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
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

        // Show carousel for multiple promos with auto-slide
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoSlide(promos.length);
        });

        return SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            pageSnapping: true,
            itemCount: promos.length,
            onPageChanged: (index) {
              // Reset timer on manual swipe
              _startAutoSlide(promos.length);
            },
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
