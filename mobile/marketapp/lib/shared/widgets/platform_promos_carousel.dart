import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/promo_code_service.dart';
import '../../features/customer/screens/shop_details_screen.dart';
import 'promo_card_banner.dart';

class PlatformPromosCarousel extends StatefulWidget {
  final Color? primaryColor;
  final VoidCallback? onPromoTap;
  final String? customerId;
  final String? phone;

  const PlatformPromosCarousel({
    super.key,
    this.primaryColor,
    this.onPromoTap,
    this.customerId,
    this.phone,
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
    _promosFuture = _promoService.getActivePromotions(
      customerId: widget.customerId,
      phone: widget.phone,
    );
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

  void _navigateToShop(PromoCode promo) {
    // If promo has shopId, navigate to that shop
    if (promo.shopId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShopDetailsScreen(
            shopId: promo.shopId!,
            shop: null, // Will load shop details from API
          ),
        ),
      );
    } else {
      // Platform offer - show a snackbar message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is a platform-wide offer. Use code "${promo.code}" at any shop!',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
            onTap: () => _navigateToShop(promos[0]),
          );
        }

        // Show carousel for multiple promos with auto-slide
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoSlide(promos.length);
        });

        return SizedBox(
          height: 220,
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
                  onTap: () => _navigateToShop(promos[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
