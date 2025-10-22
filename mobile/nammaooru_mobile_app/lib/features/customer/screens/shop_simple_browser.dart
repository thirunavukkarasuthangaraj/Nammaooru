import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/shop_api_service.dart';
import '../../../core/config/env_config.dart';
import '../cart/cart_screen.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/cart_model.dart';

class ShopSimpleBrowser extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopSimpleBrowser({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopSimpleBrowser> createState() => _ShopSimpleBrowserState();
}

class _ShopSimpleBrowserState extends State<ShopSimpleBrowser> {
  final ShopApiService _shopApi = ShopApiService();
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'image': null}
  ];
  Map<String, String?> _categoryImages = {}; // Store category name -> image URL
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      // Load products from API
      final response = await _shopApi.getShopProducts(shopId: widget.shopId);

      if (response['statusCode'] == '0000' && response['data'] != null) {
        final products = List<Map<String, dynamic>>.from(response['data']['content'] ?? []);

        // Extract unique categories with images from masterProduct.category
        final Map<String, String?> categoryMap = {};
        for (var product in products) {
          final categoryObj = product['masterProduct']?['category'];
          if (categoryObj != null) {
            // DEBUG: Print the entire category object to see what fields are available
            print('Category Object: $categoryObj');

            final categoryName = categoryObj['name']?.toString() ?? 'Other';
            // Try multiple field names for category image
            final categoryImage = categoryObj['imageUrl']?.toString() ??
                                 categoryObj['image']?.toString() ??
                                 categoryObj['categoryImage']?.toString() ??
                                 categoryObj['iconUrl']?.toString();

            print('Category: $categoryName, Image: $categoryImage');

            // Store the image URL for this category
            if (!categoryMap.containsKey(categoryName)) {
              categoryMap[categoryName] = categoryImage;
            }
          }
        }

        // Build categories list with 'All' at the beginning
        final List<Map<String, dynamic>> categoriesList = [
          {'name': 'All', 'image': null}
        ];

        final sortedKeys = categoryMap.keys.toList()..sort();
        for (var categoryName in sortedKeys) {
          categoriesList.add({
            'name': categoryName,
            'image': categoryMap[categoryName],
          });
        }

        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _categories = categoriesList;
          _categoryImages = categoryMap;
          _isLoading = false;
        });
      } else {
        // Use sample data if API fails
        _useSampleData();
      }
    } catch (e) {
      print('Error loading products: $e');
      // Use sample data if error occurs
      _useSampleData();
    }
  }

  void _useSampleData() {
    final sampleProducts = [
      {
        'id': 1,
        'name': 'Coffee Powder',
        'price': 150.0,
        'unit': '500g',
        'categoryName': 'Beverages',
        'image': 'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=300',
      },
      {
        'id': 2,
        'name': 'Basmati Rice',
        'price': 80.0,
        'unit': '1kg',
        'categoryName': 'Grains',
        'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300',
      },
      {
        'id': 3,
        'name': 'Cooking Oil',
        'price': 120.0,
        'unit': '1L',
        'categoryName': 'Cooking Essentials',
        'image': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300',
      },
      {
        'id': 4,
        'name': 'Sugar',
        'price': 45.0,
        'unit': '1kg',
        'categoryName': 'Cooking Essentials',
        'image': 'https://images.unsplash.com/photo-1559181567-c3190ca9959b?w=300',
      },
      {
        'id': 5,
        'name': 'Tomatoes',
        'price': 30.0,
        'unit': '1kg',
        'categoryName': 'Vegetables',
        'image': 'https://images.unsplash.com/photo-1558818469-2f3e4a3e9b4f?w=300',
      },
      {
        'id': 6,
        'name': 'Onions',
        'price': 25.0,
        'unit': '1kg',
        'categoryName': 'Vegetables',
        'image': 'https://images.unsplash.com/photo-1508302730834-669cc0e3bf5f?w=300',
      },
      {
        'id': 7,
        'name': 'Milk',
        'price': 30.0,
        'unit': '500ml',
        'categoryName': 'Dairy',
        'image': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300',
      },
      {
        'id': 8,
        'name': 'Bread',
        'price': 40.0,
        'unit': '1 pack',
        'categoryName': 'Bakery',
        'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300',
      },
    ];

    // Extract categories with images
    final Map<String, String?> categoryMap = {};
    for (var product in sampleProducts) {
      final categoryName = product['categoryName'] as String;
      categoryMap[categoryName] = null; // Sample data doesn't have category images
    }

    // Build categories list with 'All' at the beginning
    final List<Map<String, dynamic>> categoriesList = [
      {'name': 'All', 'image': null}
    ];

    final sortedKeys = categoryMap.keys.toList()..sort();
    for (var categoryName in sortedKeys) {
      categoriesList.add({
        'name': categoryName,
        'image': categoryMap[categoryName],
      });
    }

    setState(() {
      _allProducts = sampleProducts;
      _filteredProducts = sampleProducts;
      _categories = categoriesList;
      _categoryImages = categoryMap;
      _isLoading = false;
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((product) => product['masterProduct']?['category']?['name'] == category)
            .toList();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Main content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
              children: [
                // Left Side - Categories
                Container(
                  width: 100,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final categoryObj = _categories[index];
                      final categoryName = categoryObj['name']?.toString() ?? 'Unknown';
                      final categoryImage = categoryObj['image']?.toString();
                      final isSelected = categoryName == _selectedCategory;

                      return InkWell(
                        onTap: () => _filterByCategory(categoryName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4CAF50).withOpacity(0.1)
                                : Colors.white,
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF4CAF50)
                                    : Colors.transparent,
                                width: 3,
                              ),
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Category Image or Icon
                              _buildCategoryImageOrIcon(categoryName, categoryImage, isSelected),
                              const SizedBox(height: 4),
                              // Category Name
                              Text(
                                categoryName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey.shade700,
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
                  ),
                ),

                // Right Side - Products Grid
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F5F5),
                    child: _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_basket_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No products in this category',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.only(
                              left: 8,
                              right: 8,
                              top: 8,
                              bottom: cartProvider.isNotEmpty ? 75 : 8,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72, // Adjusted for better fit
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(_filteredProducts[index]);
                            },
                          ),
                  ),
                ),
              ],
            ),

          // Bottom Cart Bar - Shows when items in cart
          if (cartProvider.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: InkWell(
                onTap: () {
                  // Navigate to cart screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Item count and total
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cartProvider.itemCount} ${cartProvider.itemCount == 1 ? 'ITEM' : 'ITEMS'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${cartProvider.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // View Cart button
                        Row(
                          children: [
                            const Text(
                              'VIEW CART',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.shopping_cart,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
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
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final cartProvider = Provider.of<CartProvider>(context);
    final productId = product['id'] ?? 0;
    final name = product['displayName']?.toString() ?? product['masterProduct']?['name']?.toString() ?? 'Product';
    final price = (product['price'] ?? 0.0).toDouble();
    final baseWeight = product['masterProduct']?['baseWeight']?.toString() ?? '';
    final baseUnit = product['masterProduct']?['baseUnit']?.toString() ?? '';
    final unit = baseWeight.isNotEmpty && baseUnit.isNotEmpty ? '$baseWeight $baseUnit' : '';

    // Check stock availability - try multiple field names
    final stockAvailable = product['stockAvailable'] ??
                          product['stock'] ??
                          product['stockQuantity'] ??
                          product['availableQuantity'] ??
                          product['quantity'] ??
                          100; // Default to 100 if no stock field found
    final isOutOfStock = stockAvailable <= 0;

    // Debug: Print product data to see available fields
    print('Product: $name, Stock fields - stockAvailable: ${product['stockAvailable']}, stock: ${product['stock']}, stockQuantity: ${product['stockQuantity']}, Final stock: $stockAvailable');

    // Check quantity from CartProvider
    int quantity = 0;
    try {
      final cartItem = cartProvider.items.firstWhere(
        (item) => item.product.id == productId.toString(),
      );
      quantity = cartItem.quantity;
    } catch (e) {
      quantity = 0;
    }

    // Get image URL
    String image = product['primaryImageUrl']?.toString() ??
                  product['masterProduct']?['primaryImageUrl']?.toString() ??
                  product['masterProduct']?['imageUrl']?.toString() ??
                  product['imageUrl']?.toString() ?? '';

    if (image.isNotEmpty && !image.startsWith('http')) {
      image = '${EnvConfig.baseUrl}$image';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image.isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage(name);
                                },
                              )
                            : _buildPlaceholderImage(name),
                        // Out of Stock Overlay
                        if (isOutOfStock)
                          Container(
                            color: Colors.black.withOpacity(0.6),
                            child: const Center(
                              child: Text(
                                'OUT OF STOCK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
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
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price - BLACK COLOR
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Changed to black
                  ),
                ),
                // Name - BLACK COLOR
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black, // Changed to black
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Unit - DARK GRAY
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54, // Darker gray
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 6),
                // Add/Quantity Button - Fixed Height
                Container(
                  height: 30,
                  width: double.infinity,
                  child: isOutOfStock
                      ? Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : quantity == 0
                          ? ElevatedButton(
                              onPressed: () async {
                                final productModel = ProductModel(
                                  id: productId.toString(),
                                  name: name,
                                  description: product['description']?.toString() ?? name,
                                  price: price,
                                  category: product['masterProduct']?['category']?['name']?.toString() ?? 'General',
                                  shopId: widget.shopId,
                                  shopName: widget.shopName,
                                  unit: unit,
                                  images: image.isNotEmpty ? [image] : [],
                                  stockQuantity: stockAvailable,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );
                                await cartProvider.addToCart(productModel);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(double.infinity, 30),
                              ),
                              child: const Text(
                                'ADD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF4CAF50)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (quantity > 1) {
                                        cartProvider.updateQuantity(productId.toString(), quantity - 1);
                                      } else {
                                        cartProvider.removeFromCart(productId.toString());
                                      }
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 28,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.remove,
                                        size: 18,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      cartProvider.updateQuantity(productId.toString(), quantity + 1);
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 28,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.add,
                                        size: 18,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(String productName) {
    final firstLetter = productName.isNotEmpty ? productName[0].toUpperCase() : '?';
    return Container(
      color: const Color(0xFF4CAF50).withOpacity(0.1),
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4CAF50).withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryImageOrIcon(String categoryName, String? imageUrl, bool isSelected) {
    // Check if imageUrl is an actual URL (not an emoji)
    final bool isActualImage = imageUrl != null &&
                               imageUrl.isNotEmpty &&
                               (imageUrl.startsWith('http') || imageUrl.startsWith('/uploads'));

    // If category has a real image from API, display it
    if (isActualImage) {
      String fullImageUrl = imageUrl!;
      if (!imageUrl.startsWith('http')) {
        fullImageUrl = '${EnvConfig.baseUrl}$imageUrl';
      }

      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            fullImageUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image fails to load
              return Container(
                color: isSelected
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : Colors.grey.shade100,
                child: Icon(
                  _getCategoryIcon(categoryName),
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade600,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Fallback to icon if no image URL
    return Icon(
      _getCategoryIcon(categoryName),
      size: 24,
      color: isSelected
          ? const Color(0xFF4CAF50)
          : Colors.grey.shade600,
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.apps;
      case 'grocery':
        return Icons.local_grocery_store;
      case 'medicine':
        return Icons.local_pharmacy;
      case 'milk':
        return Icons.water_drop;
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'dairy':
        return Icons.egg;
      case 'beverages':
        return Icons.local_drink;
      case 'grains':
        return Icons.grain;
      case 'bakery':
        return Icons.bakery_dining;
      case 'meat':
        return Icons.restaurant;
      case 'cooking essentials':
        return Icons.kitchen;
      case 'snacks':
        return Icons.fastfood;
      case 'food':
        return Icons.restaurant;
      case 'parcel':
        return Icons.local_shipping;
      default:
        return Icons.category;
    }
  }
}