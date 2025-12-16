import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/models/address_model.dart';
import '../../../core/services/address_service.dart';
import '../screens/address_management_screen.dart';
import '../screens/google_maps_location_picker_screen.dart';

class AddressSelectionDialog extends StatefulWidget {
  final String? currentLocation;
  final Function(String) onLocationSelected;

  const AddressSelectionDialog({
    super.key,
    this.currentLocation,
    required this.onLocationSelected,
  });

  @override
  State<AddressSelectionDialog> createState() => _AddressSelectionDialogState();
}

class _AddressSelectionDialogState extends State<AddressSelectionDialog> {
  List<SavedAddress> _savedAddresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final addresses = await AddressService.instance.getSavedAddresses();
      setState(() {
        _savedAddresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddAddressOptionsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                        color: VillageTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add_location_alt, color: VillageTheme.primaryGreen, size: 24),
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
                      onPressed: () => Navigator.of(dialogContext).pop(),
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
                // Option 1: Enter Manually (Only option for now)
                InkWell(
                  onTap: () async {
                    Navigator.of(dialogContext).pop(); // Close the options dialog
                    // Small delay to ensure dialog is closed
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressManagementScreen(autoOpenManualForm: true),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: VillageTheme.primaryGreen, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: VillageTheme.primaryGreen.withOpacity(0.1),
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
                            color: VillageTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.edit_note, color: VillageTheme.primaryGreen, size: 32),
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
                        Icon(Icons.arrow_forward_ios, color: VillageTheme.primaryGreen, size: 16),
                      ],
                    ),
                  ),
                ),
                // Map option hidden for now - will be enabled later
                // const SizedBox(height: 12),
                // InkWell(...),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: VillageTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Delivery Address',
                    style: VillageTheme.headingMedium.copyWith(
                      color: VillageTheme.primaryGreen,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_savedAddresses.isEmpty)
              _buildNoAddressesView()
            else
              _buildAddressList(),

            const SizedBox(height: 16),

            // Add New Address Button - Directly open manual form (map option hidden)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Directly navigate to address management with auto-open form
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressManagementScreen(autoOpenManualForm: true),
                    ),
                  );
                  // After returning, close this dialog
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Add New Address'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VillageTheme.primaryGreen,
                  side: BorderSide(color: VillageTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAddressesView() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Addresses',
            style: VillageTheme.headingSmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first delivery address to get started',
            style: VillageTheme.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _savedAddresses.length,
        itemBuilder: (context, index) {
          final address = _savedAddresses[index];
          return _buildAddressCard(address);
        },
      ),
    );
  }

  Widget _buildAddressCard(SavedAddress address) {
    final isDefault = address.isDefault;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final locationString = '${address.addressLine1}, ${address.city}';
            widget.onLocationSelected(locationString);
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDefault ? VillageTheme.primaryGreen.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDefault ? VillageTheme.primaryGreen : Colors.grey[300]!,
                width: isDefault ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getAddressTypeIcon(address.addressType),
                      size: 18,
                      color: isDefault ? VillageTheme.primaryGreen : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      address.addressType,
                      style: VillageTheme.labelText.copyWith(
                        color: isDefault ? VillageTheme.primaryGreen : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isDefault) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: VillageTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address.addressLine1.isNotEmpty ? address.addressLine1 : 'Address Line 1',
                  style: VillageTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDefault ? VillageTheme.primaryGreen : Colors.black,
                  ),
                ),
                if (address.addressLine2.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address.addressLine2,
                    style: VillageTheme.bodyMedium.copyWith(
                      color: isDefault ? VillageTheme.primaryGreen.withOpacity(0.8) : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${address.city}, ${address.state}',
                  style: VillageTheme.bodyMedium.copyWith(
                    color: isDefault ? VillageTheme.primaryGreen.withOpacity(0.8) : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (address.landmark.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Near ${address.landmark}',
                    style: VillageTheme.bodySmall.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (address.pincode.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.pin_drop,
                        size: 14,
                        color: isDefault ? VillageTheme.primaryGreen : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pincode: ${address.pincode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDefault ? VillageTheme.primaryGreen : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
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
}