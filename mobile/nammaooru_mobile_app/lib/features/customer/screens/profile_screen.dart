import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/widgets/language_selector.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userInfo = {};
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Get basic auth info
      final userId = authProvider.userId ?? 'Not Available';
      final userRole = authProvider.userRole ?? 'CUSTOMER';
      final isAuthenticated = authProvider.isAuthenticated;
      
      // Set default values for user data
      String email = 'nammaoorucustomer@example.com';
      String name = 'NammaOoru Customer';
      String phoneNumber = '+91 98765 43210';
      String username = userId.length > 5 ? userId : 'customer_${userId.substring(0, 4)}';
      
      // Try to get stored user data from secure storage or cache
      final storedEmail = await LocalStorage.getString('user_email');
      final storedName = await LocalStorage.getString('user_name');
      final storedPhone = await LocalStorage.getString('user_phone');
      final storedUsername = await LocalStorage.getString('user_username');
      
      if (storedEmail != null && storedEmail.isNotEmpty) email = storedEmail;
      if (storedName != null && storedName.isNotEmpty) name = storedName;
      if (storedPhone != null && storedPhone.isNotEmpty) phoneNumber = storedPhone;
      if (storedUsername != null && storedUsername.isNotEmpty) username = storedUsername;

      setState(() {
        _userInfo = {
          'userId': userId,
          'userRole': userRole,
          'email': email,
          'name': name,
          'phoneNumber': phoneNumber,
          'username': username,
          'isAuthenticated': isAuthenticated,
          'loginTime': DateTime.now().toString(),
          'accountCreated': 'NammaOoru Member since 2024',
          'location': 'Chennai, Tamil Nadu',
          'totalOrders': '0',
          'membershipType': userRole == 'SHOP_OWNER' ? 'Shop Owner' : 'Customer',
          'appVersion': '1.0.0',
          'lastLogin': 'Just now',
        };
        _isLoading = false;
      });

      // Try to get cached user data and merge it
      try {
        final cachedUserData = await LocalStorage.getMap('user_profile');
        if (cachedUserData.isNotEmpty) {
          setState(() {
            _userInfo.addAll(cachedUserData);
          });
        }
      } catch (e) {
        print('No cached user data: $e');
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _userInfo = {
          'userId': 'Error loading',
          'userRole': 'CUSTOMER',
          'email': 'Error loading profile',
          'name': 'User',
          'phoneNumber': 'Error loading',
          'username': 'Error loading',
          'isAuthenticated': false,
          'error': 'Failed to load profile: $e',
        };
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      setState(() => _isLoggingOut = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Clear cache
      await CacheService().clearAllCaches();
      
      // Clear local storage
      await LocalStorage.clearAll();
      
      // Logout from auth service
      await AuthService.logout();
      
      // Update auth provider
      await authProvider.logout();

      if (mounted) {
        Helpers.showSnackBar(context, 'Logged out successfully');
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Logout failed: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildUserDetailsCard(),
                  const SizedBox(height: 24),
                  _buildAccountActionsCard(),
                  const SizedBox(height: 24),
                  _buildSystemInfoCard(),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userInfo['name'] ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _userInfo['email'] ?? 'No email',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _userInfo['userRole']?.toString().replaceAll('_', ' ') ?? 'Customer',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailsCard() {
    return _buildCard(
      'User Details',
      Icons.person_outline,
      [
        _buildDetailRow('User ID', _userInfo['userId'] ?? 'N/A'),
        _buildDetailRow('Username', _userInfo['username'] ?? 'N/A'),
        _buildDetailRow('Email', _userInfo['email'] ?? 'N/A'),
        _buildDetailRow('Phone', _userInfo['phoneNumber'] ?? 'N/A'),
        _buildDetailRow('Role', _userInfo['userRole']?.toString().replaceAll('_', ' ') ?? 'Customer'),
        _buildDetailRow('Location', _userInfo['location'] ?? 'N/A'),
        _buildDetailRow('Account Status', _userInfo['accountCreated'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildAccountActionsCard() {
    return _buildCard(
      'Account Actions',
      Icons.settings_outlined,
      [
        _buildActionRow('Edit Profile', Icons.edit_outlined, () {
          // TODO: Implement edit profile
          Helpers.showSnackBar(context, 'Edit profile feature coming soon!');
        }),
        _buildActionRow('Change Password', Icons.lock_outline, () {
          // TODO: Implement change password
          Helpers.showSnackBar(context, 'Change password feature coming soon!');
        }),
        _buildActionRow('Manage Addresses', Icons.location_on_outlined, () {
          context.push('/customer/addresses');
        }),
        _buildActionRow('Notification Settings', Icons.notifications_outlined, () {
          // TODO: Implement notification settings
          Helpers.showSnackBar(context, 'Notification settings coming soon!');
        }),
      ],
    );
  }

  Widget _buildSystemInfoCard() {
    return _buildCard(
      'System Information',
      Icons.info_outline,
      [
        _buildDetailRow('Authentication Status', _userInfo['isAuthenticated'] ? '✅ Authenticated' : '❌ Not Authenticated'),
        _buildDetailRow('Session Started', _formatDateTime(_userInfo['loginTime'])),
        _buildDetailRow('Last Login', _userInfo['lastLogin'] ?? 'N/A'),
        _buildDetailRow('App Version', _userInfo['appVersion'] ?? '1.0.0'),
        _buildDetailRow('Membership Type', _userInfo['membershipType'] ?? 'Customer'),
        _buildDetailRow('Total Orders', _userInfo['totalOrders'] ?? '0'),
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoggingOut ? null : _showLogoutConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoggingOut
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Logging out...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}