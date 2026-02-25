import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
import '../../../core/config/api_config.dart';
import '../../../core/services/promo_code_service.dart';
import '../models/combo_model.dart';
import '../services/combo_service.dart';
import '../widgets/combo_banner_widget.dart';
import 'cart_screen.dart';
import 'shop_products_screen.dart';

class ShopDetailsScreen extends StatefulWidget {
  final int shopId;
  final Map<String, dynamic>? shop;

  const ShopDetailsScreen({
    super.key,
    required this.shopId,
    this.shop,
  });

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final ShopApiService _shopApi = ShopApiService();
  final VoiceSearchService _voiceSearch = VoiceSearchService();
  final PromoCodeService _promoService = PromoCodeService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _couponPageController = PageController();

  Timer? _couponAutoSlideTimer;
  int _currentCouponPage = 0;

  Map<String, dynamic>? _shop;
  List<dynamic> _products = [];
  List<dynamic> _allProducts =
      []; // Store all products for client-side filtering
  List<dynamic> _categories = [];
  List<PromoCode> _promotions = []; // Store promotions from API
  List<CustomerCombo> _combos = []; // Store combos from API
  String? _selectedCategory;
  String? _selectedCategoryName; // Store category name for filtering
  bool _isLoadingShop = false;
  bool _isLoadingProducts = false;
  bool _isLoadingCategories = false;
  bool _isLoadingPromotions = false;
  bool _isVoiceSearching = false;
  bool _hasError = false;
  String? _errorMessage;

