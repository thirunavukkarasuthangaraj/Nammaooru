import 'package:flutter/material.dart';
import '../../services/api_service_simple.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import 'product_form_screen.dart';
import 'add_product_from_catalog_screen.dart';
import 'browse_products_screen.dart';
import 'create_product_screen.dart';
import 'categories_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String token;

  const ProductsScreen({
    super.key,
    required this.token,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;
  late ScrollController _scrollController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _fetchProducts();
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final response = await ApiService.getMyProducts(
        page: 0,
        size: _pageSize,
      );

      print('My Products API response: ${response.isSuccess}');

      if (response.isSuccess && response.data != null) {
        final data = response.data;

        // Handle nested data structure: {statusCode, message, data: {content: [...]}}
        final productsData = data['data'] ?? data;
        final content = productsData['content'] ?? productsData ?? [];

        print('Products count: ${content.length}');

        setState(() {
          _products = content;
          _hasMore = content.length >= _pageSize;
          _currentPage = 0;
          _isLoading = false;
        });
      } else {
        print('API error: ${response.error}');
        _setMockData();
      }
    } catch (e) {
      print('Error fetching products: $e');
      _setMockData();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await ApiService.getMyProducts(
        page: nextPage,
        size: _pageSize,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final productsData = data['data'] ?? data;
        final content = productsData['content'] ?? productsData ?? [];

        setState(() {
          _products.addAll(content);
          _hasMore = content.length >= _pageSize;
          _currentPage = nextPage;
          _isLoadingMore = false;
        });

        print('Loaded page $nextPage with ${content.length} products');
      } else {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more products: $e');
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
    }
  }

  void _setMockData() {
    setState(() {
      _products = [
        {
          'id': 1,
          'name': 'Basmati Rice Premium',
          'description': 'High quality basmati rice',
          'price': 180.00,
          'stock': 25,
          'category': 'Grains & Rice',
          'status': 'ACTIVE',
          'image': null,
        },
        {
          'id': 2,
          'name': 'Amul Fresh Milk',
          'description': 'Fresh dairy milk 500ml',
          'price': 32.00,
          'stock': 40,
          'category': 'Dairy',
          'status': 'ACTIVE',
          'image': null,
        },
        {
          'id': 3,
          'name': 'Britannia Good Day Cookies',
          'description': 'Chocolate chip cookies pack',
          'price': 25.00,
          'stock': 15,
          'category': 'Snacks',
          'status': 'ACTIVE',
          'image': null,
        },
        {
          'id': 4,
          'name': 'Tata Salt Crystal',
          'description': 'Iodized salt 1kg pack',
          'price': 22.00,
          'stock': 8,
          'category': 'Condiments & Spices',
          'status': 'LOW_STOCK',
          'image': null,
        },
      ];
      _isLoading = false;
    });
  }

  List<String> get _categories {
    final categories = <String>{'All'};
    for (var product in _products) {
      final category = product['masterProduct']?['category']?['name'] ?? product['category'];
      if (category != null) {
        categories.add(category.toString());
      }
    }
    return categories.toList();
  }

  List<dynamic> get _filteredProducts {
    return _products.where((product) {
      final name = (product['displayName'] ?? product['name'] ?? '').toString().toLowerCase();
      final category = (product['masterProduct']?['category']?['name'] ?? product['category'] ?? '').toString();

      final matchesSearch = _searchQuery.isEmpty ||
        name.contains(_searchQuery.toLowerCase()) ||
        category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' || category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Color _getStockColor(dynamic product) {
    final stock = product['stockQuantity'] ?? product['stock'] ?? 0;
    final inStock = product['inStock'] ?? true;
    final lowStock = product['lowStock'] ?? false;

    if (!inStock || stock == 0) return Colors.red;
    if (lowStock || stock < 10) return Colors.orange;
    return Colors.green;
  }

  String _getStockText(dynamic product) {
    final stock = product['stockQuantity'] ?? product['stock'] ?? 0;
    final inStock = product['inStock'] ?? true;
    final lowStock = product['lowStock'] ?? false;

    if (!inStock || stock == 0) return 'Out of Stock';
    if (lowStock || stock < 10) return 'Low Stock ($stock)';
    return 'In Stock ($stock)';
  }

  @override
  Widget build(BuildContext context) {
    final gridColumns = ResponsiveLayout.getGridColumns(context);
    final padding = ResponsiveLayout.getResponsivePadding(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Products', style: AppTheme.h5),
        elevation: 0,
        actions: [
          ModernIconButton(
            icon: Icons.category,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
              _fetchProducts();
            },
            size: 48,
          ),
          const SizedBox(width: AppTheme.space8),
          ModernIconButton(
            icon: Icons.add,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductFromCatalogScreen(),
                ),
              );

              if (result == true) {
                _fetchProducts();
              }
            },
            size: 48,
          ),
          const SizedBox(width: AppTheme.space8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: padding,
            color: AppTheme.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Category Filter Chips
          if (_categories.isNotEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              color: AppTheme.surface,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.space8),
                    child: ModernChip(
                      label: category,
                      selected: isSelected,
                      icon: isSelected ? Icons.check : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: AppTheme.space8),

          // Products Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: padding,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 80,
                                color: AppTheme.textHint,
                              ),
                              const SizedBox(height: AppTheme.space16),
                              Text(
                                'No products found',
                                style: AppTheme.h4.copyWith(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: AppTheme.space8),
                              Text(
                                'Add your first product to get started',
                                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textHint),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTheme.space24),
                              ModernButton(
                                text: 'Add Product',
                                icon: Icons.add,
                                variant: ButtonVariant.primary,
                                size: ButtonSize.large,
                                useGradient: true,
                                onPressed: () => _showAddProductMenu(context),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchProducts,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: padding,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridColumns > 3 ? 3 : 2,
                            crossAxisSpacing: AppTheme.space16,
                            mainAxisSpacing: AppTheme.space16,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: _filteredProducts.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredProducts.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppTheme.space16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: ModernFAB(
        icon: Icons.add,
        label: 'Add Product',
        onPressed: () => _showAddProductMenu(context),
        useGradient: true,
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final primaryImageUrl = product['primaryImageUrl'] ?? product['image'];
    final productName = product['displayName'] ?? product['name'] ?? 'Unknown Product';
    final category = product['masterProduct']?['category']?['name'] ?? product['category'] ?? 'Uncategorized';
    final price = product['price'] ?? 0;
    final originalPrice = product['originalPrice'];
    final stock = product['stockQuantity'] ?? product['stock'] ?? 0;
    // Check shop-specific unit first, then fall back to master product's unit
    final unit = product['baseUnit'] ?? product['masterProduct']?['baseUnit'] ?? product['unit'];
    final weight = product['baseWeight'] ?? product['masterProduct']?['baseWeight'];
    final imageUrl = AppConfig.getImageUrl(primaryImageUrl);
    final inStock = product['inStock'] ?? true;
    final lowStock = product['lowStock'] ?? (stock < 10);

    return ProductCard(
      name: productName,
      category: category,
      price: price.toDouble(),
      originalPrice: originalPrice?.toDouble(),
      stock: stock,
      unit: unit,
      weight: weight?.toDouble(),
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      onTap: () => _showEditProductDialog(product),
      onEdit: () => _showEditProductDialog(product),
      onDelete: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Product'),
            content: Text(
              'Are you sure you want to remove "$productName" from your shop?\n\nNote: Product can only be removed if all orders are completed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ModernButton(
                text: 'Remove',
                variant: ButtonVariant.error,
                size: ButtonSize.small,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          final deleteResult = await ApiService.removeProductFromShop(
            productId: product['id'],
          );

          if (deleteResult.isSuccess) {
            _fetchProducts();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product removed from shop successfully'),
                backgroundColor: AppTheme.success,
              ),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: ${deleteResult.error ?? "Cannot remove product with pending orders"}',
                ),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      },
    );
  }

  void _showAddProductMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: AppTheme.roundedRound,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Text('Add Product to Shop', style: AppTheme.h4),
            ),
            InfoCard(
              title: '',
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.secondaryGradient,
                    borderRadius: AppTheme.roundedMedium,
                  ),
                  child: const Icon(Icons.library_add, color: AppTheme.textWhite),
                ),
                title: Text('Browse Master Catalog', style: AppTheme.h6),
                subtitle: Text(
                  'Browse existing products and add with custom price',
                  style: AppTheme.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddProductFromCatalogScreen(),
                    ),
                  );
                  if (result == true) {
                    _fetchProducts();
                  }
                },
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            InfoCard(
              title: '',
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: AppTheme.roundedMedium,
                  ),
                  child: const Icon(Icons.add_box, color: AppTheme.textWhite),
                ),
                title: Text('Create New Product', style: AppTheme.h6),
                subtitle: Text(
                  'Create a new product and add to catalog',
                  style: AppTheme.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateProductScreen(),
                    ),
                  );
                  if (result == true) {
                    _fetchProducts();
                  }
                },
              ),
            ),
            const SizedBox(height: AppTheme.space24),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProductDialog(dynamic product) async {
    final nameController = TextEditingController(text: product['displayName'] ?? product['name'] ?? '');
    final priceController = TextEditingController(text: product['price'].toString());
    final originalPriceController = TextEditingController(text: product['originalPrice']?.toString() ?? '');
    final stockController = TextEditingController(text: (product['stockQuantity'] ?? product['stock'] ?? 0).toString());
    final minStockController = TextEditingController(text: (product['minStockLevel'] ?? 5).toString());
    // Check shop-specific unit first, then fall back to master product's unit
    final weightController = TextEditingController(text: (product['baseWeight'] ?? product['masterProduct']?['baseWeight'] ?? '').toString());
    String selectedUnit = product['baseUnit'] ?? product['masterProduct']?['baseUnit'] ?? 'piece';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${product['displayName'] ?? product['name']}'),
          content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                  helperText: 'Custom name (optional)',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Selling Price (₹)',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                  helperText: 'Price customer pays',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: originalPriceController,
                decoration: const InputDecoration(
                  labelText: 'Original Price / MRP (₹)',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                  helperText: 'For showing discount (optional)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minStockController,
                decoration: const InputDecoration(
                  labelText: 'Min Stock Level',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight/Quantity',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., 100, 250, 1, 5',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                  helperText: 'Select unit type',
                ),
                items: const [
                  DropdownMenuItem(value: 'piece', child: Text('Piece')),
                  DropdownMenuItem(value: 'gram', child: Text('Gram')),
                  DropdownMenuItem(value: 'kg', child: Text('Kilogram (KG)')),
                  DropdownMenuItem(value: 'liter', child: Text('Liter')),
                  DropdownMenuItem(value: 'ml', child: Text('Milliliter (ML)')),
                  DropdownMenuItem(value: 'pack', child: Text('Pack')),
                  DropdownMenuItem(value: 'bottle', child: Text('Bottle')),
                  DropdownMenuItem(value: 'box', child: Text('Box')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedUnit = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Show confirmation dialog
              final confirmDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove Product'),
                  content: Text('Are you sure you want to remove "${product['displayName'] ?? product['name']}" from your shop?\n\nNote: Product can only be removed if all orders are completed.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );

              if (confirmDelete == true) {
                final deleteResult = await ApiService.removeProductFromShop(
                  productId: product['id'],
                );

                if (deleteResult.isSuccess) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product removed from shop successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${deleteResult.error ?? "Cannot remove product with pending orders"}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove from Shop'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text);
              final originalPrice = originalPriceController.text.trim().isEmpty
                  ? null
                  : double.tryParse(originalPriceController.text);
              final stock = int.tryParse(stockController.text);
              final minStock = int.tryParse(minStockController.text);
              final weight = weightController.text.trim().isEmpty
                  ? null
                  : double.tryParse(weightController.text);

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter product name')),
                );
                return;
              }

              if (price == null || stock == null || minStock == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid numbers')),
                );
                return;
              }

              // Validate originalPrice if provided
              if (originalPrice != null && originalPrice <= price) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Original price must be greater than selling price')),
                );
                return;
              }

              // Update product
              final updateResult = await ApiService.updateShopProduct(
                productId: product['id'],
                masterProductId: product['masterProduct']?['id'] ?? product['masterProductId'],
                price: price,
                originalPrice: originalPrice,
                stockQuantity: stock,
                minStockLevel: minStock,
                customName: name != (product['displayName'] ?? product['name']) ? name : null,
                baseWeight: weight,
                baseUnit: selectedUnit,
              );

              if (updateResult.isSuccess) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${updateResult.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
      ),
    );

    if (result == true) {
      _fetchProducts(); // Refresh the list
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}