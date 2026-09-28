import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import 'address_selection_dialog.dart';

/// Shared "Deliver to" address picker flow, originally built for the
/// customer dashboard. Reused by any screen that needs the same
/// delivery-address flow. `AddressSelectionDialog` itself handles both the
/// "has saved addresses" and "no saved addresses yet" cases, so there is a
/// single picker UI regardless of state.
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

      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AddressSelectionDialog(
          currentLocation: currentLocation,
          onLocationSelected: (selectedLocation) {
            if (selectedLocation != currentLocation) {
              onLocationSelected(selectedLocation);
              Helpers.showSnackBar(context, 'Delivery address updated');
            }
            onAddressBookUpdated?.call();
          },
        ),
      );
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
}