  // Check if shop is currently open
  bool get _isShopOpen {
    if (_shop == null) return true; // Default to open if no data
    return _shop!['isOpenNow'] ?? _shop!['isActive'] ?? true;
  }

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
    _loadShopDetails();
    _loadCategories();
    _loadProducts();
    _loadPromotions();
    _loadCombos();
    _searchController.addListener(_onSearchChanged);
    _startCouponAutoSlide();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _couponPageController.dispose();
    _couponAutoSlideTimer?.cancel();
    super.dispose();
  }

  void _startCouponAutoSlide() {
    _scheduleNextSlide();
  }

  void _scheduleNextSlide() {
    _couponAutoSlideTimer?.cancel();
    final totalItems = _combos.length + _promotions.length;
    if (totalItems == 0) return;

    // Determine duration: combos (30 sec) vs promos (10 sec)
    final isCombo = _currentCouponPage < _combos.length;
    final duration = isCombo ? const Duration(seconds: 30) : const Duration(seconds: 10);

    _couponAutoSlideTimer = Timer(duration, () {
      if (_couponPageController.hasClients && totalItems > 0) {
        final nextPage = (_currentCouponPage + 1) % totalItems;
        _couponPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoadingPromotions = true;
    });

    try {
      final promos = await _promoService.getActivePromotions(
        shopId: widget.shopId.toString(),
      );

      if (mounted) {
        setState(() {
          _promotions = promos;
          _isLoadingPromotions = false;
        });
      }
    } catch (e) {
      print('Error loading promotions: $e');
      if (mounted) {
        setState(() {
          _promotions = [];
          _isLoadingPromotions = false;
        });
      }
    }
  }

  Future<void> _loadCombos() async {
    try {
      final combos = await CustomerComboService.getActiveCombos(widget.shopId);
      if (mounted) {
        setState(() {
          _combos = combos;
        });
      }
    } catch (e) {
      print('Error loading combos: $e');
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final response = await _shopApi.getShopCategories(widget.shopId);

      if (mounted &&
          response['statusCode'] == '0000' &&
          response['data'] != null) {
        final categoryList = response['data'] as List;

        setState(() {
          // Add "All Items" as first category
          _categories = [
            {
              'id': null,
              'name': 'All Items',
              'displayName': 'All Items',
              'icon': 'shopping_cart',
              'imageUrl': null,
              'color': '#4CAF50',
            },
            ...categoryList,
          ];
          _selectedCategory = null; // null means "All Items"
          _selectedCategoryName = null;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        // Continue with empty categories - not critical
      }
    }
  }

  Future<void> _loadShopDetails() async {
    if (_shop != null) {
      // Update cart provider with shop's free delivery threshold
      _updateCartFreeDelivery(_shop);
      return;
    }

    setState(() {
      _isLoadingShop = true;
      _hasError = false;
    });

    try {
      final response = await _shopApi.getShopById(widget.shopId);

      if (mounted &&
          response['statusCode'] == '0000' &&
          response['data'] != null) {
        setState(() {
          _shop = response['data'];
          _isLoadingShop = false;
        });
        // Update cart provider with shop's free delivery threshold
        _updateCartFreeDelivery(_shop);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoadingShop = false;
        });
        Helpers.showSnackBar(context, 'Failed to load shop details',
            isError: true);
      }
    }
  }

  void _updateCartFreeDelivery(Map<String, dynamic>? shop) {
    if (shop == null) return;
    final freeDeliveryAbove = (shop['freeDeliveryAbove'] ?? 0).toDouble();
    print('🏪 Shop freeDeliveryAbove: $freeDeliveryAbove');
    print('🏪 Shop images: ${shop['images']}');
    if (freeDeliveryAbove > 0) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.setFreeDeliveryAbove(freeDeliveryAbove);
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _hasError = false;
    });

    try {
      final searchQuery = _searchController.text.trim();

      // Always load ALL products without any filters for client-side filtering
      // Don't pass category ID since backend category IDs don't match product category IDs
      final response = await _shopApi.getShopProducts(
        shopId: widget.shopId.toString(),
        page: 0,
        size: 2000, // Load all products at once
        // Don't pass any filters - we'll filter client-side
      );

      if (mounted &&
          response['statusCode'] == '0000' &&
          response['data'] != null) {
        final allProducts = response['data']['content'] ?? [];

        setState(() {
          _allProducts = allProducts;
          // Apply client-side filtering for both search and category
          _filterProducts();
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
        Helpers.showSnackBar(context, 'Failed to load products', isError: true);
      }
    }
  }

  void _filterProducts() {
    final searchQuery = _searchController.text.trim().toLowerCase();

    // Start with all products
    List<dynamic> filteredProducts = _allProducts;

    // Apply search filter if search query exists
    if (searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        final productName =
            (product['displayName'] ?? product['customName'] ?? '')
                .toString()
                .toLowerCase();
        final productDescription =
            (product['displayDescription'] ?? '').toString().toLowerCase();
        return productName.contains(searchQuery) ||
            productDescription.contains(searchQuery);
      }).toList();
    }

    // Apply category filter if category is selected (and no search query)
    else if (_selectedCategoryName != null &&
        _selectedCategoryName!.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        final productCategoryName = product['masterProduct']?['category']
                ?['name']
            ?.toString()
            .toLowerCase();
        return productCategoryName == _selectedCategoryName!.toLowerCase();
      }).toList();
    }

    setState(() {
      _products = filteredProducts;
    });
  }

  void _onSearchChanged() {
    // Just filter the already loaded products
    _filterProducts();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
      body: _isLoadingShop
          ? const Center(child: LoadingWidget())
          : _hasError
              ? _buildErrorState()
              : Column(
                  children: [
                    // Toolbar/AppBar area
                    Container(
                      height: kToolbarHeight,
                      color: VillageTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 24),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            tooltip: 'Back',
                          ),
                          Expanded(
                            child: Text(
                              _shop?['name']?.toString() ?? 'Shop',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content area below toolbar
                    Expanded(
                      child: _buildShopDetailsContent(),
                    ),
                  ],
                ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                onTap: () {
                  context.push('/customer/cart');
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        VillageTheme.primaryGreen,
                        VillageTheme.primaryGreen.withBlue(150),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 24,
                          ),
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '${cartProvider.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'View Cart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${cartProvider.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: const _RightFloatingButtonLocation(),
    );
  }

  Widget _buildHorizontalCategories() {
    if (_isLoadingCategories) {
      return Container(
        height: 100,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final categoryId = category['id']?.toString();
          final categoryName = category['name']?.toString();
          final isSelected = _selectedCategory == categoryId;
          final displayName =
              category['displayName']?.toString() ?? categoryName ?? 'Category';
          final imageUrl = category['imageUrl']?.toString();
          final colorHex = category['color']?.toString() ?? '#4CAF50';

          // Check if imageUrl is an actual image path
          final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

          // Parse color from hex
          Color categoryColor = VillageTheme.primaryGreen;
          try {
            categoryColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
          } catch (e) {
            categoryColor = VillageTheme.primaryGreen;
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = categoryId;
                // If "All Items" is selected (categoryId is null), set categoryName to null to show all products
                _selectedCategoryName = categoryId == null ? null : categoryName;
                _filterProducts(); // Apply filter immediately without API call
              });
            },
            child: Container(
              width: 85,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected
                    ? VillageTheme.primaryGreen.withOpacity(0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: VillageTheme.primaryGreen,
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Category Image
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: hasImage
                          ? Image.network(
                              ImageUrlHelper.getFullImageUrl(imageUrl!),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildCategoryPlaceholder(
                                    categoryName ?? 'Category',
                                    categoryColor,
                                    isSelected);
                              },
                            )
                          : _buildCategoryPlaceholder(categoryName ?? 'Category',
                              categoryColor, isSelected),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Category Name
                  Flexible(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        color: isSelected
                            ? VillageTheme.primaryGreen
                            : Colors.grey[800],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 9,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySidebar() {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return const Center(
          child: Text('No categories', style: TextStyle(fontSize: 10)));
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final categoryId = category['id']?.toString();
        final categoryName = category['name']?.toString();
        final isSelected = _selectedCategory == categoryId;
        final displayName =
            category['displayName']?.toString() ?? categoryName ?? 'Category';
        final imageUrl = category['imageUrl']?.toString();
        final colorHex = category['color']?.toString() ?? '#4CAF50';

        // Check if imageUrl is an actual image path
        final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

        // Parse color from hex
        Color categoryColor = VillageTheme.primaryGreen;
        try {
          categoryColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
        } catch (e) {
          categoryColor = VillageTheme.primaryGreen;
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = categoryId;
              // If "All Items" is selected (categoryId is null), set categoryName to null to show all products
              _selectedCategoryName = categoryId == null ? null : categoryName;
              _filterProducts(); // Apply filter immediately without API call
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected
                  ? VillageTheme.primaryGreen.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: VillageTheme.primaryGreen,
                      width: 1.5,
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Image
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasImage
                        ? Image.network(
                            ImageUrlHelper.getFullImageUrl(imageUrl!),
                            width: 45,
                            height: 45,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildCategoryPlaceholder(
                                  categoryName ?? 'Category',
                                  categoryColor,
                                  isSelected);
                            },
                          )
                        : _buildCategoryPlaceholder(categoryName ?? 'Category',
                            categoryColor, isSelected),
                  ),
                ),
                const SizedBox(height: 2),
                // Category Name
                Text(
                  displayName,
                  style: TextStyle(
                    color: isSelected
                        ? VillageTheme.primaryGreen
                        : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 8,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryPlaceholder(
      String categoryName, Color color, bool isSelected) {
    // Extract first letter for display
    String firstLetter = 'C';
    try {
      // Get first character that's not a special character
      final cleanName = categoryName.split('/').last.trim();
      if (cleanName.isNotEmpty) {
        firstLetter = cleanName[0].toUpperCase();
      }
    } catch (e) {
      firstLetter = 'C';
    }

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.7),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
            const Text('😞', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Failed to load shop details',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _loadShopDetails();
                _loadProducts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: VillageTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopDetails() {
    if (_shop == null) {
      return const Center(child: LoadingWidget());
    }

    final shopName = _shop!['name']?.toString() ?? 'Shop';
    final businessType = _shop!['businessType']?.toString() ?? 'Store';
    final rating =
        double.tryParse(_shop!['averageRating']?.toString() ?? '0.0') ?? 0.0;
    final isActive = _shop!['isActive'] ?? true;
    final address = _shop!['addressLine1']?.toString() ?? '';
    final city = _shop!['city']?.toString() ?? '';
    final fullAddress = city.isNotEmpty ? '$address, $city' : address;
    final minOrder = _shop!['minOrderAmount']?.toString() ?? '';
    final deliveryFee = _shop!['deliveryFee']?.toString() ?? '';

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(shopName, businessType, rating, isActive),
        // Address info removed as requested
        // SliverToBoxAdapter(child: _buildShopInfo(fullAddress, minOrder, deliveryFee)),
        SliverToBoxAdapter(child: _buildSearchBar()),
        _buildProductGrid(),
      ],
    );
  }

  Widget _buildShopDetailsContent() {
    if (_shop == null) {
      return const Center(child: LoadingWidget());
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Shop Closed Banner
        if (!_isShopOpen)
          SliverToBoxAdapter(child: _buildShopClosedBanner()),
        // Unified Offers Carousel (Combos + Promos together)
        SliverToBoxAdapter(child: _buildUnifiedOffersCarousel()),
        SliverToBoxAdapter(child: _buildHorizontalCategories()),
        SliverToBoxAdapter(child: _buildSearchBar()),
        _buildProductGrid(),
      ],
    );
  }

  Widget _buildShopClosedBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc?.translate('shop_closed') ?? 'Shop Closed',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.loc?.translate('shop_closed_message', args: [_shop?['name'] ?? 'This shop']) ??
                      'This shop is currently closed. Please try again during business hours.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopBanner() {
    // Get banner image from shop images
    final images = _shop?['images'] as List<dynamic>?;
    if (images == null || images.isEmpty) return const SizedBox.shrink();

    // Find banner image or primary image
    String? bannerUrl;
    for (final img in images) {
      final imageType = img['imageType']?.toString()?.toUpperCase();
      if (imageType == 'BANNER') {
        bannerUrl = img['imageUrl']?.toString();
        break;
      }
    }

    // If no banner, try to find primary image
    if (bannerUrl == null) {
      for (final img in images) {
        if (img['isPrimary'] == true) {
          bannerUrl = img['imageUrl']?.toString();
          break;
        }
      }
    }

    // If still no image, use first image
    if (bannerUrl == null && images.isNotEmpty) {
      bannerUrl = images.first['imageUrl']?.toString();
    }

    if (bannerUrl == null || bannerUrl.isEmpty) return const SizedBox.shrink();

    final fullUrl = ImageUrlHelper.getFullImageUrl(bannerUrl);
    print('🖼️ Shop banner URL: $fullUrl');

    // Use FutureBuilder-like approach with Image - wrap entire widget
    // so error state properly hides the container
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          fullUrl,
          width: double.infinity,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('🖼️ Banner error: $error');
            // Return zero-height widget on error
            return const SizedBox(height: 0, width: 0);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            // Show loading skeleton with fixed height
            return Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: VillageTheme.primaryGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFreeDeliveryBanner() {
    final freeDeliveryAbove = (_shop?['freeDeliveryAbove'] ?? 0).toDouble();
    if (freeDeliveryAbove <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_shipping, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'Free Delivery above ₹${freeDeliveryAbove.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
      String shopName, String businessType, double rating, bool isActive) {
    return SliverAppBar(
      expandedHeight: 70,
      pinned: true,
      backgroundColor: VillageTheme.primaryGreen,
      elevation: 4,
      automaticallyImplyLeading: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back',
      ),
      title: Text(
        shopName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
          onPressed: () {
            context.push('/customer/smart-order', extra: {
              'shopId': widget.shopId,
              'shopName': _shop?['name'] ?? _shop?['shopName'] ?? '',
            });
          },
          tooltip: 'AI Order',
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 28),
          onPressed: () {
            // Scroll to search bar
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
          tooltip: 'Search',
        ),
      ],
    );
  }

  Widget _buildShopInfo(String address, String minOrder, String deliveryFee) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (address.isNotEmpty)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VillageTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on,
                      color: VillageTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
              ],
            ),
          if (address.isNotEmpty) const SizedBox(height: 12),
          Row(
            children: [
              if (minOrder.isNotEmpty)
                Expanded(
                  child: _buildInfoChip('🛍️', 'Min Order', '₹$minOrder'),
                ),
              if (minOrder.isNotEmpty && deliveryFee.isNotEmpty)
                const SizedBox(width: 12),
              if (deliveryFee.isNotEmpty)
                Expanded(
                  child: _buildInfoChip('🚚', 'Delivery', '₹$deliveryFee'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VillageTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: VillageTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'பொருட்களைத் தேடுங்கள்',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon:
              const Icon(Icons.search, color: VillageTheme.primaryGreen),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: VillageTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white, size: 20),
                  onPressed: () {
                    _showVoiceSearchDialog();
                  },
                  tooltip: 'AI Voice Search',
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildUnifiedOffersCarousel() {
    // Calculate total items: combos + promos
    final totalItems = _combos.length + _promotions.length;

    if (totalItems == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_offer, color: Colors.green[700], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Special Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalItems',
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
        // Unified carousel
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _couponPageController,
            onPageChanged: (index) {
              setState(() {
                _currentCouponPage = index;
              });
              _scheduleNextSlide(); // Schedule next slide with appropriate duration
            },
            itemCount: totalItems,
            itemBuilder: (context, index) {
              // First show combos, then promos
              if (index < _combos.length) {
                return _buildComboCard(_combos[index]);
              } else {
                return _buildPromoCard(_promotions[index - _combos.length]);
              }
            },
          ),
        ),
        // Page indicators
        if (totalItems > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalItems,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentCouponPage == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _currentCouponPage == index
                        ? Colors.green[700]
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComboCard(CustomerCombo combo) {
    return _ComboCardWithSlideshow(
      combo: combo,
      onTap: () => _showComboDetail(combo),
    );
  }

  Widget _buildPromoCard(PromoCode promo) {
    final code = promo.code;
    final discountType = promo.type;
    final discountValue = promo.discountValue;
    final minOrderAmount = promo.minimumOrderAmount ?? 0;

    String offerText;
    if (discountType == 'PERCENTAGE') {
      offerText = '${discountValue.toStringAsFixed(0)}% OFF';
    } else if (discountType == 'FIXED_AMOUNT') {
      offerText = '₹${discountValue.toStringAsFixed(0)} OFF';
    } else if (discountType == 'FREE_SHIPPING') {
      offerText = 'Free Delivery';
    } else {
      offerText = promo.description ?? 'Special Offer';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with gradient
          Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Colors.orange[700]!, Colors.orange[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_offer, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          offerText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          offerText,
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          minOrderAmount > 0
                              ? 'Min. order ₹${minOrderAmount.toStringAsFixed(0)}'
                              : 'No minimum order',
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Code "$code" copied!'),
                          backgroundColor: const Color(0xFF2E7D32),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[700],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Copy Code', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboSection() {
    if (_combos.isEmpty) return const SizedBox.shrink();

    return ComboBannerWidget(
      combos: _combos,
      onComboTapped: (combo) {
        _showComboDetail(combo);
      },
    );
  }

  void _showComboDetail(CustomerCombo combo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComboDetailBottomSheet(
        combo: combo,
        onAddToCart: () {
          _addComboToCart(combo);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _addComboToCart(CustomerCombo combo) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Debug: Log combo info
    print('🎁 Adding combo to cart: ${combo.name}');
    print('🎁 Combo has ${combo.items.length} items');

    // Add each item in the combo to cart
    for (final item in combo.items) {
      // Debug: Log item info before creating ProductModel
      print('📦 Item: ${item.productName}');
      print('📦 Item Tamil: ${item.productNameTamil}');

      // Create a ProductModel for each combo item
      final product = ProductModel(
        id: item.shopProductId.toString(),
        name: item.productName,
        nameTamil: item.productNameTamil,
        description: item.productName,
        price: item.unitPrice,
        images: item.imageUrl != null ? [item.imageUrl!] : [],
        unit: item.unit ?? 'piece',
        category: 'Combo Item',
        shopId: combo.shopCode ?? combo.shopId.toString(),
        shopDatabaseId: combo.shopId,
        shopName: combo.shopName ?? '',
        stockQuantity: 999,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Debug: Log the created ProductModel
      print('✅ Created ProductModel: name=${product.name}, nameTamil=${product.nameTamil}');

      // Add to cart with the specified quantity
      await cartProvider.addToCart(product, quantity: item.quantity);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${combo.name} added to cart!'),
        backgroundColor: const Color(0xFF2E7D32),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            context.push('/customer/cart');
          },
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    // Hide section when loading or no promotions
    if (_isLoadingPromotions || _promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header matching combo section style
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_offer, color: Colors.orange[700], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Special Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_promotions.length}',
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
        // Promo cards - PageView slider
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _couponPageController,
            onPageChanged: (index) {
              setState(() {
                _currentCouponPage = index;
              });
              _scheduleNextSlide();
            },
            itemCount: _promotions.length,
            itemBuilder: (context, index) {
              final promo = _promotions[index];

              // PromoCode is a class, access properties directly
              final code = promo.code;
              final discountType = promo.type;
              final discountValue = promo.discountValue;
              final minOrderAmount = promo.minimumOrderAmount ?? 0;

              String offerText;
              if (discountType == 'PERCENTAGE') {
                offerText = '${discountValue.toStringAsFixed(0)}% OFF';
              } else if (discountType == 'FIXED_AMOUNT') {
                offerText = '₹${discountValue.toStringAsFixed(0)} OFF';
              } else if (discountType == 'FREE_SHIPPING') {
                offerText = 'Free Delivery';
              } else {
                offerText = promo.description ?? 'Special Offer';
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top section with gradient
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        gradient: LinearGradient(
                          colors: [Colors.orange[700]!, Colors.orange[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.local_offer, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    code,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    offerText,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            // Min order info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    offerText,
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    minOrderAmount > 0
                                        ? 'Min. order ₹${minOrderAmount.toStringAsFixed(0)}'
                                        : 'No minimum order',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            // Copy Code button
                            GestureDetector(
                              onTap: () {
                                // Copy code to clipboard
                                Clipboard.setData(ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Code "$code" copied!'),
                                    backgroundColor: const Color(0xFF2E7D32),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange[700],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy, color: Colors.white, size: 14),
                                    SizedBox(width: 6),
                                    Text('Copy Code', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Page indicators
        if (_promotions.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _promotions.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentCouponPage == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _currentCouponPage == index
                        ? Colors.orange[700]
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductGrid() {
    if (_isLoadingProducts) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: LoadingWidget()),
        ),
      );
    }

    // Products are already filtered by the server-side search
    if (_products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: VillageTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('📦', style: TextStyle(fontSize: 60)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'பொருட்கள் இல்லை\nNo Products Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: 100, // Extra padding to prevent floating cart from blocking products
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75, // Adjusted for shorter card height
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildProductCard(_products[index]),
          childCount: _products.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // Use LanguageProvider to get the correct name based on language toggle
    // listen: true ensures the widget rebuilds when language changes
    final languageProvider = Provider.of<LanguageProvider>(context);
    final productName = languageProvider.getDisplayName(product);

    // Get description
    final description = product['customDescription']?.toString() ??
        product['displayDescription']?.toString() ??
        product['masterProduct']?['description']?.toString() ??
        '';

    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final originalPrice =
        double.tryParse(product['originalPrice']?.toString() ?? '0') ?? 0.0;
    final stockQuantity =
        int.tryParse(product['stockQuantity']?.toString() ?? '0') ?? 0;
    // isInStock should be based on actual stock quantity, not just the inStock flag
    final isInStock = stockQuantity > 0;
    final isLowStock = stockQuantity > 0 && stockQuantity <= 5;
    final baseWeight =
        product['baseWeight'] ?? product['masterProduct']?['baseWeight'] ?? 1;
    final baseUnit = product['baseUnit']?.toString() ??
        product['masterProduct']?['baseUnit']?.toString() ??
        'unit';
    final weightDisplay = '$baseWeight $baseUnit';

    // Get image URL from primaryImageUrl or master product images
    final imageUrl = product['primaryImageUrl']?.toString() ??
        product['masterProduct']?['primaryImageUrl']?.toString() ??
        '';

    // Debug: print image URL
    print('Product: $productName, Image URL: $imageUrl');

    final hasDiscount = originalPrice > price;
    final discountPercentage = hasDiscount
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with discount badge
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            ImageUrlHelper.getFullImageUrl(imageUrl),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                  'Error loading image: $imageUrl - Error: $error');
                              return Container(
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported,
                                        size: 30, color: Colors.grey[400]),
                                    const SizedBox(height: 4),
                                    Text('Image not available',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        )),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: VillageTheme.primaryGreen,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.inventory_2,
                                  size: 40, color: Colors.grey),
                            ),
                          ),
                  ),
                  // Discount badge overlay at top left
                  if (hasDiscount && discountPercentage > 0)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${discountPercentage.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Keep only "Out of Stock" overlay on image
                  if (!isInStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                        ),
                        child: const Center(
                          child: Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Product Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$weightDisplay | $stockQuantity stock',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Price Row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '₹${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: VillageTheme.primaryGreen,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 2),
                            Text(
                              '₹${originalPrice.toStringAsFixed(originalPrice == originalPrice.roundToDouble() ? 0 : 2)}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '${discountPercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Stock warning
                      if (isLowStock && isInStock)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            'Only $stockQuantity left',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      final productModel = ProductModel(
                        id: product['id'].toString(),
                        name: productName,
                        description: description,
                        price: price,
                        category:
                            product['masterProduct']?['category']?.toString() ??
                                '',
                        shopId: _shop?['shopId']?.toString() ??
                            widget.shopId.toString(),
                        shopDatabaseId: _shop?['id'] ??
                            widget.shopId, // Pass numeric shop database ID
                        shopName: _shop?['name']?.toString() ?? 'Shop',
                        images: imageUrl.isNotEmpty ? [imageUrl] : [],
                        stockQuantity: stockQuantity,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      final cartQuantity =
                          cartProvider.getQuantity(productModel.id);

                      if (!isInStock) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Out of Stock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      // Allow adding to cart even when shop is closed
                      // Order placement will be blocked at checkout
                      if (cartQuantity == 0) {
                        return GestureDetector(
                          onTap: () async {
                            await _handleAddToCart(
                                context, cartProvider, productModel);
                          },
                          child: Container(
                            width: double.infinity,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'ADD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Center(
                        child: Container(
                          height: 24,
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    cartProvider
                                        .decreaseQuantity(productModel.id);
                                  },
                                  borderRadius: BorderRadius.circular(2),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.remove,
                                        color: Colors.white, size: 12),
                                  ),
                                ),
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 20),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$cartQuantity',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    await _handleAddToCart(
                                        context, cartProvider, productModel);
                                  },
                                  borderRadius: BorderRadius.circular(2),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.add,
                                        color: Colors.white, size: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddToCart(BuildContext context, CartProvider cartProvider,
      ProductModel product) async {
    // Allow adding to cart even when shop is closed
    // Order placement will be blocked at checkout screen

    // Check stock availability before adding
    final currentCartQuantity = cartProvider.getQuantity(product.id);
    final availableStock = product.stockQuantity;

    if (currentCartQuantity >= availableStock) {
      // Show error message - cannot add more than available stock
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only $availableStock items available in stock'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final success = await cartProvider.addToCart(product);

    if (success) {
      // Store shop open status for checkout validation (no API call needed later)
      cartProvider.setShopStatus(
        isOpen: _isShopOpen,
        shopName: _shop?['name'],
      );
    } else {
      // Show dialog for different shop
      if (context.mounted) {
        final currentShopName = cartProvider.getCurrentShopName();
        final shouldClearCart = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Different Shop'),
            content: Text(
                'Your cart contains items from "$currentShopName".\n\n'
                'Adding items from "${product.shopName}" will clear your current cart.\n\n'
                'Do you want to continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                ),
                child: const Text('Clear Cart & Add'),
              ),
            ],
          ),
        );

        if (shouldClearCart == true) {
          cartProvider.clearCart();
          final addedSuccess = await cartProvider.addToCart(product, clearCartConfirmed: true);
          if (addedSuccess) {
            // Store shop open status for new shop
            cartProvider.setShopStatus(
              isOpen: _isShopOpen,
              shopName: _shop?['name'],
            );
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cart cleared. ${product.name} added to cart'),
                backgroundColor: const Color(0xFF4CAF50),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    }
  }

  void _showVoiceSearchDialog() async {
    // ✅ Auto-start voice listening BEFORE showing dialog
    // This ensures the mic opens immediately

    final scrollController = ScrollController();
    final parentContext = context;

    // Show dialog with listening state
    List<dynamic> voiceResults = [];
    bool isSearching = true;
    String searchStatus = 'listening';
    String? searchQuery;

    // Start listening immediately (before dialog finishes rendering)
    final listenFuture = _voiceSearch.listen();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Handle the listen result
          if (isSearching && searchStatus == 'listening') {
            listenFuture.then((query) async {
              if (query == null || query.trim().isEmpty) {
                setState(() {
                  isSearching = false;
                  searchStatus = '';
                });
                return;
              }

              // Now searching
              setState(() {
                searchStatus = 'searching';
                searchQuery = query;
              });

              // Search products
              final results = await _voiceSearch.searchProducts(widget.shopId, query);

              // Done
              setState(() {
                isSearching = false;
                searchStatus = '';
                voiceResults = results;
              });
              // Scroll to top of results list
              if (results.isNotEmpty && scrollController.hasClients) {
                scrollController.jumpTo(0);
              }
            });
            // Change status to prevent re-triggering
            searchStatus = 'waiting';
          }

          return WillPopScope(
            onWillPop: () async => !isSearching,
            child: Dialog(insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.95,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simple Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.mic, color: Color(0xFF2E7D32), size: 20),
                            SizedBox(width: 8),
                            Text('Voice Search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        GestureDetector(
                          onTap: isSearching ? null : () => Navigator.pop(dialogContext),
                          child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: isSearching ? Colors.grey : Colors.red, shape: BoxShape.circle), child: Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Voice Button - Only shown after results when user wants to search again
                  if (!isSearching && voiceResults.isEmpty && searchQuery == null)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // Step 1: Start listening
                            setState(() {
                              isSearching = true;
                              searchStatus = 'listening';
                            });

                            // Step 2: Listen to voice
                            final query = await _voiceSearch.listen();

                            if (query == null || query.trim().isEmpty) {
                              setState(() {
                                isSearching = false;
                                searchStatus = '';
                              });
                              return;
                            }

                            // Step 3: Now searching
                            setState(() {
                              searchStatus = 'searching';
                              searchQuery = query;
                            });

                            // Step 4: Search products
                            final results = await _voiceSearch.searchProducts(widget.shopId, query);

                            // Step 5: Done
                            setState(() {
                              isSearching = false;
                              searchStatus = '';
                              voiceResults = results;
                            });
                            // Scroll to top of results list
                            if (results.isNotEmpty && scrollController.hasClients) {
                              scrollController.jumpTo(0);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic, color: Colors.white, size: 32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Tap to speak', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),

                  // Loading indicator with different states
                  if (isSearching)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        if (searchStatus == 'listening')
                          Column(
                            children: const [
                              Icon(Icons.mic, size: 40, color: Color(0xFF2E7D32)),
                              SizedBox(height: 12),
                              Text('🎤 Listening...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                              SizedBox(height: 4),
                              Text('Speak now', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          )
                        else if (searchStatus == 'searching')
                          Column(
                            children: [
                              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32))),
                              const SizedBox(height: 12),
                              Text(
                                searchQuery != null && searchQuery!.isNotEmpty
                                    ? '🔍 Searching "$searchQuery"...'
                                    : '🔍 Searching...',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              const Text('Please wait', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          )
                        else
                          Column(
                            children: const [
                              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32))),
                              SizedBox(height: 8),
                              Text('Processing...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                      ],
                    ),

                  // Search results - Clean UI
                  if (!isSearching && voiceResults.isNotEmpty)
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (searchQuery != null && searchQuery!.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '"$searchQuery" - ${voiceResults.length} found',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() { voiceResults = []; searchQuery = null; }),
                                  child: const Text(
                                    'EDIT',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: ListView.builder(
                              controller: scrollController, // Use scroll controller to start at top
                              shrinkWrap: true,
                              itemCount: voiceResults.length,
                              itemBuilder: (context, index) {
                                final product = voiceResults[index];
                                final inStock = product['inStock'] ?? product['isAvailable'] ?? true;
                                final languageProvider = Provider.of<LanguageProvider>(parentContext, listen: false);
                                final displayName = languageProvider.getDisplayName(product);
                                final price = product['price'] ?? 0;
                                final originalPrice = product['originalPrice'];
                                String? imageUrl = product['primaryImageUrl'] ?? product['masterProduct']?['primaryImageUrl'];
                                final fullImageUrl = imageUrl != null ? ImageUrlHelper.getFullImageUrl(imageUrl) : null;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product Image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: fullImageUrl != null
                                              ? Image.network(fullImageUrl, width: 70, height: 70, fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.image, size: 30)))
                                              : Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.image, size: 30)),
                                        ),
                                        const SizedBox(width: 12),
                                        // Product Details - Expanded to show full name
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Full Product Name - allows wrapping
                                              Text(
                                                displayName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.3,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              // Price Row
                                              Row(
                                                children: [
                                                  Text(
                                                    '₹$price',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Color(0xFF2E7D32),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (originalPrice != null && originalPrice > price) ...[
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '₹$originalPrice',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[500],
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Add Button
                                        inStock
                                        ? Builder(
                                            builder: (builderContext) {
                                              final cartProvider = Provider.of<CartProvider>(parentContext);
                                              final productId = product['id'].toString();
                                              final qty = cartProvider.getQuantity(productId);
                                              final productModel = ProductModel(
                                                id: productId, name: displayName, description: '', price: price,
                                                category: '', shopId: _shop?['shopId']?.toString() ?? widget.shopId.toString(), shopName: _shop?['name']?.toString() ?? widget.shop?['name'] ?? 'Shop',
                                                images: imageUrl != null ? [imageUrl] : [], stockQuantity: product['stockQuantity'] ?? 999,
                                                createdAt: DateTime.now(), updatedAt: DateTime.now(),
                                              );
                                              if (qty == 0) {
                                                return SizedBox(
                                                  width: 50, height: 28,
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      print('🛒 Voice Search: Adding ${productModel.name} to cart');
                                                      print('🛒 Voice Search: ShopId=${productModel.shopId}');
                                                      try {
                                                        final success = await cartProvider.addToCart(productModel);
                                                        print('🛒 Voice Search: Add result=$success');
                                                        if (success) {
                                                          setState(() {}); // Trigger dialog rebuild
                                                        } else {
                                                          print('❌ Voice Search: Failed to add to cart');
                                                        }
                                                      } catch (e) {
                                                        print('❌ Voice Search: Error adding to cart: $e');
                                                      }
                                                    },
                                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), padding: EdgeInsets.zero),
                                                    child: const Text('ADD', style: TextStyle(fontSize: 10, color: Colors.white)),
                                                  ),
                                                );
                                              }
                                              return Container(
                                                height: 28,
                                                decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(4)),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        cartProvider.decreaseQuantity(productId);
                                                        setState(() {}); // Trigger dialog rebuild
                                                      },
                                                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.remove, color: Colors.white, size: 16)),
                                                    ),
                                                    Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                                    GestureDetector(
                                                      onTap: () {
                                                        cartProvider.increaseQuantity(productId);
                                                        setState(() {}); // Trigger dialog rebuild
                                                      },
                                                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.add, color: Colors.white, size: 16)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('Out of Stock', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Search Again button - Outlined style
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                // Clear previous results and start new voice search
                                setState(() {
                                  voiceResults = [];
                                  searchQuery = null;
                                  isSearching = true;
                                  searchStatus = 'listening';
                                });

                                // Start listening
                                final query = await _voiceSearch.listen();

                                if (query == null || query.trim().isEmpty) {
                                  setState(() {
                                    isSearching = false;
                                    searchStatus = '';
                                  });
                                  return;
                                }

                                // Now searching
                                setState(() {
                                  searchStatus = 'searching';
                                  searchQuery = query;
                                });

                                // Search products
                                final results = await _voiceSearch.searchProducts(widget.shopId, query);

                                // Done
                                setState(() {
                                  isSearching = false;
                                  searchStatus = '';
                                  voiceResults = results;
                                });

                                // Scroll to top
                                if (results.isNotEmpty && scrollController.hasClients) {
                                  scrollController.jumpTo(0);
                                }
                              },
                              icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32), size: 18),
                              label: const Text('Search Again', style: TextStyle(fontSize: 14, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // No results - Compact
                  if (!isSearching && voiceResults.isEmpty && searchQuery != null)
                    Column(
                      children: [
                        const Icon(Icons.search_off, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No products found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () async {
                            setState(() {
                              isSearching = true;
                              searchStatus = 'listening';
                              voiceResults = [];
                              searchQuery = null;
                            });

                            final query = await _voiceSearch.listen();
                            if (query == null || query.trim().isEmpty) {
                              setState(() {
                                isSearching = false;
                                searchStatus = '';
                              });
                              return;
                            }

                            setState(() {
                              searchStatus = 'searching';
                              searchQuery = query;
                            });

                            final results = await _voiceSearch.searchProducts(widget.shopId, query);
                            setState(() {
                              isSearching = false;
                              searchStatus = '';
                              voiceResults = results;
                            });
                            // Scroll to top of results list
                            if (results.isNotEmpty && scrollController.hasClients) {
                              scrollController.jumpTo(0);
                            }
                          },
                          icon: const Icon(Icons.mic, size: 16),
                          label: const Text('Try Again', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}

// Custom floating button location for right-aligned positioning
class _RightFloatingButtonLocation extends FloatingActionButtonLocation {
  const _RightFloatingButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Calculate position from bottom-right
    final double fabX = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        16.0;
    final double fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        scaffoldGeometry.minInsets.bottom -
        16.0;

    return Offset(fabX, fabY);
  }
}

// Combo card with product image slideshow (2 second interval)
class _ComboCardWithSlideshow extends StatefulWidget {
  final CustomerCombo combo;
  final VoidCallback onTap;

  const _ComboCardWithSlideshow({
    required this.combo,
    required this.onTap,
  });

  @override
  State<_ComboCardWithSlideshow> createState() => _ComboCardWithSlideshowState();
}

class _ComboCardWithSlideshowState extends State<_ComboCardWithSlideshow> {
  late PageController _imagePageController;
  int _currentImageIndex = 0;
  Timer? _imageSlideTimer;
  List<String> _productImages = [];

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _collectProductImages();
    _startImageSlideshow();
  }

  @override
  void dispose() {
    _imageSlideTimer?.cancel();
    _imagePageController.dispose();
    super.dispose();
  }

  void _collectProductImages() {
    // Collect all product images from combo items
    for (var item in widget.combo.items) {
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        _productImages.add(ImageUrlHelper.getFullImageUrl(item.imageUrl));
      }
    }
    // Add banner image as fallback if no product images
    if (_productImages.isEmpty && widget.combo.bannerImageUrl != null) {
      _productImages.add(ImageUrlHelper.getFullImageUrl(widget.combo.bannerImageUrl));
    }
  }

  void _startImageSlideshow() {
    if (_productImages.length > 1) {
      _imageSlideTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_imagePageController.hasClients) {
          final nextPage = (_currentImageIndex + 1) % _productImages.length;
          _imagePageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side - Product Image Slideshow
            Container(
              width: 120,
              decoration: const BoxDecoration(
                color: Color(0xFF1B4332),
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  // Product Image Slideshow
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    child: _productImages.isNotEmpty
                        ? PageView.builder(
                            controller: _imagePageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemCount: _productImages.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                _productImages[index],
                                width: 120,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(Icons.card_giftcard, color: Colors.white.withOpacity(0.5), size: 40),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(Icons.card_giftcard, color: Colors.white.withOpacity(0.5), size: 40),
                          ),
                  ),
                  // Discount Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.combo.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  // Image indicator dots
                  if (_productImages.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _productImages.length,
                          (index) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Right side - Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.combo.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.combo.nameTamil != null)
                      Text(
                        widget.combo.nameTamil!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.combo.itemCount} items included',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${widget.combo.comboPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${widget.combo.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const Spacer(),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onTap,
                            borderRadius: BorderRadius.circular(16),
                            splashColor: Colors.white.withOpacity(0.3),
                            highlightColor: Colors.white.withOpacity(0.1),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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
}
