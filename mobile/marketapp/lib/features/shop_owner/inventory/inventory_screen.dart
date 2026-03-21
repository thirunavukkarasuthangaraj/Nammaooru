import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import '../products/add_edit_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'name';
  String _filterBy = 'all';
  bool _isLoading = false;
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _products = _generateSampleProducts();
      _isLoading = false;
    });
  }

  List<ProductModel> _generateSampleProducts() {
    return [
      ProductModel(
        id: 'P001',
        name: 'Organic Bananas',
        description: 'Fresh organic bananas from local farms',
        category: 'Fruits',
        price: 60.0,
        discountPrice: 55.0,
        unit: 'kg',
        stockQuantity: 25,
        minStockLevel: 10,
        images: ['https://via.placeholder.com/300x300'],
        shopId: 'SHOP001',
        shopName: 'Fresh Mart',
        isAvailable: true,
        rating: 4.5,
        reviewCount: 125,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'P002',
        name: 'Fresh Milk',
        description: 'Pure cow milk, farm fresh',
        category: 'Dairy',
        price: 50.0,
        unit: 'liter',
        stockQuantity: 5,
        minStockLevel: 15,
        images: ['https://via.placeholder.com/300x300'],
        shopId: 'SHOP001',
        shopName: 'Fresh Mart',
        isAvailable: true,
        rating: 4.3,
        reviewCount: 89,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'P003',
        name: 'Brown Bread',
        description: 'Whole wheat brown bread',
        category: 'Bakery',
        price: 35.0,
        unit: 'piece',
        stockQuantity: 0,
        minStockLevel: 20,
        images: ['https://via.placeholder.com/300x300'],
        shopId: 'SHOP001',
        shopName: 'Fresh Mart',
        isAvailable: false,
        rating: 4.2,
        reviewCount: 67,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'P004',
        name: 'Tomatoes',
        description: 'Fresh red tomatoes',
        category: 'Vegetables',
        price: 40.0,
        discountPrice: 36.0,
        unit: 'kg',
        stockQuantity: 18,
        minStockLevel: 15,
        images: ['https://via.placeholder.com/300x300'],
        shopId: 'SHOP001',
        shopName: 'Fresh Mart',
        isAvailable: true,
        rating: 4.1,
        reviewCount: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'P005',
        name: 'Basmati Rice',
        description: 'Premium quality basmati rice',
        category: 'Grains',
        price: 120.0,
        unit: 'kg',
        stockQuantity: 8,
        minStockLevel: 10,
        images: ['https://via.placeholder.com/300x300'],
        shopId: 'SHOP001',
        shopName: 'Fresh Mart',
        isAvailable: true,
        rating: 4.6,
        reviewCount: 156,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  List<ProductModel> get _filteredProducts {
    List<ProductModel> filtered = _products;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    }

    // Tab filter
    switch (_tabController.index) {
      case 0: // All
        break;
      case 1: // Low Stock
        filtered = filtered.where((p) => p.stockQuantity <= p.minStockLevel && p.stockQuantity > 0).toList();
        break;
      case 2: // Out of Stock
        filtered = filtered.where((p) => p.stockQuantity == 0).toList();
        break;
      case 3: // Inactive
        filtered = filtered.where((p) => !p.isAvailable).toList();
        break;
    }

    // Sort
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'stock_low':
        filtered.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
        break;
      case 'stock_high':
        filtered.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      case 'price_low':
        filtered.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF9800); // Orange theme for shop owners

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Inventory Management',
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            onPressed: _showFilterSortDialog,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _loadInventory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(primaryColor),
          _buildInventoryStats(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildProductsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddProduct(),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildTabBar(Color primaryColor) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: primaryColor,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        onTap: (index) => setState(() {}),
        tabs: [
          Tab(text: 'All (${_products.length})'),
          Tab(text: 'Low Stock (${_products.where((p) => p.stockQuantity <= p.minStockLevel && p.stockQuantity > 0).length})'),
          Tab(text: 'Out of Stock (${_products.where((p) => p.stockQuantity == 0).length})'),
          Tab(text: 'Inactive (${_products.where((p) => !p.isAvailable).length})'),
        ],
      ),
    );
  }

  Widget _buildInventoryStats() {
    final totalValue = _products.fold<double>(0, (sum, product) => 
        sum + (product.effectivePrice * product.stockQuantity));
    final lowStockCount = _products.where((p) => 
        p.stockQuantity <= p.minStockLevel && p.stockQuantity > 0).length;
    final outOfStockCount = _products.where((p) => p.stockQuantity == 0).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Value',
              Helpers.formatCurrency(totalValue),
              Icons.currency_rupee,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Low Stock',
              lowStockCount.toString(),
              Icons.warning,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Out of Stock',
              outOfStockCount.toString(),
              Icons.error,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final filteredProducts = _filteredProducts;

    if (filteredProducts.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          title: 'No products found',
          message: 'Try adjusting your search or filters',
          icon: Icons.inventory,
          action: null,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          return _buildProductCard(filteredProducts[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    const primaryColor = Color(0xFFFF9800);
    final stockStatus = _getStockStatus(product);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product.images.isNotEmpty
                        ? product.images.first
                        : 'https://via.placeholder.com/80x80',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: stockStatus['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              stockStatus['text'],
                              style: TextStyle(
                                color: stockStatus['color'],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            Helpers.formatCurrency(product.effectivePrice),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 8),
                            Text(
                              Helpers.formatCurrency(product.price),
                              style: const TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              Text(
                                ' ${product.rating} (${product.reviewCount})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${product.stockQuantity} ${product.unit}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Min Stock Level',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${product.minStockLevel} ${product.unit}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            product.isAvailable ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: product.isAvailable ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStock(product),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Update Stock'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editProduct(product),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _toggleProductStatus(product),
                      icon: Icon(
                        product.isAvailable ? Icons.visibility_off : Icons.visibility,
                        color: product.isAvailable ? Colors.red : Colors.green,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: (product.isAvailable ? Colors.red : Colors.green)
                            .withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStockStatus(ProductModel product) {
    if (product.stockQuantity == 0) {
      return {'text': 'OUT OF STOCK', 'color': Colors.red};
    } else if (product.stockQuantity <= product.minStockLevel) {
      return {'text': 'LOW STOCK', 'color': Colors.orange};
    } else {
      return {'text': 'IN STOCK', 'color': Colors.green};
    }
  }

  void _showFilterSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Name (A-Z)'),
                leading: Radio<String>(
                  value: 'name',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Stock: Low to High'),
                leading: Radio<String>(
                  value: 'stock_low',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Stock: High to Low'),
                leading: Radio<String>(
                  value: 'stock_high',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Price: Low to High'),
                leading: Radio<String>(
                  value: 'price_low',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Price: High to Low'),
                leading: Radio<String>(
                  value: 'price_high',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateStock(ProductModel product) {
    final controller = TextEditingController(text: product.stockQuantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current stock: ${product.stockQuantity} ${product.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New stock quantity',
                suffixText: product.unit,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text) ?? 0;
              setState(() {
                final index = _products.indexWhere((p) => p.id == product.id);
                if (index != -1) {
                  _products[index] = product.copyWith(stockQuantity: newStock);
                }
              });
              Navigator.pop(context);
              Helpers.showSnackBar(context, 'Stock updated successfully');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _editProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: product),
      ),
    ).then((result) {
      if (result == true) {
        _loadInventory();
      }
    });
  }

  void _toggleProductStatus(ProductModel product) {
    setState(() {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product.copyWith(isAvailable: !product.isAvailable);
      }
    });
    
    final status = product.isAvailable ? 'deactivated' : 'activated';
    Helpers.showSnackBar(context, 'Product $status successfully');
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditProductScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadInventory();
      }
    });
  }
}