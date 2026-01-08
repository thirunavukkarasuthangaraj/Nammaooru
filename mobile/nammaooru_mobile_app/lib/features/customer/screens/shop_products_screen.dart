import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/shop_api_service.dart';
import '../../../services/voice_search_service.dart';
import '../../../core/config/env_config.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/helpers.dart';

class ShopProductsScreen extends StatefulWidget {
  final String shopId;
  final String categoryName;
  final String? categoryId;

  const ShopProductsScreen({
    super.key,
    required this.shopId,
    required this.categoryName,
    this.categoryId,
  });

  @override
  State<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends State<ShopProductsScreen> {
  late String _selectedCategory;
  late String? _selectedCategoryId;
  late ScrollController _scrollController;

  // Pagination state
  int _currentPage = 0;
  int _pageSize = 2000; // Load all products at once
  bool _isLoading = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _products = [];

  // Categories list (loaded from API)
  List<Map<String, dynamic>> _categories = [];
  bool _categoriesLoading = true;

  // Track quantities for each product
  final Map<String, int> _productQuantities = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Set initial category
    _selectedCategory = widget.categoryName;
    _selectedCategoryId = widget.categoryId;

    // Load all products at once
    _pageSize = 2000;

    // Load categories from API
    _loadCategories();

    // Load initial products
    _loadProducts();

    // Initialize quantities from cart
    _initializeQuantitiesFromCart();
  }

