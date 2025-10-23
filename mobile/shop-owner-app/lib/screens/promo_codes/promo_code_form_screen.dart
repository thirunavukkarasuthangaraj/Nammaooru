import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/promo_code_service.dart';

class PromoCodeFormScreen extends StatefulWidget {
  final Map<String, dynamic>? promo;

  const PromoCodeFormScreen({Key? key, this.promo}) : super(key: key);

  @override
  State<PromoCodeFormScreen> createState() => _PromoCodeFormScreenState();
}

class _PromoCodeFormScreenState extends State<PromoCodeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PromoCodeService _promoCodeService = PromoCodeService();

  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  late TextEditingController _minOrderController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _usageLimitController;
  late TextEditingController _usageLimitPerCustomerController;

  String _selectedType = 'PERCENTAGE';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isFirstTimeOnly = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.promo != null) {
      _codeController = TextEditingController(text: widget.promo!['code']);
      _titleController = TextEditingController(text: widget.promo!['title']);
      _descriptionController = TextEditingController(text: widget.promo!['description'] ?? '');
      _discountValueController = TextEditingController(text: widget.promo!['discountValue']?.toString() ?? '');
      _minOrderController = TextEditingController(text: widget.promo!['minimumOrderAmount']?.toString() ?? '');
      _maxDiscountController = TextEditingController(text: widget.promo!['maximumDiscountAmount']?.toString() ?? '');
      _usageLimitController = TextEditingController(text: widget.promo!['usageLimit']?.toString() ?? '');
      _usageLimitPerCustomerController = TextEditingController(text: widget.promo!['usageLimitPerCustomer']?.toString() ?? '');

      _selectedType = widget.promo!['type'] ?? 'PERCENTAGE';
      _isFirstTimeOnly = widget.promo!['isFirstTimeOnly'] ?? false;

      if (widget.promo!['startDate'] != null) {
        _startDate = DateTime.parse(widget.promo!['startDate']);
      }
      if (widget.promo!['endDate'] != null) {
        _endDate = DateTime.parse(widget.promo!['endDate']);
      }
    } else {
      _codeController = TextEditingController();
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _discountValueController = TextEditingController();
      _minOrderController = TextEditingController();
      _maxDiscountController = TextEditingController();
      _usageLimitController = TextEditingController();
      _usageLimitPerCustomerController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    _usageLimitPerCustomerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _savePromoCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final promoData = {
      'code': _codeController.text.toUpperCase(),
      'title': _titleController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'type': _selectedType,
      'discountValue': double.parse(_discountValueController.text),
      'minimumOrderAmount': _minOrderController.text.isEmpty ? null : double.parse(_minOrderController.text),
      'maximumDiscountAmount': _maxDiscountController.text.isEmpty ? null : double.parse(_maxDiscountController.text),
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'usageLimit': _usageLimitController.text.isEmpty ? null : int.parse(_usageLimitController.text),
      'usageLimitPerCustomer': _usageLimitPerCustomerController.text.isEmpty ? null : int.parse(_usageLimitPerCustomerController.text),
      'firstTimeOnly': _isFirstTimeOnly,
    };

    print('Saving promo code: $promoData');

    final result = widget.promo != null
        ? await _promoCodeService.updatePromoCode(widget.promo!['id'], promoData)
        : await _promoCodeService.createPromoCode(promoData);

    setState(() => _isLoading = false);

    if (result['statusCode'] == '0000') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.promo != null
                ? 'Promo code updated successfully'
                : 'Promo code created successfully'),
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to save promo code')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.promo != null ? 'Edit Promo Code' : 'Create Promo Code'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Information'),
                    _buildTextField(
                      controller: _codeController,
                      label: 'Promo Code',
                      hint: 'e.g., SAVE20',
                      enabled: widget.promo == null, // Can't change code after creation
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a promo code';
                        }
                        if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
                          return 'Only uppercase letters and numbers allowed';
                        }
                        if (value.length < 4 || value.length > 20) {
                          return 'Code must be 4-20 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'e.g., Save 20% on all orders',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description (Optional)',
                      hint: 'Brief description of the offer',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Discount Details'),
                    _buildDiscountTypeDropdown(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _discountValueController,
                      label: _selectedType == 'PERCENTAGE' ? 'Discount Percentage' : 'Discount Amount (₹)',
                      hint: _selectedType == 'PERCENTAGE' ? 'e.g., 20' : 'e.g., 50',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter discount value';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Please enter a valid positive number';
                        }
                        if (_selectedType == 'PERCENTAGE' && num > 100) {
                          return 'Percentage cannot exceed 100%';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _minOrderController,
                            label: 'Min Order Amount (₹)',
                            hint: 'e.g., 500',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _maxDiscountController,
                            label: 'Max Discount (₹)',
                            hint: 'e.g., 200',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Validity Period'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Start Date',
                            date: _startDate,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            label: 'End Date',
                            date: _endDate,
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Usage Limits'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _usageLimitController,
                            label: 'Total Usage Limit',
                            hint: 'e.g., 100',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _usageLimitPerCustomerController,
                            label: 'Per Customer',
                            hint: 'e.g., 1',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('First-Time Customers Only'),
                      subtitle: const Text('Promo code valid only for new customers'),
                      value: _isFirstTimeOnly,
                      onChanged: (value) => setState(() => _isFirstTimeOnly = value),
                      activeColor: Colors.green,
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _savePromoCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.promo != null ? 'Update Promo Code' : 'Create Promo Code',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      textCapitalization: textCapitalization,
    );
  }

  Widget _buildDiscountTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Discount Type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: const [
        DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage (%)')),
        DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Fixed Amount (₹)')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedType = value);
        }
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('MMM d, yyyy').format(date)),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }
}
