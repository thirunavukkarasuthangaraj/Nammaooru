import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_card.dart';

class InventoryScreen extends StatefulWidget {
  final String token;

  const InventoryScreen({super.key, required this.token});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // ALL, LOW_STOCK, OUT_OF_STOCK, IN_STOCK
  late TabController _tabController;
  late ScrollController _scrollController;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  // Statistics
  int _totalProducts = 0;
  int _lowStockCount = 0;
  int _outOfStockCount = 0;
  double _totalInventoryValue = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchInventoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from bottom
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreProducts();
      }
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFilter = 'ALL';
            break;
          case 1:
            _selectedFilter = 'IN_STOCK';
            break;
          case 2:
            _selectedFilter = 'LOW_STOCK';
            break;
          case 3:
            _selectedFilter = 'OUT_OF_STOCK';
            break;
        }
      });
      _applyFilters();
    }
  }

  Future<void> _fetchInventoryData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _products = [];
      _hasMoreData = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? widget.token;

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/shop-products/my-products?page=$_currentPage&size=$_pageSize'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['statusCode'] == '0000' && data['data'] != null) {
          final products = data['data']['content'] ?? [];
          final totalPages = data['data']['totalPages'] ?? 1;

          print('=== INVENTORY DEBUG ===');
          print('Products count: ${products.length}');
          print('Current page: $_currentPage, Total pages: $totalPages');

          _hasMoreData = _currentPage < (totalPages - 1);
          _processInventoryData(products);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching inventory data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? widget.token;

      _currentPage++;

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/shop-products/my-products?page=$_currentPage&size=$_pageSize'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['statusCode'] == '0000' && data['data'] != null) {
          final newProducts = data['data']['content'] ?? [];
          final totalPages = data['data']['totalPages'] ?? 1;

          print('Loaded page $_currentPage: ${newProducts.length} products');

          _hasMoreData = _currentPage < (totalPages - 1);

          setState(() {
            _products.addAll(newProducts);
          });

          _processInventoryData(_products);
        }
      }

      setState(() {
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading more products: $e');
      setState(() {
        _isLoadingMore = false;
        _currentPage--; // Revert page increment on error
      });
    }
  }

  void _processInventoryData(List<dynamic> products) {
    int lowStockCount = 0;
    int outOfStockCount = 0;
    double totalValue = 0.0;

    for (var product in products) {
      final stock = product['stockQuantity'] ?? 0;
      final minStock = product['minStockLevel'] ?? 5;
      final price = product['price'] ?? 0.0;

      // Calculate inventory value
      totalValue += (stock * price);

      // Count low stock and out of stock
      if (stock == 0) {
        outOfStockCount++;
      } else if (stock <= minStock && stock > 0) {
        lowStockCount++;
      }
    }

    setState(() {
      _products = products;
      _totalProducts = products.length;
      _lowStockCount = lowStockCount;
      _outOfStockCount = outOfStockCount;
      _totalInventoryValue = totalValue;
    });

    _applyFilters();
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(_products);

    // Apply stock filter
    if (_selectedFilter == 'LOW_STOCK') {
      filtered = filtered.where((product) {
        final stock = product['stockQuantity'] ?? 0;
        final minStock = product['minStockLevel'] ?? 5;
        return stock > 0 && stock <= minStock;
      }).toList();
    } else if (_selectedFilter == 'OUT_OF_STOCK') {
      filtered = filtered.where((product) {
        final stock = product['stockQuantity'] ?? 0;
        return stock == 0;
      }).toList();
    } else if (_selectedFilter == 'IN_STOCK') {
      filtered = filtered.where((product) {
        final stock = product['stockQuantity'] ?? 0;
        final minStock = product['minStockLevel'] ?? 5;
        return stock > minStock;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final name = (product['displayName'] ?? product['name'] ?? '').toString().toLowerCase();
        final category = (product['masterProduct']?['category']?['name'] ?? product['category'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  Future<void> _updateStock(dynamic product) async {
    final currentStock = product['stockQuantity'] ?? 0;
    final currentMinStock = product['minStockLevel'] ?? 5;
    final TextEditingController stockController = TextEditingController(text: currentStock.toString());
    final TextEditingController minStockController = TextEditingController(text: currentMinStock.toString());

    final price = product['price'] ?? 0.0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.roundedLarge),
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: AppTheme.roundedMedium,
                        ),
                        child: Icon(Icons.inventory_2, color: AppTheme.primary, size: 28),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Stock',
                              style: AppTheme.h4.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppTheme.space4),
                            Text(
                              product['displayName'] ?? product['name'] ?? 'Product',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.space24),
                  Divider(height: 1, color: AppTheme.borderLight),
                  const SizedBox(height: AppTheme.space24),

                  // Product Image & Info
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: AppTheme.roundedMedium,
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: AppTheme.roundedMedium,
                          child: _buildProductImage(product, AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['masterProduct']?['category']?['name'] ?? product['category'] ?? 'Uncategorized',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space12,
                                vertical: AppTheme.space8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: AppTheme.roundedSmall,
                                border: Border.all(
                                  color: AppTheme.success.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.currency_rupee, size: 14, color: AppTheme.success),
                                  Text(
                                    '${price.toStringAsFixed(0)} per unit',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.space24),

                  // Current Stock Field
                  Text(
                    'Current Stock',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    style: AppTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Enter stock quantity',
                      prefixIcon: Icon(Icons.inventory, color: AppTheme.primary),
                      suffixText: 'units',
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.roundedMedium,
                        borderSide: BorderSide(color: AppTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppTheme.roundedMedium,
                        borderSide: BorderSide(color: AppTheme.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppTheme.roundedMedium,
                        borderSide: BorderSide(color: AppTheme.primary, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                        vertical: AppTheme.space16,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.space20),

                  // Minimum Stock Level Field
                  Text(
                    'Minimum Stock Level',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  TextField(
                    controller: minStockController,
                    keyboardType: TextInputType.number,
                    style: AppTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Alert threshold',
                      prefixIcon: Icon(Icons.warning_amber, color: AppTheme.warning),
                      suffixText: 'units',
                      filled: true,
                      fillColor: AppTheme.background,
                      helperText: 'You\'ll be notified when stock falls below this level',
                      helperStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.roundedMedium,
                        borderSide: BorderSide(color: AppTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppTheme.roundedMedium,
                        borderSide: BorderSide(color: AppTheme.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppTheme.roundedMedium,
                        borderSide: BorderSide(color: AppTheme.warning, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                        vertical: AppTheme.space16,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.space24),
                  Divider(height: 1, color: AppTheme.borderLight),
                  const SizedBox(height: AppTheme.space20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ModernButton(
                          text: 'Cancel',
                          variant: ButtonVariant.outline,
                          size: ButtonSize.large,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: ModernButton(
                          text: 'Update Stock',
                          icon: Icons.save,
                          variant: ButtonVariant.primary,
                          size: ButtonSize.large,
                          onPressed: () async {
                            final newStock = int.tryParse(stockController.text) ?? currentStock;
                            final newMinStock = int.tryParse(minStockController.text) ?? currentMinStock;

                            if (newStock < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Stock quantity cannot be negative'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                              return;
                            }

                            await _saveStockUpdate(product['id'], newStock, newMinStock);
                            Navigator.pop(context);
                          },
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
    );
  }

  Future<void> _saveStockUpdate(int productId, int newStock, int minStock) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? widget.token;

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/shop-products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'stockQuantity': newStock,
          'minStockLevel': minStock,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        _fetchInventoryData();
      } else {
        throw Exception('Failed to update stock');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating stock: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Inventory Management', style: AppTheme.h4.copyWith(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _fetchInventoryData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.roundedMedium,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                tabs: [
                  Tab(text: 'All ($_totalProducts)'),
                  Tab(text: 'In Stock'),
                  Tab(text: 'Low ($_lowStockCount)'),
                  Tab(text: 'Out ($_outOfStockCount)'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchInventoryData,
              child: Column(
                children: [
                  // Statistics Cards
                  Container(
                    color: AppTheme.surface,
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Value',
                            '₹${_totalInventoryValue.toStringAsFixed(0)}',
                            Icons.account_balance_wallet,
                            AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: _buildStatCard(
                            'Products',
                            '$_totalProducts',
                            Icons.inventory_2,
                            AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Products List
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: AppTheme.space16),
                                Text(
                                  'No products found',
                                  style: AppTheme.h5.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(AppTheme.space16),
                            itemCount: _filteredProducts.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _filteredProducts.length) {
                                // Loading indicator at the bottom
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppTheme.space16),
                                    child: CircularProgressIndicator(color: AppTheme.primary),
                                  ),
                                );
                              }
                              final product = _filteredProducts[index];
                              return _buildProductCard(product);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductImage(dynamic product, Color statusColor) {
    // Try multiple field names for image URL (same as products_screen.dart)
    final primaryImageUrl = product['primaryImageUrl'] ??
                           product['image'] ??
                           product['imageUrl'] ??
                           product['masterProduct']?['primaryImageUrl'];

    final fullUrl = AppConfig.getImageUrl(primaryImageUrl);

    // Check if we have a valid URL
    if (fullUrl.isNotEmpty) {
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $fullUrl - $error');
          return Icon(Icons.inventory_2, color: statusColor, size: 30);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: statusColor,
            ),
          );
        },
      );
    }

    // Fallback to icon
    return Icon(Icons.inventory_2, color: statusColor, size: 30);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppTheme.roundedMedium,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: AppTheme.space4),
                  Text(value, style: AppTheme.h5.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final stock = product['stockQuantity'] ?? 0;
    final minStock = product['minStockLevel'] ?? 5;
    final price = product['price'] ?? 0.0;
    final inventoryValue = stock * price;

    // Determine stock status
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (stock == 0) {
      statusColor = AppTheme.error;
      statusText = 'Out of Stock';
      statusIcon = Icons.cancel;
    } else if (stock <= minStock) {
      statusColor = AppTheme.warning;
      statusText = 'Low Stock';
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = AppTheme.success;
      statusText = 'In Stock';
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _updateStock(product),
        borderRadius: AppTheme.roundedLarge,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              // Product Image/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: AppTheme.roundedMedium,
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: AppTheme.roundedMedium,
                  child: _buildProductImage(product, statusColor),
                ),
              ),
              const SizedBox(width: AppTheme.space16),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['displayName'] ?? product['name'] ?? 'Unknown Product',
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      product['masterProduct']?['category']?['name'] ?? product['category'] ?? 'Uncategorized',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          '$stock units',
                          style: AppTheme.bodyMedium.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Text(
                          '₹${price.toStringAsFixed(0)}/unit',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stock Status and Action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: AppTheme.roundedSmall,
                    ),
                    child: Text(
                      statusText,
                      style: AppTheme.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Value: ₹${inventoryValue.toStringAsFixed(0)}',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Icon(Icons.edit, color: AppTheme.primary, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
