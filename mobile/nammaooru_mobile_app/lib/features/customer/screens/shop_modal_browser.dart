import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../services/shop_api_service.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/utils/image_url_helper.dart';
import 'cart_screen.dart';

class ShopModalBrowser extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopModalBrowser({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopModalBrowser> createState() => _ShopModalBrowserState();
}

class _ShopModalBrowserState extends State<ShopModalBrowser> {
  final ShopApiService _shopApi = ShopApiService();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _showProducts = false;
  String _selectedCategoryName = '';
  String _selectedCategoryId = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);

      final categoriesResponse = await _shopApi.getShopCategories(int.parse(widget.shopId));

      if (categoriesResponse['statusCode'] == '0000' && categoriesResponse['data'] != null) {
        final List<dynamic> categoriesData = categoriesResponse['data'] is List
            ? categoriesResponse['data']
            : [];

        _categories = categoriesData.map((cat) => {
          'id': cat['id'],
          'name': cat['name'] ?? 'Category',
          'description': cat['description'] ?? '',
          'productCount': cat['productCount'] ?? 0,
          'icon': cat['icon'] ?? 'shopping_bag',
          'color': cat['color'] ?? '#4CAF50',
          'imageUrl': cat['imageUrl'] ?? cat['image'] ?? '',
        }).toList();

        if (_categories.isEmpty) {
          _categories = _getDefaultCategories();
        }
      } else {
        _categories = _getDefaultCategories();
      }
    } catch (e) {
      print('Error loading categories: $e');
      _categories = _getDefaultCategories();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultCategories() {
    return [
      {
        'id': '1',
        'name': 'காய்கறிகள் / Vegetables',
        'description': 'விவசாயியின் புதிய காய்கறிகள் / Farm fresh vegetables',
        'productCount': 45,
        'icon': Icons.local_florist,
        'color': const Color(0xFF2E7D32),
      },
      {
        'id': '2',
        'name': 'பழங்கள் / Fruits',
        'description': 'பருவகால சுவையான பழங்கள் / Seasonal fresh fruits',
        'productCount': 32,
        'icon': Icons.eco,
        'color': const Color(0xFFFF9800),
      },
      {
        'id': '3',
        'name': 'பால் & முட்டை / Dairy & Eggs',
        'description': 'தேசிய பால் பொருட்கள் / Fresh dairy products',
        'productCount': 28,
        'icon': Icons.egg_alt,
        'color': const Color(0xFF2196F3),
      },
      {
        'id': '4',
        'name': 'அரிசி & தானியங்கள் / Rice & Grains',
        'description': 'உணவு தானியங்கள் / Staple food grains',
        'productCount': 35,
        'icon': Icons.grain,
        'color': const Color(0xFFFFA726),
      },
      {
        'id': '5',
        'name': 'மளிகை / Grocery',
        'description': 'அன்றாட தேவைகள் / Daily essentials',
        'productCount': 50,
        'icon': Icons.shopping_basket,
        'color': const Color(0xFF4CAF50),
      },
      {
        'id': '6',
        'name': 'மருந்து / Medicine',
        'description': 'மருத்துவ பொருட்கள் / Healthcare products',
        'productCount': 15,
        'icon': Icons.medical_services,
        'color': const Color(0xFF43A047),
      },
    ];
  }

  Future<void> _loadProducts(String categoryName, String categoryId) async {
    try {
      setState(() {
        _isLoading = true;
        _selectedCategoryName = categoryName;
        _selectedCategoryId = categoryId;
      });

      final productsResponse = await _shopApi.getShopProducts(
        shopId: widget.shopId,
        category: categoryName,
      );

      if (productsResponse['statusCode'] == '0000' && productsResponse['data'] != null) {
        final List<dynamic> productsData = productsResponse['data']['content'] ?? [];
        _products = productsData.map((product) => {
          'id': product['id'],
          'name': product['name'] ?? 'Product',
          'description': product['description'] ?? '',
          'price': (product['price'] ?? 0).toDouble(),
          'originalPrice': (product['originalPrice'] ?? 0).toDouble(),
          'imageUrl': product['imageUrl'] ?? '',
          'unit': product['unit'] ?? 'piece',
          'stockQuantity': product['stockQuantity'] ?? 0,
          'isAvailable': product['isAvailable'] ?? true,
        }).toList();
      }


      setState(() {
        _showProducts = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      _products = [];
      setState(() {
        _showProducts = true;
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.itemCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
            children: [
              // Header with close button
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: VillageTheme.primaryGreen,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Expanded(
                      child: Text(
                        _showProducts ? _selectedCategoryName : widget.shopName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_showProducts)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _showProducts = false;
                            _products.clear();
                          });
                        },
                      ),
                  ],
                ),
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: LoadingWidget())
                    : _showProducts
                        ? _buildProductsWithSidebar()
                        : _buildCategoriesGrid(),
              ),

              // Cart button at bottom
              if (cartItemCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VillageTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'View Cart ($cartItemCount items)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) => _buildCategoryCard(_categories[index]),
    );
  }

  Widget _buildProductsWithSidebar() {
    return Row(
      children: [
        // Categories sidebar
        Container(
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
          ),
          child: ListView.builder(
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category['name'] == _selectedCategoryName;

              return GestureDetector(
                onTap: () => _loadProducts(category['name'], category['id']?.toString() ?? ''),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? VillageTheme.primaryGreen.withOpacity(0.1) : Colors.white,
                    border: Border(
                      left: BorderSide(
                        color: isSelected ? VillageTheme.primaryGreen : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category image
                      Container(
                        width: 80,
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: (isSelected ? VillageTheme.primaryGreen : Colors.grey[300])!.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          category['icon'] is IconData ? category['icon'] : Icons.shopping_bag,
                          color: isSelected ? VillageTheme.primaryGreen : Colors.grey[600],
                          size: 36,
                        ),
                      ),
                      // Category name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? VillageTheme.primaryGreen : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
        ),

        // Products grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) => _buildProductCard(_products[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () => _loadProducts(category['name'], category['id']?.toString() ?? ''),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (category['color'] is Color
                    ? category['color']
                    : const Color(0xFF4CAF50)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category['icon'] is IconData ? category['icon'] : Icons.shopping_bag,
                size: 40,
                color: category['color'] is Color ? category['color'] : const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${category['productCount']} Items',
                style: TextStyle(
                  fontSize: 12,
                  color: VillageTheme.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        // Get current quantity in cart for this product
        final productId = product['id'].toString();
        final cartItem = cartProvider.items.firstWhere(
          (item) => item.product.id == productId,
          orElse: () => CartItem(
            product: ProductModel(
              id: productId,
              name: '',
              price: 0,
              description: '',
              category: '',
              shopId: '',
              shopName: '',
              images: [],
              unit: '',
              stockQuantity: 0,
              isAvailable: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            quantity: 0,
          ),
        );
        final currentQuantity = cartItem.quantity;
        final stockQuantity = product['stockQuantity'] ?? 0;

        return _buildProductCardUI(product, cartProvider, currentQuantity, stockQuantity);
      },
    );
  }

  Widget _buildProductCardUI(Map<String, dynamic> product, CartProvider cartProvider, int currentQuantity, int stockQuantity) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  ImageUrlHelper.getFullImageUrl(product['imageUrl'] ?? ''),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey, size: 40),
                    );
                  },
                ),
              ),
            ),
          ),

          // Product Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product['unit'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${product['price'].toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (product['originalPrice'] > product['price'])
                            Text(
                              '₹${product['originalPrice'].toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),

                      // Quantity controls or ADD button
                      currentQuantity > 0
                        ? Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: VillageTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: VillageTheme.primaryGreen, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Decrease button
                                GestureDetector(
                                  onTap: () {
                                    if (currentQuantity > 1) {
                                      cartProvider.decreaseQuantity(product['id'].toString());
                                    } else {
                                      cartProvider.removeFromCart(product['id'].toString());
                                    }
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: VillageTheme.primaryGreen,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(5),
                                        bottomLeft: Radius.circular(5),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                                // Quantity display
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '$currentQuantity',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: VillageTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                                // Increase button
                                GestureDetector(
                                  onTap: currentQuantity < stockQuantity
                                    ? () {
                                        final productModel = ProductModel(
                                          id: product['id'].toString(),
                                          name: product['name'],
                                          price: product['price'],
                                          description: product['description'] ?? '',
                                          category: _selectedCategoryName,
                                          shopId: widget.shopId,
                                          shopName: widget.shopName,
                                          images: product['imageUrl'] != null ? [product['imageUrl']] : [],
                                          unit: product['unit'] ?? 'piece',
                                          stockQuantity: stockQuantity,
                                          isAvailable: product['isAvailable'] ?? true,
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now(),
                                        );
                                        cartProvider.increaseQuantity(product['id'].toString());
                                      }
                                    : null,
                                  child: Container(
                                    width: 24,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: currentQuantity < stockQuantity
                                          ? VillageTheme.primaryGreen
                                          : Colors.grey[300],
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(5),
                                        bottomRight: Radius.circular(5),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: currentQuantity < stockQuantity ? Colors.white : Colors.grey[500],
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: stockQuantity > 0
                              ? () {
                                  final productModel = ProductModel(
                                    id: product['id'].toString(),
                                    name: product['name'],
                                    price: product['price'],
                                    description: product['description'] ?? '',
                                    category: _selectedCategoryName,
                                    shopId: widget.shopId,
                                    shopName: widget.shopName,
                                    images: product['imageUrl'] != null ? [product['imageUrl']] : [],
                                    unit: product['unit'] ?? 'piece',
                                    stockQuantity: stockQuantity,
                                    isAvailable: product['isAvailable'] ?? true,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  cartProvider.addToCart(productModel);
                                  Helpers.showSnackBar(context, '${product['name']} added to cart');
                                }
                              : null,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: stockQuantity > 0 ? VillageTheme.primaryGreen : Colors.grey[300],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.add,
                                color: stockQuantity > 0 ? Colors.white : Colors.grey[500],
                                size: 16,
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
    );
  }
}