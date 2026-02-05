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
import '../../../core/services/promo_code_service.dart';
import '../../../services/version_service.dart';
import 'dart:async';
import '../../../shared/widgets/update_dialog.dart';
import '../services/combo_service.dart';
import '../models/combo_model.dart';
import '../widgets/combo_banner_widget.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/product_model.dart';
import '../services/marketplace_service.dart';
import '../screens/marketplace_screen.dart';
import '../screens/real_estate_screen.dart';
import '../screens/create_post_screen.dart';

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
  List<CustomerCombo> _combos = [];
  List<PromoCode> _promos = [];
  DateTime? _lastBackPressTime;
  final PageController _unifiedOffersController = PageController();
  Timer? _autoSlideTimer;
  int _currentOfferPage = 0;

  List<dynamic> _marketplacePosts = [];
  bool _isLoadingMarketplace = false;

  final _shopApi = ShopApiService();
  final _orderApi = OrderApiService();
  final _promoService = PromoCodeService();
  final _marketplaceService = MarketplaceService();

  @override
  void initState() {
    super.initState();
    print('🔵 CustomerDashboard initState called');
    _checkVersionOnStartup();
    _loadDashboardData();
    _getCurrentLocationOnStartup();
    // App version checking is handled globally in app.dart, no need for duplicate check here
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _unifiedOffersController.dispose();
    super.dispose();
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
      _loadCombos(),
      _loadPromos(),
      _loadMarketplacePosts(),
    ]);
    _startAutoSlideOffers();
  }

  Future<void> _loadMarketplacePosts() async {
    setState(() {
      _isLoadingMarketplace = true;
    });
    try {
      final response = await _marketplaceService.getApprovedPosts(page: 0, size: 6);
      if (mounted) {
        final data = response['data'];
        setState(() {
          _marketplacePosts = data?['content'] ?? [];
          _isLoadingMarketplace = false;
        });
      }
    } catch (e) {
      print('Error loading marketplace posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingMarketplace = false;
        });
      }
    }
  }

  Future<void> _loadPromos() async {
    try {
      final promos = await _promoService.getActivePromotions();
      if (mounted) {
        setState(() {
          _promos = promos;
        });
      }
    } catch (e) {
      print('Error loading promos: $e');
    }
  }

  void _startAutoSlideOffers() {
    final totalItems = _promos.length + _combos.length;
    if (totalItems <= 1) return;

    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_unifiedOffersController.hasClients && mounted) {
        final nextPage = (_currentOfferPage + 1) % totalItems;
        _unifiedOffersController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadCombos() async {
    try {
      final combos = await CustomerComboService.getAllActiveCombos();
      if (mounted) {
        setState(() {
          _combos = combos;
        });
      }
    } catch (e) {
      print('Error loading combos: $e');
    }
  }

  void _showComboDetails(CustomerCombo combo) {
    // Show combo detail bottom sheet directly
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComboDetailBottomSheet(
        combo: combo,
        onAddToCart: () {
          Navigator.pop(context); // Close bottom sheet
          _addComboToCart(combo);
        },
      ),
    );
  }

  Future<void> _addComboToCart(CustomerCombo combo) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Add each item in the combo to cart
    for (final item in combo.items) {
      final product = ProductModel(
        id: item.shopProductId.toString(),
        name: item.productName,
        nameTamil: item.productNameTamil,
        description: item.productName,
        price: item.unitPrice,
        images: item.imageUrl != null ? [item.imageUrl!] : [],
        unit: item.unit ?? 'piece',
        category: 'Combo Item',
        shopId: combo.shopCode ?? combo.shopId.toString(),
        shopDatabaseId: combo.shopId,
        shopName: combo.shopName ?? '',
        stockQuantity: 999,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cartProvider.addToCart(product, quantity: item.quantity);
    }

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${combo.name} added to cart!'),
          backgroundColor: VillageTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildUnifiedOffersCarousel() {
    final totalItems = _promos.length + _combos.length;

    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Text(
                'SPECIAL OFFERS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalItems',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Unified carousel
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _unifiedOffersController,
            itemCount: totalItems,
            onPageChanged: (index) {
              setState(() => _currentOfferPage = index);
            },
            itemBuilder: (context, index) {
              // First show combos, then promos
              if (index < _combos.length) {
                return _buildComboCard(_combos[index]);
              } else {
                return _buildPromoCard(_promos[index - _combos.length]);
              }
            },
          ),
        ),
        // Page indicator dots
        if (totalItems > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalItems, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentOfferPage == index ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentOfferPage == index
                        ? VillageTheme.primaryGreen
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildPromoCard(PromoCode promo) {
    return GestureDetector(
      onTap: () => _navigateToPromoShop(promo),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VillageTheme.primaryGreen,
              VillageTheme.primaryGreen.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: VillageTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                promo.shopName ?? 'PLATFORM OFFER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: VillageTheme.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.local_offer, color: Colors.white, size: 16),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹${promo.discountValue.toStringAsFixed(0)} OFF',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo.description ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Code: ${promo.code}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (promo.imageUrl != null)
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ImageUrlHelper.getFullImageUrl(promo.imageUrl),
                          fit: BoxFit.cover,
                          height: 120,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
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

  Widget _buildComboCard(CustomerCombo combo) {
    return GestureDetector(
      onTap: () => _showComboDetails(combo),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side - Image with discount badge
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    width: 140,
                    height: 200,
                    child: combo.bannerImageUrl != null
                        ? Image.network(
                            ImageUrlHelper.getFullImageUrl(combo.bannerImageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.local_offer, size: 40, color: Colors.grey),
                          ),
                  ),
                  // Discount badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${combo.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right side - Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      combo.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (combo.nameTamil != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        combo.nameTamil!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${combo.itemCount} items included',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${combo.comboPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${combo.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _AnimatedViewButton(onTap: () => _showComboDetails(combo)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPromoShop(PromoCode promo) {
    if (promo.shopId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShopDetailsScreen(
            shopId: promo.shopId!,
            shop: null,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Use code "${promo.code}" at checkout!'),
          backgroundColor: VillageTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
        body: SingleChildScrollView(
          child: Stack(
            children: [
              // Green curved header background
              _buildCurvedHeader(),
              // Content that overlaps the header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Spacer to position content below header top area
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location selector overlaps the curved header
                        _buildLocationSelector(),
                      ],
                    ),
                  ),
                  // White background to cover the green curve
                  Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Special Offers Carousel (top)
                          _buildUnifiedOffersCarousel(),
                          const SizedBox(height: 24),
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

  Widget _buildCurvedHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Green background with curve using Container
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : VillageTheme.primaryGreen,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.elliptical(200, 50),
              bottomRight: Radius.elliptical(200, 50),
            ),
          ),
        ),
        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome text and app name
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              languageProvider.welcome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              languageProvider.appName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // Language toggle and notification
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Language toggle
                      Consumer<LanguageProvider>(
                        builder: (context, languageProvider, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'En',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: languageProvider.showTamil ? FontWeight.w400 : FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => languageProvider.toggleLanguage(),
                                  child: Container(
                                    width: 40,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: AnimatedAlign(
                                      alignment: languageProvider.showTamil
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      duration: const Duration(milliseconds: 200),
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // Notification bell
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return InkWell(
      onTap: _showLocationPicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on,
                color: VillageTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DELIVER TO',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedLocation,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a1a),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategories() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2x2 Grid: Grocery, Food, Marketplace, Real Estate
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.15,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                // 1. Grocery
                _buildModernCategoryTile(
                  icon: Icons.shopping_basket_rounded,
                  title: languageProvider.getText('Grocery', 'மளிகை'),
                  subtitle: languageProvider.getText('Daily essentials', 'தினசரி பொருட்கள்'),
                  color: const Color(0xFF4CAF50),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShopListingScreen(
                        category: 'grocery',
                        categoryTitle: 'Grocery',
                      ),
                    ),
                  ),
                ),
                // 2. Food
                _buildModernCategoryTile(
                  icon: Icons.restaurant_rounded,
                  title: languageProvider.getText('Food', 'உணவு'),
                  subtitle: languageProvider.getText('Restaurants & more', 'உணவகங்கள்'),
                  color: const Color(0xFFFF5722),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShopListingScreen(
                        category: 'food',
                        categoryTitle: 'Food',
                      ),
                    ),
                  ),
                ),
                // 3. Marketplace - Buy & Sell locally
                _buildModernCategoryTile(
                  icon: Icons.storefront_rounded,
                  title: languageProvider.getText('Marketplace', 'சந்தை'),
                  subtitle: languageProvider.getText('Buy & Sell locally', 'வாங்கு & விற்கு'),
                  color: const Color(0xFF2196F3),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MarketplaceScreen()),
                  ),
                ),
                // 4. Real Estate - Properties
                _buildModernCategoryTile(
                  icon: Icons.home_work_rounded,
                  title: languageProvider.getText('Real Estate', 'ரியல் எஸ்டேட்'),
                  subtitle: languageProvider.getText('Buy & Rent', 'வாங்கு & வாடகை'),
                  color: const Color(0xFF9C27B0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RealEstateScreen()),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernCategoryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background accent
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 80,
                color: color.withOpacity(0.08),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
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

  Widget _buildBuySellCard(String name) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MarketplaceScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VillageTheme.primaryGreen,
              VillageTheme.primaryGreen.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: VillageTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Post & Browse',
                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String name, String nameEn, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopListingScreen(
              category: nameEn.toLowerCase(),
              categoryTitle: nameEn,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a1a1a),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Buy & Sell',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VillageTheme.primaryText,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (!authProvider.isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in to sell items'), backgroundColor: Colors.orange),
                      );
                      context.push('/login');
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()))
                        .then((_) => _loadMarketplacePosts());
                  },
                  child: const Text(
                    'Post',
                    style: TextStyle(color: VillageTheme.warningOrange, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()));
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(color: VillageTheme.primaryGreen, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: _isLoadingMarketplace
              ? const Center(child: LoadingWidget())
              : _marketplacePosts.isEmpty
                  ? Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront_outlined, size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('No items for sale yet', style: TextStyle(color: Colors.grey[500])),
                              const SizedBox(height: 4),
                              const Text('Tap to browse or sell', style: TextStyle(color: VillageTheme.primaryGreen, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _marketplacePosts.length,
                      itemBuilder: (context, index) {
                        return _buildMarketplaceCard(_marketplacePosts[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMarketplaceCard(Map<String, dynamic> post) {
    final isSold = post['status'] == 'SOLD';
    final imageUrl = post['imageUrl'];
    final price = post['price'];

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()));
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                          height: 110,
                          width: 160,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 110,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 110,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 110,
                          width: 160,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                        ),
                ),
                // Details
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (price != null)
                        Text(
                          '\u20B9${double.tryParse(price.toString())?.toStringAsFixed(0) ?? price}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.primaryGreen,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${post['sellerName']?.split(' ').first ?? ''}${post['location'] != null ? ' - ${post['location']}' : ''}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post['sellerPhone'] != null && !isSold)
                            GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse('tel:${post['sellerPhone']}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.call, size: 16, color: Colors.green),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // SOLD badge
            if (isSold)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SOLD',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ),
          ],
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
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final shopName = shop != null ? languageProvider.getShopName(shop) : 'Shop';
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

// Custom painter for curved header
class _CurvedHeaderPainter extends CustomPainter {
  final Color color;

  _CurvedHeaderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height - 60);

    // Create a smooth curve at the bottom
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 60,
    );

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated View Details Button with pulse effect
class _AnimatedViewButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedViewButton({required this.onTap});

  @override
  State<_AnimatedViewButton> createState() => _AnimatedViewButtonState();
}

class _AnimatedViewButtonState extends State<_AnimatedViewButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VillageTheme.primaryGreen,
                    const Color(0xFF66BB6A),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: VillageTheme.primaryGreen.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.touch_app,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
