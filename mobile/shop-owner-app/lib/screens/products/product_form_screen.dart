import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _skuController;
  late final TextEditingController _minStockController;

  String _selectedCategory = 'Snacks';
  String _selectedUnit = 'pcs';
  String _selectedStatus = 'ACTIVE';
  String _selectedImage = '📦';

  final List<String> _categories = [
    'Snacks',
    'Medicine',
    'Spices',
    'Beverages',
    'Household',
    'Electronics',
    'Dairy',
    'Groceries',
  ];

  final List<String> _units = [
    'pcs',
    'pack',
    'bottle',
    'liter',
    'kg',
    'gram',
    'box',
    'dozen',
  ];

  final List<String> _images = [
    '📦', '🥔', '💊', '🌶️', '☕', '🏠', '📱', '💧', '🥛', '🍪', '🍵', '🛒'
  ];

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (isEditing) {
      _populateFields();
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();
    _skuController = TextEditingController();
    _minStockController = TextEditingController();
  }

  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _skuController.text = product.sku ?? '';
    _minStockController.text = product.minStock.toString();
    _selectedCategory = product.category;
    _selectedUnit = product.unit;
    _selectedStatus = product.status;
    _selectedImage = product.image ?? '📦';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveProduct,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.padding),
              children: [
                _buildImageSelector(),
                const SizedBox(height: 24),
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildCategoryAndStatusSection(),
                const SizedBox(height: 24),
                _buildInventorySection(),
                const SizedBox(height: 32),
                _buildSaveButton(productProvider),
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  _buildDeleteButton(productProvider),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Image',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    _selectedImage,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _images.map((image) => _buildImageOption(image)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(String image) {
    final isSelected = _selectedImage == image;
    return GestureDetector(
      onTap: () => setState(() => _selectedImage = image),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            image,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                hintText: 'Enter product name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validators.validateRequired(value, 'Product name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe your product',
                border: OutlineInputBorder(),
              ),
              validator: Validators.validateDescription,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skuController,
              decoration: const InputDecoration(
                labelText: 'SKU (Stock Keeping Unit)',
                hintText: 'e.g., SNACK001',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAndStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category & Status',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
              ],
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing & Inventory',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹) *',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    validator: Validators.validatePrice,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedUnit = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Current Stock *',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateStock,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Min Stock Alert',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateStock,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Set minimum stock level to receive low stock alerts',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(ProductProvider productProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: productProvider.isLoading ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: productProvider.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(isEditing ? 'Update Product' : 'Add Product'),
      ),
    );
  }

  Widget _buildDeleteButton(ProductProvider productProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: productProvider.isLoading ? null : _deleteProduct,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: AppColors.error),
        ),
        child: Text(
          'Delete Product',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    final productData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text),
      'stock': int.parse(_stockController.text),
      'category': _selectedCategory,
      'status': _selectedStatus,
      'image': _selectedImage,
      'sku': _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
      'unit': _selectedUnit,
      'minStock': int.parse(_minStockController.text.isEmpty ? '0' : _minStockController.text),
    };

    bool success;
    if (isEditing) {
      success = await productProvider.updateProduct(widget.product!.id, productData);
    } else {
      success = await productProvider.createProduct(productData);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Product updated successfully' : 'Product added successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            productProvider.errorMessage ??
            (isEditing ? 'Failed to update product' : 'Failed to add product'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${widget.product!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              final success = await productProvider.deleteProduct(widget.product!.id);

              if (success && mounted) {
                Navigator.pop(context);
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
}