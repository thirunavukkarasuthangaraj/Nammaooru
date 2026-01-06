import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/order_api_service.dart';
import '../../../shared/services/notification_service.dart';
import '../screens/shop_listing_screen.dart';
import '../screens/shop_details_screen.dart';
// import '../screens/shop_details_modern_screen.dart';
import '../screens/location_picker_screen.dart';
import '../screens/google_maps_location_picker_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/address_management_screen.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/address_service.dart';
import '../widgets/address_selection_dialog.dart';
import '../../../shared/widgets/platform_promos_carousel.dart';
import '../../../services/version_service.dart';
import '../../../shared/widgets/update_dialog.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  String _selectedLocation = 'Getting your location...';
  bool _isLoadingShops = false;
  bool _isLoadingOrders = false;
  bool _isLocationPickerOpen = false;
  List<dynamic> _featuredShops = [];
  List<dynamic> _recentOrders = [];
  DateTime? _lastBackPressTime;

  final _shopApi = ShopApiService();
  final _orderApi = OrderApiService();

  @override
  void initState() {
    super.initState();
    print('🔵 CustomerDashboard initState called');
    _checkVersionOnStartup();
    _loadDashboardData();
    _getCurrentLocationOnStartup();
    // App version checking is handled globally in app.dart, no need for duplicate check here
  }

  Future<void> _getCurrentLocationOnStartup() async {
    try {
      // Check if user is authenticated before loading saved addresses
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isAuthenticated) {
        // Try to load default saved address for logged-in users
        try {
          final savedAddresses = await AddressService.instance.getSavedAddresses();
          final defaultAddress = savedAddresses.where((addr) => addr.isDefault).firstOrNull;

          if (defaultAddress != null && mounted) {
            setState(() {
              _selectedLocation = '${defaultAddress.addressLine1}, ${defaultAddress.city}';
            });
            return;
          }
        } catch (e) {
          print('Error loading saved addresses: $e');
          // Continue to get current location
        }
      }

      // For guest users or if no saved address, try to get current location
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && position.latitude != null && position.longitude != null) {
        final address = await LocationService.instance.getAddressFromCoordinates(
          position.latitude!,
          position.longitude!,
        );

        if (address != null && mounted) {
          setState(() {
            // Include village/subLocality if available
            final village = address['subLocality'] ?? '';
            final city = address['locality'] ?? '';

            if (village.isNotEmpty && city.isNotEmpty) {
              _selectedLocation = '$village, $city';
            } else if (city.isNotEmpty) {
              _selectedLocation = '$city, ${address['administrativeArea'] ?? ''}';
            } else {
              _selectedLocation = 'Tirupattur, Tamil Nadu'; // Fallback
            }
          });
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() {
          _selectedLocation = 'Tirupattur, Tamil Nadu'; // Fallback
        });
      }
    }
  }

  Future<void> _showLocationPicker() async {
    // Prevent multiple clicks with immediate flag setting
    if (_isLocationPickerOpen) return;

    _isLocationPickerOpen = true;

    try {
      // Check if user is authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        // Show login prompt for guests
        final shouldLogin = await _showLocationLoginPrompt();
        if (shouldLogin == true) {
          context.go('/login');
        }
        return;
      }

      // User is logged in - proceed with location picker
      // First check if user has saved addresses
      final savedAddresses = await AddressService.instance.getSavedAddresses();

      if (savedAddresses.isNotEmpty) {
        // Show address selection dialog if addresses exist
        await showDialog(
          context: context,
          builder: (context) => AddressSelectionDialog(
            currentLocation: _selectedLocation,
            onLocationSelected: (selectedLocation) {
              if (selectedLocation != _selectedLocation) {
                setState(() {
                  _selectedLocation = selectedLocation;
                });

                // Show confirmation
                Helpers.showSnackBar(
                  context,
                  'Delivery address updated',
                );
              }
            },
          ),
        );
      } else {
        // If no saved addresses, show choice dialog (Enter Manually vs Select from Map)
        await _showAddAddressOptionsDialog();
      }
    } finally {
      _isLocationPickerOpen = false;
    }
  }

  Future<void> _showAddAddressOptionsDialog() async {
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
                    Navigator.of(context).pop(); // Close options dialog
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (mounted) {
                      // Navigate to Address Management and auto-open manual form
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddressManagementScreen(autoOpenManualForm: true),
                        ),
                      );
                      if (result != null) {
                        await AddressService.instance.getSavedAddresses();
                        // Reload current location
                        _getCurrentLocationOnStartup();
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
                          currentLocation: _selectedLocation,
                        ),
                      ),
                    );

                    if (selectedLocation != null && selectedLocation != _selectedLocation) {
                      setState(() {
                        _selectedLocation = selectedLocation;
                      });

                      // Show confirmation
                      Helpers.showSnackBar(
                        context,
                        'Location updated to $selectedLocation',
                      );

                      // Reload addresses to update the list
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
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadFeaturedShops(),
      _loadRecentOrders(),
    ]);
  }
  
  Future<void> _loadFeaturedShops() async {
    setState(() => _isLoadingShops = true);
    
    try {
      final response = await _shopApi.getActiveShops(page: 0, size: 10);
      if (mounted && response['success'] == true && response['data'] != null) {
        setState(() {
          _featuredShops = response['data']['content'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load shops', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingShops = false);
      }
    }
  }
  
  Future<void> _loadRecentOrders() async {
    setState(() => _isLoadingOrders = true);

    try {
      // Check if user is authenticated before loading orders
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        // Guest user - skip loading orders
        if (mounted) {
          setState(() {
            _recentOrders = [];
            _isLoadingOrders = false;
          });
        }
        return;
      }

      // User is logged in - load orders
      final response = await _orderApi.getCustomerOrders(page: 0, size: 3);
      if (mounted && response['success'] == true && response['data'] != null) {
        setState(() {
          _recentOrders = response['data']['content'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error loading recent orders: $e');
        // Don't show error for orders as user might not be logged in
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }
  
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
        _lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2);

    if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
      _lastBackPressTime = now;
      Helpers.showSnackBar(
        context,
        'Press back again to exit',
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 CustomerDashboard build called');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await _onWillPop();
        if (shouldPop) {
          // Exit the app when user presses back twice on home screen
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationSelector(),
                      const SizedBox(height: 20),
                      PlatformPromosCarousel(
                        onPromoTap: () {
                          // Handle promo tap - navigate to deals page or show details
                          // context.push('/customer/deals');
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildServiceCategories(),
                      const SizedBox(height: 24),
                      _buildFeaturedShops(),
                      const SizedBox(height: 24),
                      _buildRecentOrders(),
                      const SizedBox(height: 20),
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

  // Automatic version check on dashboard startup
  Future<void> _checkVersionOnStartup() async {
    try {
      print('🔄 Starting version check...');
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      print('📱 Current app version: $currentVersion');

      final versionInfo = await VersionService.checkVersion(currentVersion);
      print('✅ Version check response: $versionInfo');

      if (!mounted) {
        print('⚠️ Widget not mounted, cannot show dialog');
        return;
      }

      if (versionInfo != null) {
        print('ℹ️ Update available! Showing dialog...');
        // Show update dialog only if update is available
        final isMandatory = versionInfo['isMandatory'] ?? false;

        // Add small delay to ensure context is ready
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) {
          print('⚠️ Widget unmounted during delay');
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: !isMandatory, // Prevent dismissing mandatory updates by tapping outside
          builder: (context) => UpdateDialog(
            currentVersion: currentVersion,
            newVersion: versionInfo['currentVersion'] ?? 'Unknown',
            releaseNotes: versionInfo['releaseNotes'] ?? '',
            updateUrl: versionInfo['updateUrl'] ?? '',
            isMandatory: isMandatory,
            updateRequired: versionInfo['updateRequired'] ?? false,
          ),
        );
        print('✅ Dialog shown successfully');
      } else {
        print('ℹ️ No update needed or check skipped');
      }
      // If versionInfo is null, no update needed - do nothing (silent success)
    } catch (e) {
      // Silent fail for version check - don't bother user with errors
      print('❌ Version check failed: $e');
    }
  }

  Widget _buildSliverAppBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 100.0,
      floating: false,
      pinned: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : VillageTheme.primaryGreen,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageProvider.welcome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  languageProvider.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
      ),
      actions: [
        Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        languageProvider.showTamil ? 'த' : 'En',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Switch(
                      value: languageProvider.showTamil,
                      onChanged: (value) {
                        languageProvider.toggleLanguage();
                      },
                      activeColor: Colors.white,
                      activeTrackColor: VillageTheme.accentOrange,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${NotificationService.getUnreadCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return InkWell(
      onTap: _showLocationPicker,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [],
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on,
                color: VillageTheme.primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deliver to',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedLocation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1a1a1a),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: VillageTheme.primaryGreen,
                size: 24,
                weight: 600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategories() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final categories = [
          {
            'name': languageProvider.getText('Farmer Products', 'விவசாய பொருட்கள்'),
            'nameEn': 'Farmer Products',
            'imageUrl': 'assets/images/formar.png',
            'borderRadius': const BorderRadius.only(
              topLeft: Radius.circular(48),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(48),
              bottomRight: Radius.circular(24),
            )
          },
          {
            'name': languageProvider.getText('Grocery', 'மளிகை'),
            'nameEn': 'Grocery',
            'imageUrl': 'assets/images/gorceries.webp',
            'borderRadius': const BorderRadius.all(Radius.circular(32))
          },
          {
            'name': languageProvider.getText('Food', 'உணவு'),
            'nameEn': 'Food',
            'imageUrl': 'assets/images/Food.jpeg',
            'borderRadius': const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(48),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(48),
            )
          },
          {
            'name': languageProvider.getText('Medicine', 'மருந்து'),
            'nameEn': 'Medicine',
            'imageUrl': 'assets/images/Medicines.png',
            'borderRadius': const BorderRadius.all(Radius.circular(32))
          },
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  VillageTheme.primaryGreen,
                  VillageTheme.primaryGreen.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                languageProvider.getText('What do you need?', 'உங்களுக்கு என்ன வேண்டும்?'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(
                  category['name'] as String,
                  category['nameEn'] as String,
                  category['imageUrl'] as String,
                  category['borderRadius'] as BorderRadius,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(String name, String nameEn, String imageUrl, BorderRadius borderRadius) {
    return GestureDetector(
      onTap: () async {
        // Special handling for Farmer Products - redirect to WhatsApp channel
        if (nameEn == 'Farmer Products') {
          await _openWhatsAppChannel(context);
        } else {
          // Regular category - navigate to shop listing
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShopListingScreen(
                category: nameEn.toLowerCase(),
                categoryTitle: nameEn,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [],
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [],
                    ),
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedShops() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Shops',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VillageTheme.primaryText,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/customer/shops');
              },
              child: const Text(
                'See All',
                style: TextStyle(
                  color: VillageTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _isLoadingShops
              ? const Center(child: LoadingWidget())
              : _featuredShops.isEmpty
                  ? const Center(
                      child: Text(
                        'No shops available',
                        style: TextStyle(color: VillageTheme.secondaryText),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _featuredShops.length,
                      itemBuilder: (context, index) {
                        final shop = _featuredShops[index];
                        return _buildShopCard(shop);
                      },
                    ),
        ),
      ],
    );
  }

  /// Extract logo URL from shop images
  String? _getShopLogoUrl(Map<String, dynamic>? shop) {
    if (shop == null) return null;
    final images = shop['images'] as List<dynamic>?;
    if (images == null || images.isEmpty) return null;

    // Find LOGO type first, then primary, then first image
    var logo = images.firstWhere(
      (img) => img['imageType'] == 'LOGO',
      orElse: () => images.firstWhere(
        (img) => img['isPrimary'] == true,
        orElse: () => images.isNotEmpty ? images.first : null,
      ),
    );

    return logo?['imageUrl'];
  }

  Widget _buildShopCard(Map<String, dynamic>? shop) {
    final shopName = shop?['name'] ?? 'Shop';
    final businessType = shop?['businessType'] ?? 'Store';
    final rating = shop?['averageRating']?.toString() ?? '4.0';
    final deliveryTime = shop?['estimatedDeliveryTime']?.toString() ?? '30';
    final isActive = shop?['isActive'] ?? true;
    final logoUrl = _getShopLogoUrl(shop);

    if (!isActive) return const SizedBox();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailsScreen(
              shopId: shop?['id'] ?? 1,
              shop: shop,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [],
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: ImageUrlHelper.getFullImageUrl(logoUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Center(
                          child: Icon(
                            Icons.store,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.store,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.store,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VillageTheme.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontSize: 12,
                          color: VillageTheme.secondaryText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$deliveryTime min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: VillageTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    businessType,
                    style: const TextStyle(
                      fontSize: 10,
                      color: VillageTheme.hintText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VillageTheme.primaryText,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/customer/orders');
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: VillageTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoadingOrders
            ? const Center(child: LoadingWidget())
            : _recentOrders.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: VillageTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: VillageTheme.primaryGreen.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Orders Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your order history will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: VillageTheme.hintText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.push('/customer/shops');
                          },
                          icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                          label: const Text('Start Shopping'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VillageTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _recentOrders.take(3).map((order) {
                      return _buildOrderCard(order);
                    }).toList(),
                  ),
      ],
    );
  }

  Widget _buildPromotionalBanners() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Offers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: VillageTheme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      VillageTheme.primaryGreen,
                      VillageTheme.primaryGreen.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '50% OFF',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'On your first grocery order',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Apply offer
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: VillageTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Order Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderNumber = order['orderNumber'] ?? 'N/A';
    final totalAmount = order['totalAmount']?.toString() ?? '0';
    final status = order['status'] ?? 'PENDING';
    final itemCount = order['itemCount'] ?? order['numberOfItems'] ?? order['items']?.length ?? 1;
    final createdAt = order['createdAt'] ?? '';

    Color statusColor = VillageTheme.primaryGreen;
    String statusText = status;

    switch (status.toUpperCase()) {
      case 'DELIVERED':
        statusColor = VillageTheme.successGreen;
        statusText = 'Delivered';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'CONFIRMED':
        statusColor = VillageTheme.primaryGreen;
        statusText = 'Confirmed';
        break;
      default:
        statusText = status;
    }

    return GestureDetector(
      onTap: () {
        context.go('/customer/orders');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [],
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_bag,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$orderNumber',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VillageTheme.primaryText,
                    ),
                  ),
                  Text(
                    '$itemCount items • ₹$totalAmount',
                    style: const TextStyle(
                      fontSize: 14,
                      color: VillageTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (status.toUpperCase() == 'DELIVERED')
                  TextButton(
                    onPressed: () async {
                      try {
                        await _orderApi.reorder(order['id']);
                        Helpers.showSnackBar(context, 'Items added to cart');
                        // Navigate to cart after adding items
                        if (mounted) {
                          context.push('/customer/cart');
                        }
                      } catch (e) {
                        Helpers.showSnackBar(context, 'Failed to reorder', isError: true);
                      }
                    },
                    child: const Text(
                      'Reorder',
                      style: TextStyle(
                        color: VillageTheme.primaryGreen,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showLocationLoginPrompt() {
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

  Future<void> _openWhatsAppChannel(BuildContext context) async {
    const whatsappChannelUrl = 'https://www.whatsapp.com/channel/0029VbB1iXbAYlULfRaQlc0z';
    final whatsappUrl = Uri.parse(whatsappChannelUrl);

    // Show loading indicator
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Opening WhatsApp Channel...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Try to launch the URL
      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.platformDefault,
      );

      // Close loading dialog - use post frame callback to avoid navigator lock issues
      if (mounted && Navigator.of(context).canPop()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.pop(context);
          }
        });
      }

      if (launched) {
        // Success
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'Opening WhatsApp Channel...',
            isError: false,
          );
        }
      } else {
        // Failed to launch - show fallback dialog
        if (mounted) {
          await _showWhatsAppLinkDialog(context, whatsappChannelUrl);
        }
      }
    } catch (e) {
      // Close loading dialog - use post frame callback to avoid navigator lock issues
      if (mounted && Navigator.of(context).canPop()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.pop(context);
          }
        });
      }

      // Show fallback dialog
      if (mounted) {
        await _showWhatsAppLinkDialog(context, whatsappChannelUrl);
      }
    }
  }

  Future<void> _showWhatsAppLinkDialog(BuildContext context, String url) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.message,
                color: Color(0xFF25D366),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Join Our WhatsApp Channel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get fresh farmer products directly! Copy the link below and open it in your browser:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: url));
                      if (context.mounted) {
                        Helpers.showSnackBar(
                          context,
                          'Link copied to clipboard!',
                          isError: false,
                        );
                      }
                    },
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF25D366), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can also search for "NammaOoru Farmer Products" on WhatsApp',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                Navigator.pop(context);
                Helpers.showSnackBar(
                  context,
                  'Link copied! Open it in your browser.',
                  isError: false,
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Link', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
