import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/jwt_helper.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/address_service.dart';
import '../../../core/models/address_model.dart';
import '../../../services/address_api_service.dart';
// import 'order_confirmation_screen.dart'; // Temporarily commented

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
  bool _saveAddress = true; // Always save by default
  List<SavedAddress> _savedAddresses = [];
  SavedAddress? _selectedSavedAddress;
  bool _preventFieldReload = false; // Flag to prevent overwriting user-entered data

  // Delivery Address
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _selectedAddressType = 'HOME';
  String _selectedCity = 'Tirupattur';
  String _selectedState = 'Tamil Nadu';

  // Delivery Type
  String _selectedDeliveryType = 'HOME_DELIVERY';

  // Payment
  String _selectedPaymentMethod = 'CASH_ON_DELIVERY';

  // Payment form keys
  final _cardFormKey = GlobalKey<FormState>();
  final _upiFormKey = GlobalKey<FormState>();

  // Payment controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _upiIdController = TextEditingController();

  // Delivery
  String _selectedDeliverySlot = 'ASAP';
  String _deliveryInstructions = '';

  final List<String> _addressTypes = ['HOME', 'WORK', 'OTHER'];
  final List<String> _cities = ['Tirupattur']; // Only Tirupattur for now
  final List<String> _states = ['Tamil Nadu'];
  final List<Map<String, String>> _deliveryTypes = [
    {'key': 'HOME_DELIVERY', 'label': 'Home Delivery', 'icon': '🚚'},
    {'key': 'SELF_PICKUP', 'label': 'Self Pickup', 'icon': '🏪'},
  ];
  final List<String> _paymentMethods = ['CASH_ON_DELIVERY'];
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
      _loadUserData();
    });
    _loadSavedAddresses();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      // Get name from JWT token
      try {
        final token = await SecureStorage.getAuthToken();
        if (token != null) {
          final userName = JwtHelper.getUserName(token);
          setState(() {
            if (userName != null && userName.isNotEmpty) {
              // Split name into first and last name
              final nameParts = userName.trim().split(' ');
              if (nameParts.length > 1) {
                _nameController.text = nameParts.first;
                _lastNameController.text = nameParts.sublist(1).join(' ');
              } else {
                _nameController.text = userName;
                _lastNameController.text = userName; // Use same name for last name if no space
              }
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  void _checkAuthentication() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      Navigator.pop(context); // Go back to cart/previous screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to continue checkout'),
          backgroundColor: Colors.orange,
        ),
      );
      // Navigate to login screen using GoRouter
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _pageController.dispose();

    // Payment controllers
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _upiIdController.dispose();

    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      // First try to load from API
      final result = await AddressApiService.getUserAddresses();

      if (result['success']) {
        final addressList = result['data'] as List<dynamic>? ?? [];

        // Convert API addresses to SavedAddress objects
        _savedAddresses = addressList.map((addr) {
          // Handle different field names from API
          final firstName = addr['firstName'] ?? addr['name'] ?? '';
          final phoneNumber = addr['phone'] ?? addr['mobileNumber'] ?? addr['mobile'] ?? '';
          final postalCode = addr['pincode']?.toString() ?? addr['postalCode']?.toString() ?? addr['postal_code']?.toString() ?? '';

          // Build addressLine1 from available fields (flatHouse + street)
          List<String> addressLine1Parts = [];
          if (addr['flatHouse'] != null && addr['flatHouse'].toString().isNotEmpty) {
            addressLine1Parts.add(addr['flatHouse'].toString());
          }
          if (addr['street'] != null && addr['street'].toString().isNotEmpty) {
            addressLine1Parts.add(addr['street'].toString());
          }
          // Fallback to old format if new fields not available
          if (addressLine1Parts.isEmpty) {
            final fallback = addr['addressLine1'] ?? addr['address_line1'] ?? addr['streetAddress'] ?? '';
            if (fallback.isNotEmpty) addressLine1Parts.add(fallback);
          }

          // Build addressLine2 from area/village
          String addressLine2 = addr['area']?.toString() ??
                                addr['village']?.toString() ??
                                addr['addressLine2']?.toString() ??
                                addr['address_line2']?.toString() ?? '';

          return SavedAddress(
            id: addr['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: firstName,
            lastName: addr['lastName'] ?? '',
            phone: phoneNumber,
            addressLine1: addressLine1Parts.join(', '),
            addressLine2: addressLine2,
            landmark: addr['landmark'] ?? '',
            city: addr['city'] ?? 'Tirupattur',
            state: addr['state'] ?? 'Tamil Nadu',
            pincode: postalCode,
            addressType: addr['addressType'] ?? 'HOME',
            isDefault: addr['isDefault'] ?? false,
            createdAt: DateTime.now(),
          );
        }).toList();

        // Auto-select default address or first address
        if (_savedAddresses.isNotEmpty && !_preventFieldReload) {
          final defaultAddress = _savedAddresses.firstWhere(
            (addr) => addr.isDefault,
            orElse: () => _savedAddresses.first,
          );
          _loadAddressToFields(defaultAddress);
          setState(() {
            _selectedSavedAddress = defaultAddress;
          });
        } else if (_savedAddresses.isNotEmpty && _preventFieldReload) {
          // Just update the list, don't reload fields
          setState(() {});
        }
      } else {
        // If API fails, try local storage
        final localAddresses = await AddressService.instance.getSavedAddresses();
        setState(() {
          _savedAddresses = localAddresses;
        });

        if (localAddresses.isNotEmpty && !_preventFieldReload) {
          final defaultAddress = localAddresses.firstWhere(
            (addr) => addr.isDefault,
            orElse: () => localAddresses.first,
          );
          _loadAddressToFields(defaultAddress);
          setState(() {
            _selectedSavedAddress = defaultAddress;
          });
        } else if (localAddresses.isNotEmpty && _preventFieldReload) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error loading addresses: $e');
      // Fallback to local storage
      final addresses = await AddressService.instance.getSavedAddresses();
      setState(() {
        _savedAddresses = addresses;
      });

      if (addresses.isNotEmpty && !_preventFieldReload) {
        final defaultAddress = addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => addresses.first,
        );
        _loadAddressToFields(defaultAddress);
        setState(() {
          _selectedSavedAddress = defaultAddress;
        });
      } else if (addresses.isNotEmpty && _preventFieldReload) {
        setState(() {});
      }
    }
  }

  void _loadAddressToFields(SavedAddress address) {
    print('🔍 Loading address to fields: name=${address.name}, lastName=${address.lastName}, phone=${address.phone}');
    _nameController.text = address.name;
    _lastNameController.text = address.lastName;
    _phoneController.text = address.phone;
    _addressLine1Controller.text = address.addressLine1;
    _addressLine2Controller.text = address.addressLine2;
    _landmarkController.text = address.landmark;
    _pincodeController.text = address.pincode;

    // Ensure city value is in the dropdown list
    if (_cities.contains(address.city)) {
      _selectedCity = address.city;
    } else {
      _selectedCity = 'Tirupattur'; // Default to Tirupattur if not found
    }

    // Ensure state value is in the dropdown list
    if (_states.contains(address.state)) {
      _selectedState = address.state;
    } else {
      _selectedState = 'Tamil Nadu'; // Default to Tamil Nadu if not found
    }

    _selectedAddressType = address.addressType;
  }

  Future<void> _saveCurrentAddress() async {
    // Always save address with updated name and phone

    final addressId = _selectedSavedAddress?.id ?? AddressService.instance.generateAddressId();

    // Preserve isDefault status if updating existing address, otherwise make first address default
    final isDefault = _selectedSavedAddress?.isDefault ?? _savedAddresses.isEmpty;

    final address = SavedAddress(
      id: addressId,
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      landmark: _landmarkController.text.trim(),
      city: _selectedCity,
      state: _selectedState,
      pincode: _pincodeController.text.trim(),
      addressType: _selectedAddressType,
      isDefault: isDefault,
      createdAt: _selectedSavedAddress?.createdAt ?? DateTime.now(),
    );

    print('💾 Saving address with name=${address.name}, lastName=${address.lastName}, phone=${address.phone}, isDefault=$isDefault');

    // Set flag to prevent field reload from overwriting user data
    _preventFieldReload = true;

    final success = await AddressService.instance.saveAddress(address);
    if (success) {
      print('✅ Address saved successfully');

      // Update the selected address reference
      _selectedSavedAddress = address;

      // Reload the addresses list in the background for the address selection UI
      // The flag will prevent it from overwriting the form fields
      await _loadSavedAddresses();

      // Reset the flag after reload completes
      _preventFieldReload = false;
    } else {
      print('❌ Failed to save address');
      _preventFieldReload = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const CustomAppBar(
        title: 'Checkout',
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Prevent swipe navigation
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: List.generate(steps.length, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? VillageTheme.primaryGreen : Colors.grey.shade300,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? VillageTheme.primaryGreen : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: isCompleted ? VillageTheme.primaryGreen : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildDeliveryAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Type Card
            Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Delivery Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _deliveryTypes.map((type) {
                        final isSelected = _selectedDeliveryType == type['key'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDeliveryType = type['key']!;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? VillageTheme.primaryGreen : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? VillageTheme.primaryGreen : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      type['icon']!,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      type['label']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Show address section only for home delivery
            if (_selectedDeliveryType == 'HOME_DELIVERY') ...[
              // Saved Addresses Carousel
              if (_savedAddresses.isNotEmpty) ...[
                Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Select Address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_savedAddresses.length} saved',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(bottom: 4),
                            itemCount: _savedAddresses.length + 1,
                            itemBuilder: (context, index) {
                              // Add New Address Button
                              if (index == _savedAddresses.length) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedSavedAddress = null;
                                      _nameController.clear();
                                      _lastNameController.clear();
                                      _phoneController.clear();
                                      _addressLine1Controller.clear();
                                      _addressLine2Controller.clear();
                                      _landmarkController.clear();
                                      _pincodeController.clear();
                                      _selectedAddressType = 'HOME';
                                      _selectedCity = 'Tirupattur';
                                      _selectedState = 'Tamil Nadu';
                                    });
                                  },
                                  child: Container(
                                    width: 140,
                                    height: 110,
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: VillageTheme.primaryGreen,
                                        width: 1.5,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 32,
                                          color: VillageTheme.primaryGreen,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Add New\nAddress',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: VillageTheme.primaryGreen,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final address = _savedAddresses[index];
                              final isSelected = _selectedSavedAddress?.id == address.id;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSavedAddress = address;
                                  });
                                  _loadAddressToFields(address);
                                },
                                child: Container(
                                  width: 200,
                                  height: 110,
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? VillageTheme.primaryGreen.withOpacity(0.1) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? VillageTheme.primaryGreen : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _getAddressTypeIcon(address.addressType),
                                            size: 14,
                                            color: isSelected ? VillageTheme.primaryGreen : Colors.black87,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              address.addressType,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected ? VillageTheme.primaryGreen : Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: VillageTheme.primaryGreen,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        address.fullName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? VillageTheme.primaryGreen : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Expanded(
                                        child: Text(
                                          address.shortAddress,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected ? VillageTheme.primaryGreen.withOpacity(0.8) : Colors.black54,
                                            height: 1.2,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Address Form Card
              Card(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Address Type Radio Buttons
                      Row(
                        children: _addressTypes.map((type) {
                          return Expanded(
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: type,
                                  groupValue: _selectedAddressType,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedAddressType = value!;
                                    });
                                  },
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                Expanded(
                                  child: Text(
                                    type,
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Name Fields
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'First Name *',
                                labelStyle: TextStyle(fontSize: 12),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                isDense: true,
                              ),
                              validator: (value) => value?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'Last Name *',
                                labelStyle: TextStyle(fontSize: 12),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                isDense: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Required';
                                if (value.trim().length < 2) return 'Min 2 chars';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Phone Number
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          labelStyle: TextStyle(fontSize: 12),
                          hintText: '10-digit mobile',
                          hintStyle: TextStyle(fontSize: 12),
                          prefixIcon: Icon(Icons.phone, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                          counterText: '',
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          if (value.trim().length != 10) return 'Must be 10 digits';
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) return 'Invalid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Address Lines
                      TextFormField(
                        controller: _addressLine1Controller,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Address Line 1 *',
                          labelStyle: TextStyle(fontSize: 12),
                          hintText: 'House/Flat/Office No',
                          hintStyle: TextStyle(fontSize: 12),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          if (value.trim().length < 5) return 'Too short';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _addressLine2Controller,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Address Line 2',
                          labelStyle: TextStyle(fontSize: 12),
                          hintText: 'Area, Colony, Street',
                          hintStyle: TextStyle(fontSize: 12),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _landmarkController,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Landmark',
                          labelStyle: TextStyle(fontSize: 12),
                          hintText: 'Near famous place',
                          hintStyle: TextStyle(fontSize: 12),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // City, State, Pincode
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _cities.contains(_selectedCity) ? _selectedCity : 'Tirupattur',
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'City *',
                                labelStyle: TextStyle(fontSize: 12),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                isDense: true,
                              ),
                              items: _cities.map((city) {
                                return DropdownMenuItem(
                                  value: city,
                                  child: Text(city, style: const TextStyle(color: Colors.black, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCity = value;
                                  });
                                }
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _states.contains(_selectedState) ? _selectedState : 'Tamil Nadu',
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'State *',
                                labelStyle: TextStyle(fontSize: 12),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                isDense: true,
                              ),
                              items: _states.map((state) {
                                return DropdownMenuItem(
                                  value: state,
                                  child: Text(state, style: const TextStyle(color: Colors.black, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                );
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
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pincodeController,
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'Pincode *',
                                labelStyle: TextStyle(fontSize: 12),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                isDense: true,
                                counterText: '',
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Required';
                                if (value.trim().length != 6) return '6 digits';
                                if (!RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location, size: 16),
                              label: const Text('Use GPS', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Delivery Slot
                      const Text('Delivery Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _deliverySlots.map((slot) {
                          return RadioListTile<String>(
                            title: Text(
                              slot['label']!,
                              style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: slot['key']!,
                            groupValue: _selectedDeliverySlot,
                            onChanged: (value) {
                              setState(() {
                                _selectedDeliverySlot = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            activeColor: VillageTheme.primaryGreen,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Delivery Instructions
                      TextFormField(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Delivery Instructions (Optional)',
                          labelStyle: TextStyle(fontSize: 12),
                          hintText: 'Any specific instructions',
                          hintStyle: TextStyle(fontSize: 12),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          _deliveryInstructions = value;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Save Address Info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: VillageTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: VillageTheme.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: VillageTheme.primaryGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This address will be saved for future orders',
                                style: TextStyle(
                                  color: VillageTheme.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Self Pickup Information
            if (_selectedDeliveryType == 'SELF_PICKUP') ...[
              Card(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.store, color: Colors.orange.shade700, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Pickup from Shop',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Collect your order directly from the shop',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 18, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Ready in 15-20 minutes',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Shop owner will notify you when order is ready',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Your Name*',
                          labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: 'Phone Number*',
                          labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          if (value.length != 10) return '10 digits required';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VillageTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payment, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Payment Method',
                          style: VillageTheme.headingMedium.copyWith(
                            color: VillageTheme.primaryGreen,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Choose your payment option',
                          style: VillageTheme.bodySmall.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModernPaymentOption(
                'CASH_ON_DELIVERY',
                'Cash on Delivery',
                'Pay when order arrives',
                Icons.local_shipping,
                Colors.orange,
              ),
              // const SizedBox(height: 10),
              // _buildModernPaymentOption(
              //   'ONLINE',
              //   'Online Payment',
              //   'Pay now with card/wallet',
              //   Icons.credit_card,
              //   Colors.blue,
              // ),
              // const SizedBox(height: 10),
              // _buildModernPaymentOption(
              //   'UPI',
              //   'UPI Payment',
              //   'Pay with UPI apps',
              //   Icons.account_balance_wallet,
              //   VillageTheme.primaryGreen,
              // ),
            ],
          ),

          if (_selectedPaymentMethod == 'ONLINE') ...[
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _cardFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Card Details',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _cardNumberController,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Card Number',
                          labelStyle: TextStyle(fontSize: 12),
                          hintText: '1234 5678 9012 3456',
                          hintStyle: TextStyle(fontSize: 12),
                          prefixIcon: Icon(Icons.credit_card, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                          counterText: '',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 19,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          if (value.replaceAll(' ', '').length < 16) return 'Invalid';
                          return null;
                        },
                        onChanged: (value) => _formatCardNumber(value),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expiryController,
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'Expiry',
                                labelStyle: TextStyle(fontSize: 12),
                                hintText: 'MM/YY',
                                hintStyle: TextStyle(fontSize: 12),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                isDense: true,
                                counterText: '',
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Required';
                                if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(value)) return 'Invalid';
                                return null;
                              },
                              onChanged: (value) => _formatExpiry(value),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvController,
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                                labelStyle: TextStyle(fontSize: 12),
                                hintText: '123',
                                hintStyle: TextStyle(fontSize: 12),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                isDense: true,
                                counterText: '',
                              ),
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Required';
                                if (value.length < 3) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _cardHolderController,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Cardholder Name',
                          labelStyle: TextStyle(fontSize: 12),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _validateAndSaveCardDetails,
                          style: VillageTheme.primaryButtonStyle,
                          child: const Text('Save Card Details', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          if (_selectedPaymentMethod == 'UPI') ...[
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _upiFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'UPI ID',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _upiIdController,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'UPI ID',
                          labelStyle: TextStyle(fontSize: 12),
                          hintText: 'yourname@upi',
                          hintStyle: TextStyle(fontSize: 12),
                          prefixIcon: Icon(Icons.account_balance_wallet, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          if (!value.contains('@')) return 'Invalid UPI ID';
                          if (!RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+$').hasMatch(value)) return 'Invalid format';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _validateAndSaveUPIDetails,
                          style: VillageTheme.primaryButtonStyle,
                          child: const Text('Save UPI Details', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernPaymentOption(String value, String title, String subtitle, IconData icon, Color iconColor) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Card(
        elevation: 2,
        shadowColor: isSelected ? VillageTheme.primaryGreen.withOpacity(0.3) : Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? VillageTheme.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected ? VillageTheme.primaryGreen.withOpacity(0.05) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isSelected ? VillageTheme.primaryGreen : VillageTheme.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isSelected ? VillageTheme.primaryGreen.withOpacity(0.8) : VillageTheme.secondaryText,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? VillageTheme.primaryGreen : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? VillageTheme.primaryGreen : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryStep() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Card
              Card(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: VillageTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Order Summary',
                              style: VillageTheme.headingMedium.copyWith(
                                color: VillageTheme.primaryGreen,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Review your order details',
                              style: VillageTheme.bodySmall.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Order Items Card
              Card(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_bag, color: VillageTheme.primaryGreen, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Items',
                            style: VillageTheme.textLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryGreen,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...cartProvider.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.product.name}',
                                style: VillageTheme.bodyMedium.copyWith(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              Helpers.formatCurrency(item.totalPrice),
                              style: VillageTheme.bodyMedium.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Delivery Address Card
              Card(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: VillageTheme.primaryGreen, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Delivery Address',
                            style: VillageTheme.textLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryGreen,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_nameController.text} ${_lastNameController.text} - ${_phoneController.text}',
                        style: VillageTheme.bodyMedium.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_addressLine1Controller.text}, ${_addressLine2Controller.text}',
                        style: VillageTheme.bodyMedium.copyWith(
                          color: Colors.black,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_landmarkController.text}, $_selectedCity, $_selectedState - ${_pincodeController.text}',
                        style: VillageTheme.bodyMedium.copyWith(
                          color: Colors.black,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Payment Method Card
              Card(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payment, color: VillageTheme.primaryGreen, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Payment Method',
                            style: VillageTheme.textLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryGreen,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedPaymentMethod.replaceAll('_', ' '),
                        style: VillageTheme.bodyMedium.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Bill Details Card
              Card(
                elevation: 2,
                shadowColor: VillageTheme.primaryGreen.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: VillageTheme.primaryGreen.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt, color: VillageTheme.primaryGreen, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Bill Details',
                            style: VillageTheme.textLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryGreen,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                      const Divider(height: 16),
                      _buildBillRow(
                        'Total Amount',
                        Helpers.formatCurrency(cartProvider.total),
                        isTotal: true,
                      ),
                      // Minimum order warning
                      if (cartProvider.subtotal < 100)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Add ₹${(100 - cartProvider.subtotal).toStringAsFixed(2)} more to meet minimum order of ₹100',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isTotal ? VillageTheme.primaryGreen : Colors.black),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Back', style: TextStyle(fontSize: 13)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 10),
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

  void _nextStep() async {
    // Validate address form on step 0
    if (_currentStep == 0) {
      // Check if form validates
      if (!_formKey.currentState!.validate()) {
        _showErrorMessage('Please fill in all required fields');
        return;
      }

      // Additional validation for required fields
      if (_nameController.text.trim().isEmpty) {
        _showErrorMessage('First name is required');
        return;
      }
      // Last name only required for home delivery
      if (_selectedDeliveryType == 'HOME_DELIVERY' && _lastNameController.text.trim().isEmpty) {
        _showErrorMessage('Last name is required');
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        _showErrorMessage('Phone number is required');
        return;
      }
      if (_phoneController.text.trim().length != 10) {
        _showErrorMessage('Phone number must be 10 digits');
        return;
      }
      // Address fields only required for home delivery
      if (_selectedDeliveryType == 'HOME_DELIVERY') {
        if (_addressLine1Controller.text.trim().isEmpty) {
          _showErrorMessage('Address Line 1 is required');
          return;
        }
        if (_pincodeController.text.trim().isEmpty) {
          _showErrorMessage('Pincode is required');
          return;
        }
        if (_pincodeController.text.trim().length != 6) {
          _showErrorMessage('Pincode must be 6 digits');
          return;
        }
      }
    }

    // Validate payment details when moving from payment step
    if (_currentStep == 1) {
      if (!_validatePaymentDetails()) {
        return;
      }
    }

    // Save address when moving from address step
    if (_currentStep == 0) {
      await _saveCurrentAddress();
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validatePaymentDetails() {
    switch (_selectedPaymentMethod) {
      case 'ONLINE':
        if (_cardFormKey.currentState == null || !_cardFormKey.currentState!.validate()) {
          _showErrorMessage('Please fill in all card details correctly');
          return false;
        }
        break;
      case 'UPI':
        if (_upiIdController.text.trim().isEmpty) {
          _showErrorMessage('UPI ID is required. Please enter your UPI ID before proceeding.');
          return false;
        }
        if (!_upiIdController.text.contains('@')) {
          _showErrorMessage('Please enter a valid UPI ID (e.g., yourname@upi)');
          return false;
        }
        if (_upiFormKey.currentState == null || !_upiFormKey.currentState!.validate()) {
          _showErrorMessage('Please enter a valid UPI ID');
          return false;
        }
        break;
      case 'CASH_ON_DELIVERY':
        // No validation needed for COD
        break;
    }
    return true;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  IconData _getAddressTypeIcon(String addressType) {
    switch (addressType.toUpperCase()) {
      case 'HOME':
        return Icons.home;
      case 'WORK':
        return Icons.work;
      case 'OTHER':
        return Icons.location_on;
      default:
        return Icons.location_on;
    }
  }

  void _formatCardNumber(String value) {
    String formatted = value.replaceAll(' ', '');
    String newValue = '';

    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && i % 4 == 0) {
        newValue += ' ';
      }
      newValue += formatted[i];
    }

    _cardNumberController.value = TextEditingValue(
      text: newValue,
      selection: TextSelection.collapsed(offset: newValue.length),
    );
  }

  void _formatExpiry(String value) {
    String formatted = value.replaceAll('/', '');
    String newValue = '';

    for (int i = 0; i < formatted.length && i < 4; i++) {
      if (i == 2) {
        newValue += '/';
      }
      newValue += formatted[i];
    }

    _expiryController.value = TextEditingValue(
      text: newValue,
      selection: TextSelection.collapsed(offset: newValue.length),
    );
  }

  void _validateAndSaveUPIDetails() {
    if (_upiFormKey.currentState!.validate()) {
      _showSuccessMessage('UPI details saved successfully!');
    }
  }

  void _validateAndSaveCardDetails() {
    if (_cardFormKey.currentState!.validate()) {
      _showSuccessMessage('Card details saved successfully!');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: VillageTheme.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
    if (!mounted) return;

    // Get providers before async operations to avoid context issues
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isPlacingOrder = true);

    try {
      if (cartProvider.items.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Check minimum order amount (₹100)
      const double minimumOrderAmount = 100.0;
      if (cartProvider.subtotal < minimumOrderAmount) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'Minimum order amount is ₹${minimumOrderAmount.toStringAsFixed(0)}. Current subtotal is ₹${cartProvider.subtotal.toStringAsFixed(2)}',
            isError: true,
          );
        }
        setState(() => _isPlacingOrder = false);
        return;
      }

      // Ensure user is authenticated before placing order
      if (!authProvider.isAuthenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to place an order'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pushNamed(context, '/login');
        }
        return;
      }

      print('🔍 Debug - User authenticated with userId: ${authProvider.userId}');
      print('🔍 Debug - Cart items count: ${cartProvider.items.length}');
      if (cartProvider.items.isNotEmpty) {
        print('🔍 Debug - First product shopId: ${cartProvider.items.first.product.shopId}');
      }

      // Get user email from AuthService
      final userEmail = await AuthService.getCurrentUserEmail() ?? 'customer@example.com';

      // Ensure all required fields are filled
      final firstName = _nameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final phone = _phoneController.text.trim();
      final address1 = _addressLine1Controller.text.trim();
      final address2 = _addressLine2Controller.text.trim();
      final pincode = _pincodeController.text.trim();

      // Detailed validation with specific error messages
      if (firstName.isEmpty) {
        Helpers.showSnackBar(context, 'Please enter your first name', isError: true);
        setState(() => _isPlacingOrder = false);
        return;
      }

      if (phone.isEmpty) {
        Helpers.showSnackBar(context, 'Please enter your phone number', isError: true);
        setState(() => _isPlacingOrder = false);
        return;
      }

      // Only validate address fields for home delivery
      if (_selectedDeliveryType == 'HOME_DELIVERY') {
        if (lastName.isEmpty) {
          Helpers.showSnackBar(context, 'Please enter your last name', isError: true);
          setState(() => _isPlacingOrder = false);
          return;
        }

        if (address1.isEmpty) {
          Helpers.showSnackBar(context, 'Please enter your street address', isError: true);
          setState(() => _isPlacingOrder = false);
          return;
        }

        if (pincode.isEmpty) {
          Helpers.showSnackBar(context, 'Please enter your pincode', isError: true);
          setState(() => _isPlacingOrder = false);
          return;
        }
      }

      // Get actual shop ID from cart items
      final shopId = cartProvider.items.isNotEmpty
          ? (int.tryParse(cartProvider.items.first.product.shopId.toString()) ?? cartProvider.items.first.product.shopId)
          : null;

      if (shopId == null) {
        Helpers.showSnackBar(context, 'Invalid shop information', isError: true);
        setState(() => _isPlacingOrder = false);
        return;
      }

      // Create order request matching current backend expectation
      final orderRequest = {
        'shopId': shopId,  // Dynamic shop ID from cart
        'deliveryType': _selectedDeliveryType,
        'items': cartProvider.items.map((item) => {
          'productId': int.tryParse(item.product.id.toString()) ?? item.product.id,
          'productName': item.product.name,
          'price': item.product.effectivePrice,
          'quantity': item.quantity,
          'unit': 'piece'
        }).toList(),
        if (_selectedDeliveryType == 'HOME_DELIVERY')
          'deliveryAddress': {
            'streetAddress': address1 + (address2.isNotEmpty ? ', $address2' : ''),
            'landmark': _landmarkController.text.trim().isNotEmpty ? _landmarkController.text.trim() : _deliveryInstructions.isNotEmpty ? _deliveryInstructions : null,
            'city': _selectedCity,
            'state': _selectedState,
            'pincode': pincode
          },
        'paymentMethod': _selectedPaymentMethod,
        'subtotal': cartProvider.subtotal,
        'deliveryFee': _selectedDeliveryType == 'SELF_PICKUP' ? 0 : cartProvider.deliveryFee,
        'discount': cartProvider.promoDiscount,
        'total': _selectedDeliveryType == 'SELF_PICKUP' ? cartProvider.subtotal - cartProvider.promoDiscount : cartProvider.total,
        'notes': _deliveryInstructions.isNotEmpty ? _deliveryInstructions : null,
        'customerInfo': {
          'firstName': firstName,
          'lastName': lastName.isNotEmpty ? lastName : '',
          'phone': phone,
          'email': userEmail
        }
      };

      print('🚀 Placing order with request: ${orderRequest.toString()}');
      final result = await OrderService().placeOrder(orderRequest);
      print('📦 Order result: ${result.toString()}');

      if (result['success']) {
        // Clear cart on success
        cartProvider.clearCart();

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Order placed successfully!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: VillageTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(12),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Failed to place order',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(12),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Order placement error: $e');
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to place order: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final locationAddress = await LocationService.instance.getCurrentLocationAddress();

      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      if (locationAddress != null) {
        setState(() {
          // Set address fields based on location
          if (locationAddress['street']?.isNotEmpty == true) {
            _addressLine1Controller.text = locationAddress['street']!;
          }
          if (locationAddress['subLocality']?.isNotEmpty == true) {
            _addressLine2Controller.text = locationAddress['subLocality']!;
          }
          if (locationAddress['postalCode']?.isNotEmpty == true) {
            _pincodeController.text = locationAddress['postalCode']!;
          }
          // Force Tirupattur and Tamil Nadu
          _selectedCity = 'Tirupattur';
          _selectedState = 'Tamil Nadu';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location updated successfully!'),
              backgroundColor: VillageTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(12),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to get current location. Please enable location services.'),
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(12),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(12),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
