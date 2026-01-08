import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/combo_model.dart';
import '../../services/combo_service.dart';
import '../../utils/app_config.dart';

class CreateComboScreen extends StatefulWidget {
  final int shopId;
  final Combo? combo; // For editing

  const CreateComboScreen({super.key, required this.shopId, this.combo});

  @override
  State<CreateComboScreen> createState() => _CreateComboScreenState();
}

class _CreateComboScreenState extends State<CreateComboScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingProducts = true;

  // Form Controllers
  final _nameController = TextEditingController();
  final _nameTamilController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _comboPriceController = TextEditingController();
  final _maxQtyController = TextEditingController(text: '5');

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isActive = true;

  // Products
  List<Map<String, dynamic>> _availableProducts = [];
  List<ComboItem> _selectedItems = [];
  double _originalPrice = 0;

  bool get isEditMode => widget.combo != null;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (isEditMode) {
      _populateForm();
    }
  }

  void _populateForm() {
    final combo = widget.combo!;
    _nameController.text = combo.name;
    _nameTamilController.text = combo.nameTamil ?? '';
    _descriptionController.text = combo.description ?? '';
    _comboPriceController.text = combo.comboPrice.toStringAsFixed(0);
    _maxQtyController.text = combo.maxQuantityPerOrder.toString();
    _startDate = combo.startDate;
    _endDate = combo.endDate;
    _isActive = combo.isActive;
    _selectedItems = List.from(combo.items);
    _calculateOriginalPrice();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await ComboService.getShopProducts(widget.shopId);
      setState(() {
        _availableProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  void _calculateOriginalPrice() {
    double total = 0;
    for (var item in _selectedItems) {
      total += item.unitPrice * item.quantity;
    }
    setState(() => _originalPrice = total);
  }

  Future<void> _saveCombo() async {
    // Validate
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter combo name')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one product')),
      );
      setState(() => _currentStep = 1);
      return;
    }

    final comboPrice = double.tryParse(_comboPriceController.text) ?? 0;
    if (comboPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid combo price')),
      );
      return;
    }

    if (comboPrice >= _originalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Combo price must be less than original price')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final comboData = {
      'name': _nameController.text.trim(),
      'nameTamil': _nameTamilController.text.trim().isEmpty
          ? null
          : _nameTamilController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'comboPrice': comboPrice,
      'startDate': _startDate.toIso8601String().split('T')[0],
      'endDate': _endDate.toIso8601String().split('T')[0],
      'isActive': _isActive,
      'maxQuantityPerOrder': int.tryParse(_maxQtyController.text) ?? 5,
      'items': _selectedItems
          .map((e) => {
                'shopProductId': e.shopProductId,
                'quantity': e.quantity,
              })
          .toList(),
    };

    Map<String, dynamic> result;
    if (isEditMode) {
      result = await ComboService.updateCombo(
          widget.shopId, widget.combo!.id!, comboData);
    } else {
      result = await ComboService.createCombo(widget.shopId, comboData);
    }

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error saving combo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Combo' : 'Create Combo',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _saveCombo();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                } else {
                  Navigator.pop(context);
                }
              },
              onStepTapped: (step) => setState(() => _currentStep = step),
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_currentStep == 2 ? 'Save' : 'Next'),
                      ),
                      const SizedBox(width: 12),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Basic Info'),
                  subtitle: Text(_nameController.text.isEmpty
                      ? 'Enter combo details'
                      : _nameController.text),
                  isActive: _currentStep >= 0,
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildBasicInfoStep(),
                ),
                Step(
                  title: const Text('Select Products'),
                  subtitle: Text(_selectedItems.isEmpty
                      ? 'Choose items for combo'
                      : '${_selectedItems.length} items selected'),
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildProductSelectionStep(),
                ),
                Step(
                  title: const Text('Pricing & Validity'),
                  subtitle: Text(_comboPriceController.text.isEmpty
                      ? 'Set price and dates'
                      : '₹${_comboPriceController.text}'),
                  isActive: _currentStep >= 2,
                  state: StepState.indexed,
                  content: _buildPricingStep(),
                ),
              ],
            ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Combo Name *',
            hintText: 'e.g., Pongal Special Combo',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameTamilController,
          decoration: const InputDecoration(
            labelText: 'Name (Tamil)',
            hintText: 'e.g., பொங்கல் சிறப்பு கூடை',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your combo offer',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Search controller for products
  final _productSearchController = TextEditingController();
  String _productSearchQuery = '';

  Widget _buildProductSelectionStep() {
    if (_isLoadingProducts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availableProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No products available'),
        ),
      );
    }

    // Filter available products (excluding selected)
    final availableForSelection = _availableProducts.where((product) {
      final productId = product['id'] as int;
      final isAlreadySelected = _selectedItems.any((item) => item.shopProductId == productId);
      if (isAlreadySelected) return false;

      // Apply search filter
      if (_productSearchQuery.isNotEmpty) {
        final productName = (product['displayName'] ??
            product['customName'] ??
            product['masterProduct']?['name'] ??
            'Product').toString().toLowerCase();
        return productName.contains(_productSearchQuery.toLowerCase());
      }
      return true;
    }).take(20).toList(); // Limit to 20 products for performance

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Items Summary
        if (_selectedItems.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedItems.length} items | Total: ₹${_originalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Selected Products - Compact list
          const Text(
            'Selected Products',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 8),
          ..._selectedItems.map((item) => _buildCompactSelectedItem(item)),
          const Divider(thickness: 1, height: 24),
        ],

        // Search box for available products
        TextField(
          controller: _productSearchController,
          decoration: InputDecoration(
            hintText: 'Search products to add...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
            suffixIcon: _productSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _productSearchController.clear();
                        _productSearchQuery = '';
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) => setState(() => _productSearchQuery = value),
        ),
        const SizedBox(height: 8),

        Text(
          'Showing ${availableForSelection.length} products',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),

        // Available Product List - Limited height
        ...availableForSelection.map((product) {
          final productId = product['id'] as int;
          final productName = product['displayName'] ??
              product['customName'] ??
              product['masterProduct']?['name'] ??
              'Product';
          final price = (product['price'] ?? 0).toDouble();
          final imageUrl = product['primaryImageUrl'] ??
              product['masterProduct']?['primaryImageUrl'];
          final unit = product['baseUnit'] != null
              ? '${product['baseWeight']} ${product['baseUnit']}'
              : '';

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _buildProductImage(imageUrl, 40),
              ),
              title: Text(productName, style: const TextStyle(fontSize: 14)),
              subtitle: Text('$unit • ₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF2E7D32), size: 28),
                onPressed: () {
                  setState(() {
                    _selectedItems.add(ComboItem(
                      shopProductId: productId,
                      productName: productName,
                      unitPrice: price,
                      totalPrice: price,
                      unit: unit,
                      imageUrl: imageUrl,
                      quantity: 1,
                    ));
                    _calculateOriginalPrice();
                  });
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCompactSelectedItem(ComboItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Small image
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildProductImage(item.imageUrl, 36),
          ),
          const SizedBox(width: 8),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Price
          Text(
            '₹${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 4),
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    final index = _selectedItems.indexWhere((i) => i.shopProductId == item.shopProductId);
                    if (index >= 0 && item.quantity > 1) {
                      setState(() {
                        _selectedItems[index] = item.copyWith(quantity: item.quantity - 1);
                        _calculateOriginalPrice();
                      });
                    }
                  },
                  child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.remove, size: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: const Color(0xFF2E7D32),
                  child: Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                InkWell(
                  onTap: () {
                    final index = _selectedItems.indexWhere((i) => i.shopProductId == item.shopProductId);
                    if (index >= 0) {
                      setState(() {
                        _selectedItems[index] = item.copyWith(quantity: item.quantity + 1);
                        _calculateOriginalPrice();
                      });
                    }
                  },
                  child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.add, size: 14, color: Color(0xFF2E7D32))),
                ),
              ],
            ),
          ),
          // Delete button
          InkWell(
            onTap: () {
              final index = _selectedItems.indexWhere((i) => i.shopProductId == item.shopProductId);
              if (index >= 0) {
                setState(() {
                  _selectedItems.removeAt(index);
                  _calculateOriginalPrice();
                });
              }
            },
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 16, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductCard(ComboItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF2E7D32).withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF2E7D32), width: 1),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildProductImage(item.imageUrl, 50),
        ),
        title: Text(
          item.productName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${item.unit ?? ''} • ₹${item.unitPrice.toStringAsFixed(0)} × ${item.quantity} = ₹${(item.unitPrice * item.quantity).toStringAsFixed(0)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decrease quantity
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 22),
              onPressed: () {
                final index = _selectedItems.indexWhere((i) => i.shopProductId == item.shopProductId);
                if (index >= 0 && item.quantity > 1) {
                  setState(() {
                    _selectedItems[index] = item.copyWith(quantity: item.quantity - 1);
                    _calculateOriginalPrice();
                  });
                }
              },
            ),
            // Quantity badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            // Increase quantity
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32), size: 22),
              onPressed: () {
                final index = _selectedItems.indexWhere((i) => i.shopProductId == item.shopProductId);
                if (index >= 0) {
                  setState(() {
                    _selectedItems[index] = item.copyWith(quantity: item.quantity + 1);
                    _calculateOriginalPrice();
                  });
                }
              },
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 22),
              onPressed: () {
                final index = _selectedItems.indexWhere((i) => i.shopProductId == item.shopProductId);
                if (index >= 0) {
                  setState(() {
                    _selectedItems.removeAt(index);
                    _calculateOriginalPrice();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingStep() {
    final savings = _originalPrice -
        (double.tryParse(_comboPriceController.text) ?? _originalPrice);
    final discountPercent = _originalPrice > 0
        ? (savings / _originalPrice * 100)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original Price Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Items Total:'),
              Text(
                '₹${_originalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Combo Price
        TextField(
          controller: _comboPriceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Combo Price *',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
            helperText: 'Must be less than items total',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),

        // Savings Display
        if (savings > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Customer saves ₹${savings.toStringAsFixed(0)} (${discountPercent.toStringAsFixed(0)}% OFF)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),

        // Date Selection
        const Text(
          'Validity Period',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_endDate)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Max Quantity
        TextField(
          controller: _maxQtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Max Quantity per Order',
            border: OutlineInputBorder(),
            helperText: 'Limit how many combos a customer can buy',
          ),
        ),
        const SizedBox(height: 16),

        // Active Switch
        SwitchListTile(
          title: const Text('Active'),
          subtitle: const Text('Combo will be visible to customers'),
          value: _isActive,
          activeColor: const Color(0xFF2E7D32),
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ],
    );
  }

  String _getFullImageUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${AppConfig.imageBaseUrl}$url';
  }

  Widget _buildProductImage(String? imageUrl, double size) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Icon(Icons.inventory_2),
      );
    }
    return CachedNetworkImage(
      imageUrl: _getFullImageUrl(imageUrl),
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: (size * 2).toInt(),
      memCacheHeight: (size * 2).toInt(),
      placeholder: (context, url) => Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Icon(Icons.image),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameTamilController.dispose();
    _descriptionController.dispose();
    _comboPriceController.dispose();
    _maxQtyController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }
}