  @override
  void dispose() {
    _voiceSearchOverlay?.remove();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      // TODO: Replace with actual category API endpoint
      // For now, you can use mock data or connect to your backend
      // Example: GET /api/categories or GET /api/shops/{shopId}/categories

      // Placeholder: Add 'All' category at the beginning
      setState(() {
        _categories = [
          {
            'id': null,
            'name': 'All',
            'imageUrl':
                'https://images.unsplash.com/photo-1543168256-8133d1f3d731?w=400'
          },
        ];
        _categoriesLoading = false;
      });

      // TODO: Uncomment and update when category API is available
      // final baseUrl = '${EnvConfig.apiBaseUrl}/api/categories';
      // final response = await http.get(Uri.parse(baseUrl));
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   final categories = List<Map<String, dynamic>>.from(data['data'] ?? []);
      //
      //   setState(() {
      //     _categories = [
      //       {'id': null, 'name': 'All', 'imageUrl': ''},
      //       ...categories,
      //     ];
      //     _categoriesLoading = false;
      //   });
      // }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _categoriesLoading = false);
    }
  }

  void _onScroll() {
    // Only trigger when scrolling vertically near the bottom
    if (!_scrollController.hasClients) return;

    final pixels = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // Trigger pagination when reaching 90% of scroll (closer to bottom)
    if (pixels >= maxScroll * 0.9 && _hasMore && !_isLoading) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final baseUrl =
          '${EnvConfig.fullApiUrl}/customer/shops/${widget.shopId}/products';
      final Map<String, String> queryParams = {
        'page': '0',
        'size': _pageSize.toString(),
      };
      if (_selectedCategory != null && _selectedCategory != 'All') {
        queryParams['category'] = _selectedCategory;
      }
      final uri =
          Uri.parse(baseUrl).replace(queryParameters: queryParams).toString();

      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _products =
              List<Map<String, dynamic>>.from(data['data']['content'] ?? []);
          _hasMore = !(data['data']['last'] ?? true);
          _currentPage = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    print(
        '📥 _loadMoreProducts called! _isLoading=$_isLoading, _hasMore=$_hasMore');
    if (_isLoading || !_hasMore) {
      print('📥 Returning early: _isLoading=$_isLoading, _hasMore=$_hasMore');
      return;
    }

    print('📥 Setting _isLoading=true');
    setState(() => _isLoading = true);

    try {
      _currentPage++;
      print('📥 Loading page $_currentPage with size $_pageSize');
      final baseUrl =
          '${EnvConfig.fullApiUrl}/customer/shops/${widget.shopId}/products';
      final Map<String, String> queryParams = {
        'page': _currentPage.toString(),
        'size': _pageSize.toString(),
      };
      if (_selectedCategory != null && _selectedCategory != 'All') {
        queryParams['category'] = _selectedCategory;
      }
      final uri =
          Uri.parse(baseUrl).replace(queryParameters: queryParams).toString();
      print('📥 Fetching URI: $uri');

      final response = await http.get(Uri.parse(uri));
      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newProducts =
            List<Map<String, dynamic>>.from(data['data']['content'] ?? []);
        final isLast = data['data']['last'] ?? true;
        print('📥 Loaded ${newProducts.length} products. isLast=$isLast');
        setState(() {
          _products.addAll(newProducts);
          _hasMore = !isLast;
          _isLoading = false;
          print('📥 Total products now: ${_products.length}');
        });
      }
    } catch (e) {
      print('❌ Error loading more products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCategory(String? categoryId, String categoryName) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategory = categoryName;
      _pageSize = categoryId != null ? 20 : 10; // Smart sizing
      _currentPage = 0;
      _products = [];
      _isLoading = true;
    });

    await _loadProducts();
  }

  void _initializeQuantitiesFromCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    for (var item in cartProvider.items) {
      final productId = item.product.id.toString();
      _productQuantities[productId] = item.quantity;
    }
  }

  void _updateQuantity(String productId, int change, int maxStock) {
    setState(() {
      int currentQty = _productQuantities[productId] ?? 0;
      int newQty = currentQty + change;

      if (newQty >= 0 && newQty <= maxStock) {
        if (newQty == 0) {
          _productQuantities.remove(productId);
        } else {
          _productQuantities[productId] = newQty;
        }
      } else if (newQty > maxStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('${_selectedCategory} Products',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(color: Colors.white),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => context.push('/customer/cart'),
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // ============================================
          // FIXED HEADER (Search + Voice + Categories)
          // ============================================
          Container(
            color: Colors.white,
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SEARCH BOX
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),

                // VOICE SEARCH BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap: () => _showVoiceSearchDialog(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.mic, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Voice Search',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // CATEGORY FILTERS (Horizontal Scroll)
                // const SizedBox(height: 12),
                // SizedBox(
                //   height: 50,
                //   child: _categoriesLoading
                //       ? const Center(child: SizedBox(
                //           width: 30,
                //           height: 30,
                //           child: CircularProgressIndicator(strokeWidth: 2),
                //         ))
                //       : _categories.isEmpty
                //           ? Center(child: Text('No categories', style: TextStyle(color: Colors.grey[500])))
                //           : ListView.builder(
                //             scrollDirection: Axis.horizontal,
                //             padding: const EdgeInsets.symmetric(horizontal: 12),
                //             itemCount: _categories.length,
                //             itemBuilder: (context, index) {
                //               final category = _categories[index];
                //               final isSelected = _selectedCategoryId == category['id'];
                //
                //               return Padding(
                //                 padding: const EdgeInsets.only(right: 8),
                //                 child: GestureDetector(
                //                   onTap: () => _selectCategory(category['id'], category['name']),
                //                   child: Chip(
                //                     label: Text(category['name']),
                //                     backgroundColor: isSelected ? Colors.green : Colors.grey[300],
                //                     labelStyle: TextStyle(
                //                       color: isSelected ? Colors.white : Colors.black,
                //                       fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                //                     ),
                //                   ),
                //                 ),
                //               );
                //             },
                //           ),
                // ),
                // const SizedBox(height: 8),~
              ],
            ),
          ),

          // ============================================
          // SCROLLABLE AREA (ONLY Products + Banner)
          // ============================================
          Expanded(
            child: _isLoading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      // BANNER (hides on scroll)
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green, Colors.green[700]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer,
                                  color: Colors.white, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Special Offers Today',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // PRODUCTS GRID
                      if (_products.isEmpty && !_isLoading)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text('No products available',
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            final productId = product['id'].toString();
                            final quantity = _productQuantities[productId] ?? 0;
                            final stock = product['stockQuantity'] as int? ?? 0;
                            final isOutOfStock = stock == 0;
                            final isLowStock = stock > 0 && stock <= 5;

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image Area with Stock Badge
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(8)),
                                          child: Image.network(
                                            product['primaryImageUrl'] !=
                                                        null &&
                                                    product['primaryImageUrl']
                                                        .toString()
                                                        .isNotEmpty
                                                ? (product['primaryImageUrl']
                                                        .toString()
                                                        .startsWith('http')
                                                    ? product['primaryImageUrl']
                                                    : '${EnvConfig.baseUrl}${product['primaryImageUrl']}')
                                                : '',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              decoration: BoxDecoration(
                                                color: isOutOfStock
                                                    ? Colors.grey[300]
                                                    : Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top:
                                                            Radius.circular(8)),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  _getCategoryIcon(
                                                      product['category']),
                                                  size: 40,
                                                  color: isOutOfStock
                                                      ? Colors.grey[500]
                                                      : Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Stock Badge
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isOutOfStock
                                                  ? Colors.red
                                                  : isLowStock
                                                      ? Colors.orange
                                                      : Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isOutOfStock
                                                  ? 'Out of Stock'
                                                  : isLowStock
                                                      ? 'Only $stock left'
                                                      : '$stock in stock',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Product Details
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['displayName'] ??
                                                product['name'] ??
                                                'Product',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isOutOfStock
                                                  ? Colors.grey
                                                  : Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            product['unit'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${product['price'] ?? 0}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isOutOfStock
                                                  ? Colors.grey
                                                  : Colors.green,
                                            ),
                                          ),
                                          const Spacer(),

                                          // Quantity Selector or Add Button
                                          if (isOutOfStock)
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'OUT OF STOCK',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          else if (quantity > 0)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.green
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: Colors.green),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  InkWell(
                                                    onTap: () =>
                                                        _updateQuantity(
                                                            productId,
                                                            -1,
                                                            stock),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      child: const Icon(
                                                          Icons.remove,
                                                          color: Colors.green,
                                                          size: 18),
                                                    ),
                                                  ),
                                                  Column(
                                                    children: [
                                                      Text(
                                                        '$quantity',
                                                        style: const TextStyle(
                                                          color: Colors.green,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (quantity == stock)
                                                        const Text(
                                                          'Max',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.orange,
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  InkWell(
                                                    onTap: () =>
                                                        _updateQuantity(
                                                            productId,
                                                            1,
                                                            stock),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      child: Icon(
                                                        Icons.add,
                                                        color: quantity < stock
                                                            ? Colors.green
                                                            : Colors.grey,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            InkWell(
                                              onTap: () => _updateQuantity(
                                                  productId, 1, stock),
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'ADD',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
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
                      // LOADING INDICATOR (bottom for infinite scroll)
                      if (_isLoading && _products.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Loading more...',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),

                      // NO MORE PRODUCTS
                      if (!_hasMore && _products.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'No more products',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),

      // Floating Cart Summary
      bottomNavigationBar: cartProvider.itemCount > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cartProvider.itemCount} items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(cartProvider.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/customer/cart');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'View Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  OverlayEntry? _voiceSearchOverlay;

  void _showVoiceSearchDialog() {
    // Remove existing overlay if any
    _voiceSearchOverlay?.remove();

    // Create overlay entry
    _voiceSearchOverlay = OverlayEntry(
      builder: (context) => VoiceSearchDialog(
        shopId: widget.shopId,
        onProductSelected: (product) {
          // Add product to cart
          _updateQuantity(
              product['id'].toString(), 1, product['stockQuantity'] ?? 0);

          // Show confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${product['displayName']} to cart'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onClose: () {
          // Remove overlay when close button is clicked
          _voiceSearchOverlay?.remove();
          _voiceSearchOverlay = null;
        },
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(_voiceSearchOverlay!);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Grocery':
        return Icons.shopping_basket;
      case 'Medicine':
        return Icons.medical_services;
      case 'Dairy':
        return Icons.egg;
      case 'Snacks':
        return Icons.cookie;
      case 'All':
        return Icons.apps;
      default:
        return Icons.category;
    }
  }
}

// ============================================
// VOICE SEARCH DIALOG WIDGET
// ============================================
class VoiceSearchDialog extends StatefulWidget {
  final String shopId;
  final Function(Map<String, dynamic>) onProductSelected;
  final VoidCallback onClose;

  const VoiceSearchDialog({
    Key? key,
    required this.shopId,
    required this.onProductSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog> {
  final VoiceSearchService _voiceService = VoiceSearchService();
  List<Map<String, dynamic>> _voiceSearchResults = [];
  bool _isListening = false;
  bool _isSearching = false;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    // Auto-start voice listening when dialog opens
    _startVoiceListening();
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startVoiceListening() async {
    setState(() => _isListening = true);

    final spokenText = await _voiceService.listen();

    setState(() {
      _isListening = false;
      _spokenText = spokenText ?? '';
    });

    if (spokenText != null && spokenText.isNotEmpty) {
      await _performVoiceSearch(spokenText);
    }
  }

  Future<void> _performVoiceSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final baseUrl =
          '${EnvConfig.baseUrl}/api/v1/products/search/voice/grouped';
      final uri =
          Uri.parse(baseUrl).replace(queryParameters: {'q': query}).toString();

      final response = await http.post(Uri.parse(uri));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final groupedResults =
            List<Map<String, dynamic>>.from(data['data'] ?? []);

        // Flatten grouped results into single list
        List<Map<String, dynamic>> allProducts = [];
        for (var group in groupedResults) {
          if (group['products'] != null) {
            allProducts
                .addAll(List<Map<String, dynamic>>.from(group['products']));
          }
        }

        setState(() {
          _voiceSearchResults = allProducts;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Voice search error: $e');
      setState(() => _isSearching = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () {}, // Absorb all taps on the background
        child: Container(
          color: Colors.black87,
          child: SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: widget.onClose,
                  ),
                ),

                const Spacer(),

                // Listening state or results
                if (_isListening) ...[
                  // Listening animation
                  const Text(
                    'Listening...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Animated microphone
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _spokenText.isEmpty ? 'Speak now...' : _spokenText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_isSearching) ...[
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Searching products...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ] else if (_voiceSearchResults.isNotEmpty) ...[
                  // Results list
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {}, // Absorb taps to prevent dismissal
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.search, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _spokenText,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.mic,
                                        color: Colors.red),
                                    onPressed: _startVoiceListening,
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _voiceSearchResults.length,
                                itemBuilder: (context, index) {
                                  final product = _voiceSearchResults[index];
                                  final stock =
                                      product['stockQuantity'] as int? ?? 0;
                                  final isOutOfStock = stock == 0;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isOutOfStock
                                            ? Colors.grey[300]!
                                            : Colors.blue[200]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: isOutOfStock
                                          ? Colors.grey[100]
                                          : Colors.blue[50],
                                    ),
                                    child: Row(
                                      children: [
                                        // Product Image
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: product['primaryImageUrl'] !=
                                                    null
                                                ? Image.network(
                                                    product['primaryImageUrl'],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        Icon(Icons.shopping_bag,
                                                            color: Colors
                                                                .grey[500]),
                                                  )
                                                : Icon(Icons.shopping_bag,
                                                    color: Colors.grey[500]),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Product Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['displayName'] ??
                                                    product['name'] ??
                                                    'Product',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '₹${product['price'] ?? 0}',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (isOutOfStock)
                                                const Text(
                                                  'Out of Stock',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 12),
                                                )
                                              else
                                                Text(
                                                  '$stock in stock',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Add Button
                                        if (!isOutOfStock)
                                          IconButton(
                                            icon: const Icon(Icons.add_circle,
                                                color: Colors.blue, size: 28),
                                            onPressed: () {
                                              widget.onProductSelected(product);
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // No results state
                  const Text(
                    'No products found',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _startVoiceListening,
                    icon: const Icon(Icons.mic),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                  ),
                ],

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
