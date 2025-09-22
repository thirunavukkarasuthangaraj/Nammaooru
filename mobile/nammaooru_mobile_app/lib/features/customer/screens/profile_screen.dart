import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../core/api/api_client.dart';

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

      if (!authProvider.isAuthenticated) {
        setState(() {
          _isLoading = false;
          _userInfo = {
            'error': 'Not authenticated',
            'name': 'Guest User',
            'email': 'Please log in',
          };
        });
        return;
      }

      // Fetch real user data from API
      try {
        final response = await ApiClient.get('/users/me');

        if (response.statusCode == 200) {
          final responseData = response.data;
          if (responseData is Map<String, dynamic>) {
            final statusCode = responseData['statusCode']?.toString();
            final userData = responseData['data'];

            if (statusCode == '0000' && userData != null) {
              // Cache the user data
              await LocalStorage.setMap('user_profile', userData);

              setState(() {
                _userInfo = {
                  'userId': userData['id']?.toString() ?? 'N/A',
                  'userRole': userData['role'] ?? 'CUSTOMER',
                  'email': userData['email'] ?? 'N/A',
                  'name': '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}',
                  'phoneNumber': userData['mobileNumber'] ?? 'N/A',
                  'username': userData['username'] ?? 'N/A',
                  'address': 'Chennai, Tamil Nadu', // Default for now
                  'isAuthenticated': true,
                  'loginTime': DateTime.now().toString(),
                  'accountCreated': userData['createdAt'] ?? 'N/A',
                  'location': 'Chennai, Tamil Nadu',
                  'totalOrders': '0', // TODO: Get from orders API
                  'membershipType': userData['role'] == 'SHOP_OWNER' ? 'Shop Owner' : 'Customer',
                  'appVersion': '1.0.0',
                  'lastLogin': userData['lastLoginAt'] ?? 'Just now',
                  'isActive': userData['isActive'] ?? true,
                  'department': userData['department'],
                };
                _isLoading = false;
              });
              return;
            }
          }
        }
      } catch (e) {
        print('Error fetching user profile: $e');
      }

      // Fallback to cached data if API fails
      try {
        final cachedUserData = await LocalStorage.getMap('user_profile');
        if (cachedUserData.isNotEmpty) {
          setState(() {
            _userInfo = {
              'userId': cachedUserData['id']?.toString() ?? 'N/A',
              'userRole': cachedUserData['role'] ?? 'CUSTOMER',
              'email': cachedUserData['email'] ?? 'N/A',
              'name': '${cachedUserData['firstName'] ?? ''} ${cachedUserData['lastName'] ?? ''}',
              'phoneNumber': cachedUserData['mobileNumber'] ?? 'N/A',
              'username': cachedUserData['username'] ?? 'N/A',
              'address': 'Chennai, Tamil Nadu',
              'isAuthenticated': true,
              'totalOrders': '0',
              'membershipType': cachedUserData['role'] == 'SHOP_OWNER' ? 'Shop Owner' : 'Customer',
            };
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('No cached user data: $e');
      }

      // Final fallback to basic auth data
      setState(() {
        _userInfo = {
          'userId': authProvider.userId ?? 'N/A',
          'userRole': authProvider.userRole ?? 'CUSTOMER',
          'email': 'Email not available',
          'name': 'User',
          'phoneNumber': 'Phone not available',
          'username': 'Username not available',
          'address': 'Address not available',
          'isAuthenticated': authProvider.isAuthenticated,
          'membershipType': authProvider.userRole == 'SHOP_OWNER' ? 'Shop Owner' : 'Customer',
        };
        _isLoading = false;
      });
      
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
      body: Container(
        decoration: BoxDecoration(
          gradient: VillageTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
                actions: [
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: LanguageSelector(),
                  ),
                ],
              ),
              Expanded(
                child: _isLoading
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withOpacity(0.1),
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
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            _userInfo['email'] ?? 'No email',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _userInfo['userRole']?.toString().replaceAll('_', ' ') ?? 'Customer',
              style: const TextStyle(
                color: AppColors.primary,
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
        _buildDetailRow('Address', _userInfo['address'] ?? 'N/A'),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
            borderRadius: BorderRadius.circular(24),
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