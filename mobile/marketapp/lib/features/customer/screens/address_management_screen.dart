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
  final bool autoOpenManualForm;

  const AddressManagementScreen({super.key, this.autoOpenManualForm = false});

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

    // Auto-open manual form if requested
    if (widget.autoOpenManualForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAddAddressDialog();
        }
      });
    }
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

            // Sort addresses: default address first, then others
            _addresses.sort((a, b) {
              final aIsDefault = a['isDefault'] == true;
              final bIsDefault = b['isDefault'] == true;

              if (aIsDefault && !bIsDefault) return -1; // a comes first
              if (!aIsDefault && bIsDefault) return 1;  // b comes first
              return 0; // keep original order for non-default addresses
            });

            _isLoading = false;
          });

          print('UI updated with ${_addresses.length} addresses (sorted with default first)');

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
    String selectedLabel = 'Home';
    final flatHouseController = TextEditingController();
    final floorController = TextEditingController();
    final streetController = TextEditingController();
    final areaController = TextEditingController();
    final villageController = TextEditingController();
    final landmarkController = TextEditingController();
    final cityController = TextEditingController(text: 'Tirupattur');
    final stateController = TextEditingController(text: 'Tamil Nadu');
    final pincodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
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
                        DropdownButtonFormField<String>(
                          value: selectedLabel,
                          decoration: InputDecoration(
                            labelText: 'Label',
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
                          items: ['Home', 'Office', 'Other'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedLabel = newValue;
                              });
                            }
                          },
                        ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: flatHouseController,
                      decoration: InputDecoration(
                        labelText: 'Flat / House no. / Building name',
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
                        prefixIcon: Icon(Icons.home_outlined, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: floorController,
                      decoration: InputDecoration(
                        labelText: 'Floor (optional)',
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
                        prefixIcon: Icon(Icons.layers_outlined, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: streetController,
                      decoration: InputDecoration(
                        labelText: 'Street Name',
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
                        prefixIcon: Icon(Icons.signpost, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: areaController,
                      decoration: InputDecoration(
                        labelText: 'Area / Sector / Locality',
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
                        prefixIcon: Icon(Icons.map_outlined, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: villageController,
                      decoration: InputDecoration(
                        labelText: 'Village',
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
                        prefixIcon: Icon(Icons.nature_people, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: landmarkController,
                      decoration: InputDecoration(
                        labelText: 'Nearby landmark (optional)',
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
                        prefixIcon: Icon(Icons.place_outlined, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityController,
                            decoration: InputDecoration(
                              labelText: 'City',
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
                              prefixIcon: Icon(Icons.location_city, color: AppColors.primary, size: 18),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: stateController,
                            decoration: InputDecoration(
                              labelText: 'State',
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
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pincodeController,
                      decoration: InputDecoration(
                        labelText: 'Pincode',
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
                        prefixIcon: Icon(Icons.pin_drop_outlined, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pincode is required';
                        }
                        if (value.length != 6) {
                          return 'Enter valid 6-digit pincode';
                        }
                        return null;
                      },
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
                                await _addAddressDetailed(
                                  selectedLabel,
                                  flatHouseController.text,
                                  floorController.text,
                                  streetController.text,
                                  areaController.text,
                                  villageController.text,
                                  landmarkController.text,
                                  cityController.text,
                                  stateController.text,
                                  pincodeController.text,
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
              ),
            );
          },
        );
      },
    );
  }

  void _showEditAddressDialog(int index) {
    final address = _addresses[index];
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController(text: address['addressType'] ?? '');

    // Initialize all field controllers with existing address data
    final flatHouseController = TextEditingController(text: address['flatHouse'] ?? '');
    final floorController = TextEditingController(text: address['floor'] ?? '');
    final streetController = TextEditingController(text: address['street'] ?? '');
    final areaController = TextEditingController(text: address['area'] ?? '');
    final villageController = TextEditingController(text: address['village'] ?? '');
    final landmarkController = TextEditingController(text: address['landmark'] ?? '');
    final cityController = TextEditingController(text: address['city'] ?? 'Tirupattur');
    final stateController = TextEditingController(text: address['state'] ?? 'Tamil Nadu');
    final pincodeController = TextEditingController(text: (address['postalCode'] ?? address['pincode'] ?? '').toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
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
                      controller: flatHouseController,
                      decoration: InputDecoration(
                        labelText: 'Flat / House no. / Building name',
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
                        prefixIcon: Icon(Icons.home_outlined, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: floorController,
                      decoration: InputDecoration(
                        labelText: 'Floor (optional)',
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
                        prefixIcon: Icon(Icons.layers_outlined, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: streetController,
                      decoration: InputDecoration(
                        labelText: 'Street Name',
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
                        prefixIcon: Icon(Icons.signpost, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: areaController,
                      decoration: InputDecoration(
                        labelText: 'Area / Sector / Locality',
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
                        prefixIcon: Icon(Icons.map_outlined, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: villageController,
                      decoration: InputDecoration(
                        labelText: 'Village',
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
                        prefixIcon: Icon(Icons.nature_people, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: landmarkController,
                      decoration: InputDecoration(
                        labelText: 'Nearby landmark (optional)',
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
                        prefixIcon: Icon(Icons.place_outlined, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityController,
                            decoration: InputDecoration(
                              labelText: 'City',
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
                              prefixIcon: Icon(Icons.location_city, color: AppColors.primary, size: 18),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: stateController,
                            decoration: InputDecoration(
                              labelText: 'State',
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
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pincodeController,
                      decoration: InputDecoration(
                        labelText: 'Pincode',
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
                        prefixIcon: Icon(Icons.pin_drop_outlined, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pincode is required';
                        }
                        if (value.length != 6) {
                          return 'Enter valid 6-digit pincode';
                        }
                        return null;
                      },
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
                                  flatHouseController.text,
                                  floorController.text,
                                  streetController.text,
                                  areaController.text,
                                  villageController.text,
                                  landmarkController.text,
                                  cityController.text,
                                  stateController.text,
                                  pincodeController.text,
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
          ),
        );
      },
    );
  }

  void _showAddAddressOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add_location_alt, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add New Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.black54),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Choose how you want to add your delivery address:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Option 1: Enter Manually
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddAddressDialog();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.edit_note, color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enter Manually',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Type your address details',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Option 2: Select from Map
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _openMapPickerForNewAddress();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.map, color: Colors.green, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Select from Map',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pinpoint your exact location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.green, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMapPickerForNewAddress() async {
    try {
      // Open map picker directly to select location and save address
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GoogleMapsLocationPickerScreen(),
        ),
      );

      if (result != null && mounted) {
        // Address was saved successfully via map picker
        print('Address saved successfully: $result');
        await _loadAddresses(); // Refresh the address list
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error opening location picker: $e', isError: true);
      }
    }
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

  Future<void> _addAddressDetailed(
    String label,
    String flatHouse,
    String floor,
    String street,
    String area,
    String village,
    String landmark,
    String city,
    String state,
    String pincode,
  ) async {
    try {
      // Build full address from components for geocoding
      List<String> addressParts = [];
      if (flatHouse.trim().isNotEmpty) {
        addressParts.add(flatHouse.trim());
      }
      if (floor.trim().isNotEmpty) {
        addressParts.add('Floor ${floor.trim()}');
      }
      if (street.trim().isNotEmpty) {
        addressParts.add(street.trim());
      }
      if (area.trim().isNotEmpty) {
        addressParts.add(area.trim());
      }
      if (village.trim().isNotEmpty) {
        addressParts.add(village.trim());
      }
      if (city.trim().isNotEmpty) {
        addressParts.add(city.trim());
      }
      if (state.trim().isNotEmpty) {
        addressParts.add(state.trim());
      }
      if (pincode.trim().isNotEmpty) {
        addressParts.add(pincode.trim());
      }
      String fullAddress = addressParts.join(', ');

      print('Adding detailed address: $label - $fullAddress');

      // Geocode the address to get real lat/long coordinates
      double latitude = 13.0827; // Default fallback
      double longitude = 80.2707; // Default fallback

      try {
        // Try to get coordinates from the full address
        final locations = await locationFromAddress(fullAddress);
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

      // Get contact info from LocalStorage (saved from profile)
      final firstName = await LocalStorage.getString('firstName') ?? '';
      final lastName = await LocalStorage.getString('lastName') ?? '';
      final phoneNumber = await LocalStorage.getString('phoneNumber') ?? '';
      final contactPersonName = '$firstName $lastName'.trim();

      final result = await AddressApiService.addAddress(
        label: label,
        fullAddress: fullAddress,
        details: landmark,
        latitude: latitude,
        longitude: longitude,
        isDefault: _addresses.isEmpty,
        city: city,
        state: state,
        pincode: pincode,
        flatHouse: flatHouse,
        floor: floor,
        street: street,
        area: area,
        village: village,
        contactPersonName: contactPersonName.isNotEmpty ? contactPersonName : null,
        contactMobileNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
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

  Future<void> _updateAddress(
    int index,
    String label,
    String flatHouse,
    String floor,
    String street,
    String area,
    String village,
    String landmark,
    String city,
    String state,
    String pincode,
  ) async {
    try {
      final addressId = _addresses[index]['id'] as int;
      final currentAddress = _addresses[index];

      // Build full address from components for display
      List<String> addressParts = [];
      if (flatHouse.trim().isNotEmpty) {
        addressParts.add(flatHouse.trim());
      }
      if (floor.trim().isNotEmpty) {
        addressParts.add('Floor ${floor.trim()}');
      }
      if (street.trim().isNotEmpty) {
        addressParts.add(street.trim());
      }
      if (area.trim().isNotEmpty) {
        addressParts.add(area.trim());
      }
      if (village.trim().isNotEmpty) {
        addressParts.add(village.trim());
      }
      if (city.trim().isNotEmpty) {
        addressParts.add(city.trim());
      }
      if (state.trim().isNotEmpty) {
        addressParts.add(state.trim());
      }
      if (pincode.trim().isNotEmpty) {
        addressParts.add(pincode.trim());
      }
      String fullAddress = addressParts.join(', ');

      print('Updating address $addressId: $label - $fullAddress');

      // Get contact info from LocalStorage (saved from profile)
      final firstName = await LocalStorage.getString('firstName') ?? '';
      final lastName = await LocalStorage.getString('lastName') ?? '';
      final phoneNumber = await LocalStorage.getString('phoneNumber') ?? '';
      final contactPersonName = '$firstName $lastName'.trim();

      final result = await AddressApiService.updateAddress(
        addressId: addressId,
        label: label,
        fullAddress: fullAddress,
        details: landmark,
        latitude: currentAddress['latitude'] ?? 13.0827,
        longitude: currentAddress['longitude'] ?? 80.2707,
        isDefault: currentAddress['isDefault'] ?? false,
        city: city,
        state: state,
        pincode: pincode,
        flatHouse: flatHouse,
        floor: floor,
        street: street,
        area: area,
        village: village,
        contactPersonName: contactPersonName.isNotEmpty ? contactPersonName : null,
        contactMobileNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            return _buildAddressCard(index);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAddressDialog,  // Directly open manual form, map option hidden for now
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
    final addressType = address['addressType'] ?? address['addressLabel'] ?? 'Home';
    final pin = (address['postalCode'] ?? address['pincode'] ?? '').toString();
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final cityState = [city, state].where((s) => s.isNotEmpty).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isDefault
            ? BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide(color: Colors.grey.shade200),
      ),
      elevation: isDefault ? 2 : 0.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: type badge + default badge + actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDefault ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        addressType.toLowerCase() == 'work' ? Icons.work_outline_rounded : Icons.home_outlined,
                        size: 14,
                        color: isDefault ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        addressType,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDefault ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50)),
                    ),
                  ),
                ],
                const Spacer(),
                InkWell(
                  onTap: () => _showEditAddressDialog(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _deleteAddress(index),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Address text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildFullAddress(address),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // City, State + PIN
            if (cityState.isNotEmpty || pin.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Row(
                  children: [
                    if (cityState.isNotEmpty)
                      Text(cityState, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    if (cityState.isNotEmpty && pin.isNotEmpty)
                      Text('  ·  ', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    if (pin.isNotEmpty)
                      Text(pin, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
            // Set as default button
            if (!isDefault) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => _setAsDefault(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Set as Default',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
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
