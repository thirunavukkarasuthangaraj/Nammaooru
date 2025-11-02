import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service_simple.dart';
import '../../utils/constants.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '5');

  String? _selectedCategoryId;
  String _selectedUnit = 'piece';
  bool _isActive = true;
  bool _isFeatured = false;
  bool _trackInventory = true;

  List<dynamic> _categories = [];

  // Image picker
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();

    // Auto-generate SKU from name
    _nameController.addListener(() {
      if (_skuController.text.isEmpty && _nameController.text.isNotEmpty) {
        _skuController.text = _generateSKU(_nameController.text);
      }
    });
  }

  String _generateSKU(String name) {
    final prefix = name.substring(0, name.length > 3 ? 3 : name.length).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return '$prefix$timestamp';
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiService.getCategories();
      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final categoriesData = data['data'] ?? data;
        final content = categoriesData['content'] ?? categoriesData ?? [];

        setState(() {
          _categories = content is List ? content : [];
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.sublist(0, 5);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum 5 images allowed')),
            );
          }
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _uploadImages(int masterProductId) async {
    try {
      print('Uploading ${_selectedImages.length} images for master product $masterProductId');

      final response = await ApiService.uploadMasterProductImages(
        masterProductId: masterProductId,
        images: _selectedImages,
      );

      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Failed to upload images');
      }

      print('Images uploaded successfully');
    } catch (e) {
      print('Error uploading images: $e');
      rethrow;
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Create Master Product
      final masterProductResponse = await ApiService.createMasterProduct(
        name: _nameController.text,
        description: _descriptionController.text,
        sku: _skuController.text,
        categoryId: int.parse(_selectedCategoryId!),
        brand: _brandController.text,
        baseUnit: _selectedUnit,
        isActive: _isActive,
        isFeatured: _isFeatured,
      );

      if (!masterProductResponse.isSuccess) {
        throw Exception(masterProductResponse.error ?? 'Failed to create master product');
      }

      final masterProduct = masterProductResponse.data['data'] ?? masterProductResponse.data;
      final masterProductId = masterProduct['id'];

      // Step 2: Add to Shop with custom price
      final shopProductResponse = await ApiService.createShopProduct(
        masterProductId: masterProductId,
        price: double.parse(_priceController.text),
        originalPrice: _originalPriceController.text.isNotEmpty
            ? double.parse(_originalPriceController.text)
            : null,
        stockQuantity: int.parse(_stockController.text),
        minStockLevel: int.parse(_minStockController.text),
        costPrice: _costPriceController.text.isNotEmpty
            ? double.parse(_costPriceController.text)
            : null,
      );

      if (!shopProductResponse.isSuccess) {
        throw Exception(shopProductResponse.error ?? 'Failed to add product to shop');
      }

      // Step 3: Upload images if any are selected
      if (_selectedImages.isNotEmpty) {
        try {
          await _uploadImages(masterProductId);
        } catch (e) {
          print('Failed to upload images, but product created: $e');
          // Continue even if image upload fails
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedImages.isEmpty
                  ? 'Product created and added to your shop successfully!'
                  : 'Product created with ${_selectedImages.length} images successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Product name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['id'].toString(),
                          child: Text(category['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                      validator: (value) => value == null ? 'Category is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU (Optional)',
                        border: OutlineInputBorder(),
                        helperText: 'Leave empty to auto-generate from category, brand, and product name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
                        DropdownMenuItem(value: 'gram', child: Text('Gram (g)')),
                        DropdownMenuItem(value: 'liter', child: Text('Liter (l)')),
                        DropdownMenuItem(value: 'ml', child: Text('Milliliter (ml)')),
                        DropdownMenuItem(value: 'piece', child: Text('Piece')),
                        DropdownMenuItem(value: 'packet', child: Text('Packet')),
                        DropdownMenuItem(value: 'dozen', child: Text('Dozen')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedUnit = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Product Images Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Product Images',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Images'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add up to 5 product images (Optional)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImages.isEmpty)
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              const Text(
                                'No images selected',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? Image.network(
                                            _selectedImages[index].path,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_selectedImages[index].path),
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (index == 0)
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Primary',
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
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pricing & Stock Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pricing & Stock',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price (₹) *',
                        border: OutlineInputBorder(),
                        prefixText: '₹',
                        helperText: 'Price customer pays',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Price is required';
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) return 'Enter a valid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _originalPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Original Price / MRP (₹)',
                        border: OutlineInputBorder(),
                        prefixText: '₹',
                        helperText: 'For showing discount (optional)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final originalPrice = double.tryParse(value);
                          final sellingPrice = double.tryParse(_priceController.text);
                          if (originalPrice != null && sellingPrice != null && originalPrice <= sellingPrice) {
                            return 'Original price must be greater than selling price';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price (₹)',
                        border: OutlineInputBorder(),
                        prefixText: '₹',
                        helperText: 'Your purchase cost (optional)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(
                              labelText: 'Initial Stock *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Stock is required';
                              final stock = int.tryParse(value);
                              if (stock == null || stock < 0) return 'Enter valid stock';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _minStockController,
                            decoration: const InputDecoration(
                              labelText: 'Min Stock Alert',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: const Text('Active (Available for sale)'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() => _isActive = value ?? true);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Featured Product'),
                      value: _isFeatured,
                      onChanged: (value) {
                        setState(() => _isFeatured = value ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Track Stock Levels'),
                      value: _trackInventory,
                      onChanged: (value) {
                        setState(() => _trackInventory = value ?? true);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Create Product',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }
}
