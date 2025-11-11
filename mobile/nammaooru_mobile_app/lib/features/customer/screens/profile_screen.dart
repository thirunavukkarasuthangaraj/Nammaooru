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
import '../../../shared/services/location_service.dart';

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
        int orderCount = 0;

        // Fetch order count
        try {
          final ordersResponse = await ApiClient.get('/customer/orders');
          if (ordersResponse.statusCode == 200) {
            final ordersData = ordersResponse.data;
            if (ordersData is Map<String, dynamic>) {
              final orders = ordersData['data'];
              if (orders is Map<String, dynamic>) {
                orderCount = orders['totalElements'] ?? 0;
              } else if (orders is List) {
                orderCount = orders.length;
              }
            }
          }
        } catch (e) {
          print('Error fetching order count: $e');
        }

        if (response.statusCode == 200) {
          final responseData = response.data;
          if (responseData is Map<String, dynamic>) {
            final statusCode = responseData['statusCode']?.toString();
            final userData = responseData['data'];

            if (statusCode == '0000' && userData != null) {
              // Cache the user data
              await LocalStorage.setMap('user_profile', userData);

              // Fetch user's addresses to get location
              String userLocation = 'Not set';
              String userAddress = 'No address added';

              try {
                final addressesResponse = await ApiClient.get('/customer/delivery-locations');
                if (addressesResponse.statusCode == 200) {
                  final addressData = addressesResponse.data;

                  if (addressData is Map<String, dynamic>) {
                    final addresses = addressData['data'];

                    if (addresses is List && addresses.isNotEmpty) {
                      // Find default address or use first address
                      final defaultAddress = addresses.firstWhere(
                        (addr) => addr['isDefault'] == true,
                        orElse: () => addresses[0],
                      );

                      // Get location from Google reverse geocoding using lat/lng
                      final latitude = defaultAddress['latitude'];
                      final longitude = defaultAddress['longitude'];

                      if (latitude != null && longitude != null) {
                        try {
                          final placemarks = await LocationService.getAddressFromCoordinates(
                            latitude.toDouble(),
                            longitude.toDouble(),
                          );

                          if (placemarks.isNotEmpty) {
                            final placemark = placemarks.first;
                            // Use subLocality (village), locality (city/town), and administrativeArea (state) from Google
                            final village = placemark.subLocality ?? '';
                            final city = placemark.locality ?? placemark.subAdministrativeArea ?? '';
                            final state = placemark.administrativeArea ?? '';

                            // Build location string: Village, City format or City, State format
                            if (village.isNotEmpty && city.isNotEmpty) {
                              userLocation = '$village, $city';
                            } else if (city.isNotEmpty && state.isNotEmpty) {
                              userLocation = '$city, $state';
                            } else if (city.isNotEmpty) {
                              userLocation = city;
                            } else if (village.isNotEmpty) {
                              userLocation = village;
                            } else if (state.isNotEmpty) {
                              userLocation = state;
                            }
                          }
                        } catch (e) {
                          print('Error getting location from coordinates: $e');
                          // Fallback to manually entered city/state if geocoding fails
                          final city = defaultAddress['city'] ?? '';
                          final state = defaultAddress['state'] ?? '';
                          if (city.isNotEmpty && state.isNotEmpty) {
                            userLocation = '$city, $state';
                          } else if (city.isNotEmpty) {
                            userLocation = city;
                          } else if (state.isNotEmpty) {
                            userLocation = state;
                          }
                        }
                      } else {
                        // No coordinates, use manually entered city/state
                        final city = defaultAddress['city'] ?? '';
                        final state = defaultAddress['state'] ?? '';
                        if (city.isNotEmpty && state.isNotEmpty) {
                          userLocation = '$city, $state';
                        } else if (city.isNotEmpty) {
                          userLocation = city;
                        } else if (state.isNotEmpty) {
                          userLocation = state;
                        }
                      }

                      // Build full address string
                      final area = defaultAddress['area'] ?? '';
                      final landmark = defaultAddress['landmark'] ?? '';

                      if (area.isNotEmpty) {
                        userAddress = area;
                        if (landmark.isNotEmpty) {
                          userAddress += ', $landmark';
                        }
                      } else if (landmark.isNotEmpty) {
                        userAddress = landmark;
                      }
                    }
                  }
                }
              } catch (e) {
                print('Error fetching addresses: $e');
              }

              setState(() {
                _userInfo = {
                  'userId': userData['id']?.toString() ?? 'N/A',
                  'userRole': userData['role'] ?? 'CUSTOMER',
                  'email': userData['email'] ?? 'N/A',
                  'name': '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}',
                  'phoneNumber': userData['mobileNumber'] ?? 'N/A',
                  'username': userData['username'] ?? 'N/A',
                  'address': userAddress,
                  'isAuthenticated': true,
                  'loginTime': DateTime.now().toString(),
                  'accountCreated': userData['createdAt'] ?? 'N/A',
                  'location': userLocation,
                  'totalOrders': orderCount.toString(),
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
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                backgroundColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
                centerTitle: true,
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Icon(
                  Icons.person_rounded,
                  size: 54,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _userInfo['name'] ?? 'User',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _userInfo['email'] ?? 'No email',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _userInfo['phoneNumber'] ?? 'No phone',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _userInfo['userRole']?.toString().replaceAll('_', ' ') ?? 'Customer',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
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
        _buildActionRow('Manage Addresses', Icons.location_on_outlined, () {
          context.push('/customer/addresses');
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
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoggingOut ? null : _showLogoutConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.red.shade400,
        ),
        child: _isLoggingOut
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 14),
                  Text(
                    'Logging out...',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
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