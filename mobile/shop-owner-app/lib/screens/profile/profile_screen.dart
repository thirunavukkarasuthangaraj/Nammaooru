import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/login_screen.dart';
import '../settings/business_hours_screen.dart';
import '../inventory/inventory_screen.dart';
import '../promo_codes/promo_codes_screen.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_card.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String token;

  const ProfileScreen({super.key, required this.userName, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _shopName = 'My Shop';
  String _shopAddress = 'Shop Address Not Set';
  String _phoneNumber = 'Phone Not Set';
  String _email = 'Email Not Set';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? widget.token;

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/shops/my-shop'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final shopData = jsonDecode(response.body);

        if (shopData['statusCode'] == '0000' && shopData['data'] != null) {
          final shop = shopData['data'];

          setState(() {
            _shopName = shop['name'] ?? widget.userName;
            _email = shop['email'] ?? shop['owner']?['email'] ?? 'N/A';
            _phoneNumber = shop['phone'] ?? shop['phoneNumber'] ?? 'N/A';
            _shopAddress = '${shop['address'] ?? ''}, ${shop['city'] ?? ''} - ${shop['pincode'] ?? ''}';
          });
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.roundedLarge),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.error),
            const SizedBox(width: AppTheme.space8),
            Text('Confirm Logout', style: AppTheme.h5),
          ],
        ),
        content: Text('Are you sure you want to logout?', style: AppTheme.bodyMedium),
        actions: [
          ModernButton(
            text: 'Cancel',
            variant: ButtonVariant.outline,
            size: ButtonSize.medium,
            onPressed: () => Navigator.pop(context),
          ),
          ModernButton(
            text: 'Logout',
            icon: Icons.logout,
            variant: ButtonVariant.error,
            size: ButtonSize.medium,
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Profile', style: AppTheme.h4.copyWith(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
            onPressed: () => _showComingSoon('Settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.store, size: 40, color: AppTheme.primary),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    _shopName,
                    style: AppTheme.h3.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    _email,
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space16),

            // Contact Information
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.roundedLarge,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildModernInfoTile(Icons.phone, 'Phone', _phoneNumber),
                  Divider(height: 1, color: AppTheme.borderLight),
                  _buildModernInfoTile(Icons.location_on, 'Address', _shopAddress),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space16),

            // Settings & Options
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.roundedLarge,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuTile(Icons.access_time, 'Business Hours', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BusinessHoursScreen(token: widget.token)),
                    );
                  }),
                  Divider(height: 1, color: AppTheme.borderLight),
                  _buildMenuTile(Icons.payment, 'Payment Settings', () => _showComingSoon('Payment Settings')),
                  Divider(height: 1, color: AppTheme.borderLight),
                  _buildMenuTile(Icons.inventory_2, 'Inventory', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InventoryScreen(token: widget.token)),
                    );
                  }),
                  Divider(height: 1, color: AppTheme.borderLight),
                  _buildMenuTile(Icons.local_offer, 'Promo Codes', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PromoCodesScreen()),
                    );
                  }),
                  Divider(height: 1, color: AppTheme.borderLight),
                  _buildMenuTile(Icons.analytics, 'Analytics', () => _showComingSoon('Analytics')),
                  Divider(height: 1, color: AppTheme.borderLight),
                  _buildMenuTile(Icons.help_outline, 'Support', () => _showComingSoon('Support')),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: ModernButton(
                text: 'Logout',
                icon: Icons.logout,
                variant: ButtonVariant.error,
                size: ButtonSize.large,
                fullWidth: true,
                onPressed: _logout,
              ),
            ),

            const SizedBox(height: AppTheme.space20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space8),
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: AppTheme.roundedMedium,
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(label, style: AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space12),
      leading: Icon(icon, color: AppTheme.primary, size: 24),
      title: Text(title, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
      onTap: onTap,
    );
  }
}
