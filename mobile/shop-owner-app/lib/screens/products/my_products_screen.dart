import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/language_selector.dart';
import '../../models/product.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'product_form_screen.dart';
import 'product_details_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: LanguageSelector(showLabel: false),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddProduct,
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading && productProvider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildSearchAndStats(productProvider),
              _buildFilterChips(productProvider),
              Expanded(
                child: _buildProductsList(productProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndStats(ProductProvider productProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        productProvider.searchProducts('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            onChanged: (value) {
              productProvider.searchProducts(value);
            },
          ),
          const SizedBox(height: 16),
          // Statistics
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  productProvider.totalProducts.toString(),
                  Icons.inventory,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  productProvider.activeProducts.toString(),
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Low Stock',
                  productProvider.lowStockProducts.toString(),
                  Icons.warning,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Out of Stock',
                  productProvider.outOfStockProducts.toString(),
                  Icons.remove_circle,
                  AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
            style: AppTextStyles.heading3.copyWith(color: color),
          ),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ProductProvider productProvider) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', '', productProvider),
          const SizedBox(width: 8),
          ...productProvider.categories.map((category) =>
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(category, category, productProvider),
              )),
          const SizedBox(width: 8),
          _buildStatusFilterChip('Active', 'ACTIVE', productProvider),
          const SizedBox(width: 8),
          _buildStatusFilterChip('Inactive', 'INACTIVE', productProvider),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ProductProvider productProvider) {
    final isSelected = productProvider.selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          productProvider.filterByCategory(value);
        } else {
          productProvider.clearFilters();
        }
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.grey,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value, ProductProvider productProvider) {
    final isSelected = productProvider.selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          productProvider.filterByStatus(value);
        } else {
          productProvider.clearFilters();
        }
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.secondary.withOpacity(0.2),
      checkmarkColor: AppColors.secondary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.secondary : AppColors.grey,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildProductsList(ProductProvider productProvider) {
    if (productProvider.products.isEmpty) {
      return _buildEmptyState(productProvider);
    }

    return RefreshIndicator(
      onRefresh: () => productProvider.loadProducts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.padding),
        itemCount: productProvider.products.length,
        itemBuilder: (context, index) {
          final product = productProvider.products[index];
          return _buildProductCard(product, productProvider);
        },
      ),
    );
  }

  Widget _buildEmptyState(ProductProvider productProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            productProvider.searchQuery.isNotEmpty
                ? 'No products found'
                : 'No products yet',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            productProvider.searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Add your first product to get started',
            style: AppTextStyles.body2.copyWith(color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: productProvider.searchQuery.isNotEmpty
                ? () {
                    _searchController.clear();
                    productProvider.clearFilters();
                  }
                : _navigateToAddProduct,
            icon: Icon(productProvider.searchQuery.isNotEmpty
                ? Icons.clear
                : Icons.add),
            label: Text(productProvider.searchQuery.isNotEmpty
                ? 'Clear Filters'
                : 'Add Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, ProductProvider productProvider) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _navigateToProductDetails(product),
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Product image/icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            product.image ?? '📦',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    languageProvider.getProductName(product),
                                    style: AppTextStyles.heading3,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _buildStatusChip(product.status),
                              ],
                            ),
                        const SizedBox(height: 4),
                        Text(
                          product.category,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppHelpers.formatCurrency(product.price),
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action menu
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleProductAction(value, product, productProvider),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_status',
                        child: ListTile(
                          leading: Icon(product.status == 'ACTIVE'
                              ? Icons.pause_circle
                              : Icons.play_circle),
                          title: Text(product.status == 'ACTIVE'
                              ? 'Deactivate'
                              : 'Activate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Duplicate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: AppColors.error),
                          title: Text('Delete', style: TextStyle(color: AppColors.error)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stock and sales info
              Row(
                children: [
                  _buildInfoChip(
                    'Stock: ${product.stock} ${product.unit}',
                    product.isLowStock
                        ? AppColors.warning
                        : product.isOutOfStock
                            ? AppColors.error
                            : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    'SKU: ${product.sku ?? 'N/A'}',
                    AppColors.grey,
                  ),
                ],
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'ACTIVE':
        color = AppColors.success;
        break;
      case 'INACTIVE':
        color = AppColors.error;
        break;
      default:
        color = AppColors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }

  void _handleProductAction(String action, Product product, ProductProvider productProvider) {
    switch (action) {
      case 'edit':
        _navigateToEditProduct(product);
        break;
      case 'toggle_status':
        _toggleProductStatus(product, productProvider);
        break;
      case 'duplicate':
        _duplicateProduct(product);
        break;
      case 'delete':
        _deleteProduct(product, productProvider);
        break;
    }
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductFormScreen(),
      ),
    );
  }

  void _navigateToEditProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );
  }

  void _navigateToProductDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  void _duplicateProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(
          product: product.copyWith(
            id: '', // Clear ID for new product
            name: '${product.name} (Copy)',
            stock: 0, // Start with 0 stock
          ),
        ),
      ),
    );
  }

  void _toggleProductStatus(Product product, ProductProvider productProvider) async {
    final success = await productProvider.toggleProductStatus(product.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Product ${product.status == 'ACTIVE' ? 'deactivated' : 'activated'} successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productProvider.errorMessage ?? 'Failed to update product status'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _deleteProduct(Product product, ProductProvider productProvider) {
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
            onPressed: () async {
              Navigator.pop(context);
              final success = await productProvider.deleteProduct(product.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(productProvider.errorMessage ?? 'Failed to delete product'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Products',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 16),
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category:', style: AppTextStyles.body1),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip('All', '', productProvider),
                        ...productProvider.categories.map((category) =>
                            _buildFilterChip(category, category, productProvider)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Status:', style: AppTextStyles.body1),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildStatusFilterChip('All', '', productProvider),
                        _buildStatusFilterChip('Active', 'ACTIVE', productProvider),
                        _buildStatusFilterChip('Inactive', 'INACTIVE', productProvider),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              productProvider.clearFilters();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}