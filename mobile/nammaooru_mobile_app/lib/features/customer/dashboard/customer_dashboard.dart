import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/order_api_service.dart';
import '../../../shared/services/notification_service.dart';
import '../screens/shop_listing_screen.dart';
import '../screens/shop_details_screen.dart';
import '../screens/shop_categories_screen.dart';
import '../screens/location_picker_screen.dart';
import '../screens/google_maps_location_picker_screen.dart';
import '../screens/notifications_screen.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/address_service.dart';
import '../widgets/address_selection_dialog.dart';

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

  final _shopApi = ShopApiService();
  final _orderApi = OrderApiService();
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _getCurrentLocationOnStartup();
  }

  Future<void> _getCurrentLocationOnStartup() async {
    try {
      // First try to load default saved address
      final savedAddresses = await AddressService.instance.getSavedAddresses();
      final defaultAddress = savedAddresses.where((addr) => addr.isDefault).firstOrNull;

      if (defaultAddress != null && mounted) {
        setState(() {
          _selectedLocation = '${defaultAddress.addressLine1}, ${defaultAddress.city}';
        });
        return;
      }

      // If no default address, try to get current location
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && position.latitude != null && position.longitude != null) {
        final address = await LocationService.instance.getAddressFromCoordinates(
          position.latitude!,
          position.longitude!,
        );

        if (address != null && mounted) {
          setState(() {
            _selectedLocation = '${address['locality'] ?? ''}, ${address['administrativeArea'] ?? ''}';
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
        // If no saved addresses, open map picker to add first address
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
        }
      }
    } finally {
      _isLocationPickerOpen = false;
    }
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF388E3C),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
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
                      _buildServiceCategories(),
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome! 🙏',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'What would you like to order?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            // TODO: Implement search
          },
        ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${NotificationService.getUnreadCount()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
      ],
    );
  }

  Widget _buildLocationSelector() {
    return InkWell(
      onTap: _showLocationPicker,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: VillageTheme.primaryGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deliver to',
                    style: TextStyle(
                      fontSize: 12,
                      color: VillageTheme.secondaryText,
                    ),
                  ),
                  Text(
                    _selectedLocation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VillageTheme.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategories() {
    final categories = [
      {'name': 'Grocery', 'icon': Icons.local_grocery_store, 'color': Colors.green},
      {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.orange},
      {'name': 'Parcel', 'icon': Icons.local_shipping, 'color': Colors.blue},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you need?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: VillageTheme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'What do you need?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: VillageTheme.secondaryText,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(
              category['name'] as String,
              category['icon'] as IconData,
              category['color'] as Color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String name, IconData icon, Color color) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopListingScreen(
                  category: name.toLowerCase(),
                  categoryTitle: name,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickAction(
            'Track Order',
            Icons.delivery_dining,
            VillageTheme.primaryGreen,
            () {
              Navigator.pushNamed(context, '/customer/orders');
            },
          ),
          _buildQuickAction(
            'Reorder',
            Icons.refresh,
            VillageTheme.accentOrange,
            () {
              // TODO: Show reorder options
            },
          ),
          _buildQuickAction(
            'Favorites',
            Icons.favorite_border,
            Colors.red,
            () {
              // TODO: Navigate to favorites
            },
          ),
          _buildQuickAction(
            'Support',
            Icons.help_outline,
            Colors.orange,
            () {
              // TODO: Navigate to support
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: VillageTheme.secondaryText,
                fontWeight: FontWeight.w500,
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
                // TODO: Navigate to all shops
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

  Widget _buildShopCard(Map<String, dynamic>? shop) {
    final shopName = shop?['name'] ?? 'Shop';
    final businessType = shop?['businessType'] ?? 'Store';
    final rating = shop?['averageRating']?.toString() ?? '4.0';
    final deliveryTime = shop?['estimatedDeliveryTime']?.toString() ?? '30';
    final isActive = shop?['isActive'] ?? true;
    
    if (!isActive) return const SizedBox();

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopCategoriesScreen(
                  shopId: (shop?['id'] ?? 1).toString(),
                  shopName: shop?['name'] ?? 'Shop',
                ),
              ),
            );
          },
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
                child: const Center(
                  child: Icon(
                    Icons.store,
                    size: 40,
                    color: VillageTheme.hintText,
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
                Navigator.pushNamed(context, '/customer/orders');
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
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No recent orders',
                          style: TextStyle(
                            fontSize: 16,
                            color: VillageTheme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start shopping to see your orders here',
                          style: TextStyle(
                            fontSize: 12,
                            color: VillageTheme.hintText,
                          ),
                          textAlign: TextAlign.center,
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
    final itemCount = order['items']?.length ?? 0;
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
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
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/order-tracking', arguments: orderNumber);
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: VillageTheme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}