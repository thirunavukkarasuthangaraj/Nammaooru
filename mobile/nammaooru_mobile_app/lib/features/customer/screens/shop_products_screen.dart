import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/shop_api_service.dart';
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
  int _pageSize = 10; // Default for general browsing
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

    // Adjust page size based on category selection
    _pageSize = _selectedCategoryId != null ? 20 : 10;

    // Load categories from API
    _loadCategories();

    // Load initial products
    _loadProducts();

    // Initialize quantities from cart
    _initializeQuantitiesFromCart();
  }

  @override
  void dispose() {
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
          {'id': null, 'name': 'All', 'imageUrl': 'https://images.unsplash.com/photo-1543168256-8133d1f3d731?w=400'},
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (_hasMore && !_isLoading) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final baseUrl = '${EnvConfig.apiBaseUrl}/api/shops/${widget.shopId}/products/mobile-list';
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'page': '0',
        'categoryId': _selectedCategoryId,
        'size': _pageSize.toString(),
      }).toString();

      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _products = List<Map<String, dynamic>>.from(data['data']['products'] ?? []);
          _hasMore = data['data']['hasNext'] ?? false;
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
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      _currentPage++;
      final baseUrl = '${EnvConfig.apiBaseUrl}/api/shops/${widget.shopId}/products/mobile-list';
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'page': _currentPage.toString(),
        'categoryId': _selectedCategoryId,
        'size': _pageSize.toString(),
      }).toString();

      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _products.addAll(List<Map<String, dynamic>>.from(data['data']['products'] ?? []));
          _hasMore = data['data']['hasNext'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading more products: $e');
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
        title: Text('${_selectedCategory} Products', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                onPressed: () => Navigator.pushNamed(context, '/cart'),
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
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ============================================
          // FIXED HEADER (Search + Voice + Categories)
          // ============================================
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // SEARCH BOX
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                // VOICE SEARCH BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap: () => _showVoiceSearchDialog(),
                    child: Container(
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
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // CATEGORY FILTERS (Horizontal Scroll)
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: _categoriesLoading
                      ? const Center(child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                      : _categories.isEmpty
                          ? Center(child: Text('No categories', style: TextStyle(color: Colors.grey[500])))
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategoryId == category['id'];

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _selectCategory(category['id'], category['name']),
                                  child: Chip(
                                    label: Text(category['name']),
                                    backgroundColor: isSelected ? Colors.green : Colors.grey[300],
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ============================================
          // SCROLLABLE AREA (ONLY Products + Banner)
          // ============================================
          Expanded(
            child: _isLoading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollEndNotification) {
                        double pixels = scrollNotification.metrics.pixels;
                        double maxScroll = scrollNotification.metrics.maxScrollExtent;

                        // Load more when 80% scrolled
                        if (pixels > maxScroll * 0.8 && _hasMore && !_isLoading) {
                          _loadMoreProducts();
                        }
                      }
                      return false;
                    },
                    child: ListView(
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
                                Icon(Icons.local_offer, color: Colors.white, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'Special Offers Today',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
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
                              child: Text('No products available', style: Theme.of(context).textTheme.titleMedium),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                          child: Image.network(
                                            product['primaryImageUrl'] != null && product['primaryImageUrl'].toString().isNotEmpty
                                                ? (product['primaryImageUrl'].toString().startsWith('http')
                                                    ? product['primaryImageUrl']
                                                    : '${EnvConfig.baseUrl}${product['primaryImageUrl']}')
                                                : '',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              decoration: BoxDecoration(
                                                color: isOutOfStock ? Colors.grey[300] : Colors.grey[200],
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  _getCategoryIcon(product['category']),
                                                  size: 40,
                                                  color: isOutOfStock ? Colors.grey[500] : Colors.grey[400],
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
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isOutOfStock ? Colors.red :
                                                    isLowStock ? Colors.orange :
                                                    Colors.green,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isOutOfStock ? 'Out of Stock' :
                                              isLowStock ? 'Only $stock left' :
                                              '$stock in stock',
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['displayName'] ?? product['name'] ?? 'Product',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isOutOfStock ? Colors.grey : Colors.black,
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
                                              color: isOutOfStock ? Colors.grey : Colors.green,
                                            ),
                                          ),
                                          const Spacer(),

                                          // Quantity Selector or Add Button
                                          if (isOutOfStock)
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(4),
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
                                                color: Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.green),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  InkWell(
                                                    onTap: () => _updateQuantity(productId, -1, stock),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      child: const Icon(Icons.remove, color: Colors.green, size: 18),
                                                    ),
                                                  ),
                                                  Column(
                                                    children: [
                                                      Text(
                                                        '$quantity',
                                                        style: const TextStyle(
                                                          color: Colors.green,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (quantity == stock)
                                                        const Text(
                                                          'Max',
                                                          style: TextStyle(
                                                            color: Colors.orange,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  InkWell(
                                                    onTap: () => _updateQuantity(productId, 1, stock),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      child: Icon(
                                                        Icons.add,
                                                        color: quantity < stock ? Colors.green : Colors.grey,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            InkWell(
                                              onTap: () => _updateQuantity(productId, 1, stock),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius: BorderRadius.circular(4),
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
                              Text('Loading more...', style: TextStyle(color: Colors.grey)),
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
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
                        Navigator.pushNamed(context, '/cart');
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
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
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

  void _showVoiceSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return VoiceSearchDialog(
          shopId: widget.shopId,
          onProductSelected: (product) {
            // Close dialog when product is selected
            Navigator.pop(context);

            // Optionally add product to cart
            _updateQuantity(product['id'].toString(), 1, product['stockQuantity'] ?? 0);

            // Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${product['displayName']} to cart'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
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

  const VoiceSearchDialog({
    Key? key,
    required this.shopId,
    required this.onProductSelected,
  }) : super(key: key);

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _voiceSearchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performVoiceSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final baseUrl = '${EnvConfig.apiBaseUrl}/api/v1/products/search/voice/grouped';
      final uri = Uri.parse(baseUrl).replace(queryParameters: {'q': query}).toString();

      final response = await http.post(Uri.parse(uri));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final groupedResults = List<Map<String, dynamic>>.from(data['data'] ?? []);

        // Flatten grouped results into single list
        List<Map<String, dynamic>> allProducts = [];
        for (var group in groupedResults) {
          if (group['products'] != null) {
            allProducts.addAll(List<Map<String, dynamic>>.from(group['products']));
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
    return Dialog(
      insetPadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Row(
              children: [
                Icon(Icons.mic, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Voice Search',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Search Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products (e.g., rice, tomato, oil)',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _voiceSearchResults = []);
                        },
                        child: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: (value) => _performVoiceSearch(value),
            ),
          ),

          // Search Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _performVoiceSearch(_searchController.text),
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _voiceSearchResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Enter search query to find products'
                                : 'No products found',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _voiceSearchResults.length,
                        itemBuilder: (context, index) {
                          final product = _voiceSearchResults[index];
                          final stock = product['stockQuantity'] as int? ?? 0;
                          final isOutOfStock = stock == 0;

                          return GestureDetector(
                            onTap: isOutOfStock ? null : () => widget.onProductSelected(product),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isOutOfStock ? Colors.grey[300]! : Colors.blue[200]!,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isOutOfStock ? Colors.grey[100] : Colors.blue[50],
                              ),
                              child: Row(
                                children: [
                                  // Product Image
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: product['primaryImageUrl'] != null
                                          ? Image.network(
                                              product['primaryImageUrl'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Icon(Icons.shopping_bag, color: Colors.grey[500]),
                                            )
                                          : Icon(Icons.shopping_bag, color: Colors.grey[500]),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Product Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['displayName'] ?? product['name'] ?? 'Product',
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
                                            style: TextStyle(color: Colors.red, fontSize: 12),
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
                                    Icon(Icons.add_circle, color: Colors.blue, size: 24),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}