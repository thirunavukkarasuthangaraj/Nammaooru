import 'package:flutter/material.dart';
import 'dart:async';
import '../models/combo_model.dart';
import '../../../core/config/env_config.dart';

class ComboBannerWidget extends StatelessWidget {
  final List<CustomerCombo> combos;
  final Function(CustomerCombo) onComboTapped;

  const ComboBannerWidget({
    super.key,
    required this.combos,
    required this.onComboTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (combos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - "SPECIAL OFFERS" with count badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'SPECIAL OFFERS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${combos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Combo Cards - Horizontal PageView
        SizedBox(
          height: 160,
          child: _ComboCarousel(
            combos: combos,
            onComboTapped: onComboTapped,
          ),
        ),
      ],
    );
  }
}

// Stateful widget for auto-sliding carousel
class _ComboCarousel extends StatefulWidget {
  final List<CustomerCombo> combos;
  final Function(CustomerCombo) onComboTapped;

  const _ComboCarousel({
    required this.combos,
    required this.onComboTapped,
  });

  @override
  State<_ComboCarousel> createState() => _ComboCarouselState();
}

class _ComboCarouselState extends State<_ComboCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_pageController.hasClients && widget.combos.length > 1) {
        final nextPage = (_currentPage + 1) % widget.combos.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: widget.combos.length,
      itemBuilder: (context, index) {
        return _ComboCard(
          combo: widget.combos[index],
          onTap: () => widget.onComboTapped(widget.combos[index]),
        );
      },
    );
  }
}

// Compact horizontal combo card with product images slideshow
class _ComboCard extends StatefulWidget {
  final CustomerCombo combo;
  final VoidCallback onTap;

  const _ComboCard({
    required this.combo,
    required this.onTap,
  });

  @override
  State<_ComboCard> createState() => _ComboCardState();
}

class _ComboCardState extends State<_ComboCard> {
  late PageController _imagePageController;
  int _currentImageIndex = 0;
  Timer? _imageSlideTimer;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _startImageAutoSlide();
  }

  @override
  void dispose() {
    _imageSlideTimer?.cancel();
    _imagePageController.dispose();
    super.dispose();
  }

  void _startImageAutoSlide() {
    final imageCount = widget.combo.items.length;
    if (imageCount > 1) {
      _imageSlideTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_imagePageController.hasClients) {
          final nextPage = (_currentImageIndex + 1) % imageCount;
          _imagePageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${EnvConfig.imageBaseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.combo;
    final hasImages = combo.items.any((item) => item.imageUrl != null && item.imageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side - Product Image with discount badge
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  // Product Image Container
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: _buildImageSection(combo, hasImages),
                    ),
                  ),
                  // Discount badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${combo.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right side - Details
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Combo name (English / Tamil)
                    Text(
                      combo.nameTamil != null && combo.nameTamil!.isNotEmpty
                          ? '${combo.name} / ${combo.nameTamil}'
                          : combo.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Items count
                    Text(
                      '${combo.itemCount} items included',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    // Price row with cart button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${combo.comboPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            Text(
                              '₹${combo.originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // View button
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(CustomerCombo combo, bool hasImages) {
    if (hasImages) {
      return PageView.builder(
        controller: _imagePageController,
        onPageChanged: (index) {
          setState(() {
            _currentImageIndex = index;
          });
        },
        itemCount: combo.items.length,
        itemBuilder: (context, index) {
          final item = combo.items[index];
          final imageUrl = _getFullImageUrl(item.imageUrl);
          return Padding(
            padding: const EdgeInsets.all(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          );
        },
      );
    } else if (combo.bannerImageUrl != null && combo.bannerImageUrl!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Image.network(
          _getFullImageUrl(combo.bannerImageUrl),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        ),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(
        Icons.card_giftcard,
        size: 40,
        color: Colors.white.withOpacity(0.5),
      ),
    );
  }
}

// Combo Detail Bottom Sheet
class ComboDetailBottomSheet extends StatelessWidget {
  final CustomerCombo combo;
  final VoidCallback onAddToCart;

  const ComboDetailBottomSheet({
    super.key,
    required this.combo,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner
                      if (combo.bannerImageUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: Image.network(
                            _getFullImageUrl(combo.bannerImageUrl!),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultBanner(),
                          ),
                        )
                      else
                        _buildDefaultBanner(),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              combo.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (combo.nameTamil != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                combo.nameTamil!,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Description
                            if (combo.description != null)
                              Text(
                                combo.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Price Box
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green[50]!,
                                    Colors.green[100]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Combo Price',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        '₹${combo.comboPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${combo.originalPrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[500],
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Save ₹${combo.savings.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Items List
                            Row(
                              children: [
                                const Icon(Icons.inventory_2, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${combo.itemCount} Items Included',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Items
                            ...combo.items.map((item) => _buildItemTile(item)),

                            const SizedBox(height: 80), // Space for button
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Add to Cart Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart),
                          const SizedBox(width: 8),
                          Text(
                            'Add Combo to Cart  •  ₹${combo.comboPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[700]!, Colors.red[600]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.card_giftcard, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(
              'Special Combo',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(CustomerComboItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl != null
                ? Image.network(
                    _getFullImageUrl(item.imageUrl!),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Icon(Icons.inventory_2),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[200],
                    child: const Icon(Icons.inventory_2),
                  ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (item.productNameTamil != null && item.productNameTamil!.isNotEmpty)
                  Text(
                    item.productNameTamil!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                if (item.unit != null)
                  Text(
                    item.unit!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),

          // Quantity & Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'x${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${item.totalPrice.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFullImageUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${EnvConfig.imageBaseUrl}$url';
  }
}
