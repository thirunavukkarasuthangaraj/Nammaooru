import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/storage_service.dart';

class ShopSettingsScreen extends StatefulWidget {
  final String token;

  const ShopSettingsScreen({
    super.key,
    required this.token,
  });

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  bool _isLoading = true;
  bool _isShopAvailable = true;
  Map<String, dynamic>? _shopData;
  String _fcmToken = '';
  bool _notificationsEnabled = true;

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deliveryRadiusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShopData();
    _initializeFCM();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _deliveryRadiusController.dispose();
    super.dispose();
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);

    try {
      // Load shop data and availability
      final futures = await Future.wait([
        ApiService.getMyShop(),
        ApiService.getShopAvailability('1'), // Using shop ID 1 for now
      ]);

      final shopResponse = futures[0];
      final availabilityResponse = futures[1];

      if (shopResponse.success) {
        final data = shopResponse.data['data'];
        setState(() {
          _shopData = data;
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _deliveryRadiusController.text = (data['deliveryRadius'] ?? 0).toString();
        });
      }

      if (availabilityResponse.success) {
        final availabilityData = availabilityResponse.data['data'];
        setState(() {
          _isShopAvailable = availabilityData['isAvailable'] ?? true;
        });
      }
    } catch (e) {
      _showError('Error loading shop data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await messaging.requestPermission();
      setState(() {
        _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
      });

      // Get FCM token
      final token = await messaging.getToken();
      if (token != null) {
        setState(() {
          _fcmToken = token;
        });

        // Submit token to server
        await _submitFCMToken(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((token) {
        setState(() {
          _fcmToken = token;
        });
        _submitFCMToken(token);
      });

    } catch (e) {
      print('FCM initialization error: $e');
    }
  }

  Future<void> _submitFCMToken(String token) async {
    try {
      await ApiService.submitFcmToken(
        token: token,
        deviceType: 'MOBILE',
      );
    } catch (e) {
      print('Error submitting FCM token: $e');
    }
  }

  Future<void> _updateShopSettings() async {
    if (_shopData == null) return;

    try {
      final updateData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'phoneNumber': _phoneController.text,
        'deliveryRadius': double.tryParse(_deliveryRadiusController.text) ?? 0.0,
        'isActive': _isShopAvailable,
      };

      final response = await ApiService.updateShop(_shopData!['id'].toString(), updateData);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop settings updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadShopData();
      } else {
        _showError('Failed to update settings: ${response.error}');
      }
    } catch (e) {
      _showError('Error updating settings: $e');
    }
  }

  Future<void> _toggleNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;

      if (_notificationsEnabled) {
        // Disable notifications
        await messaging.deleteToken();
        setState(() {
          _notificationsEnabled = false;
          _fcmToken = '';
        });
      } else {
        // Enable notifications
        final settings = await messaging.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          final token = await messaging.getToken();
          if (token != null) {
            setState(() {
              _notificationsEnabled = true;
              _fcmToken = token;
            });
            await _submitFCMToken(token);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _notificationsEnabled
                ? 'Notifications enabled'
                : 'Notifications disabled'
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      _showError('Error toggling notifications: $e');
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            TextFormField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              try {
                final response = await ApiService.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );

                if (response.success) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to change password: ${response.error}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error changing password: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.logout();
        await StorageService.clearAll();

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        _showError('Error logging out: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Settings'),
        backgroundColor: AppColors.surface,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _updateShopSettings,
            icon: const Icon(Icons.save, color: AppColors.primary),
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Status
                  _buildShopStatusCard(),
                  const SizedBox(height: AppSizes.spacingLg),

                  // Basic Shop Settings
                  _buildSectionTitle('Shop Information'),
                  _buildShopInfoSection(),
                  const SizedBox(height: AppSizes.spacingLg),

                  // Notifications Settings
                  _buildSectionTitle('Notifications'),
                  _buildNotificationsSection(),
                  const SizedBox(height: AppSizes.spacingLg),

                  // Account Settings
                  _buildSectionTitle('Account'),
                  _buildAccountSection(),
                  const SizedBox(height: AppSizes.spacingLg),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMd),
      child: Text(
        title,
        style: AppTextStyles.headlineMedium,
      ),
    );
  }

  Widget _buildShopStatusCard() {
    if (_shopData == null) return const SizedBox.shrink();

    final status = _shopData!['status'] ?? 'PENDING';
    final isApproved = status == 'APPROVED';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isApproved ? AppColors.success : AppColors.warning,
                borderRadius: BorderRadius.circular(AppSizes.radiusRound),
              ),
              child: Icon(
                isApproved ? Icons.verified : Icons.pending,
                color: Colors.white,
                size: AppSizes.iconLg,
              ),
            ),
            const SizedBox(width: AppSizes.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop Status',
                    style: AppTextStyles.titleMedium,
                  ),
                  Text(
                    status.replaceAll('_', ' ').toLowerCase().replaceRange(0, 1, status[0]),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isApproved ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isApproved)
                    Text(
                      'Your shop is under review',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: _isShopAvailable,
              onChanged: (value) {
                setState(() {
                  _isShopAvailable = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Shop Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            TextFormField(
              controller: _deliveryRadiusController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Delivery Radius (km)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: Text(
                _notificationsEnabled
                    ? 'Receive notifications for new orders, messages, etc.'
                    : 'Notifications are disabled',
              ),
              value: _notificationsEnabled,
              onChanged: (value) => _toggleNotifications(),
              activeColor: AppColors.primary,
            ),

            if (_fcmToken.isNotEmpty) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.token),
                title: const Text('FCM Token'),
                subtitle: Text(
                  '${_fcmToken.substring(0, 20)}...',
                  style: AppTextStyles.labelSmall,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    // Copy token to clipboard functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token copied to clipboard')),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help with your shop'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('App version and information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show about dialog
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _updateShopSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: AppThemes.primaryButtonStyle,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMd),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingLg,
                vertical: AppSizes.spacingMd,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}