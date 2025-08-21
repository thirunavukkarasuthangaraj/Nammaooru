import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import 'add_edit_product_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  bool _isGridView = false;
  String _sortBy = 'name';
  String? _selectedCategory;
  bool _showOutOfStock = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement API call to fetch shop products
      await Future.delayed(const Duration(seconds: 2));
      
      _products = _generateSampleProducts();
      _filteredProducts = List.from(_products);
      _applySortAndFilter();
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load products', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ProductModel> _generateSampleProducts() {
    return List.generate(15, (index) {
      final isOutOfStock = index % 7 == 0;
      return ProductModel(
        id: 'product_$index',
        name: 'Product ${index + 1}',
        description: 'High quality product with great features and benefits.',
        price: 50.0 + (index * 15),
        discountPrice: index % 3 == 0 ? 40.0 + (index * 12) : null,
        category: ['Vegetables', 'Fruits', 'Dairy', 'Snacks', 'Beverages'][index % 5],
        shopId: 'shop_1',
        shopName: 'My Shop',
        images: ['https://via.placeholder.com/300x300'],
        stockQuantity: isOutOfStock ? 0 : 10 + index,
        unit: ['kg', 'piece', 'liter', 'pack'][index % 4],
        rating: 3.5 + (index % 3 * 0.5),
        reviewCount: 5 + index,
        isAvailable: !isOutOfStock,
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now(),
      );
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query);
            
        final matchesCategory = _selectedCategory == null || 
            product.category == _selectedCategory;
            
        final matchesStock = _showOutOfStock || product.isInStock;
        
        return matchesSearch && matchesCategory && matchesStock;
      }).toList();
      
      _applySortAndFilter();
    });
  }

  void _applySortAndFilter() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'price_low':
          _filteredProducts.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
          break;
        case 'price_high':
          _filteredProducts.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
          break;
        case 'stock_low':
          _filteredProducts.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
          break;
        case 'stock_high':
          _filteredProducts.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
          break;
        case 'newest':
          _filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF9800);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Product Management',
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndStats(primaryColor),
          _buildSortingChips(primaryColor),
          Expanded(
            child: _isLoading 
                ? const LoadingWidget()
                : _buildProductList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewProduct,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildSearchAndStats(Color primaryColor) {
    final outOfStockCount = _products.where((p) => !p.isInStock).length;
    final lowStockCount = _products.where((p) => p.isInStock && p.stockQuantity < 5).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  _products.length.toString(),
                  primaryColor,
                  Icons.inventory,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Low Stock',
                  lowStockCount.toString(),
                  Colors.orange,
                  Icons.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Out of Stock',
                  outOfStockCount.toString(),
                  Colors.red,
                  Icons.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortingChips(Color primaryColor) {
    final sortOptions = [
      {'key': 'name', 'label': 'Name'},
      {'key': 'price_low', 'label': 'Price ↑'},
      {'key': 'price_high', 'label': 'Price ↓'},
      {'key': 'stock_low', 'label': 'Stock ↑'},
      {'key': 'stock_high', 'label': 'Stock ↓'},
      {'key': 'newest', 'label': 'Newest'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortOptions.length,
        itemBuilder: (context, index) {
          final option = sortOptions[index];
          final isSelected = _sortBy == option['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(option['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _sortBy = option['key']!;
                  _applySortAndFilter();
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: primaryColor.withOpacity(0.2),
              checkmarkColor: primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return _isGridView ? _buildGridView() : _buildListView();
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_filteredProducts[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductListTile(_filteredProducts[index]);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editProduct(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: product.images.isNotEmpty 
                            ? product.images.first 
                            : 'https://via.placeholder.com/300x300',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                  ),
                  
                  // Status badges
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      children: [
                        if (!product.isInStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'OUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (product.isInStock && product.stockQuantity < 5)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'LOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatCurrency(product.effectivePrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9800),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 12,
                          color: product.isInStock ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.stockQuantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.isInStock ? Colors.green : Colors.red,
                          ),
                        ),
                        const Spacer(),
                        _buildQuickActionButton(product),
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

  Widget _buildProductListTile(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: product.images.isNotEmpty 
                ? product.images.first 
                : 'https://via.placeholder.com/60x60',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Helpers.formatCurrency(product.effectivePrice)),
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  size: 14,
                  color: product.isInStock ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  'Stock: ${product.stockQuantity}',
                  style: TextStyle(
                    color: product.isInStock ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  product.category,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(value, product),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            PopupMenuItem(
              value: product.isAvailable ? 'disable' : 'enable',
              child: Row(
                children: [
                  Icon(product.isAvailable ? Icons.visibility_off : Icons.visibility),
                  const SizedBox(width: 8),
                  Text(product.isAvailable ? 'Disable' : 'Enable'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _editProduct(product),
      ),
    );
  }

  Widget _buildQuickActionButton(ProductModel product) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleProductAction(value, product),
      icon: const Icon(Icons.more_vert, size: 16),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Text('Edit', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'stock',
          child: Text('Update Stock', style: TextStyle(fontSize: 12)),
        ),
        PopupMenuItem(
          value: product.isAvailable ? 'disable' : 'enable',
          child: Text(
            product.isAvailable ? 'Disable' : 'Enable',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _handleProductAction(String action, ProductModel product) {
    switch (action) {
      case 'edit':
        _editProduct(product);
        break;
      case 'duplicate':
        _duplicateProduct(product);
        break;
      case 'stock':
        _updateStock(product);
        break;
      case 'enable':
      case 'disable':
        _toggleProductStatus(product);
        break;
      case 'delete':
        _deleteProduct(product);
        break;
    }
  }

  void _addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditProductScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadProducts();
      }
    });
  }

  void _editProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: product),
      ),
    ).then((result) {
      if (result == true) {
        _loadProducts();
      }
    });
  }

  void _duplicateProduct(ProductModel product) {
    final duplicatedProduct = product.copyWith(
      id: '',
      name: '${product.name} (Copy)',
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: duplicatedProduct),
      ),
    ).then((result) {
      if (result == true) {
        _loadProducts();
      }
    });
  }

  void _updateStock(ProductModel product) {
    final controller = TextEditingController(text: product.stockQuantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock - ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Update stock via API
              Navigator.pop(context);
              Helpers.showSnackBar(context, 'Stock updated successfully');
              _loadProducts();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _toggleProductStatus(ProductModel product) {
    // TODO: Toggle product status via API
    Helpers.showSnackBar(
      context,
      '${product.name} ${product.isAvailable ? 'disabled' : 'enabled'}',
    );
    _loadProducts();
  }

  void _deleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete product via API
              Navigator.pop(context);
              Helpers.showSnackBar(context, 'Product deleted successfully');
              _loadProducts();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                const Text('Category'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Vegetables', 'Fruits', 'Dairy', 'Snacks', 'Beverages']
                      .map((category) => FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == (category == 'All' ? null : category),
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedCategory = category == 'All' ? null : category;
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                
                CheckboxListTile(
                  title: const Text('Show Out of Stock'),
                  value: _showOutOfStock,
                  onChanged: (value) {
                    setModalState(() {
                      _showOutOfStock = value ?? true;
                    });
                  },
                ),
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _filterProducts();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}