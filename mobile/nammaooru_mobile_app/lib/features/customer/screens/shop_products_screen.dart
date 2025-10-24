import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/shop_api_service.dart';
import '../../../core/config/env_config.dart';
import '../../../shared/providers/cart_provider.dart';
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
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All',
      'imageUrl': 'https://images.unsplash.com/photo-1543168256-8133d1f3d731?w=400',
    },
    {
      'name': 'Grocery',
      'imageUrl': 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=400',
    },
    {
      'name': 'Medicine',
      'imageUrl': 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400',
    },
    {
      'name': 'Milk',
      'imageUrl': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400',
    },
    {
      'name': 'Snacks',
      'imageUrl': 'https://images.unsplash.com/photo-1621939514649-280e2ee25f60?w=400',
    },
  ];

  // Track quantities for each product
  final Map<int, int> _productQuantities = {};

  final List<Map<String, dynamic>> _allProducts = [
    {'id': 1, 'name': 'Coffee', 'price': 150, 'category': 'Grocery', 'unit': '500g', 'stock': 10},
    {'id': 2, 'name': 'Rice', 'price': 180, 'category': 'Grocery', 'unit': '1kg', 'stock': 25},
    {'id': 3, 'name': 'Oil', 'price': 120, 'category': 'Grocery', 'unit': '1L', 'stock': 15},
    {'id': 4, 'name': 'Cough Syrup', 'price': 95, 'category': 'Medicine', 'unit': '100ml', 'stock': 5},
    {'id': 5, 'name': 'Paracetamol', 'price': 30, 'category': 'Medicine', 'unit': '10 tabs', 'stock': 20},
    {'id': 6, 'name': 'Milk', 'price': 60, 'category': 'Dairy', 'unit': '1L', 'stock': 30},
    {'id': 7, 'name': 'Cheese', 'price': 120, 'category': 'Dairy', 'unit': '200g', 'stock': 8},
    {'id': 8, 'name': 'Chips', 'price': 20, 'category': 'Snacks', 'unit': '50g', 'stock': 50},
    {'id': 9, 'name': 'Biscuits', 'price': 30, 'category': 'Snacks', 'unit': '100g', 'stock': 40},
    {'id': 10, 'name': 'Sugar', 'price': 45, 'category': 'Grocery', 'unit': '1kg', 'stock': 35},
  ];

  @override
  void initState() {
    super.initState();
    // Set initial category from the passed categoryName
    _selectedCategory = widget.categoryName == 'Grocery' ? 'Grocery' :
                       widget.categoryName == 'Medicine' ? 'Medicine' :
                       widget.categoryName == 'Dairy' ? 'Dairy' :
                       widget.categoryName == 'Snacks' ? 'Snacks' : 'All';

    // Initialize quantities from cart
    _initializeQuantitiesFromCart();
  }

  void _initializeQuantitiesFromCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    for (var item in cartProvider.items) {
      final productId = int.tryParse(item.product.id.toString());
      if (productId != null) {
        _productQuantities[productId] = item.quantity;
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == 'All') {
      return _allProducts;
    }
    // Handle 'Milk' category mapping to 'Dairy'
    final categoryToFilter = _selectedCategory == 'Milk' ? 'Dairy' : _selectedCategory;
    return _allProducts.where((p) => p['category'] == categoryToFilter).toList();
  }

  void _updateQuantity(int productId, int change, int maxStock) {
    setState(() {
      int currentQty = _productQuantities[productId] ?? 0;
      int newQty = currentQty + change;

      // Ensure quantity stays within bounds
      if (newQty >= 0 && newQty <= maxStock) {
        if (newQty == 0) {
          _productQuantities.remove(productId);
        } else {
          _productQuantities[productId] = newQty;
        }
      } else if (newQty > maxStock) {
        // Show error if trying to exceed stock
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Text('Only $maxStock items available in stock'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
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
        title: Text('Shop Products', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
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
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
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
        ],
      ),
      body: Row(
        children: [
          // Left - Categories
          Container(
            width: 130,
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final categoryName = category['name'];
                final isSelected = _selectedCategory == categoryName;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = categoryName;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? Colors.green : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Category Image
                        SizedBox(
                          width: 100,
                          height: 90,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              category['imageUrl'] ?? '',
                              width: 100,
                              height: 90,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 100,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                // Log the error
                                print('Error loading category image for $categoryName: $error');
                                return Container(
                                  width: 100,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(categoryName),
                                    color: Colors.grey[600],
                                    size: 48,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.green : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Right - Products
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product count
                Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        '${_filteredProducts.length} Products',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      if (_selectedCategory != 'All')
                        Text(
                          ' in $_selectedCategory',
                          style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),

                // Products Grid
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            'No products in this category',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final productId = product['id'] as int;
                            final quantity = _productQuantities[productId] ?? 0;
                            final stock = product['stock'] as int;
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
                                        Container(
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
                                      padding: EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isOutOfStock ? Colors.grey : Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            product['unit'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${product['price']}',
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
                                              padding: EdgeInsets.symmetric(vertical: 8),
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
                                                      padding: EdgeInsets.all(4),
                                                      child: Icon(
                                                        Icons.remove,
                                                        color: Colors.green,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    children: [
                                                      Text(
                                                        '$quantity',
                                                        style: TextStyle(
                                                          color: Colors.green,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (quantity == stock)
                                                        Text(
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
                                                      padding: EdgeInsets.all(4),
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
                                                padding: EdgeInsets.symmetric(vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
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