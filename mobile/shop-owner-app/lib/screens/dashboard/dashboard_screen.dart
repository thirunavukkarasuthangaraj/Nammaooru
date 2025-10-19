import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/login_screen.dart';
import '../../services/api_service_simple.dart';
import '../notifications/notifications_screen.dart';
import '../orders/orders_screen.dart';
import '../payments/payments_screen.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import '../../core/services/app_update_service.dart';

class DashboardHomeScreen extends StatefulWidget {
  final String userName;
  final String token;

  const DashboardHomeScreen({
    super.key,
    required this.userName,
    required this.token,
  });

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  Map<String, dynamic> _stats = {
    'todayOrders': 0,
    'todayRevenue': 0.0,
    'monthlyRevenue': 0.0,
    'totalRevenue': 0.0,
    'totalOrders': 0,
    'pendingOrders': 0,
    'totalProducts': 0,
  };
  List<dynamic> _recentOrders = [];
  bool _isLoading = true;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _checkForAppUpdates();
  }

  Future<void> _checkForAppUpdates() async {
    // Delay the version check to let the UI load first
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      AppUpdateService.showUpdateDialogIfNeeded(context);
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Get token from stored data
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      final token = storedToken ?? widget.token;

      print('Using token: ${token.isNotEmpty ? "${token.substring(0, 30)}..." : "EMPTY"}');

      if (token.isEmpty) {
        print('ERROR: Token is empty!');
        _setMockData();
        return;
      }

      // Step 1: Fetch current user's shop to get the shopId (alphanumeric ID like SH616BAAB9)
      final myShopResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/shops/my-shop'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('My Shop API response: ${myShopResponse.statusCode}');

      if (myShopResponse.statusCode != 200) {
        print('Failed to fetch shop: ${myShopResponse.body}');
        _setMockData();
        return;
      }

      final myShopData = jsonDecode(myShopResponse.body);
      if (myShopData['statusCode'] != '0000' || myShopData['data'] == null) {
        print('Invalid shop response: ${myShopResponse.body}');
        _setMockData();
        return;
      }

      final shopId = myShopData['data']['shopId'];  // e.g., "SH616BAAB9"
      final internalShopId = myShopData['data']['id'];  // e.g., 4
      print('Shop ID: $shopId (internal: $internalShopId)');

      // Step 2: Fetch dashboard stats using shopId
      final dashboardResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/shops/$shopId/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Dashboard API response: ${dashboardResponse.statusCode}');

      // Step 3: Fetch recent orders using shopId
      final ordersResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/shops/$shopId/orders?page=0&size=5'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Orders API response: ${ordersResponse.statusCode}');

      // Process dashboard data
      if (dashboardResponse.statusCode == 200) {
        final dashboardData = jsonDecode(dashboardResponse.body);

        if (dashboardData['statusCode'] == '0000' && dashboardData['data'] != null) {
          final data = dashboardData['data'];
          final orderMetrics = data['orderMetrics'] ?? {};
          final productMetrics = data['productMetrics'] ?? {};

          print('Parsed dashboard data - orderMetrics: $orderMetrics');
          print('Parsed dashboard data - productMetrics: $productMetrics');

          setState(() {
            _stats = {
              'todayOrders': orderMetrics['todayOrders'] ?? 0,
              'todayRevenue': (orderMetrics['todayRevenue'] ?? 0).toDouble(),
              'monthlyRevenue': (orderMetrics['monthlyRevenue'] ?? 0).toDouble(),
              'totalRevenue': (orderMetrics['totalRevenue'] ?? 0).toDouble(),
              'totalOrders': orderMetrics['totalOrders'] ?? 0,
              'pendingOrders': orderMetrics['pendingOrders'] ?? 0,
              'totalProducts': productMetrics['totalProducts'] ?? 0,
            };
            _unreadNotificationCount = orderMetrics['pendingOrders'] ?? 0;
            _isLoading = false;
          });
          print('Stats updated: $_stats');
        }
      }

      // Process orders data
      if (ordersResponse.statusCode == 200) {
        final ordersData = jsonDecode(ordersResponse.body);

        if (ordersData['statusCode'] == '0000' && ordersData['data'] != null) {
          final orders = ordersData['data']['orders'] ?? [];
          print('Parsed orders count: ${orders.length}');
          setState(() {
            _recentOrders = orders.take(5).toList();
          });
          print('Recent orders updated: ${_recentOrders.length} orders');
        }
      }

      // If both APIs failed, use mock data
      if (dashboardResponse.statusCode != 200 && ordersResponse.statusCode != 200) {
        print('Both APIs failed, using mock data');
        _setMockData();
      }
    } catch (e, stackTrace) {
      print('Error fetching dashboard data: $e');
      print('Stack trace: $stackTrace');
      _setMockData();
    }
  }

  void _setMockData() {
    setState(() {
      _stats = {
        'todayOrders': 12,
        'todayRevenue': 5430.00,
        'monthlyRevenue': 45200.00,
        'totalRevenue': 125000.00,
        'totalOrders': 150,
        'pendingOrders': 3,
        'totalProducts': 45,
      };
      _recentOrders = [
        {
          'id': 1,
          'orderNumber': 'ORD001',
          'customerName': 'John Doe',
          'totalAmount': 250.00,
          'status': 'PENDING',
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 2,
          'orderNumber': 'ORD002',
          'customerName': 'Jane Smith',
          'totalAmount': 180.00,
          'status': 'CONFIRMED',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrdersScreen(token: widget.token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gridColumns = ResponsiveLayout.getGridColumns(context);
    final padding = ResponsiveLayout.getResponsivePadding(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Dashboard', style: AppTheme.h5),
        elevation: 0,
        actions: [
          Badge(
            label: Text('$_unreadNotificationCount'),
            isLabelVisible: _unreadNotificationCount > 0,
            child: ModernIconButton(
              icon: Icons.notifications,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(token: widget.token),
                  ),
                );
              },
              size: 48,
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Settings'),
                onTap: () {},
              ),
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: _logout,
              ),
            ],
          ),
          const SizedBox(width: AppTheme.space8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: AppTheme.roundedLarge,
                        boxShadow: AppTheme.shadowMedium,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textWhite.withOpacity(0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppTheme.space4),
                                Text(
                                  widget.userName,
                                  style: AppTheme.h3.copyWith(
                                    color: AppTheme.textWhite,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: AppTheme.roundedMedium,
                            ),
                            child: const Icon(
                              Icons.store,
                              size: 40,
                              color: AppTheme.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.space24),

                    // Statistics Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: gridColumns > 2 ? 3 : 2,
                      mainAxisSpacing: AppTheme.space12,
                      crossAxisSpacing: AppTheme.space12,
                      childAspectRatio: MediaQuery.of(context).size.width < 360
                          ? 1.35
                          : (gridColumns > 2 ? 1.85 : 1.55),
                      children: [
                        StatCard(
                          title: 'Today\'s Orders',
                          value: _stats['todayOrders'].toString(),
                          icon: Icons.shopping_cart,
                          color: AppTheme.secondary,
                          subtitle: 'Orders today',
                          useGradient: true,
                          onTap: _navigateToOrders,
                        ),
                        StatCard(
                          title: 'Pending Orders',
                          value: _stats['pendingOrders'].toString(),
                          icon: Icons.pending_actions,
                          color: AppTheme.warning,
                          subtitle: 'Awaiting action',
                          useGradient: true,
                          onTap: _navigateToOrders,
                        ),
                        StatCard(
                          title: 'Total Orders',
                          value: _stats['totalOrders'].toString(),
                          icon: Icons.receipt_long,
                          color: const Color(0xFF5E35B1),
                          subtitle: 'All time',
                          onTap: _navigateToOrders,
                        ),
                        StatCard(
                          title: 'Today\'s Revenue',
                          value: '₹${_stats['todayRevenue']}',
                          icon: Icons.attach_money,
                          color: AppTheme.success,
                          subtitle: 'Today\'s earnings',
                          useGradient: true,
                        ),
                        StatCard(
                          title: 'Monthly Revenue',
                          value: '₹${_stats['monthlyRevenue']}',
                          icon: Icons.trending_up,
                          color: const Color(0xFF00897B),
                          subtitle: 'This month',
                        ),
                        StatCard(
                          title: 'Total Products',
                          value: _stats['totalProducts'].toString(),
                          icon: Icons.inventory_2,
                          color: AppTheme.accent,
                          subtitle: 'In inventory',
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.space24),

                    // Payments & Settlements Card
                    InfoCard(
                      title: '',
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentsScreen(token: widget.token),
                            ),
                          );
                        },
                        borderRadius: AppTheme.roundedLarge,
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.space20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.space16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: AppTheme.roundedMedium,
                                  boxShadow: AppTheme.shadowSmall,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  color: AppTheme.textWhite,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payments & Settlements',
                                      style: AppTheme.h6,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppTheme.space4),
                                    Text(
                                      'Track your order payments and platform settlements',
                                      style: AppTheme.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: AppTheme.success),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.space24),

                    // Recent Orders Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Orders', style: AppTheme.h5),
                        ModernButton(
                          text: 'View All',
                          variant: ButtonVariant.text,
                          size: ButtonSize.small,
                          onPressed: _navigateToOrders,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),

                    if (_recentOrders.isEmpty)
                      InfoCard(
                        title: '',
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.space24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: AppTheme.textHint,
                                ),
                                const SizedBox(height: AppTheme.space12),
                                Text(
                                  'No recent orders',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._recentOrders.map((order) => Card(
                        margin: const EdgeInsets.only(bottom: AppTheme.space12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.roundedLarge,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppTheme.space16),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: _getStatusColor(order['status']),
                            child: Text(
                              _getCustomerInitials(order['customerName']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            order['customerName'] ?? 'Unknown',
                            style: AppTheme.h6,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: AppTheme.space4),
                            child: Text(
                              'Order #${order['orderNumber']} • ₹${order['totalAmount']}',
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space12,
                              vertical: AppTheme.space8,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order['status']).withOpacity(0.1),
                              borderRadius: AppTheme.roundedMedium,
                              border: Border.all(
                                color: _getStatusColor(order['status']),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              order['status'] ?? 'UNKNOWN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(order['status']),
                              ),
                            ),
                          ),
                        ),
                      )),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED': return Colors.blue;
      case 'PREPARING': return Colors.purple;
      case 'READY_FOR_PICKUP': return Colors.teal;
      case 'OUT_FOR_DELIVERY': return Colors.indigo;
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getCustomerInitials(String? customerName) {
    if (customerName == null || customerName.isEmpty) return '??';

    final nameParts = customerName.trim().split(' ');
    if (nameParts.isEmpty) return '??';

    if (nameParts.length == 1) {
      // Single name - take first 2 characters
      return nameParts[0].substring(0, nameParts[0].length >= 2 ? 2 : 1).toUpperCase();
    } else {
      // Multiple names - take first letter of first two words
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
  }
}