import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/shop_api_service.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/image_url_helper.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _shop;
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  List<dynamic> _categories = [];
  String? _selectedCategory;
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
        final productName = product['customName']?.toString().toLowerCase() ??
                           product['displayName']?.toString().toLowerCase() ??
                           product['masterProduct']?['name']?.toString().toLowerCase() ?? '';
        final matchesSearch = searchTerm.isEmpty || productName.contains(searchTerm);

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
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.black87),
                          onPressed: () {
                            // Show search dialog
                            _showSearchDialog();
                          },
                        ),
                      ],
                    ),

                    // Promotional Banner
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 10,
                              bottom: 0,
                              child: Image.asset(
                                'assets/images/cashback.png',
                                height: 50,
                                errorBuilder: (context, error, stackTrace) => const SizedBox(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'GET ₹75',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'CASHBACK',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFD600),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          'Collect now',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios, size: 12),
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

                    // Categories Section
                    if (_categories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Recommended for you',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  category['icon'] ?? '📦',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category['name'] ?? '',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProductCard(Map<String, dynamic> product) {
    final productName = product['customName']?.toString() ??
                       product['displayName']?.toString() ??
                       product['masterProduct']?['name']?.toString() ??
                       'Product';

    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final originalPrice = double.tryParse(product['originalPrice']?.toString() ?? '0') ?? 0.0;
    final isInStock = product['inStock'] ?? true;
    final stockQuantity = int.tryParse(product['stockQuantity']?.toString() ?? '0') ?? 0;

    final imageUrl = product['primaryImageUrl']?.toString() ??
                    product['masterProduct']?['primaryImageUrl']?.toString() ?? '';

    final hasDiscount = originalPrice > price && originalPrice > 0;
    final discountPercentage = hasDiscount ? ((originalPrice - price) / originalPrice * 100).round() : 0;

    // Get weight and unit
    final weight = product['masterProduct']?['baseWeight'];
    final unit = product['masterProduct']?['baseUnit'] ?? '';
    final displayUnit = weight != null ? '$weight $unit' : unit.toString();

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
                          // Product Name
                          Text(
                            productName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  _onSearchChanged();
                },
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
}