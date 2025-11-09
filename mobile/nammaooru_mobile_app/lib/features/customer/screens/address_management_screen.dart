import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
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
      print('Loading addresses from API...');
      // First try to load from API
      final result = await AddressApiService.getUserAddresses();
      print('API result: $result');

      if (mounted) {
        if (result['success']) {
          final data = result['data'];
          List<dynamic> addresses = [];

          // Handle both single address and array of addresses
          if (data is List) {
            addresses = data;
            print('Found ${addresses.length} addresses in list');
          } else if (data is Map) {
            addresses = [data];
            print('Found 1 address in map format');
          }

          setState(() {
            _addresses = addresses.map((addr) => Map<String, dynamic>.from(addr)).toList();
            _isLoading = false;
          });

          print('UI updated with ${_addresses.length} addresses');

          // Cache the addresses for offline access
          if (_addresses.isNotEmpty) {
            await LocalStorage.setList('user_addresses', _addresses);
            print('Addresses cached successfully');
          }
        } else {
          print('API call failed: ${result['message']}');
          // API failed, try to load from cache
          await _loadCachedAddresses();
          if (mounted && _addresses.isEmpty) {
            Helpers.showSnackBar(context, result['message'] ?? 'Failed to load addresses', isError: true);
          }
        }
      }
    } catch (e) {
      print('Exception loading addresses: $e');
      // Error with API, try to load from cache
      await _loadCachedAddresses();
      if (mounted && _addresses.isEmpty) {
        print('Error loading addresses: $e');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.add_location, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: labelController,
                    decoration: InputDecoration(
                      labelText: 'Label (e.g., Home, Office)',
                      labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.label_outline, color: AppColors.primary, size: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a label';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Complete Address',
                      labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: detailsController,
                    decoration: InputDecoration(
                      labelText: 'Additional Details (Optional)',
                      labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  void _showEditAddressDialog(int index) {
    final address = _addresses[index];
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController(text: address['addressType'] ?? '');

    // Build the address text from available fields
    String addressText = '';
    final List<String> addressParts = [];
    if (address['flatHouse'] != null && address['flatHouse'].toString().isNotEmpty) {
      addressParts.add(address['flatHouse']);
    }
    if (address['street'] != null && address['street'].toString().isNotEmpty) {
      addressParts.add(address['street']);
    }
    if (address['area'] != null && address['area'].toString().isNotEmpty) {
      addressParts.add(address['area']);
    }
    addressText = addressParts.join(', ');

    final addressController = TextEditingController(text: addressText);
    final detailsController = TextEditingController(text: address['landmark'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.edit_location, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Edit Address',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: labelController,
                    decoration: InputDecoration(
                      labelText: 'Label (e.g., Home, Office)',
                      labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.label_outline, color: AppColors.primary, size: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a label';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Complete Address',
                      labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: detailsController,
                    decoration: InputDecoration(
                      labelText: 'Additional Details (Optional)',
                      labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Navigator.of(context).pop();
                              await _updateAddress(
                                index,
                                labelController.text,
                                addressController.text,
                                detailsController.text,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      print('Adding address: $label - $address');

      // Geocode the manually entered address to get real lat/long coordinates
      double latitude = 13.0827; // Default fallback
      double longitude = 80.2707; // Default fallback

      try {
        // Try to get coordinates from the address text
        final locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;
          print('✅ Geocoded address to: $latitude, $longitude');
        } else {
          print('⚠️ Could not geocode address, using fallback coordinates');
        }
      } catch (e) {
        print('⚠️ Geocoding failed: $e, using fallback coordinates');
      }

      final result = await AddressApiService.addAddress(
        label: label,
        fullAddress: address,
        details: details,
        latitude: latitude,
        longitude: longitude,
        isDefault: _addresses.isEmpty,
      );

      print('Add address result: $result');

      if (mounted) {
        if (result['success']) {
          // Force refresh the address list from API
          setState(() {
            _isLoading = true;
          });

          await _loadAddresses(); // This will update _addresses and setState

          // Double-check that addresses are loaded
          if (_addresses.isNotEmpty) {
            print('Successfully loaded ${_addresses.length} addresses after adding');
            // Update cache with the new address list
            await LocalStorage.setList('user_addresses', _addresses);
            Helpers.showSnackBar(context, result['message'] ?? 'Address added successfully!');
          } else {
            print('No addresses found after adding - trying to reload again');
            // Try one more time
            await Future.delayed(const Duration(milliseconds: 500));
            await _loadAddresses();
          }
        } else {
          Helpers.showSnackBar(context, result['message'] ?? 'Failed to add address', isError: true);
        }
      }
    } catch (e) {
      print('Error adding address: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  Future<void> _updateAddress(int index, String label, String address, String details) async {
    try {
      final addressId = _addresses[index]['id'] as int;
      final currentAddress = _addresses[index];

      print('Updating address $addressId: $label - $address');

      final result = await AddressApiService.updateAddress(
        addressId: addressId,
        label: label,
        fullAddress: address,
        details: details,
        latitude: currentAddress['latitude'] ?? 13.0827,
        longitude: currentAddress['longitude'] ?? 80.2707,
        isDefault: currentAddress['isDefault'] ?? false,
      );

      print('Update address result: $result');

      if (mounted) {
        if (result['success']) {
          // Force refresh the address list from API
          setState(() {
            _isLoading = true;
          });

          await _loadAddresses(); // This will update _addresses and setState

          if (_addresses.isNotEmpty) {
            print('Successfully loaded ${_addresses.length} addresses after updating');
            // Update cache with the new address list
            await LocalStorage.setList('user_addresses', _addresses);
            Helpers.showSnackBar(context, result['message'] ?? 'Address updated successfully!');
          } else {
            print('No addresses found after updating - trying to reload again');
            // Try one more time
            await Future.delayed(const Duration(milliseconds: 500));
            await _loadAddresses();
          }
        } else {
          Helpers.showSnackBar(context, result['message'] ?? 'Failed to update address', isError: true);
        }
      }
    } catch (e) {
      print('Error updating address: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Helpers.showSnackBar(context, 'Error updating address: $e', isError: true);
      }
    }
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Delete Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          content: const Text('Are you sure you want to delete this address?', style: TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 13)),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Delete', style: TextStyle(fontSize: 13)),
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
    // If fullAddress is provided, use it directly
    if (address['fullAddress'] != null && address['fullAddress'].toString().isNotEmpty) {
      return address['fullAddress'];
    }

    // Otherwise build from available parts
    final List<String> parts = [];

    // Add flat/house details if available
    if (address['flatHouse'] != null && address['flatHouse'].toString().isNotEmpty) {
      parts.add(address['flatHouse']);
    }

    // Add street if available
    if (address['street'] != null && address['street'].toString().isNotEmpty) {
      parts.add(address['street']);
    }

    // Add area (this is the main address field from our form)
    if (address['area'] != null && address['area'].toString().isNotEmpty) {
      parts.add(address['area']);
    }

    // Add address line 1 (for backwards compatibility)
    if (parts.isEmpty && address['addressLine1'] != null && address['addressLine1'].toString().isNotEmpty) {
      parts.add(address['addressLine1']);
    }

    // Add address line 2 (for backwards compatibility)
    if (address['addressLine2'] != null && address['addressLine2'].toString().isNotEmpty) {
      parts.add(address['addressLine2']);
    }

    // If still empty, try to build from other fields
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
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
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Manage your delivery addresses for faster checkout',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _addresses.isEmpty
                      ? _buildEmptyState()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Responsive grid: 1 column mobile, 2 columns tablet (600px+)
                            final crossAxisCount = constraints.maxWidth >= 600 ? 2 : 1;
                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: crossAxisCount == 2 ? 1.5 : 1.8, // Much taller cards to accommodate long village addresses
                              ),
                              itemCount: _addresses.length,
                              itemBuilder: (context, index) {
                                return _buildAddressCard(index);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAddressDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Addresses Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your delivery addresses to get started',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(int index) {
    final address = _addresses[index];
    final isDefault = address['isDefault'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDefault
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDefault
                        ? AppColors.primary
                        : AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    address['addressType'] ?? address['addressLabel'] ?? 'Home',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDefault ? Colors.white : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDefault) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showEditAddressDialog(index),
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      onPressed: () => _deleteAddress(index),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _buildFullAddress(address),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${address['city'] ?? 'Tirupattur'}, ${address['state'] ?? 'Tamil Nadu'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((address['postalCode'] ?? address['pincode'] ?? '').toString().isNotEmpty)
                          Text(
                            'PIN: ${address['postalCode'] ?? address['pincode'] ?? ''}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isDefault) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _setAsDefault(index),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Set as Default',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
