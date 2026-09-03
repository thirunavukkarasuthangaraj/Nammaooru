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
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/promo_code_service.dart';
import '../models/combo_model.dart';
import '../services/combo_service.dart';
import '../widgets/combo_banner_widget.dart';
import 'cart_screen.dart';
import 'shop_products_screen.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // Starts true so the spinner shows from the first frame until the (slow)
  // products query returns — never a flash of "No Products Found"
  bool _isLoadingProducts = true;
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
    _voiceSearch.stopListening();
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
    final duration =
        isCombo ? const Duration(seconds: 30) : const Duration(seconds: 10);

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
          // Default to the maligai (essentials) category when the shop has
          // one; otherwise start on "All Items"
          Map<String, dynamic>? essentials;
          for (final c in categoryList) {
            if (_categoryPriority(c['name']?.toString()) == 0) {
              essentials = Map<String, dynamic>.from(c as Map);
              break;
            }
          }
          _selectedCategory = essentials?['id']?.toString();
          _selectedCategoryName = essentials?['name']?.toString();
          _isLoadingCategories = false;
        });
        // Re-filter in case products finished loading before categories
        _filterProducts();
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
    // Defer to after the frame: this runs from the initState/load path while
    // the tree may still be building, and CartProvider.notifyListeners()
    // during build throws "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      if (freeDeliveryAbove > 0) {
        cartProvider.setFreeDeliveryAbove(freeDeliveryAbove);
      }
      // Set this as soon as shop data loads, not only on the specific
      // "Add" buttons that happen to call setShopStatus — several quick-add
      // buttons in this screen skip that call entirely, leaving
      // minOrderAmount null and checkout falling back to its ₹100 default.
      cartProvider.setShopStatus(
        isOpen: _isShopOpen,
        shopName: shop['name'],
        minOrderAmount: (shop['minOrderAmount'] as num?)?.toDouble(),
      );
    });
  }

  // False while background pages are still streaming in — searches during
  // that window show a loader instead of a wrong "No Products Found"
  bool _catalogFullyLoaded = false;

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _catalogFullyLoaded = false;
      _hasError = false;
    });

    try {
      final searchQuery = _searchController.text.trim();

      // Progressive load: fetch the first page fast so the screen renders in
      // ~1s, then pull the remaining pages in the background and append them.
      // All filtering stays client-side (backend category IDs don't match
      // product category IDs), so search/chips behave exactly as before.
      const pageSize = 150;
      final response = await _shopApi.getShopProducts(
        shopId: widget.shopId.toString(),
        page: 0,
        size: pageSize,
      );

      if (mounted &&
          response['statusCode'] == '0000' &&
          response['data'] != null) {
        final firstPage = response['data']['content'] ?? [];
        final totalPages =
            int.tryParse(response['data']['totalPages']?.toString() ?? '1') ??
                1;

        setState(() {
          _allProducts = List.of(firstPage);
          // Apply client-side filtering for both search and category
          _filterProducts();
          _isLoadingProducts = false;
        });

        // Fetch the FULL catalog in one background request (the same query
        // that always returned complete results) and REPLACE the list when it
        // arrives — idempotent, so a retry/second call can never duplicate.
        if (totalPages > 1) {
          try {
            final full = await _shopApi.getShopProducts(
              shopId: widget.shopId.toString(),
              page: 0,
              size: 2000,
            );
            if (!mounted) return;
            if (full['statusCode'] == '0000' && full['data'] != null) {
              final all = full['data']['content'] ?? [];
              if (all.length >= _allProducts.length) {
                setState(() {
                  _allProducts = List.of(all);
                });
              }
            }
          } catch (_) {
            // Keep the first page — screen stays usable with partial catalog
          }
        }
        if (mounted) {
          setState(() {
            _catalogFullyLoaded = true;
            _filterProducts();
          });
        }
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

    // "All Items": daily-essential categories (maligai) come first instead of
    // the server's plain alphabetical order
    else {
      filteredProducts = List.of(filteredProducts)
        ..sort((a, b) {
          final pa = _categoryPriority(
              a['masterProduct']?['category']?['name']?.toString());
          final pb = _categoryPriority(
              b['masterProduct']?['category']?['name']?.toString());
          if (pa != pb) return pa - pb;
          final na = (a['displayName'] ?? '').toString().toLowerCase();
          final nb = (b['displayName'] ?? '').toString().toLowerCase();
          return na.compareTo(nb);
        });
    }

    setState(() {
      _products = filteredProducts;
    });
  }

  // Lower number = shown earlier in "All Items". Essentials (maligai) first,
  // occasional-use goods (electronics, medicine) last.
  int _categoryPriority(String? categoryName) {
    final c = (categoryName ?? '').toLowerCase();
    if (c.contains('maligai') ||
        c.contains('மளிகை') ||
        c.contains('grocery') ||
        c.contains('provision') ||
        c.contains('essential')) return 0;
    if (c.contains('vegetable') ||
        c.contains('fruit') ||
        c.contains('rice') ||
        c.contains('oil') ||
        c.contains('dairy') ||
        c.contains('milk') ||
        c.contains('egg')) return 1;
    if (c.contains('snack') ||
        c.contains('food') ||
        c.contains('beverage') ||
        c.contains('drink') ||
        c.contains('tea') ||
        c.contains('coffee')) return 2;
    if (c.contains('household') || c.contains('cleaning')) return 3;
    if (c.contains('medicine') || c.contains('health')) return 5;
    if (c.contains('electronic')) return 6;
    return 4; // anything else sits between household and medicine
  }

  void _onSearchChanged() {
    // Just filter the already loaded products
    _filterProducts();
  }

  // One-time tour: search → voice order → card/list toggle
  final GlobalKey _tourSearchKey = GlobalKey();
  final GlobalKey _tourVoiceKey = GlobalKey();
  final GlobalKey _tourCategoriesKey = GlobalKey();
  final GlobalKey _tourToggleKey = GlobalKey();
  final GlobalKey _tourAddKey = GlobalKey();
  bool _shopTourChecked = false;
  BuildContext? _shopShowcaseCtx;

  Future<void> _startShopTourIfNeeded(BuildContext showcaseCtx) async {
    _shopShowcaseCtx = showcaseCtx;
    if (_shopTourChecked) return;
    _shopTourChecked = true;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('shop_screen_tour_shown') ?? false;
    if (shown || !mounted) return;
    await prefs.setBool('shop_screen_tour_shown', true);
    // Wait until the first products are on screen so the ADD button step has
    // a target; give up waiting after ~6s and run the tour without it
    int attempts = 0;
    Timer.periodic(const Duration(milliseconds: 800), (timer) {
      attempts++;
      if (!mounted || _shopShowcaseCtx == null) {
        timer.cancel();
        return;
      }
      final addReady =
          !_isLoadingProducts && _products.isNotEmpty && !_isListView;
      if (addReady || attempts >= 8) {
        timer.cancel();
        if (!mounted) return;
        // Never draw the tour over another screen
        if (ModalRoute.of(context)?.isCurrent != true) return;
        ShowCaseWidget.of(_shopShowcaseCtx!).startShowCase([
          _tourSearchKey,
          _tourVoiceKey,
          if (_categories.isNotEmpty) _tourCategoriesKey,
          _tourToggleKey,
          if (addReady) _tourAddKey,
        ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ShowCaseWidget(
      builder: (showcaseCtx) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _startShopTourIfNeeded(showcaseCtx));
        return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: _isLoadingShop
          ? const Center(child: LoadingWidget())
          : _hasError
              ? _buildErrorState()
              : Column(
                  children: [
                    // Toolbar/AppBar area
                    Container(
                      height: 64,
                      color: VillageTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 24),
                            onPressed: () {
                              // Leaving mid-tour lets the showcase overlay
                              // try to find a target that's no longer in the
                              // tree ("inactive element" crash) — dismiss
                              // first.
                              try {
                                ShowCaseWidget.of(context).dismiss();
                              } catch (_) {}
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
                          _buildViewToggle(),
                          const SizedBox(width: 8),
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
                                '${cartProvider.productCount}',
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
      },
    );
  }

  // Deep green accent from the reference design
  static const Color _deepGreen = Color(0xFF0F7B23);

  Widget _buildHorizontalCategories() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    // Simple text pill chips, like the reference design.
    // Order: "All Items" first, then essentials (maligai) before the rest.
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isTamil = languageProvider.currentLanguage == 'ta';
    final sortedCategories = List<dynamic>.of(_categories)
      ..sort((a, b) {
        final aAll = a['id'] == null ? 0 : 1;
        final bAll = b['id'] == null ? 0 : 1;
        if (aAll != bAll) return aAll - bAll;
        return _categoryPriority(a['name']?.toString()) -
            _categoryPriority(b['name']?.toString());
      });
    return Showcase(
      key: _tourCategoriesKey,
      title: languageProvider.getText('Categories', 'வகைகள்'),
      description: languageProvider.getText(
          'Tap a category to see only those products. Maligai opens first.',
          'ஒரு வகையைத் தட்டினால் அந்தப் பொருட்கள் மட்டும் தெரியும். மளிகை முதலில் திறக்கும்.'),
      tooltipBackgroundColor: Colors.white,
      textColor: Colors.grey.shade800,
      titleTextStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: VillageTheme.primaryGreen,
      ),
      descTextStyle: const TextStyle(fontSize: 12, height: 1.5),
      child: SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final category = sortedCategories[index];
          final categoryId = category['id']?.toString();
          final categoryName = category['name']?.toString();
          final isSelected = _selectedCategory == categoryId;
          // Respect the Tamil/English toggle, falling back to English
          final tamilName =
              (category['displayNameTamil'] ?? category['nameTamil'])
                  ?.toString()
                  .trim();
          final displayName = (isTamil && tamilName != null && tamilName.isNotEmpty)
              ? tamilName
              : category['displayName']?.toString() ?? categoryName ?? 'Category';

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = categoryId;
                // If "All Items" is selected (categoryId is null), set categoryName to null to show all products
                _selectedCategoryName =
                    categoryId == null ? null : categoryName;
                _filterProducts(); // Apply filter immediately without API call
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _deepGreen : const Color(0xFFF1F2F4),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFDDDFE2)),
              ),
              child: Text(
                displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF212121),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
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

    // Chip row is 52 high; search field ~56 + 16 margin.
    final double categoriesExtent =
        _isLoadingCategories ? 52 : (_categories.isEmpty ? 0 : 52);
    const double searchExtent = 72;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Shop Closed Banner
        if (!_isShopOpen) SliverToBoxAdapter(child: _buildShopClosedBanner()),
        // Unified Offers Carousel (Combos + Promos together)
        SliverToBoxAdapter(child: _buildUnifiedOffersCarousel()),
        // Categories + search stay pinned at the top while products scroll
        SliverAppBar(
          pinned: true,
          primary: false,
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          toolbarHeight: categoriesExtent + searchExtent,
          titleSpacing: 0,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search first, then category chips
              _buildSearchBar(),
              _buildHorizontalCategories(),
            ],
          ),
        ),
        _buildProductGrid(),
      ],
    );
  }

  Widget _buildAiOrderButton() {
    return GestureDetector(
      onTap: () {
        context.push('/customer/voice-assistant', extra: {
          'shopId': widget.shopId,
          'shopName': _shop?['name'] ?? _shop?['shopName'] ?? '',
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.assistant, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Talk & Order / பேசி ஆர்டர் செய்',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShopClosedBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // Soft amber notice — informative, not alarming (customers can still
      // browse and add to cart; only ordering is blocked).
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.orange.shade800, size: 24),
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
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.loc?.translate('shop_closed_message',
                          args: [_shop?['name'] ?? 'This shop']) ??
                      'This shop is currently closed. Please try again during business hours.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
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
    final lang = Provider.of<LanguageProvider>(context);
    return Showcase(
      key: _tourSearchKey,
      title: lang.getText('Search Products', 'பொருட்களைத் தேடுங்கள்'),
      description: lang.getText(
          'Type here to instantly find any product in this shop.',
          'இந்தக் கடையில் எந்தப் பொருளையும் இங்கே உடனே தேடலாம்.'),
      tooltipBackgroundColor: Colors.white,
      textColor: Colors.grey.shade800,
      titleTextStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: VillageTheme.primaryGreen,
      ),
      descTextStyle: const TextStyle(fontSize: 12, height: 1.5),
      child: Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      // White field with a hairline border, like the reference design.
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC9CDD1)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'பொருட்களைத் தேடுங்கள்',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
              Showcase(
                key: _tourVoiceKey,
                title: lang.getText('Voice Order', 'பேசி ஆர்டர்'),
                description: lang.getText(
                    'Tap and just say what you need — the app finds and adds it.',
                    'தட்டி தேவையானதைச் சொல்லுங்கள் — ஆப் தேடிச் சேர்க்கும்.'),
                tooltipBackgroundColor: Colors.white,
                textColor: Colors.grey.shade800,
                titleTextStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: VillageTheme.primaryGreen,
                ),
                descTextStyle: const TextStyle(fontSize: 12, height: 1.5),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.assistant,
                        color: Colors.white, size: 20),
                    onPressed: () {
                      context.push('/customer/voice-assistant', extra: {
                        'shopId': widget.shopId,
                        'shopName': _shop?['name'] ?? _shop?['shopName'] ?? '',
                      });
                    },
                    tooltip: 'Talk & Order',
                  ),
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
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
                child:
                    Icon(Icons.local_offer, color: Colors.green[700], size: 20),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
                    child: const Icon(Icons.local_offer,
                        color: Colors.white, size: 18),
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
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 11),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[700],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Copy Code',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
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
      print(
          '✅ Created ProductModel: name=${product.name}, nameTamil=${product.nameTamil}');

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
                child: Icon(Icons.local_offer,
                    color: Colors.orange[700], size: 20),
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
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        gradient: LinearGradient(
                          colors: [Colors.orange[700]!, Colors.orange[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.local_offer,
                                  color: Colors.white, size: 18),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange[700],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 6),
                                    Text('Copy Code',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
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

  // Card ↔ list view toggle, user-selectable from the header
  bool _isListView = false;

  // Lives in the green app bar: white translucent pill, active mode = white
  Widget _buildViewToggle() {
    Widget modeButton(IconData icon, bool active, VoidCallback onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? VillageTheme.primaryGreen : Colors.white,
          ),
        ),
      );
    }

    final lang = Provider.of<LanguageProvider>(context);
    return Showcase(
      key: _tourToggleKey,
      title: lang.getText('Card / List View', 'கார்டு / பட்டியல்'),
      description: lang.getText(
          'Tap to switch how products are shown — big cards or a compact list.',
          'பொருட்களை கார்டு அல்லது பட்டியல் வடிவில் மாற்றிப் பார்க்க தட்டவும்.'),
      tooltipBackgroundColor: Colors.white,
      textColor: Colors.grey.shade800,
      titleTextStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: VillageTheme.primaryGreen,
      ),
      descTextStyle: const TextStyle(fontSize: 12, height: 1.5),
      // While this step is highlighted, the tour overlay would otherwise
      // swallow the tap and just advance the tour instead of toggling the
      // view — make the tap do the real thing AND finish this step.
      onTargetClick: () => setState(() => _isListView = !_isListView),
      disposeOnTap: true,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            modeButton(Icons.grid_view_rounded, !_isListView,
                () => setState(() => _isListView = false)),
            const SizedBox(width: 2),
            modeButton(Icons.view_list_rounded, _isListView,
                () => setState(() => _isListView = true)),
          ],
        ),
      ),
    );
  }

  // List-view row: same old-design styling as the grid card, horizontal layout
  Widget _buildProductListTile(Map<String, dynamic> product) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final productName = languageProvider.getDisplayName(product);
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final originalPrice =
        double.tryParse(product['originalPrice']?.toString() ?? '0') ?? 0.0;
    final stockQuantity =
        int.tryParse(product['stockQuantity']?.toString() ?? '0') ?? 0;
    final isInStock = stockQuantity > 0;
    final baseWeight =
        product['baseWeight'] ?? product['masterProduct']?['baseWeight'] ?? 1;
    final baseUnit = product['baseUnit']?.toString() ??
        product['masterProduct']?['baseUnit']?.toString() ??
        'unit';
    final weightDisplay = '$baseWeight $baseUnit';
    final imageUrl = product['primaryImageUrl']?.toString() ??
        product['masterProduct']?['primaryImageUrl']?.toString() ??
        '';
    final hasDiscount = originalPrice > price;

    final productModel = ProductModel(
      id: product['id'].toString(),
      name: productName,
      description: '',
      price: price,
      category: product['masterProduct']?['category']?.toString() ?? '',
      shopId: _shop?['shopId']?.toString() ?? widget.shopId.toString(),
      shopDatabaseId: _shop?['id'] ?? widget.shopId,
      shopName: _shop?['name']?.toString() ?? 'Shop',
      images: imageUrl.isNotEmpty ? [imageUrl] : [],
      stockQuantity: stockQuantity,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Whole row opens the product; the ADD control still wins its own taps
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          _showProductDetails(productModel, weightDisplay, originalPrice),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                _showProductDetails(productModel, weightDisplay, originalPrice),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 84,
                height: 84,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.inventory_2,
                              size: 24, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.inventory_2,
                            size: 24, color: Colors.grey),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  languageProvider.getText(
                      'Stock $stockQuantity', 'இருப்பு $stockQuantity'),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '₹${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: VillageTheme.primaryGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 4),
                      Text(
                        '₹${originalPrice.toStringAsFixed(originalPrice == originalPrice.roundToDouble() ? 0 : 2)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
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
          SizedBox(
            width: 92,
            child: _buildListCartControl(productModel, isInStock),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildListCartControl(ProductModel productModel, bool isInStock) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartQuantity = cartProvider.getQuantity(productModel.id);

        if (!isInStock) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              languageProvider.getText('Out of Stock', 'இருப்பு இல்லை'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          );
        }

        if (cartQuantity == 0) {
          return GestureDetector(
            onTap: () async {
              await _handleAddToCart(context, cartProvider, productModel);
              if (mounted) setState(() {});
            },
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 2),
                  Text(
                    languageProvider.getText('ADD', 'சேர்'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 30,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  cartProvider.decreaseQuantity(productModel.id);
                  if (mounted) setState(() {});
                },
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: Icon(Icons.remove, color: Colors.white, size: 14),
                ),
              ),
              Text(
                '$cartQuantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              InkWell(
                onTap: () async {
                  await _handleAddToCart(context, cartProvider, productModel);
                  if (mounted) setState(() {});
                },
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    if (_isLoadingProducts) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: VillageTheme.primaryGreen,
                ),
                const SizedBox(height: 14),
                Text(
                  Provider.of<LanguageProvider>(context).getText(
                      'Loading products...', 'பொருட்கள் ஏற்றப்படுகின்றன...'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Catalog still streaming in — a search/filter may simply not have its
    // items yet, so show progress instead of a wrong "No Products Found"
    if (_products.isEmpty && !_catalogFullyLoaded) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: VillageTheme.primaryGreen,
                ),
                const SizedBox(height: 14),
                Text(
                  Provider.of<LanguageProvider>(context).getText(
                      'Loading all products...',
                      'எல்லா பொருட்களும் ஏற்றப்படுகின்றன...'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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

    // Responsive sizing: card height = image (scales with phone width) + a
    // fixed info budget, so no overflow on small or large screens.
    final itemWidth = (MediaQuery.of(context).size.width - 36) / 2;
    final cardExtent = itemWidth + 120;

    return SliverPadding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom:
            100, // Extra padding to prevent floating cart from blocking products
      ),
      sliver: _isListView
          ? SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductListTile(_products[index]),
                childCount: _products.length,
              ),
            )
          : SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: cardExtent,
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
    final description = [
      product['customDescription'],
      product['displayDescription'],
      product['description'],
      product['masterProduct']?['description'],
    ]
        .map((value) => value?.toString().trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

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

    final hasDiscount = originalPrice > price;
    final discountPercentage = hasDiscount
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;

    final productModel = ProductModel(
      id: product['id'].toString(),
      name: productName,
      description: description,
      price: price,
      category: product['masterProduct']?['category']?.toString() ?? '',
      shopId: _shop?['shopId']?.toString() ?? widget.shopId.toString(),
      shopDatabaseId: _shop?['id'] ?? widget.shopId,
      shopName: _shop?['name']?.toString() ?? 'Shop',
      images: imageUrl.isNotEmpty ? [imageUrl] : [],
      stockQuantity: stockQuantity,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Whole card opens the product; inner ADD buttons still win their taps
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          _showProductDetails(productModel, weightDisplay, originalPrice),
      child: Container(
      // Old design: flat soft-grey card on a white page, no drop shadow.
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with discount badge
          Expanded(
            flex: 2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showProductDetails(
                productModel,
                weightDisplay,
                originalPrice,
              ),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl:
                                  ImageUrlHelper.getFullImageUrl(imageUrl),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey[100],
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: VillageTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.inventory_2,
                                      size: 30, color: Colors.grey),
                                ),
                              ),
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
                                top: Radius.circular(16)),
                          ),
                          child: Center(
                            child: Text(
                              languageProvider.getText(
                                  'Out of Stock', 'இருப்பு இல்லை'),
                              style: const TextStyle(
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
          ),

          // Product Details — natural height (not flex-split), so long Tamil
          // names + low-stock line can never overflow; the image above
          // absorbs whatever space is left.
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        languageProvider.getText(
                            'Stock $stockQuantity', 'இருப்பு $stockQuantity'),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Price Row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '₹${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: VillageTheme.primaryGreen,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 4),
                            Text(
                              '₹${originalPrice.toStringAsFixed(originalPrice == originalPrice.roundToDouble() ? 0 : 2)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
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
                            languageProvider.getText('Only $stockQuantity left',
                                '$stockQuantity மட்டும் உள்ளது'),
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
                          child: Text(
                            languageProvider.getText(
                                'Out of Stock', 'இருப்பு இல்லை'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                        final addButton = GestureDetector(
                          onTap: () async {
                            await _handleAddToCart(
                                context, cartProvider, productModel);
                            if (mounted) setState(() {});
                          },
                          child: Container(
                            width: double.infinity,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  languageProvider.getText('ADD', 'சேர்'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        // The one-time tour highlights the first card's ADD
                        final isFirstProduct = _products.isNotEmpty &&
                            identical(product, _products[0]);
                        if (!isFirstProduct) return addButton;
                        return Showcase(
                          key: _tourAddKey,
                          title: languageProvider.getText(
                              'Add to Cart', 'கார்ட்டில் சேர்'),
                          description: languageProvider.getText(
                              'Tap ADD to put this item in your cart. Then use − and + to change the quantity.',
                              'ADD தட்டி பொருளை கார்ட்டில் சேருங்கள். பிறகு − / + மூலம் எண்ணிக்கையை மாற்றலாம்.'),
                          tooltipBackgroundColor: Colors.white,
                          textColor: Colors.grey.shade800,
                          titleTextStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.primaryGreen,
                          ),
                          descTextStyle:
                              const TextStyle(fontSize: 12, height: 1.5),
                          // Otherwise the tour overlay swallows the tap and
                          // just advances instead of adding the item
                          onTargetClick: () async {
                            await _handleAddToCart(
                                context, cartProvider, productModel);
                            if (mounted) setState(() {});
                          },
                          disposeOnTap: true,
                          child: addButton,
                        );
                      }

                      return Center(
                        child: Container(
                          height: 30,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
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
                                    if (mounted) setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(13),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.remove,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 26),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$cartQuantity',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    await _handleAddToCart(
                                        context, cartProvider, productModel);
                                    if (mounted) setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(13),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.add,
                                        color: Colors.white, size: 16),
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
        ],
      ),
      ),
    );
  }

  void _showProductDetails(
    ProductModel product,
    String weightDisplay,
    double originalPrice,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            final quantity = cartProvider.getQuantity(product.id);
            final hasDiscount = originalPrice > product.price;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.82,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (product.images.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: ImageUrlHelper.getFullImageUrl(
                              product.images.first,
                            ),
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Container(
                              height: 220,
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.inventory_2,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        weightDisplay,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            Helpers.formatCurrency(product.price),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryGreen,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 10),
                            Text(
                              Helpers.formatCurrency(originalPrice),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Product details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'No description available for this product.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (!product.isInStock)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Out of Stock',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      else if (quantity == 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final added = await _addFromProductDetails(
                                sheetContext,
                                cartProvider,
                                product,
                              );
                              if (added && sheetContext.mounted) {
                                setModalState(() {});
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('ADD'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VillageTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filled(
                              onPressed: () {
                                cartProvider.decreaseQuantity(product.id);
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.remove),
                              style: IconButton.styleFrom(
                                backgroundColor: VillageTheme.primaryGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton.filled(
                              onPressed: quantity >= product.stockQuantity
                                  ? null
                                  : () async {
                                      final added =
                                          await _addFromProductDetails(
                                        sheetContext,
                                        cartProvider,
                                        product,
                                      );
                                      if (added && sheetContext.mounted) {
                                        setModalState(() {});
                                      }
                                    },
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: VillageTheme.primaryGreen,
                                foregroundColor: Colors.white,
                              ),
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
      ),
    );
  }

  Future<bool> _addFromProductDetails(
    BuildContext sheetContext,
    CartProvider cartProvider,
    ProductModel product,
  ) async {
    final success = await cartProvider.addToCart(product);
    if (success) {
      cartProvider.setShopStatus(
        isOpen: _isShopOpen,
        shopName: _shop?['name'],
        minOrderAmount: (_shop?['minOrderAmount'] as num?)?.toDouble(),
      );
      return true;
    }

    if (!sheetContext.mounted) return false;

    final currentShopName = cartProvider.getCurrentShopName();
    if (currentShopName != null && cartProvider.items.isNotEmpty) {
      final replaceCart = await showDialog<bool>(
        context: sheetContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Different Shop'),
          content: Text(
            'Your cart contains items from "$currentShopName".\n\n'
            'Clear the cart and add this product from "${product.shopName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: VillageTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Cart & Add'),
            ),
          ],
        ),
      );

      if (replaceCart == true) {
        cartProvider.clearCart();
        final added = await cartProvider.addToCart(
          product,
          clearCartConfirmed: true,
        );
        cartProvider.setShopStatus(
          isOpen: _isShopOpen,
          shopName: _shop?['name'],
          minOrderAmount: (_shop?['minOrderAmount'] as num?)?.toDouble(),
        );
        return added;
      }
      return false;
    }

    ScaffoldMessenger.of(sheetContext).showSnackBar(
      SnackBar(
        content: Text('Only ${product.stockQuantity} available'),
        backgroundColor: Colors.orange,
      ),
    );
    return false;
  }

  Future<void> _handleAddToCart(BuildContext context, CartProvider cartProvider,
      ProductModel product) async {
    // Allow adding to cart even when shop is closed
    // Order placement will be blocked at checkout screen

    // Check stock availability before adding
    final currentCartQuantity = cartProvider.getQuantity(product.id);
    final availableStock = product.stockQuantity;

    if (currentCartQuantity >= availableStock) {
      // Stock limit reached — refresh products to get real stock
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only $availableStock available'),
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
        minOrderAmount: (_shop?['minOrderAmount'] as num?)?.toDouble(),
      );

      // First ADD of this product (not stepper +): suggest same-category
      // products the customer may also need. They can add or just dismiss.
      if (currentCartQuantity == 0 && context.mounted) {
        _showRelatedProducts(product);
      }
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
          final addedSuccess =
              await cartProvider.addToCart(product, clearCartConfirmed: true);
          if (addedSuccess) {
            // Store shop open status for new shop
            cartProvider.setShopStatus(
              isOpen: _isShopOpen,
              shopName: _shop?['name'],
              minOrderAmount: (_shop?['minOrderAmount'] as num?)?.toDouble(),
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

  /// Bottom sheet with in-stock products from the same category as the one
  /// just added — quick extra ADDs without leaving the flow. Uses the
  /// already-loaded product list, so no API call.
  void _showRelatedProducts(ProductModel added) {
    dynamic raw;
    for (final p in _allProducts) {
      if (p['id'].toString() == added.id) {
        raw = p;
        break;
      }
    }
    final categoryName =
        raw?['masterProduct']?['category']?['name']?.toString();
    if (categoryName == null || categoryName.isEmpty) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    final candidates = _allProducts.where((p) {
      if (p['id'].toString() == added.id) return false;
      final cat = p['masterProduct']?['category']?['name']?.toString();
      if (cat == null || cat.toLowerCase() != categoryName.toLowerCase()) {
        return false;
      }
      final stock = int.tryParse(p['stockQuantity']?.toString() ?? '0') ?? 0;
      if (stock <= 0) return false;
      return cartProvider.getQuantity(p['id'].toString()) == 0;
    }).toList();
    if (candidates.isEmpty) return;

    // Categories can be broad ("Grocery"), so rank inside the category:
    // shared name words (English + Tamil) rank highest, plus a small bonus
    // for a similar price range. Ties keep the original catalog order.
    Set<String> tokensOf(dynamic p) => [
          p?['customName']?.toString(),
          p?['masterProduct']?['name']?.toString(),
          p?['masterProduct']?['nameTamil']?.toString(),
        ]
            .whereType<String>()
            .join(' ')
            .toLowerCase()
            .split(RegExp(r'[^a-z0-9஀-௿]+'))
            .where((t) => t.length >= 3)
            .toSet();

    final addedTokens = tokensOf(raw)
      ..addAll(tokensOf({'customName': added.name}));
    final addedPrice = double.tryParse(raw?['price']?.toString() ?? '') ?? 0.0;

    int relevance(dynamic p) {
      var score = 0;
      final tokens = tokensOf(p);
      for (final t in addedTokens) {
        if (tokens.contains(t)) score += 3;
      }
      final price = double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
      if (addedPrice > 0 && price > 0) {
        final ratio = price / addedPrice;
        if (ratio >= 0.5 && ratio <= 2.0) score += 1;
      }
      return score;
    }

    final ranked = List.generate(
        candidates.length, (i) => MapEntry(i, relevance(candidates[i])))
      ..sort((a, b) => b.value != a.value ? b.value - a.value : a.key - b.key);
    // A name-word match scores >= 3. Show ONLY name-matched products —
    // padding with random same-category items reads as "completely wrong",
    // so with no real match the sheet is skipped entirely.
    final related = ranked
        .where((e) => e.value >= 3)
        .take(8)
        .map((e) => candidates[e.key])
        .toList();
    if (related.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    languageProvider.getText(
                        'You may also need', 'இதுவும் வேண்டுமா?'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 195,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: related.length,
                    itemBuilder: (context, index) {
                      final p = related[index];
                      final name = languageProvider.getDisplayName(p);
                      final price =
                          double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
                      final stock =
                          int.tryParse(p['stockQuantity']?.toString() ?? '0') ??
                              0;
                      final imageUrl = p['primaryImageUrl']?.toString() ??
                          p['masterProduct']?['primaryImageUrl']?.toString() ??
                          '';
                      final originalPrice = double.tryParse(
                              p['originalPrice']?.toString() ?? '0') ??
                          0.0;
                      final baseWeight = p['baseWeight'] ??
                          p['masterProduct']?['baseWeight'] ??
                          1;
                      final baseUnit = p['baseUnit']?.toString() ??
                          p['masterProduct']?['baseUnit']?.toString() ??
                          'unit';
                      final description = [
                        p['customDescription'],
                        p['displayDescription'],
                        p['description'],
                        p['masterProduct']?['description'],
                      ]
                          .map((value) => value?.toString().trim() ?? '')
                          .firstWhere((value) => value.isNotEmpty,
                              orElse: () => '');
                      final model = ProductModel(
                        id: p['id'].toString(),
                        name: name,
                        description: description,
                        price: price,
                        category: categoryName,
                        shopId: _shop?['shopId']?.toString() ??
                            widget.shopId.toString(),
                        shopDatabaseId: _shop?['id'] ?? widget.shopId,
                        shopName: _shop?['name']?.toString() ?? 'Shop',
                        images: imageUrl.isNotEmpty ? [imageUrl] : [],
                        stockQuantity: stock,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      final cartQuantity = cartProvider.getQuantity(model.id);
                      return Container(
                        width: 124,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFF1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                Navigator.of(sheetContext).pop();
                                await Future<void>.delayed(
                                    const Duration(milliseconds: 250));
                                if (mounted) {
                                  _showProductDetails(
                                    model,
                                    '$baseWeight $baseUnit',
                                    originalPrice,
                                  );
                                }
                              },
                              child: Container(
                                height: 72,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl:
                                              ImageUrlHelper.getFullImageUrl(
                                                  imageUrl),
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              const Icon(Icons.inventory_2,
                                                  color: Colors.grey),
                                        )
                                      : const Icon(Icons.inventory_2,
                                          color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '₹${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: VillageTheme.primaryGreen,
                              ),
                            ),
                            const Spacer(),
                            if (cartQuantity == 0)
                              GestureDetector(
                                onTap: () async {
                                  await cartProvider.addToCart(model);
                                  if (sheetContext.mounted) {
                                    setSheetState(() {});
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: VillageTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_rounded,
                                          color: Colors.white, size: 14),
                                      Text(
                                        'ADD',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 26,
                                decoration: BoxDecoration(
                                  color: VillageTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        cartProvider.decreaseQuantity(model.id);
                                        setSheetState(() {});
                                      },
                                      borderRadius: BorderRadius.circular(13),
                                      child: const SizedBox(
                                        width: 30,
                                        height: 26,
                                        child: Icon(Icons.remove,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                    Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 24),
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$cartQuantity',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        if (cartQuantity >= stock) {
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(SnackBar(
                                              content:
                                                  Text('Only $stock available'),
                                              backgroundColor: Colors.orange,
                                              duration:
                                                  const Duration(seconds: 2),
                                            ));
                                          return;
                                        }
                                        await cartProvider.addToCart(model);
                                        if (sheetContext.mounted) {
                                          setSheetState(() {});
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(13),
                                      child: const SizedBox(
                                        width: 30,
                                        height: 26,
                                        child: Icon(Icons.add,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showVoiceSearchDialog() {
    // Navigate to interactive Voice Assistant
    final shopName =
        _shop?['name']?.toString() ?? widget.shop?['name']?.toString();
    context.push('/customer/voice-assistant', extra: {
      'shopId': widget.shopId,
      'shopName': shopName,
    });
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
  State<_ComboCardWithSlideshow> createState() =>
      _ComboCardWithSlideshowState();
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
      _productImages
          .add(ImageUrlHelper.getFullImageUrl(widget.combo.bannerImageUrl));
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
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  // Product Image Slideshow
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
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
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                  child: Icon(Icons.card_giftcard,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 40),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(Icons.card_giftcard,
                                color: Colors.white.withOpacity(0.5), size: 40),
                          ),
                  ),
                  // Discount Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('View',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
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
