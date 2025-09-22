import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/storage/local_storage.dart';
import '../../../services/address_api_service.dart';
import 'google_maps_location_picker_screen.dart';
import '../../../core/services/address_service.dart';
import '../widgets/address_selection_dialog.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      // First try to load from API
      final result = await AddressApiService.getUserAddresses();
      
      if (mounted) {
        if (result['success']) {
          final addresses = result['data'] as List<dynamic>? ?? [];
          setState(() {
            _addresses = addresses.map((addr) => Map<String, dynamic>.from(addr)).toList();
            _isLoading = false;
          });
        } else {
          // API failed, try to load from cache
          await _loadCachedAddresses();
          if (mounted && _addresses.isEmpty) {
            Helpers.showSnackBar(context, result['message'] ?? 'Failed to load addresses', isError: true);
          }
        }
      }
    } catch (e) {
      // Error with API, try to load from cache
      await _loadCachedAddresses();
      if (mounted && _addresses.isEmpty) {
        Helpers.showSnackBar(context, 'Error loading addresses: $e', isError: true);
      }
    }
  }

  Future<void> _loadCachedAddresses() async {
    try {
      final cachedAddresses = await LocalStorage.getList('user_addresses');
      if (mounted) {
        setState(() {
          _addresses = cachedAddresses.map((addr) => Map<String, dynamic>.from(addr)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _addresses = [];
        });
      }
    }
  }


  void _showAddAddressDialog() {
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add_location, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.black54),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: labelController,
                    decoration: InputDecoration(
                      labelText: 'Label (e.g., Home, Office)',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.label_outline, color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    style: const TextStyle(color: Colors.black87),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a label';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Complete Address',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    style: const TextStyle(color: Colors.black87),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: detailsController,
                    decoration: InputDecoration(
                      labelText: 'Additional Details (Optional)',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.info_outline, color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    style: const TextStyle(color: Colors.black87),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.map_outlined, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tip: You can also pick location from map for accurate delivery',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.black54, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Navigator.of(context).pop();
                              await _addAddress(
                                labelController.text,
                                addressController.text,
                                detailsController.text,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMapPicker(TextEditingController labelController,
                      TextEditingController addressController,
                      TextEditingController detailsController) async {
    Navigator.of(context).pop(); // Close the add dialog

    try {
      // First check if user has saved addresses
      final savedAddresses = await AddressService.instance.getSavedAddresses();

      if (savedAddresses.isNotEmpty) {
        // Show address selection dialog if addresses exist
        await showDialog(
          context: context,
          builder: (context) => AddressSelectionDialog(
            currentLocation: '',
            onLocationSelected: (selectedLocation) {
              addressController.text = selectedLocation;
              _showAddAddressDialog();
            },
          ),
        );
      } else {
        // If no saved addresses, open map picker to add first address
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GoogleMapsLocationPickerScreen(),
          ),
        );

        if (result != null && mounted) {
          // If user selected a location, show the add dialog again with the selected address
          addressController.text = result;
          _showAddAddressDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error opening location picker: $e', isError: true);
      }
    }
  }

  Future<void> _addAddress(String label, String address, String details) async {
    try {
      final result = await AddressApiService.addAddress(
        label: label,
        fullAddress: address,
        details: details,
        latitude: 13.0827 + (DateTime.now().millisecondsSinceEpoch % 100) / 10000,
        longitude: 80.2707 + (DateTime.now().millisecondsSinceEpoch % 100) / 10000,
        isDefault: _addresses.isEmpty,
      );
      
      if (mounted) {
        if (result['success']) {
          await _loadAddresses(); // Refresh the list
          // Update cache with the new address list
          await LocalStorage.setList('user_addresses', _addresses);
          Helpers.showSnackBar(context, result['message'] ?? 'Address added successfully!');
        } else {
          Helpers.showSnackBar(context, result['message'] ?? 'Failed to add address', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error adding address: $e', isError: true);
      }
    }
  }

  Future<void> _addAddressFromMap(String label, String address, String details, double lat, double lng) async {
    try {
      final result = await AddressApiService.addAddress(
        label: label,
        fullAddress: address,
        details: details,
        latitude: lat,
        longitude: lng,
        isDefault: _addresses.isEmpty,
      );
      
      if (mounted) {
        if (result['success']) {
          await _loadAddresses(); // Refresh the list
          Helpers.showSnackBar(context, result['message'] ?? 'Address added from map successfully!');
        } else {
          Helpers.showSnackBar(context, result['message'] ?? 'Failed to add address from map', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error adding address from map: $e', isError: true);
      }
    }
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Address'),
          content: const Text('Are you sure you want to delete this address?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final addressId = _addresses[index]['id'] as int;
                  final result = await AddressApiService.deleteAddress(addressId);
                  
                  if (mounted) {
                    if (result['success']) {
                      await _loadAddresses(); // Refresh the list
                      Helpers.showSnackBar(context, result['message'] ?? 'Address deleted');
                    } else {
                      Helpers.showSnackBar(context, result['message'] ?? 'Failed to delete address', isError: true);
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Helpers.showSnackBar(context, 'Error deleting address: $e', isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setAsDefault(int index) async {
    try {
      final addressId = _addresses[index]['id'] as int;
      final result = await AddressApiService.setDefaultAddress(addressId);
      
      if (mounted) {
        if (result['success']) {
          await _loadAddresses(); // Refresh the list
          Helpers.showSnackBar(context, result['message'] ?? 'Default address updated');
        } else {
          Helpers.showSnackBar(context, result['message'] ?? 'Failed to update default address', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error updating default address: $e', isError: true);
      }
    }
  }

  String _buildFullAddress(Map<String, dynamic> address) {
    // Build full address from components
    final List<String> parts = [];

    // Add address line 1 (flat/house details)
    if (address['addressLine1'] != null && address['addressLine1'].toString().isNotEmpty) {
      parts.add(address['addressLine1']);
    }

    // Add address line 2 (area)
    if (address['addressLine2'] != null && address['addressLine2'].toString().isNotEmpty) {
      parts.add(address['addressLine2']);
    }

    // If fullAddress is provided, use it
    if (address['fullAddress'] != null && address['fullAddress'].toString().isNotEmpty) {
      return address['fullAddress'];
    }

    // Otherwise build from parts
    if (parts.isEmpty && address['area'] != null) {
      parts.add(address['area']);
    }

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Manage Addresses',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Manage your delivery addresses for faster checkout',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _addresses.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            return _buildAddressCard(index);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location, color: Colors.white),
        label: const Text(
          'Add Address',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 100, color: Colors.black54),
          const SizedBox(height: 20),
          const Text(
            'No Addresses Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add your delivery addresses to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(int index) {
    final address = _addresses[index];
    final isDefault = address['isDefault'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDefault
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: Colors.black26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDefault
                        ? AppColors.primary
                        : AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    address['addressType'] ?? address['addressLabel'] ?? 'Home',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDefault ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    if (!isDefault)
                      PopupMenuItem(
                        onTap: () => _setAsDefault(index),
                        child: const Row(
                          children: [
                            Icon(Icons.star_outline),
                            SizedBox(width: 8),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      onTap: () => _deleteAddress(index),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildFullAddress(address),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if ((address['landmark'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Landmark: ${address['landmark']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.my_location,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${address['city'] ?? 'Tirupattur'}, ${address['state'] ?? 'Tamil Nadu'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      if ((address['postalCode'] ?? address['pincode'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.pin_drop,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pincode: ${address['postalCode'] ?? address['pincode'] ?? ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}