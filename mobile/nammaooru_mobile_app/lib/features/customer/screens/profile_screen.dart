import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'payment_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userInfo = {};
  bool _isLoading = true;
  bool _isLoggingOut = false;

  // Post counts (keyed by displayName from API)
  Map<String, Map<String, int>> _postCounts = {};
  Map<String, int> _postLimits = {};
  Map<String, Map<String, dynamic>> _postPricing = {};
  // Module metadata from API (keyed by displayName)
  Map<String, Color> _moduleColors = {};
  Map<String, IconData> _moduleIcons = {};
  bool _isLoadingPosts = true;
  bool _postsExpanded = false;

  // Icon string -> IconData mapping (same as dashboard)
  static const _iconMap = <String, IconData>{
    'shopping_basket_rounded': Icons.shopping_basket_rounded,
    'restaurant_rounded': Icons.restaurant_rounded,
    'storefront_rounded': Icons.storefront_rounded,
    'eco_rounded': Icons.eco_rounded,
    'construction_rounded': Icons.construction_rounded,
    'directions_bus_rounded': Icons.directions_bus_rounded,
    'local_shipping_rounded': Icons.local_shipping_rounded,
    'directions_car_rounded': Icons.directions_car_rounded,
    'home_work_rounded': Icons.home_work_rounded,
    'vpn_key_rounded': Icons.vpn_key_rounded,
    'account_balance_rounded': Icons.account_balance_rounded,
  };

  static IconData _mapIcon(String? iconName) {
    return _iconMap[iconName] ?? Icons.grid_view_rounded;
  }

  static Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return const Color(0xFF2196F3);
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2196F3);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadPostCounts();
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

              // Save individual profile fields to LocalStorage for checkout auto-fill
              await LocalStorage.setString('firstName', userData['firstName'] ?? '');
              await LocalStorage.setString('lastName', userData['lastName'] ?? '');
              await LocalStorage.setString('phoneNumber', userData['mobileNumber'] ?? '');

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

  Future<void> _loadPostCounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      setState(() => _isLoadingPosts = false);
      return;
    }

    final counts = <String, Map<String, int>>{};
    final colors = <String, Color>{};
    final icons = <String, IconData>{};

    try {
      final response = await ApiClient.get('/posts/my-stats');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['data'] != null) {
          final statsData = data['data'] as Map;

          // Parse module metadata from API (dynamic — no hardcoded maps)
          final modulesData = statsData['modules'] as Map? ?? {};
          final keyToDisplayName = <String, String>{};
          for (final entry in modulesData.entries) {
            final key = entry.key.toString();
            final meta = entry.value as Map? ?? {};
            final displayName = meta['displayName']?.toString() ?? key;
            keyToDisplayName[key] = displayName;
            colors[displayName] = _parseColor(meta['color']?.toString());
            icons[displayName] = _mapIcon(meta['icon']?.toString());
          }

          // Parse counts
          final countsData = statsData['counts'] as Map? ?? {};
          for (final entry in countsData.entries) {
            final displayName = keyToDisplayName[entry.key.toString()];
            if (displayName != null && entry.value is Map) {
              final c = entry.value as Map;
              counts[displayName] = {
                'free': (c['free'] as num?)?.toInt() ?? 0,
                'paid': (c['paid'] as num?)?.toInt() ?? 0,
                'total': (c['total'] as num?)?.toInt() ?? 0,
              };
            }
          }

          // Parse limits
          final limitsData = statsData['limits'] as Map? ?? {};
          _postLimits = limitsData.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));

          // Parse pricing (keyed by displayName)
          final pricingData = statsData['pricing'] as Map? ?? {};
          final parsedPricing = <String, Map<String, dynamic>>{};
          for (final entry in pricingData.entries) {
            final displayName = keyToDisplayName[entry.key.toString()];
            if (displayName != null && entry.value is Map) {
              final p = entry.value as Map;
              parsedPricing[displayName] = {
                'price': (p['price'] as num?)?.toInt() ?? 0,
                'durationDays': (p['durationDays'] as num?)?.toInt() ?? 30,
                'perDayRate': (p['perDayRate'] as num?)?.toDouble() ?? 0.0,
              };
            }
          }
          _postPricing = parsedPricing;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _postCounts = counts;
        _moduleColors = colors;
        _moduleIcons = icons;
        _isLoadingPosts = false;
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
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        // Navigate to dashboard instead of exiting
        if (context.mounted) {
          context.go('/');
        }
      },
      child: Scaffold(
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
                              _buildPostStatsCard(),
                              const SizedBox(height: 24),
                              _buildSystemInfoCard(),
                              const SizedBox(height: 24),
                              _buildContactSupportCard(),
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
        _buildActionRow('Payment History', Icons.payment_outlined, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const PaymentHistoryScreen(),
          ));
        }),
      ],
    );
  }

  Widget _buildPostStatsCard() {
    if (_isLoadingPosts) {
      return _buildCard('My Posts', Icons.article_outlined, [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      ]);
    }

    int totalFree = 0, totalPaid = 0, totalAll = 0;
    for (final c in _postCounts.values) {
      totalFree += c['free'] ?? 0;
      totalPaid += c['paid'] ?? 0;
      totalAll += c['total'] ?? 0;
    }

    // Module display properties come from API (dynamic — no hardcoded maps)
    final moduleColors = _moduleColors;
    final moduleIcons = _moduleIcons;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () => setState(() => _postsExpanded = !_postsExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.article_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('My Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/customer/my-posts'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _postsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          // Summary badges - always visible
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _buildStatChip('$totalAll', 'Total', const Color(0xFF2196F3)),
                const SizedBox(width: 10),
                _buildStatChip('$totalFree', 'Free', const Color(0xFF4CAF50)),
                const SizedBox(width: 10),
                _buildStatChip('$totalPaid', 'Paid', const Color(0xFFFF9800)),
              ],
            ),
          ),
          // Pricing info banner - always visible
          if (_postPricing.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50).withOpacity(0.08),
                      const Color(0xFF2196F3).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Post Pricing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildPricingRow(Icons.card_giftcard_rounded, '1st Post', 'FREE', const Color(0xFF4CAF50)),
                    const SizedBox(height: 6),
                    Builder(builder: (_) {
                      final firstPricing = _postPricing.values.isNotEmpty ? _postPricing.values.first : null;
                      final price = firstPricing?['price'] ?? 15;
                      final days = firstPricing?['durationDays'] ?? 30;
                      final perDay = firstPricing?['perDayRate'] ?? 0.5;
                      return Column(
                        children: [
                          _buildPricingRow(Icons.currency_rupee_rounded, 'Next Post', '\u20B9$price per post', const Color(0xFFFF9800)),
                          const SizedBox(height: 6),
                          _buildPricingRow(Icons.calendar_today_rounded, 'Validity', '$days days', const Color(0xFF2196F3)),
                          const SizedBox(height: 6),
                          _buildPricingRow(Icons.trending_down_rounded, 'Per Day', '\u20B9$perDay / day', const Color(0xFF9C27B0)),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          // Expandable module breakdown
          if (_postsExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            // Column headers
            Padding(
              padding: const EdgeInsets.fromLTRB(64, 10, 16, 4),
              child: Row(
                children: [
                  const Expanded(child: SizedBox()),
                  SizedBox(width: 42, child: Text('Free', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                  const SizedBox(width: 6),
                  SizedBox(width: 42, child: Text('Paid', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                  const SizedBox(width: 6),
                  SizedBox(width: 42, child: Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                  const SizedBox(width: 6),
                  SizedBox(width: 52, child: Text('Price', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                  const SizedBox(width: 6),
                  SizedBox(width: 42, child: Text('Days', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                ],
              ),
            ),
            ..._postCounts.entries.map((entry) {
              final name = entry.key;
              final counts = entry.value;
              final color = moduleColors[name] ?? Colors.grey;
              final icon = moduleIcons[name] ?? Icons.article;
              final total = counts['total'] ?? 0;
              final free = counts['free'] ?? 0;
              final paid = counts['paid'] ?? 0;
              final pricing = _postPricing[name];
              final price = pricing?['price'] ?? 0;
              final days = pricing?['durationDays'] ?? 30;

              return InkWell(
                onTap: () => context.push('/customer/my-posts?module=$name'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      SizedBox(
                        width: 42,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('$free', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)), textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 42,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('$paid', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)), textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 42,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('$total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 52,
                        child: Text('\u20B9$price', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 42,
                        child: Text('${days}d', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildStatChip(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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

  Widget _buildContactSupportCard() {
    const supportNumber = '6374217724';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final Uri launchUri = Uri(
            scheme: 'tel',
            path: supportNumber,
          );
          try {
            if (await canLaunchUrl(launchUri)) {
              await launchUrl(launchUri);
            } else {
              if (mounted) {
                Helpers.showSnackBar(context, 'Could not launch phone call', isError: true);
              }
            }
          } catch (e) {
            if (mounted) {
              Helpers.showSnackBar(context, 'Error: $e', isError: true);
            }
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.phone_in_talk_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Support',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        supportNumber,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ],
            ),
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