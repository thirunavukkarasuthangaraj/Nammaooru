import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/services/address_service.dart';
import '../../../core/services/location_service.dart';
import '../screens/address_management_screen.dart';
import '../screens/google_maps_location_picker_screen.dart';
import 'address_selection_dialog.dart';
import 'location_search_sheet.dart';

/// Shared "Deliver to" address picker flow, originally built for the
/// customer dashboard: if the user has saved addresses, shows the address
/// selection dialog; otherwise lets them add one manually or pick it on the
/// map. Reused by any screen that needs the same delivery-address flow.
class DeliverToPicker {
  static bool _isOpen = false;

  static Future<void> show(
    BuildContext context, {
    required String currentLocation,
    required ValueChanged<String> onLocationSelected,
    VoidCallback? onAddressBookUpdated,
  }) async {
    if (_isOpen) return;
    _isOpen = true;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        final shouldLogin = await _showLoginPrompt(context);
        if (shouldLogin == true && context.mounted) {
          context.go('/register');
        }
        return;
      }

      final savedAddresses = await AddressService.instance.getSavedAddresses();
      if (!context.mounted) return;

      if (savedAddresses.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (context) => AddressSelectionDialog(
            currentLocation: currentLocation,
            onLocationSelected: (selectedLocation) {
              if (selectedLocation != currentLocation) {
                onLocationSelected(selectedLocation);
                Helpers.showSnackBar(context, 'Delivery address updated');
              }
            },
          ),
        );
      } else {
        await _showAddAddressOptionsDialog(
          context,
          currentLocation,
          onLocationSelected,
          onAddressBookUpdated,
        );
      }
    } finally {
      _isOpen = false;
    }
  }

  static Future<bool?> _showLoginPrompt(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: VillageTheme.primaryGreen, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Login Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please login to save and manage your delivery addresses.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VillageTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: VillageTheme.primaryGreen, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can still browse with your current location',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: VillageTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Login / Sign Up', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  static Future<void> _showAddAddressOptionsDialog(
    BuildContext context,
    String currentLocation,
    ValueChanged<String> onLocationSelected,
    VoidCallback? onAddressBookUpdated,
  ) async {
    await showDialog(
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
                        color: VillageTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add_location_alt, color: VillageTheme.primaryGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add Delivery Address',
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
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (context.mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddressManagementScreen(autoOpenManualForm: true),
                        ),
                      );
                      if (result != null) {
                        await AddressService.instance.getSavedAddresses();
                        onAddressBookUpdated?.call();
                      }
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
                const SizedBox(height: 12),
                // Option 2: Select from Map
                InkWell(
                  onTap: () async {
                    Navigator.of(context).pop();
                    final selectedLocation = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoogleMapsLocationPickerScreen(
                          currentLocation: currentLocation,
                        ),
                      ),
                    );

                    if (selectedLocation != null && selectedLocation != currentLocation) {
                      onLocationSelected(selectedLocation);

                      if (context.mounted) {
                        Helpers.showSnackBar(
                          context,
                          'Location updated to $selectedLocation',
                        );
                      }

                      await AddressService.instance.getSavedAddresses();
                    }
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
                const SizedBox(height: 12),
                // Option 3: Search by name (works even when the map view
                // can't load — uses text search, not map tiles)
                InkWell(
                  onTap: () async {
                    Navigator.of(context).pop();
                    final result = await LocationSearchSheet.show(context);
                    if (result == null) return;
                    if (result['useCurrentLocation'] == true) {
                      LocationService.clearManualPosition();
                      final position = await LocationService.instance.getCurrentPosition();
                      if (position?.latitude == null || position?.longitude == null) return;
                      final address = await LocationService.instance.getAddressFromCoordinates(
                        position!.latitude!,
                        position.longitude!,
                      );
                      final label = address != null
                          ? '${address['locality'] ?? ''}${address['administrativeArea'] != null ? ', ${address['administrativeArea']}' : ''}'
                          : 'Current location';
                      onLocationSelected(label.isNotEmpty ? label : 'Current location');
                    } else {
                      final latitude = result['latitude'] as double;
                      final longitude = result['longitude'] as double;
                      final name = result['name'] as String;
                      LocationService.setManualPosition(latitude, longitude);
                      LocationService.manualLocationLabel = name;
                      onLocationSelected(name);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.1),
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
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.search, color: Colors.orange, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Search by Name',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Type your village or town',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 16),
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
}
