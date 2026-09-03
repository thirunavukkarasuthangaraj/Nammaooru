import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/services/order_payment_service.dart';
import '../../../core/services/delivery_fee_service.dart';
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
import '../../../core/storage/local_storage.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/address_service.dart';
import '../../../core/models/address_model.dart';
import '../../../services/address_api_service.dart';
import '../../../core/services/promo_code_service.dart';
import '../../../core/services/device_info_service.dart';
import '../../../core/api/api_client.dart';
import '../widgets/promo_code_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/address_management_screen.dart';
import '../../../services/shop_api_service.dart';
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
  Razorpay? _razorpay;
  _PendingOnlinePayment? _pendingOnlinePayment;
  double _gatewayFeePercent = 0.0;


  // Delivery
  String _selectedDeliverySlot = 'ASAP';
  String _deliveryInstructions = '';

  // Promo Code
  PromoCodeValidationResult? _appliedPromo;
  String? _appliedPromoCode;

  final List<String> _addressTypes = ['HOME', 'WORK', 'OTHER'];
  final List<String> _cities = ['Tirupattur']; // Only Tirupattur for now
  final List<String> _states = ['Tamil Nadu'];
  final List<Map<String, dynamic>> _deliveryTypes = [
    {'key': 'HOME_DELIVERY', 'label': 'Home Delivery', 'icon': Icons.delivery_dining_rounded},
    {'key': 'SELF_PICKUP', 'label': 'Self Pickup', 'icon': Icons.storefront_rounded},
  ];
  final List<String> _paymentMethods = ['CASH_ON_DELIVERY', 'ONLINE_PAYMENT'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkAuthentication();
      await _loadUserData(); // Load profile data first
      await _loadSavedAddresses(); // Then load addresses
      // Previously this only ran once the user tapped "Next" on the address
      // step, so a cart carried over from an earlier session showed whatever
      // delivery fee was last saved (e.g. a stale platform-fallback ₹50) until
      // that tap happened. Running it here too means the bill summary is
      // correct from the moment checkout opens, using the address that just loaded.
      await _recalculateDeliveryFee();
    });
    OrderPaymentService.getGatewayFeePercent().then((percent) {
      if (mounted) setState(() => _gatewayFeePercent = percent);
    });
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      // Fetch complete user profile from API
      try {
        final response = await ApiClient.get('/users/me');

        if (response.statusCode == 200) {
          final responseData = response.data;
          if (responseData is Map<String, dynamic>) {
            final userData = responseData['data'];

            if (userData != null && mounted) {
              // Extract data before setState
              final firstName = userData['firstName'] ?? '';
              final lastName = userData['lastName'] ?? '';
              final phoneNumber = userData['mobileNumber'] ?? '';

              setState(() {
                // Auto-populate first name
                if (firstName.isNotEmpty) {
                  _nameController.text = firstName;
                }

                // Auto-populate last name
                if (lastName.isNotEmpty) {
                  _lastNameController.text = lastName;
                }

                // Auto-populate phone number
                if (phoneNumber.isNotEmpty) {
                  _phoneController.text = phoneNumber;
                }
              });

              debugPrint('✅ User data loaded: firstName=$firstName, lastName=$lastName, phone=$phoneNumber');
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading user profile from API: $e');

        // Fallback to JWT token for name only
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
                  _lastNameController.text = userName;
                }
              }
            });
          }
        } catch (e) {
          debugPrint('Error loading user data from JWT: $e');
        }
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
      context.go('/register');
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
    _razorpay?.clear();

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
          await _loadAddressToFields(defaultAddress);
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
          await _loadAddressToFields(defaultAddress);
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
        await _loadAddressToFields(defaultAddress);
        setState(() {
          _selectedSavedAddress = defaultAddress;
        });
      } else if (addresses.isNotEmpty && _preventFieldReload) {
        setState(() {});
      }
    }
  }

  Future<void> _loadAddressToFields(SavedAddress address) async {
    print('🔍 Loading address to fields: name=${address.name}, lastName=${address.lastName}, phone=${address.phone}');

    // Only load name and phone from address if they exist, otherwise preserve current values or use profile
    if (address.name.isNotEmpty) {
      _nameController.text = address.name;
    } else if (_nameController.text.isEmpty) {
      // Only load from profile if field is currently empty
      final firstName = await LocalStorage.getString('firstName') ?? '';
      if (firstName.isNotEmpty) {
        _nameController.text = firstName;
      }
    }

    if (address.lastName.isNotEmpty) {
      _lastNameController.text = address.lastName;
    } else if (_lastNameController.text.isEmpty) {
      // Only load from profile if field is currently empty
      final lastName = await LocalStorage.getString('lastName') ?? '';
      if (lastName.isNotEmpty) {
        _lastNameController.text = lastName;
      }
    }

    if (address.phone.isNotEmpty) {
      _phoneController.text = address.phone;
    } else if (_phoneController.text.isEmpty) {
      // Only load from profile if field is currently empty
      final phoneNumber = await LocalStorage.getString('phoneNumber') ?? '';
      if (phoneNumber.isNotEmpty) {
        _phoneController.text = phoneNumber;
      }
    }

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

    // Convert address type to uppercase to match radio button values
    _selectedAddressType = address.addressType.toUpperCase();
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                                    Icon(
                                      type['icon'] as IconData,
                                      size: 30,
                                      color: isSelected ? Colors.white : VillageTheme.primaryGreen,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      type['label'] as String,
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
                                  onTap: () async {
                                    // Navigate to address management screen with auto-open manual form
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddressManagementScreen(autoOpenManualForm: true),
                                      ),
                                    );
                                    // Reload addresses after returning
                                    await _loadSavedAddresses();
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
                                onTap: () async {
                                  await _loadAddressToFields(address);
                                  setState(() {
                                    _selectedSavedAddress = address;
                                  });
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
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Required';
                                return null;
                              },
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
                        validator: (value) {
                          // Optional field, but if entered, must be valid
                          if (value != null && value.trim().isNotEmpty) {
                            if (value.trim().length < 3) return 'Too short (min 3 chars)';
                            if (value.trim().length > 100) return 'Too long (max 100 chars)';
                          }
                          return null;
                        },
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
                        validator: (value) {
                          // Optional field, but if entered, must be valid
                          if (value != null && value.trim().isNotEmpty) {
                            if (value.trim().length < 3) return 'Too short (min 3 chars)';
                            if (value.trim().length > 100) return 'Too long (max 100 chars)';
                          }
                          return null;
                        },
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

                      // Pincode field
                      TextFormField(
                        controller: _pincodeController,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Pincode *',
                          labelStyle: TextStyle(fontSize: 12, color: Colors.black87),
                          hintText: 'Enter 6-digit pincode',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.black45),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
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
                      const SizedBox(height: 12),

                      // Delivery Time - Fixed to ASAP (30-40 mins)
                      const Text('Delivery Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: VillageTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: VillageTheme.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.access_time, size: 18, color: VillageTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text(
                              'ASAP (30-40 mins)',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
                        validator: (value) {
                          // Optional field, but if entered, must be valid
                          if (value != null && value.trim().isNotEmpty) {
                            if (value.trim().length < 5) return 'Too short (min 5 chars)';
                            if (value.trim().length > 200) return 'Too long (max 200 chars)';
                          }
                          return null;
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              const SizedBox(height: 10),
              _buildModernPaymentOption(
                'ONLINE_PAYMENT',
                'Online Payment',
                'Pay now via UPI, card or wallet',
                Icons.credit_card,
                Colors.blue,
              ),
            ],
          ),

          if (_selectedPaymentMethod == 'ONLINE_PAYMENT') ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You\'ll be taken to a secure Razorpay checkout to complete payment. '
                        'A small gateway fee is added to the total to cover the payment processing cost.',
                        style: TextStyle(fontSize: 12.5, color: Colors.blue.shade900, height: 1.4),
                      ),
                    ),
                  ],
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    '${item.quantity}x ',
                                    style: VillageTheme.bodyMedium.copyWith(
                                      color: VillageTheme.primaryGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: VillageTheme.bodyMedium.copyWith(
                                            color: Colors.black,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.product.nameTamil != null && item.product.nameTamil!.isNotEmpty)
                                          Text(
                                            item.product.nameTamil!,
                                            style: VillageTheme.bodyMedium.copyWith(
                                              color: Colors.grey[600],
                                              fontSize: 10,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (item.product.unit.isNotEmpty && item.product.unit != 'piece') ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: Colors.green.shade200, width: 0.5),
                                      ),
                                      child: Text(
                                        item.product.unit,
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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

              // Promo Code Widget
              PromoCodeWidget(
                orderAmount: cartProvider.subtotal,
                shopId: cartProvider.items.isNotEmpty
                    ? cartProvider.items.first.product.shopDatabaseId?.toString()
                    : null,
                customerId: Provider.of<AuthProvider>(context, listen: false).userId?.toString(),
                customerPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
                onPromoApplied: (result) {
                  setState(() {
                    _appliedPromo = result;
                    _appliedPromoCode = result.promotionTitle;
                  });
                  // Update cart provider with discount
                  cartProvider.applyPromoDiscount(result.discountAmount);
                },
                onPromoRemoved: () {
                  setState(() {
                    _appliedPromo = null;
                    _appliedPromoCode = null;
                  });
                  // Remove discount from cart
                  cartProvider.applyPromoDiscount(0);
                },
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
                      if (_selectedPaymentMethod == 'ONLINE_PAYMENT' && _onlinePaymentFee(cartProvider.total) > 0)
                        _buildBillRow(
                          'Online Payment Fee',
                          Helpers.formatCurrency(_onlinePaymentFee(cartProvider.total)),
                        ),
                      const Divider(height: 16),
                      _buildBillRow(
                        'Total Amount',
                        Helpers.formatCurrency(cartProvider.total + _onlinePaymentFeeIfApplicable(cartProvider.total)),
                        isTotal: true,
                      ),
                      // Minimum order warning
                      if (cartProvider.subtotal < (cartProvider.minOrderAmount ?? 100.0))
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
                                  'Add ₹${((cartProvider.minOrderAmount ?? 100.0) - cartProvider.subtotal).toStringAsFixed(2)} more to meet minimum order of ₹${(cartProvider.minOrderAmount ?? 100.0).toStringAsFixed(0)}',
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

  // Estimate only, for display before the order is placed — the backend
  // computes and charges the authoritative amount in OrderPaymentService.
  double _onlinePaymentFee(double orderTotal) {
    return double.parse((orderTotal * _gatewayFeePercent / 100).toStringAsFixed(2));
  }

  double _onlinePaymentFeeIfApplicable(double orderTotal) {
    return _selectedPaymentMethod == 'ONLINE_PAYMENT' ? _onlinePaymentFee(orderTotal) : 0.0;
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
        child: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return Row(
              children: [
                // Payable amount stays visible on every checkout step
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      Helpers.formatCurrency(cartProvider.total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: VillageTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
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
                          onPressed:
                              _currentStep == 2 ? _placeOrder : _nextStep,
                          icon: _currentStep == 2
                              ? Icons.check
                              : Icons.arrow_forward,
                        ),
                ),
              ],
            );
          },
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

    // Save address when moving from address step
    if (_currentStep == 0) {
      await _saveCurrentAddress();
      await _recalculateDeliveryFee();
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Replaces CartProvider's hardcoded ₹30 default with the real distance-based
  /// fee (admin-configured tiers via /api/delivery-fees/calculate). Self Pickup
  /// doesn't need a delivery fee at all — the order submission already forces
  /// it to 0 for that case — so this only runs for Home Delivery. Best-effort:
  /// if the shop/customer coordinates aren't available or the call fails, the
  /// existing fee is left as-is rather than blocking checkout over it.
  Future<void> _recalculateDeliveryFee() async {
    if (_selectedDeliveryType != 'HOME_DELIVERY' || !mounted) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.items.isEmpty) return;

    final customerLat = _selectedSavedAddress?.latitude ?? LocationService.cachedLatitude;
    final customerLng = _selectedSavedAddress?.longitude ?? LocationService.cachedLongitude;
    if (customerLat == null || customerLng == null) return;

    final shopId = int.tryParse(cartProvider.items.first.product.shopDatabaseId.toString());
    if (shopId == null) return;

    try {
      final shopResponse = await ShopApiService().getShopById(shopId);
      final shopData = shopResponse['data'];
      final shopLat = (shopData?['latitude'] as num?)?.toDouble();
      final shopLng = (shopData?['longitude'] as num?)?.toDouble();
      if (shopLat == null || shopLng == null) return;

      final result = await DeliveryFeeService.instance.calculateDeliveryFee(
        shopLatitude: shopLat,
        shopLongitude: shopLng,
        customerLatitude: customerLat,
        customerLongitude: customerLng,
        shopId: shopId,
      );
      if (result != null && result.success && mounted) {
        cartProvider.setDeliveryFee(result.deliveryFee);
      }
    } catch (e) {
      print('⚠️ Delivery fee recalculation failed, keeping existing fee: $e');
    }
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

      // Per-shop minimum order amount (shop.minOrderAmount, set in the shop's
      // own profile) — falls back to ₹100 only if that value was never loaded
      // (e.g. a cart restored from storage saved before this field existed).
      // A shop that has explicitly set 0 means "no minimum", not "unknown".
      final double minimumOrderAmount = cartProvider.minOrderAmount ?? 100.0;
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

      // Get actual shop database ID from cart items
      final shopId = cartProvider.items.isNotEmpty
          ? cartProvider.items.first.product.shopDatabaseId
          : null;

      if (shopId == null) {
        Helpers.showSnackBar(context, 'Invalid shop information. Please try adding items again.', isError: true);
        setState(() => _isPlacingOrder = false);
        return;
      }

      // Check if shop is open before placing order (using cached status, no API call needed)
      if (!cartProvider.isShopOpen) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.store_outlined, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  const Text('Shop Closed'),
                ],
              ),
              content: Text(
                'Sorry, ${cartProvider.shopName ?? 'the shop'} is currently closed and not accepting orders. Please try again during business hours.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VillageTheme.primaryGreen,
                  ),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        setState(() => _isPlacingOrder = false);
        return;
      }

      // Get device UUID for promo code tracking
      final deviceUuid = await DeviceInfoService().getDeviceUuid();

      // Create order request matching current backend expectation
      final orderRequest = {
        'shopId': shopId,  // Dynamic shop ID from cart
        'deliveryType': _selectedDeliveryType,
        'items': cartProvider.items.map((item) => {
          'productId': int.tryParse(item.product.id.toString()) ?? item.product.id,
          'productName': item.product.name,
          'productNameTamil': item.product.nameTamil,
          'price': item.product.effectivePrice,
          'quantity': item.quantity,
          'unit': 'piece'
        }).toList(),
        // Include promo code if applied
        if (_appliedPromo != null && _appliedPromo!.promotionId != null) ...{
          'couponCode': _appliedPromoCode,
          'promotionId': _appliedPromo!.promotionId,
          'deviceUuid': deviceUuid,
        },
        if (_selectedDeliveryType == 'HOME_DELIVERY')
          'deliveryAddress': {
            'streetAddress': address1 + (address2.isNotEmpty ? ', $address2' : ''),
            'landmark': _landmarkController.text.trim().isNotEmpty ? _landmarkController.text.trim() : _deliveryInstructions.isNotEmpty ? _deliveryInstructions : null,
            'city': _selectedCity,
            'state': _selectedState,
            'pincode': pincode,
            // Delivery coordinates: the backend validates them against the
            // shop's delivery radius. Saved address coordinates win; otherwise
            // fall back to the location the shops were browsed from.
            'latitude': _selectedSavedAddress?.latitude ?? LocationService.cachedLatitude,
            'longitude': _selectedSavedAddress?.longitude ?? LocationService.cachedLongitude,
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
        final data = result['data'];
        final orderNumber = (data is Map && data['orderNumber'] != null)
            ? data['orderNumber'].toString()
            : null;
        final orderId = (data is Map && data['id'] != null)
            ? int.tryParse(data['id'].toString())
            : null;

        if (_selectedPaymentMethod == 'ONLINE_PAYMENT' && orderId != null) {
          // Order exists now but is unpaid (PENDING) — don't clear the cart or
          // show success until the payment itself actually goes through.
          await _startOnlinePayment(orderId: orderId, orderNumber: orderNumber, cartProvider: cartProvider);
        } else {
          // Big, un-missable confirmation (village users overlook SnackBar
          // toasts) + guaranteed navigation away from checkout. The previous
          // code showed a toast and called context.go() after 500ms - but this
          // screen is pushed imperatively on the ROOT navigator, so context.go
          // only rebuilt the dashboard UNDERNEATH it; checkout stayed on top
          // and re-taps created duplicate orders.
          cartProvider.clearCart();
          if (mounted) {
            _showOrderSuccessDialog(orderNumber);
          }
        }
      } else {
        // Surface the real underlying error (order_service.dart tucks it into
        // 'error' but the generic 'message' hides it) so failures are debuggable
        // from the UI alone instead of needing browser/device console access.
        final baseMessage = result['message'] ?? 'Failed to place order';
        final detail = result['error']?.toString();
        final displayMessage = (detail != null && detail.isNotEmpty && detail != baseMessage)
            ? '$baseMessage\n($detail)'
            : baseMessage;
        print('❌ Order placement failed: $result');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                displayMessage,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(12),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
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

  /// The order already exists (PENDING/unpaid) at this point. Creates the
  /// Razorpay order and opens checkout; only on confirmed payment does the
  /// cart get cleared and the success dialog shown. On any failure/cancel,
  /// the just-created order is cancelled so it doesn't linger unpaid.
  Future<void> _startOnlinePayment({
    required int orderId,
    required String? orderNumber,
    required CartProvider cartProvider,
  }) async {
    final createResult = await OrderPaymentService.createOrder(orderId);
    if (createResult['success'] != true) {
      await _abandonUnpaidOrder(orderId, createResult['message'] ?? 'Could not start payment');
      return;
    }

    final paymentData = createResult['data'] as Map;
    final bool isTestMode = paymentData['testMode'] == true;
    final String razorpayOrderId = paymentData['razorpayOrderId'].toString();
    final double gatewayFee = (paymentData['gatewayFeeAmount'] as num?)?.toDouble() ?? 0.0;
    final double totalCharged = (paymentData['totalChargedAmount'] as num?)?.toDouble() ?? 0.0;

    if (isTestMode) {
      await _handleTestModeOrderPayment(
          orderId, orderNumber, razorpayOrderId, cartProvider, gatewayFee, totalCharged);
      return;
    }

    if (gatewayFee > 0 && mounted) {
      final proceed = await _confirmGatewayFee(gatewayFee, totalCharged);
      if (proceed != true) {
        await _abandonUnpaidOrder(orderId, null);
        return;
      }
    }

    _pendingOnlinePayment = _PendingOnlinePayment(orderId, orderNumber, cartProvider);
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleOrderPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleOrderPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    final options = {
      'key': paymentData['keyId'],
      'amount': paymentData['amountPaise'],
      'currency': paymentData['currency'] ?? 'INR',
      'name': 'NammaOoru',
      'description': 'Order ${orderNumber ?? orderId}',
      'order_id': razorpayOrderId,
      'prefill': {'contact': _phoneController.text.trim()},
      'theme': {'color': '#2E7D32'},
      // UPI carries zero MDR by law; card/netbanking/wallet don't, and Razorpay's
      // order amount is fixed before the customer picks a method, so we can't
      // charge a fee only on the non-UPI ones. Restricting to UPI here keeps this
      // gateway fee-free without needing per-method pricing. Mirror this in the
      // Razorpay Dashboard (Settings > Payment Methods) too — that's the
      // authoritative, server-side control; this is defense-in-depth on the client.
      'method': {'netbanking': 0, 'card': 0, 'wallet': 0, 'upi': 1, 'paylater': 0},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      await _abandonUnpaidOrder(orderId, 'Unable to open payment gateway');
    }
  }

  /// Shows the Razorpay gateway fee that gets added on top of the order total
  /// before charging the card/UPI — the app's own bill summary only shows the
  /// order total, so without this the amount Razorpay asks for looks wrong.
  Future<bool?> _confirmGatewayFee(double gatewayFee, double totalCharged) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payment Gateway Fee'),
        content: Text(
          'A payment gateway fee of ₹${gatewayFee.toStringAsFixed(2)} applies to online payments.\n\n'
          'Total to be charged: ₹${totalCharged.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: VillageTheme.primaryGreen, foregroundColor: Colors.white),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTestModeOrderPayment(int orderId, String? orderNumber, String razorpayOrderId,
      CartProvider cartProvider, double gatewayFee, double totalCharged) async {
    final feeText = gatewayFee > 0
        ? '\n\nPayment gateway fee: ₹${gatewayFee.toStringAsFixed(2)}\nTotal to be charged: ₹${totalCharged.toStringAsFixed(2)}'
        : '';
    final pay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('TEST MODE', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('This is a test payment. No real money will be charged.$feeText'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Simulate Pay'),
          ),
        ],
      ),
    );

    if (pay != true) {
      await _abandonUnpaidOrder(orderId, null);
      return;
    }

    final verifyResult = await OrderPaymentService.verifyPayment(
      orderId: orderId,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: 'test_pay_${DateTime.now().millisecondsSinceEpoch}',
      razorpaySignature: null,
    );
    await _completeOnlinePayment(verifyResult, orderId, orderNumber, cartProvider);
  }

  void _handleOrderPaymentSuccess(PaymentSuccessResponse response) async {
    final pending = _pendingOnlinePayment;
    _razorpay?.clear();
    if (pending == null) return;

    final verifyResult = await OrderPaymentService.verifyPayment(
      orderId: pending.orderId,
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature,
    );
    await _completeOnlinePayment(verifyResult, pending.orderId, pending.orderNumber, pending.cartProvider);
  }

  void _handleOrderPaymentError(PaymentFailureResponse response) async {
    final pending = _pendingOnlinePayment;
    _razorpay?.clear();
    if (pending == null) return;

    // Cancelling via the device back button (rather than Razorpay's own close
    // button) comes through with code=PAYMENT_CANCELLED but response.message
    // as the literal string "undefined" (a JS-bridge artifact on Android),
    // not a real Dart null — so a plain `?? fallback` doesn't catch it.
    final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    final message = isCancelled || response.message == null || response.message == 'undefined'
        ? 'Payment cancelled'
        : response.message!;
    await _abandonUnpaidOrder(pending.orderId, message);
  }

  Future<void> _completeOnlinePayment(
      Map<String, dynamic> verifyResult, int orderId, String? orderNumber, CartProvider cartProvider) async {
    _pendingOnlinePayment = null;
    if (verifyResult['success'] == true) {
      cartProvider.clearCart();
      if (mounted) {
        _showOrderSuccessDialog(orderNumber);
      }
    } else {
      await _abandonUnpaidOrder(orderId, verifyResult['message'] ?? 'Payment verification failed');
    }
  }

  /// Cancels an order left unpaid after a failed/cancelled online payment, so it
  /// doesn't sit around as a phantom PENDING order the customer never actually paid for.
  Future<void> _abandonUnpaidOrder(int orderId, String? reason) async {
    try {
      await OrderService().cancelOrder(orderId.toString(), 'Online payment not completed');
    } catch (_) {
      // Best-effort cleanup — even if cancellation itself fails, the order stays
      // unpaid (PENDING) and won't be settled to anyone, so nothing is lost silently.
    }
    if (mounted && reason != null) {
      Helpers.showSnackBar(context, reason, isError: true);
    }
  }

  /// Big SweetAlert-style order confirmation. Not dismissible by tapping
  /// outside or the back button - the only way forward is the button, which
  /// pops the checkout page off the ROOT navigator (it was pushed there
  /// imperatively, so context.go alone can't remove it) and then routes to
  /// the orders screen. English + Tamil so village customers can't miss it.
  void _showOrderSuccessDialog(String? orderNumber) {
    final router = GoRouter.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: VillageTheme.primaryGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded,
                      color: VillageTheme.primaryGreen, size: 72),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Order Placed!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'உங்கள் ஆர்டர் வெற்றிகரமாக வைக்கப்பட்டது',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                if (orderNumber != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Order #$orderNumber',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VillageTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      // 1. close this dialog
                      Navigator.of(dialogContext).pop();
                      // 2. remove the checkout page itself from the root stack
                      Navigator.of(context, rootNavigator: true).pop();
                      // 3. land on the orders list (router captured before the
                      //    pop so it survives this widget being disposed)
                      router.go('/customer/orders');
                    },
                    child: const Text(
                      'View My Orders',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> _openMapLocation() async {
    try {
      // Default location: Tirupattur, Tamil Nadu
      const double defaultLat = 12.4996;
      const double defaultLng = 78.5766;

      // Open Google Maps in browser with Tirupattur location
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$defaultLat,$defaultLng',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Google Maps opened. After viewing your location, you can manually enter your address above.'),
              backgroundColor: VillageTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(12),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('Could not open Google Maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening map: ${e.toString()}'),
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

/// Carries the just-created order's identity across the async gap while
/// Razorpay's own checkout UI is open, so the success/error callbacks know
/// which order to verify or abandon.
class _PendingOnlinePayment {
  final int orderId;
  final String? orderNumber;
  final CartProvider cartProvider;
  _PendingOnlinePayment(this.orderId, this.orderNumber, this.cartProvider);
}
