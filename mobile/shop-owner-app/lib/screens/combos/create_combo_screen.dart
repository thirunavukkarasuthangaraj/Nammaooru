import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        title: Text(isEditMode ? 'Edit Combo' : 'Create Combo'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
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
                Text(
                  '${_selectedItems.length} items | Total: ₹${_originalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Product List
        ...List.generate(_availableProducts.length, (index) {
          final product = _availableProducts[index];
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

          final selectedIndex = _selectedItems
              .indexWhere((item) => item.shopProductId == productId);
          final isSelected = selectedIndex >= 0;
          final quantity =
              isSelected ? _selectedItems[selectedIndex].quantity : 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? Image.network(
                        _getFullImageUrl(imageUrl),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image),
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.inventory_2),
                      ),
              ),
              title: Text(
                productName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text('$unit • ₹${price.toStringAsFixed(0)}'),
              trailing: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() {
                                _selectedItems[selectedIndex] =
                                    _selectedItems[selectedIndex]
                                        .copyWith(quantity: quantity - 1);
                                _calculateOriginalPrice();
                              });
                            } else {
                              setState(() {
                                _selectedItems.removeAt(selectedIndex);
                                _calculateOriginalPrice();
                              });
                            }
                          },
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() {
                              _selectedItems[selectedIndex] =
                                  _selectedItems[selectedIndex]
                                      .copyWith(quantity: quantity + 1);
                              _calculateOriginalPrice();
                            });
                          },
                        ),
                      ],
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: Color(0xFF2E7D32)),
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

  @override
  void dispose() {
    _nameController.dispose();
    _nameTamilController.dispose();
    _descriptionController.dispose();
    _comboPriceController.dispose();
    _maxQtyController.dispose();
    super.dispose();
  }
}
