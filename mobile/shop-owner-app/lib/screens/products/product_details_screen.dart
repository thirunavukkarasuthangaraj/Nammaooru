import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'product_form_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(context, value),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProductHeader(),
            const SizedBox(height: 16),
            _buildProductInfo(),
            const SizedBox(height: 16),
            _buildInventoryInfo(),
            const SizedBox(height: 16),
            _buildProductMetadata(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Product image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                product.image ?? '📦',
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Product name
          Text(
            product.name,
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              product.category,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Price
          Text(
            AppHelpers.formatCurrency(product.price),
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.success,
              fontSize: 28,
            ),
          ),
          Text(
            'per ${product.unit}',
            style: AppTextStyles.caption.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Product Information',
                    style: AppTextStyles.heading3,
                  ),
                  _buildStatusChip(product.status),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                product.description,
                style: AppTextStyles.body1,
              ),
              if (product.sku != null) ...[
                const SizedBox(height: 16),
                _buildInfoRow('SKU', product.sku!),
              ],
              if (product.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Tags',
                  style: AppTextStyles.body1,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: product.tags.map((tag) => _buildTag(tag)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inventory & Stock',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStockCard(
                      'Current Stock',
                      '${product.stock} ${product.unit}',
                      product.isOutOfStock
                          ? AppColors.error
                          : product.isLowStock
                              ? AppColors.warning
                              : AppColors.success,
                      product.isOutOfStock
                          ? Icons.remove_circle
                          : product.isLowStock
                              ? Icons.warning
                              : Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStockCard(
                      'Min Stock Alert',
                      '${product.minStock} ${product.unit}',
                      AppColors.primary,
                      Icons.notifications,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: product.isLowStock
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: product.isLowStock
                        ? AppColors.warning.withOpacity(0.3)
                        : AppColors.success.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      product.isLowStock ? Icons.warning : Icons.check_circle,
                      color: product.isLowStock ? AppColors.warning : AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.isOutOfStock
                            ? 'Out of stock - restock immediately'
                            : product.isLowStock
                                ? 'Low stock - consider restocking soon'
                                : 'Stock level is healthy',
                        style: AppTextStyles.body2.copyWith(
                          color: product.isLowStock ? AppColors.warning : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductMetadata() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Details',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Status', product.status),
              const SizedBox(height: 12),
              _buildInfoRow('Unit', product.unit),
              const SizedBox(height: 12),
              _buildInfoRow('Created', AppHelpers.formatDateTime(product.createdAt)),
              const SizedBox(height: 12),
              _buildInfoRow('Last Updated', AppHelpers.formatDateTime(product.updatedAt)),
              if (product.discountPercentage != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow('Discount', '${product.discountPercentage}%'),
              ],
              if (product.discountedPrice != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow('Discounted Price', AppHelpers.formatCurrency(product.discountedPrice!)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        tag,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body2,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateStock(context),
              icon: const Icon(Icons.inventory),
              label: const Text('Update Stock'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _editProduct(context),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Product'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _editProduct(context);
        break;
      case 'toggle_status':
        _toggleStatus(context);
        break;
      case 'duplicate':
        _duplicateProduct(context);
        break;
      case 'delete':
        _deleteProduct(context);
        break;
    }
  }

  void _editProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );
  }

  void _updateStock(BuildContext context) {
    final controller = TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current stock: ${product.stock} ${product.unit}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'New Stock Quantity',
                suffixText: product.unit,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newStock = int.tryParse(controller.text);
              if (newStock != null) {
                Navigator.pop(context);
                final productProvider = Provider.of<ProductProvider>(context, listen: false);
                final success = await productProvider.updateStock(product.id, newStock);

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stock updated successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(productProvider.errorMessage ?? 'Failed to update stock'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(BuildContext context) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final success = await productProvider.toggleProductStatus(product.id);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Product ${product.status == 'ACTIVE' ? 'deactivated' : 'activated'} successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productProvider.errorMessage ?? 'Failed to update product status'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _duplicateProduct(BuildContext context) {
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

  void _deleteProduct(BuildContext context) {
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
              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              final success = await productProvider.deleteProduct(product.id);

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (context.mounted) {
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
}