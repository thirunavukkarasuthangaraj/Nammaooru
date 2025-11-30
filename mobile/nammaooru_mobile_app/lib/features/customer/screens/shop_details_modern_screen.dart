import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/voice_search_service.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/services/promo_code_service.dart';
import 'cart_screen.dart';

class ShopDetailsModernScreen extends StatefulWidget {
  final int shopId;
  final Map<String, dynamic>? shop;

  const ShopDetailsModernScreen({
    super.key,
    required this.shopId,
    this.shop,
  });

  @override
  State<ShopDetailsModernScreen> createState() => _ShopDetailsModernScreenState();
}

class _ShopDetailsModernScreenState extends State<ShopDetailsModernScreen> {
  final ShopApiService _shopApi = ShopApiService();
  final VoiceSearchService _voiceSearch = VoiceSearchService();
  final PromoCodeService _promoService = PromoCodeService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController();

  Map<String, dynamic>? _shop;
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  List<dynamic> _categories = [];
  List<PromoCode> _promotions = [];
  int _currentBannerIndex = 0;
  String? _selectedCategory;
  bool _isLoadingShop = false;
  bool _isLoadingProducts = false;
  bool _isLoadingCategories = false;
  bool _isLoadingPromotions = false;
  bool _isVoiceSearching = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
    _loadShopDetails();
    _loadCategories();
    _loadProducts();
    _loadPromotions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoadingPromotions = true;
    });

    try {
      final promotions = await _promoService.getActivePromotions(
        shopId: widget.shopId.toString(),
      );
      if (mounted) {
        setState(() {
          _promotions = promotions;
          _isLoadingPromotions = false;
        });
      }
    } catch (e) {
      print('Error loading promotions: $e');
      if (mounted) {
        setState(() {
          _isLoadingPromotions = false;
        });
      }
    }
  }

  Future<void> _loadShopDetails() async {
    if (_shop != null) return;
    setState(() {
      _isLoadingShop = true;
      _hasError = false;
    });

    try {
      final response = await _shopApi.getShopById(widget.shopId);
      if (mounted && response['statusCode'] == '0000' && response['data'] != null) {
        setState(() {
          _shop = response['data'];
          _isLoadingShop = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoadingShop = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final response = await _shopApi.getShopCategories(widget.shopId);
      if (mounted && response['statusCode'] == '0000' && response['data'] != null) {
        final categoryList = response['data'] as List;
        setState(() {
          _categories = [
            {
              'id': null,
              'name': 'All',
              'displayName': 'All',
              'icon': '🏪',
            },
            ...categoryList.map((cat) => {
              ...cat,
              'icon': _getCategoryIcon(cat['name']?.toString() ?? ''),
            }),
          ];
          _selectedCategory = null;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  String _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('fruit') || name.contains('vegetable')) return '🥬';
    if (name.contains('dairy') || name.contains('milk')) return '🥛';
    if (name.contains('meat') || name.contains('chicken')) return '🍖';
    if (name.contains('bread') || name.contains('bakery')) return '🍞';
    if (name.contains('snack')) return '🍿';
    if (name.contains('beverage') || name.contains('drink')) return '🥤';
    if (name.contains('grocery')) return '🛒';
    if (name.contains('medical') || name.contains('pharmacy')) return '💊';
    return '📦';
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _hasError = false;
    });

    try {
      final response = await _shopApi.getShopProducts(shopId: widget.shopId.toString());
      if (mounted && response['statusCode'] == '0000' && response['data'] != null) {
        final responseData = response['data'];
        final productsList = responseData is Map && responseData.containsKey('content')
            ? responseData['content'] as List
            : responseData as List;
        setState(() {
          _products = productsList;
          _filteredProducts = _products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    _filterProducts();
  }

  void _filterProducts() {
    setState(() {
      String searchTerm = _searchController.text.toLowerCase();
      _filteredProducts = _products.where((product) {
        // Search in both English and Tamil names for better UX
        final englishName = product['customName']?.toString().toLowerCase() ??
                           product['displayName']?.toString().toLowerCase() ??
                           product['masterProduct']?['name']?.toString().toLowerCase() ?? '';
        final tamilName = product['masterProduct']?['nameTamil']?.toString().toLowerCase() ?? '';

        final matchesSearch = searchTerm.isEmpty ||
                             englishName.contains(searchTerm) ||
                             tamilName.contains(searchTerm);

        final categoryMatch = _selectedCategory == null ||
                             product['masterProduct']?['category']?['id'] == _selectedCategory;

        return matchesSearch && categoryMatch;
      }).toList();
    });
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      _filterProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.itemCount;
    final cartTotal = cartProvider.total;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _hasError
          ? _buildErrorState()
          : Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      pinned: true,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: Text(
                        _shop?['name'] ?? 'Shop',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      actions: [
                        // Language Toggle Button
                        Consumer<LanguageProvider>(
                          builder: (context, languageProvider, child) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () async {
                                  await languageProvider.toggleLanguage();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        languageProvider.showTamil ? 'த' : 'EN',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.language,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.black87, size: 28),
                          onPressed: () {
                            // Show search dialog for text search
                            _showSearchDialog();
                          },
                          tooltip: 'Text Search',
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic, color: Colors.red, size: 28),
                          onPressed: () {
                            // Show voice search dialog
                            _showVoiceSearchDialog();
                          },
                          tooltip: 'Voice Search (Tamil/English)',
                        ),
                      ],
                    ),

                    // Promotional Banner - Dynamic from Database
                    if (_promotions.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          height: 110,
                          child: Column(
                            children: [
                              Expanded(
                                child: PageView.builder(
                                  controller: _bannerController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentBannerIndex = index;
                                    });
                                  },
                                  itemCount: _promotions.length,
                                  itemBuilder: (context, index) {
                                    final promo = _promotions[index];
                                    return _buildPromoBanner(promo);
                                  },
                                ),
                              ),
                              if (_promotions.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _promotions.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: _currentBannerIndex == index ? 10 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: _currentBannerIndex == index
                                              ? const Color(0xFF2E7D32)
                                              : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    else if (_isLoadingPromotions)
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 8),
                      ),

                    // Categories Section
                    if (_categories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Shop by Category',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (_selectedCategory != null)
                                      InkWell(
                                        onTap: () {
                                          _selectCategory(null);
                                        },
                                        child: const Text(
                                          'Clear',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4CAF50),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 110,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final category = _categories[index] as Map<String, dynamic>;
                                    final isSelected = _selectedCategory == category['id'];
                                    return _buildCategoryItem(category, isSelected);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Products Grid
                    if (_isLoadingProducts)
                      const SliverFillRemaining(
                        child: Center(child: LoadingWidget()),
                      )
                    else if (_filteredProducts.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No products available',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(12),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.65,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildModernProductCard(_filteredProducts[index]),
                            childCount: _filteredProducts.length,
                          ),
                        ),
                      ),

                    // Bottom padding for cart bar
                    const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                  ],
                ),

                // Cart Bottom Bar
                if (cartItemCount > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildCartBottomBar(cartItemCount, cartTotal),
                  ),
              ],
            ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectCategory(category['id']?.toString()),
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey[50]!, Colors.grey[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
                  width: isSelected ? 3 : 1.5,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  category['icon'] ?? '📦',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              height: 1.3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(PromoCode promo) {
    final isPercentage = promo.type == 'PERCENTAGE';
    final isFreeShipping = promo.type == 'FREE_SHIPPING';
    final isFixedAmount = promo.type == 'FIXED_AMOUNT';

    late Color accentColor;
    late Color lightColor;
    late Color darkColor;
    late IconData bannerIcon;

    if (isPercentage) {
      accentColor = const Color(0xFF2E7D32);
      lightColor = const Color(0xFF81C784);
      darkColor = const Color(0xFF1B5E20);
      bannerIcon = Icons.local_offer_rounded;
    } else if (isFreeShipping) {
      accentColor = const Color(0xFF1976D2);
      lightColor = const Color(0xFF64B5F6);
      darkColor = const Color(0xFF0D47A1);
      bannerIcon = Icons.local_shipping_rounded;
    } else {
      accentColor = const Color(0xFFE65100);
      lightColor = const Color(0xFFFFB74D);
      darkColor = const Color(0xFFBF360C);
      bannerIcon = Icons.local_atm_rounded;
    }

    return GestureDetector(
      onTap: () {
        _showPromoDetails(promo);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accentColor.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [darkColor, accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Premium background pattern - Curved design elements
              Positioned(
                right: -40,
                top: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.01),
                      ],
                    ),
                  ),
                ),
              ),
              // Diagonal stripe pattern overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: DiagonalStripePainter(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Banner image if available
              if (promo.bannerUrl != null && promo.bannerUrl!.isNotEmpty)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      ImageUrlHelper.getFullImageUrl(promo.bannerUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),
                ),
              // Premium overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.25),
                            darkColor.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: [
                    // Discount badge - Elite style
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            bannerIcon,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            promo.formattedDiscount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title and details - Flex
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          if (promo.minimumOrderAmount != null && promo.minimumOrderAmount! > 0)
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_cart_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  promo.formattedMinOrder,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Premium promo code badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFFFFD600), const Color(0xFFFFC400)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD600).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            promo.code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.black.withOpacity(0.6),
                            size: 13,
                          ),
                        ],
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

  void _showPromoDetails(PromoCode promo) {
    // Copy promo code to clipboard
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  promo.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    promo.formattedDiscount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (promo.description != null)
              Text(
                promo.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    promo.code,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Copy to clipboard
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Promo code "${promo.code}" copied!'),
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (promo.minimumOrderAmount != null && promo.minimumOrderAmount! > 0)
              _buildPromoInfoRow(
                Icons.shopping_cart_outlined,
                promo.formattedMinOrder,
              ),
            if (promo.isFirstTimeOnly == true)
              _buildPromoInfoRow(
                Icons.star_outline,
                'First order only',
              ),
            _buildPromoInfoRow(
              Icons.access_time,
              'Valid till ${_formatDate(promo.endDate)}',
            ),
            if (promo.termsAndConditions != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  promo.termsAndConditions!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildModernProductCard(Map<String, dynamic> product) {
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final originalPrice = double.tryParse(product['originalPrice']?.toString() ?? '0') ?? 0.0;
    final stockQuantity = int.tryParse(product['stockQuantity']?.toString() ?? '0') ?? 0;
    // isInStock should be based on actual stock quantity, not just the inStock flag
    final isInStock = stockQuantity > 0;

    final imageUrl = product['primaryImageUrl']?.toString() ??
                    product['masterProduct']?['primaryImageUrl']?.toString() ?? '';

    final hasDiscount = originalPrice > price && originalPrice > 0;
    final discountPercentage = hasDiscount ? ((originalPrice - price) / originalPrice * 100).round() : 0;

    // Get weight and unit
    final weight = product['masterProduct']?['baseWeight'];
    final unit = product['masterProduct']?['baseUnit'] ?? '';
    final displayUnit = weight != null ? '$weight $unit' : unit.toString();

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Use language provider to get the correct name based on selected language
        final productName = languageProvider.getDisplayName(product);

        return Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            final productModel = ProductModel(
              id: product['id'].toString(),
              name: productName,
              description: product['customDescription']?.toString() ?? '',
              price: price,
              category: product['masterProduct']?['category']?.toString() ?? '',
              shopId: _shop?['shopId']?.toString() ?? widget.shopId.toString(),
              shopName: _shop?['name']?.toString() ?? 'Shop',
              images: imageUrl.isNotEmpty ? [imageUrl] : [],
              stockQuantity: stockQuantity,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            final cartQuantity = cartProvider.getQuantity(productModel.id);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Container
                  Expanded(
                    flex: 5,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              ImageUrlHelper.getFullImageUrl(imageUrl),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported,
                                             size: 50,
                                             color: Colors.grey);
                              },
                            )
                          : const Icon(Icons.inventory_2,
                                   size: 50,
                                   color: Colors.grey),
                    ),
                  ),

                  // Product Details
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name - Reactive to language changes
                          Consumer<LanguageProvider>(
                            builder: (context, langProvider, child) {
                              final displayName = langProvider.getDisplayName(product);
                              print('🔍 PRODUCT DISPLAY: showTamil=${langProvider.showTamil}, name=$displayName');
                              print('🔍 PRODUCT DATA: ${product['displayName']}, masterProduct.nameTamil=${product['masterProduct']?['nameTamil']}');
                              return Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                          const SizedBox(height: 2),

                          // Weight/Unit
                          if (displayUnit.isNotEmpty && displayUnit != 'null')
                            Text(
                              displayUnit,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                height: 1.2,
                              ),
                            ),

                          const Spacer(),

                          // Price Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '₹${originalPrice.toStringAsFixed(originalPrice == originalPrice.roundToDouble() ? 0 : 2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                      // Add/Remove Button - Blinkit Style
                      if (!isInStock)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Out of Stock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else if (cartQuantity == 0)
                        InkWell(
                          onTap: () => _handleAddToCart(context, cartProvider, productModel),
                          child: Container(
                            width: double.infinity,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD600),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFD600)),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                size: 20,
                                color: Colors.black87,
                                weight: 700,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD600),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => cartProvider.removeFromCart(productModel.id),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      bottomLeft: Radius.circular(6),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.remove,
                                      size: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '$cartQuantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (cartQuantity < stockQuantity) {
                                    cartProvider.addToCart(productModel);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Only $stockQuantity items available'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(6),
                                      bottomRight: Radius.circular(6),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      size: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildCartBottomBar(int itemCount, double total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Free delivery indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Free delivery unlocked',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4CAF50),
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$itemCount items',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // Use GoRouter to navigate to cart (already in routes)
              context.go('/customer/cart');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD600),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Proceed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      barrierLabel: 'Dialog',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation1, animation2) {
        return StatefulBuilder(
          builder: (context, setState) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isVoiceSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.mic, color: Color(0xFF2E7D32)),
                            onPressed: () async {
                              setState(() {
                                _isVoiceSearching = true;
                              });
                              this.setState(() {
                                _isVoiceSearching = true;
                              });

                              final results = await _voiceSearch.voiceSearch(widget.shopId);

                              if (mounted) {
                                setState(() {
                                  _isVoiceSearching = false;
                                });
                                this.setState(() {
                                  _isVoiceSearching = false;
                                  if (results.isNotEmpty) {
                                    _filteredProducts = results;
                                  }
                                });

                                if (results.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No products found for your voice query'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                } else {
                                  Navigator.pop(context);
                                }
                              }
                            },
                            tooltip: 'Voice Search (Tamil/English)',
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    _onSearchChanged();
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  '🎤 Tap mic for AI voice search in Tamil or English',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // Large Voice Search Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isVoiceSearching ? null : () async {
                      setState(() {
                        _isVoiceSearching = true;
                      });
                      this.setState(() {
                        _isVoiceSearching = true;
                      });

                      final results = await _voiceSearch.voiceSearch(widget.shopId);

                      if (mounted) {
                        setState(() {
                          _isVoiceSearching = false;
                        });
                        this.setState(() {
                          _isVoiceSearching = false;
                          if (results.isNotEmpty) {
                            _filteredProducts = results;
                          }
                        });

                        if (results.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No products found for your voice query'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    },
                    icon: _isVoiceSearching
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.mic, size: 28),
                    label: Text(
                      _isVoiceSearching ? 'Listening...' : 'Start Voice Search',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
            ),
          );
          },
        );
      },
    );
  }

  Future<void> _handleAddToCart(BuildContext context, CartProvider cartProvider, ProductModel product) async {
    cartProvider.addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Failed to load shop details',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _loadShopDetails();
                _loadProducts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceSearchDialog() {
    List<dynamic> voiceResults = [];
    bool isSearching = false;
    String? searchQuery;
    final TextEditingController searchController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      barrierLabel: 'Dialog',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation1, animation2) {
        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.mic, color: Color(0xFF2E7D32), size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Voice Search',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.dispose();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Text input - Always visible
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Type product names (e.g., Sugar, Rice, Milk)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onSubmitted: (query) async {
                        if (query.trim().isEmpty) return;

                        setState(() {
                          isSearching = true;
                        });

                        final results = await _voiceSearch.searchProducts(
                            widget.shopId, query);

                        setState(() {
                          isSearching = false;
                          voiceResults = results;
                          searchQuery = query;
                        });
                      },
                    ),
                  ),

                  // Voice search button
                  if (!isSearching && voiceResults.isEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                          ),
                          padding: const EdgeInsets.all(32),
                          child: const Icon(
                            Icons.mic,
                            size: 80,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Tap to speak',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            setState(() {
                              isSearching = true;
                            });

                            final results = await _voiceSearch.voiceSearch(widget.shopId);
                            final query = _voiceSearch.lastWords;

                            setState(() {
                              isSearching = false;
                              voiceResults = results;
                              searchQuery = query;
                              // Update the text field with voice search query
                              if (query != null && query.isNotEmpty) {
                                searchController.text = query;
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.mic, color: Colors.white),
                          label: const Text(
                            'Start Voice Search',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),

                  // Loading indicator
                  if (isSearching)
                    Column(
                      children: [
                        const SizedBox(height: 32),
                        const CircularProgressIndicator(
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Listening...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),

                  // Search results
                  if (!isSearching && voiceResults.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (searchQuery != null && searchQuery!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.mic, color: Color(0xFF2E7D32), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You said: "$searchQuery"',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            '${voiceResults.length} products found',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: voiceResults.length,
                              itemBuilder: (context, index) {
                                final product = voiceResults[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(
                                      product['displayName'] ?? product['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '₹${product['price']}',
                                      style: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: product['inStock'] == true
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : const Icon(Icons.cancel, color: Colors.red),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  // No results message
                  if (!isSearching && voiceResults.isEmpty && searchQuery != null)
                    Column(
                      children: [
                        const SizedBox(height: 32),
                        const Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try saying the product name again',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            setState(() {
                              isSearching = true;
                              voiceResults = [];
                              searchQuery = null;
                            });

                            final results = await _voiceSearch.voiceSearch(widget.shopId);
                            final query = _voiceSearch.lastWords;

                            setState(() {
                              isSearching = false;
                              voiceResults = results;
                              searchQuery = query;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.mic, color: Colors.white),
                          label: const Text(
                            'Try Again',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                ],
              ),
            ),
            ),
          );
          },
        );
      },
    );
  }
}

// Custom painter for diagonal stripe pattern
class DiagonalStripePainter extends CustomPainter {
  final Color color;

  DiagonalStripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 20.0;

    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DiagonalStripePainter oldDelegate) => false;
}