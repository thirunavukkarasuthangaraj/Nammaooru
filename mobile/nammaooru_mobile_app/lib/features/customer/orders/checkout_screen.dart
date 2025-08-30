import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  
  int _currentStep = 0;
  bool _isPlacingOrder = false;

  // Delivery Address
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  String _selectedAddressType = 'HOME';
  String _selectedCity = 'Chennai';
  String _selectedState = 'Tamil Nadu';

  // Payment
  String _selectedPaymentMethod = 'CASH_ON_DELIVERY';
  
  // Delivery
  String _selectedDeliverySlot = 'ASAP';
  String _deliveryInstructions = '';
  
  final List<String> _addressTypes = ['HOME', 'WORK', 'OTHER'];
  final List<String> _cities = ['Chennai', 'Bangalore', 'Mumbai', 'Delhi'];
  final List<String> _states = ['Tamil Nadu', 'Karnataka', 'Maharashtra', 'Delhi'];
  final List<String> _paymentMethods = ['CASH_ON_DELIVERY', 'ONLINE', 'UPI'];
  final List<Map<String, String>> _deliverySlots = [
    {'key': 'ASAP', 'label': 'ASAP (30-45 mins)'},
    {'key': 'SLOT1', 'label': 'Today 6:00 PM - 8:00 PM'},
    {'key': 'SLOT2', 'label': 'Today 8:00 PM - 10:00 PM'},
    {'key': 'SLOT3', 'label': 'Tomorrow 10:00 AM - 12:00 PM'},
    {'key': 'SLOT4', 'label': 'Tomorrow 2:00 PM - 4:00 PM'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadSavedAddress() {
    // TODO: Load saved addresses from API/Local storage
    _nameController.text = 'John Doe';
    _phoneController.text = '+91 9876543210';
    _addressLine1Controller.text = '123, Main Street';
    _addressLine2Controller.text = 'Near City Mall';
    _landmarkController.text = 'Opposite Bus Stand';
    _pincodeController.text = '600001';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Checkout',
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildDeliveryAddressStep(),
                _buildPaymentMethodStep(),
                _buildOrderSummaryStep(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Address', 'Payment', 'Review'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.primary : Colors.grey.shade300,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppColors.primary : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (index < steps.length - 1) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDeliveryAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Address Type
            const Text('Address Type'),
            const SizedBox(height: 8),
            Row(
              children: _addressTypes.map((type) {
                return Expanded(
                  child: RadioListTile<String>(
                    title: Text(type),
                    value: type,
                    groupValue: _selectedAddressType,
                    onChanged: (value) {
                      setState(() {
                        _selectedAddressType = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Name and Phone
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty == true ? 'Phone is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Address Lines
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1 *',
                hintText: 'House/Flat/Office No, Building Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty == true ? 'Address is required' : null,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2',
                hintText: 'Area, Colony, Street Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'Landmark',
                hintText: 'Near famous place',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // City, State, Pincode
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
                    ),
                    items: _cities.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                    items: _states.map((state) {
                      return DropdownMenuItem(value: state, child: Text(state));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(
                      labelText: 'Pincode *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) => value?.isEmpty == true ? 'Pincode is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Get current location
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, size: 18),
                        SizedBox(width: 4),
                        Text('Use Current'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Delivery Slot
            const Text('Delivery Time'),
            const SizedBox(height: 8),
            Column(
              children: _deliverySlots.map((slot) {
                return RadioListTile<String>(
                  title: Text(slot['label']!),
                  value: slot['key']!,
                  groupValue: _selectedDeliverySlot,
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliverySlot = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Delivery Instructions
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Delivery Instructions (Optional)',
                hintText: 'Any specific instructions for delivery partner',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) {
                _deliveryInstructions = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Column(
            children: [
              _buildPaymentOption(
                'CASH_ON_DELIVERY',
                'Cash on Delivery',
                'Pay when your order arrives',
                Icons.money,
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                'ONLINE',
                'Online Payment',
                'Pay now with card/wallet',
                Icons.credit_card,
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                'UPI',
                'UPI Payment',
                'Pay with UPI apps',
                Icons.account_balance_wallet,
              ),
            ],
          ),
          
          if (_selectedPaymentMethod == 'ONLINE') ...[
            const SizedBox(height: 20),
            const Text(
              'Card Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Expiry',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
          
          if (_selectedPaymentMethod == 'UPI') ...[
            const SizedBox(height: 20),
            const Text(
              'UPI ID',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'UPI ID',
                hintText: 'yourname@upi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String title, String subtitle, IconData icon) {
    return Card(
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value!;
          });
        },
        title: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryStep() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Order Items
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...cartProvider.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.product.name}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            Helpers.formatCurrency(item.totalPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Delivery Address Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${_nameController.text} - ${_phoneController.text}'),
                    Text(
                      '${_addressLine1Controller.text}, ${_addressLine2Controller.text}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '${_landmarkController.text}, $_selectedCity, $_selectedState - ${_pincodeController.text}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Payment Method Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedPaymentMethod.replaceAll('_', ' ')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Bill Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bill Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBillRow('Subtotal', Helpers.formatCurrency(cartProvider.subtotal)),
                    _buildBillRow('Delivery Fee', Helpers.formatCurrency(cartProvider.deliveryFee)),
                    _buildBillRow('Tax', Helpers.formatCurrency(cartProvider.taxAmount)),
                    if (cartProvider.promoDiscount > 0)
                      _buildBillRow(
                        'Discount',
                        '-${Helpers.formatCurrency(cartProvider.promoDiscount)}',
                        valueColor: Colors.green,
                      ),
                    const Divider(),
                    _buildBillRow(
                      'Total Amount',
                      Helpers.formatCurrency(cartProvider.total),
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillRow(String label, String value, {Color? valueColor, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isTotal ? AppColors.primary : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _isPlacingOrder
                  ? const LoadingWidget()
                  : PrimaryButton(
                      text: _currentStep == 2 ? 'Place Order' : 'Continue',
                      onPressed: _currentStep == 2 ? _placeOrder : _nextStep,
                      icon: _currentStep == 2 ? Icons.check : Icons.arrow_forward,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) {
      return;
    }
    
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);
    
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      // Create order data
      final orderData = {
        'items': cartProvider.items.map((item) => {
          'productId': item.product.id,
          'quantity': item.quantity,
          'price': item.product.effectivePrice,
        }).toList(),
        'deliveryAddress': {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'addressLine1': _addressLine1Controller.text,
          'addressLine2': _addressLine2Controller.text,
          'landmark': _landmarkController.text,
          'city': _selectedCity,
          'state': _selectedState,
          'pincode': _pincodeController.text,
          'type': _selectedAddressType,
        },
        'paymentMethod': _selectedPaymentMethod,
        'deliverySlot': _selectedDeliverySlot,
        'deliveryInstructions': _deliveryInstructions,
        'subtotal': cartProvider.subtotal,
        'deliveryFee': cartProvider.deliveryFee,
        'taxAmount': cartProvider.taxAmount,
        'promoDiscount': cartProvider.promoDiscount,
        'total': cartProvider.total,
      };
      
      // TODO: API call to place order
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Clear cart
      cartProvider.clearCart();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
              orderData: orderData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to place order', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }
}