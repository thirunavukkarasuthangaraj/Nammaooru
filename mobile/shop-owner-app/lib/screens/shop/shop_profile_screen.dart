import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../models/shop_profile.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _gstNumberController;

  Map<String, BusinessHours> _businessHours = {};
  bool _isDeliveryAvailable = true;
  double _deliveryRadius = 5.0;
  double _minimumOrderAmount = 100.0;

  final List<String> _categories = [
    'General Store',
    'Medical Store',
    'Grocery Store',
    'Electronics Store',
    'Clothing Store',
    'Restaurant',
    'Bakery',
    'Stationery',
  ];

  String _selectedCategory = 'General Store';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeBusinessHours();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShopProfile();
    });
  }

  void _initializeControllers() {
    _shopNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _gstNumberController = TextEditingController();
  }

  void _initializeBusinessHours() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    for (String day in days) {
      _businessHours[day] = BusinessHours(
        day: day,
        isOpen: day != 'Sunday',
        openTime: const TimeOfDay(hour: 9, minute: 0),
        closeTime: const TimeOfDay(hour: 21, minute: 0),
      );
    }
  }

  void _loadShopProfile() {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    shopProvider.loadProfile();

    if (shopProvider.profile != null) {
      _populateFields(shopProvider.profile!);
    } else {
      _shopNameController.text = authProvider.currentUser?.shopName ?? '';
    }
  }

  void _populateFields(ShopProfile profile) {
    _shopNameController.text = profile.shopName;
    _descriptionController.text = profile.description;
    _addressController.text = profile.address;
    _phoneController.text = profile.phone;
    _emailController.text = profile.email;
    _gstNumberController.text = profile.gstNumber ?? '';
    _selectedCategory = profile.category;
    _isDeliveryAvailable = profile.isDeliveryAvailable;
    _deliveryRadius = profile.deliveryRadius;
    _minimumOrderAmount = profile.minimumOrderAmount;

    if (profile.businessHours.isNotEmpty) {
      _businessHours = Map.fromEntries(
        profile.businessHours.map((bh) => MapEntry(bh.day, bh)),
      );
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.padding),
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildContactInfoSection(),
                const SizedBox(height: 24),
                _buildBusinessHoursSection(),
                const SizedBox(height: 24),
                _buildDeliverySettingsSection(),
                const SizedBox(height: 32),
                _buildSaveButton(shopProvider),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
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
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: 'Shop Name *',
                hintText: 'Enter your shop name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Shop name is required';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Shop Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
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
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your shop and what you sell',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gstNumberController,
              decoration: const InputDecoration(
                labelText: 'GST Number',
                hintText: 'Enter GST number (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Shop Address *',
                hintText: 'Enter complete shop address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Shop address is required';
                }
                return null;
              },
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'Enter contact number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (value.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter email address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Hours',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            ..._businessHours.entries.map((entry) => _buildDaySchedule(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySchedule(String day, BusinessHours hours) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: hours.isOpen,
            onChanged: (value) {
              setState(() {
                _businessHours[day] = hours.copyWith(isOpen: value);
              });
            },
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: 12),
          if (hours.isOpen) ...[
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(day, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hours.openTime.format(context),
                    style: AppTextStyles.body,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(' - '),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(day, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hours.closeTime.format(context),
                    style: AppTextStyles.body,
                  ),
                ),
              ),
            ),
          ] else
            Expanded(
              child: Text(
                'Closed',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliverySettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Settings',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Delivery Available'),
              subtitle: const Text('Enable delivery service for customers'),
              value: _isDeliveryAvailable,
              onChanged: (value) => setState(() => _isDeliveryAvailable = value),
              activeColor: AppColors.primary,
            ),
            if (_isDeliveryAvailable) ...[
              const SizedBox(height: 16),
              Text(
                'Delivery Radius: ${_deliveryRadius.toStringAsFixed(1)} km',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              ),
              Slider(
                value: _deliveryRadius,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                label: '${_deliveryRadius.toStringAsFixed(1)} km',
                onChanged: (value) => setState(() => _deliveryRadius = value),
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _minimumOrderAmount.toStringAsFixed(0),
                decoration: const InputDecoration(
                  labelText: 'Minimum Order Amount (₹)',
                  hintText: 'Enter minimum order value for delivery',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  if (amount != null) {
                    _minimumOrderAmount = amount;
                  }
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Customers within the delivery radius can place orders',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(ShopProvider shopProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: shopProvider.isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: shopProvider.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Save Profile'),
      ),
    );
  }

  Future<void> _selectTime(String day, bool isOpenTime) async {
    final currentHours = _businessHours[day]!;
    final currentTime = isOpenTime ? currentHours.openTime : currentHours.closeTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _businessHours[day] = currentHours.copyWith(openTime: picked);
        } else {
          _businessHours[day] = currentHours.copyWith(closeTime: picked);
        }
      });
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    final profileData = ShopProfile(
      id: shopProvider.profile?.id ?? '',
      shopName: _shopNameController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      gstNumber: _gstNumberController.text.trim().isEmpty ? null : _gstNumberController.text.trim(),
      businessHours: _businessHours.values.toList(),
      isDeliveryAvailable: _isDeliveryAvailable,
      deliveryRadius: _deliveryRadius,
      minimumOrderAmount: _minimumOrderAmount,
      isActive: shopProvider.profile?.isActive ?? true,
      createdAt: shopProvider.profile?.createdAt ?? DateTime.now(),
    );

    final success = await shopProvider.updateProfile(profileData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shopProvider.errorMessage ?? 'Failed to update profile',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}