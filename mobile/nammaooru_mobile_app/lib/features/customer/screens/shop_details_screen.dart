import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../services/shop_api_service.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/image_url_helper.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _shop;
  List<dynamic> _products = [];
  List<dynamic> _allProducts =
      []; // Store all products for client-side filtering
  List<dynamic> _categories = [];
  String? _selectedCategory;
  String? _selectedCategoryName; // Store category name for filtering
  bool _isLoadingShop = false;
  bool _isLoadingProducts = false;
  bool _isLoadingCategories = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
    _loadShopDetails();
    _loadCategories();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadShopDetails() async {
    if (_shop != null) return;

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
        size: 100,
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
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.white, size: 22),
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Cart total - HIDDEN
                                  // if (cartProvider.isNotEmpty)
                                  //   Padding(
                                  //     padding: const EdgeInsets.only(right: 12),
                                  //     child: Text(
                                  //       '₹${cartProvider.subtotal.toStringAsFixed(0)}',
                                  //       style: const TextStyle(
                                  //         color: Colors.white,
                                  //         fontSize: 16,
                                  //         fontWeight: FontWeight.bold,
                                  //       ),
                                  //     ),
                                  //   ),
                                  // Cart icon with badge
                                  IconButton(
                                    icon: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(Icons.shopping_cart,
                                            color: Colors.white, size: 24),
                                        if (cartProvider.itemCount > 0)
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
                                                    width: 2),
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
                                    onPressed: () =>
                                        context.push('/customer/cart'),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Content area below toolbar
                    Expanded(
                      child: Row(
                        children: [
                          // LEFT SIDEBAR with categories
                          Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(
                                      3, 0), // Shadow on right side
                                ),
                              ],
                            ),
                            child: _buildCategorySidebar(),
                          ),
                          // MAIN CONTENT AREA
                          Expanded(
                            child: _buildShopDetailsContent(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          // Only show floating button when cart has items
          if (cartProvider.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                onTap: () {
                  context.go('/customer/cart');
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
        SliverToBoxAdapter(child: _buildSearchBar()),
        _buildProductGrid(),
      ],
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
          hintText: '🔍 பொருட்களைத் தேடுங்கள்',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon:
              const Icon(Icons.search, color: VillageTheme.primaryGreen),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
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
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62, // Further reduced for better vertical spacing
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildProductCard(_products[index]),
          childCount: _products.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // Get display name from customName or displayName or master product name
    final productName = product['customName']?.toString() ??
        product['displayName']?.toString() ??
        product['masterProduct']?['name']?.toString() ??
        'Product';

    // Get description
    final description = product['customDescription']?.toString() ??
        product['displayDescription']?.toString() ??
        product['masterProduct']?['description']?.toString() ??
        '';

    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final originalPrice =
        double.tryParse(product['originalPrice']?.toString() ?? '0') ?? 0.0;
    final isInStock = product['inStock'] ?? true;
    final stockQuantity =
        int.tryParse(product['stockQuantity']?.toString() ?? '0') ?? 0;
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
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
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
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                          height: 1.1,
                        ),
                        maxLines: 2,
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
      // Successfully added to cart
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
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
          await cartProvider.addToCart(product, clearCartConfirmed: true);
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
