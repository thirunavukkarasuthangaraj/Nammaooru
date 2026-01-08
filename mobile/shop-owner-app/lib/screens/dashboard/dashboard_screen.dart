import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../auth/login_screen.dart';
import '../../providers/language_provider.dart';
import '../notifications/notifications_screen.dart';
import '../orders/orders_screen.dart';
import '../payments/payments_screen.dart';
import '../promo_codes/promo_codes_screen.dart';
import '../combos/combo_list_screen.dart';
import '../inventory/inventory_screen.dart';
import '../products/products_screen.dart';
import '../../utils/app_config.dart';
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
    'totalOrders': 0,
    'pendingOrders': 0,
    'todayRevenue': 0.0,
    'monthlyRevenue': 0.0,
    'totalProducts': 0,
    'lowStockProducts': 0,
    'outOfStockProducts': 0,
  };
  bool _isLoading = true;
  int _unreadNotificationCount = 0;
  int? _shopId;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _checkForAppUpdates();
  }

  Future<void> _checkForAppUpdates() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      AppUpdateService.showUpdateDialogIfNeeded(context);
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      final token = storedToken ?? widget.token;

      if (token.isEmpty) {
        _setMockData();
        return;
      }

      final myShopResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/shops/my-shop'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (myShopResponse.statusCode != 200) {
        _setMockData();
        return;
      }

      final myShopData = jsonDecode(myShopResponse.body);
      print('My shop API response: $myShopData');
      if (myShopData['statusCode'] != '0000' || myShopData['data'] == null) {
        print('My shop API failed or no data');
        _setMockData();
        return;
      }

      // Try 'id' first (numeric), then 'shopId' (might be string)
      final shopData = myShopData['data'];
      print('Shop data: $shopData');
      final shopId = shopData['id'] ?? shopData['shopId'];
      print('Raw shopId value: $shopId (type: ${shopId.runtimeType})');
      _shopId = shopId is int ? shopId : int.tryParse(shopId.toString());
      print('Loaded shopId: $_shopId');

      final dashboardResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/shops/$shopId/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (dashboardResponse.statusCode == 200) {
        final dashboardData = jsonDecode(dashboardResponse.body);

        if (dashboardData['statusCode'] == '0000' && dashboardData['data'] != null) {
          final data = dashboardData['data'];
          final orderMetrics = data['orderMetrics'] ?? {};
          final productMetrics = data['productMetrics'] ?? {};

          setState(() {
            _stats = {
              'todayOrders': orderMetrics['todayOrders'] ?? 0,
              'totalOrders': orderMetrics['totalOrders'] ?? 0,
              'pendingOrders': orderMetrics['pendingOrders'] ?? 0,
              'todayRevenue': (orderMetrics['todayRevenue'] ?? 0).toDouble(),
              'monthlyRevenue': (orderMetrics['monthlyRevenue'] ?? 0).toDouble(),
              'totalProducts': productMetrics['totalProducts'] ?? 0,
              'lowStockProducts': productMetrics['lowStockProducts'] ?? 0,
              'outOfStockProducts': productMetrics['outOfStockProducts'] ?? 0,
            };
            _unreadNotificationCount = orderMetrics['pendingOrders'] ?? 0;
            _isLoading = false;
          });
        }
      } else {
        _setMockData();
      }
    } catch (e) {
      _setMockData();
    }
  }

  void _setMockData() {
    setState(() {
      _stats = {
        'todayOrders': 0,
        'totalOrders': 0,
        'pendingOrders': 0,
        'todayRevenue': 0.0,
        'monthlyRevenue': 0.0,
        'totalProducts': 0,
        'lowStockProducts': 0,
        'outOfStockProducts': 0,
      };
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    try {
      await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/shop-owner/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
    } catch (e) {
      // Ignore logout errors
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final hasStockAlert = (_stats['lowStockProducts'] as int) > 0 ||
                          (_stats['outOfStockProducts'] as int) > 0;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDashboardData,
                  color: const Color(0xFF2E7D32),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header
                      SliverAppBar(
                        expandedHeight: 100,
                        floating: false,
                        pinned: true,
                        backgroundColor: const Color(0xFF2E7D32),
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                              ),
                            ),
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      languageProvider.getText('Welcome back,', 'வணக்கம்,'),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => NotificationsScreen(token: widget.token)),
                                ),
                              ),
                              if (_unreadNotificationCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                    child: Text(
                                      '$_unreadNotificationCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_outlined, color: Colors.white, size: 24),
                            onPressed: () => _showLogoutDialog(context, languageProvider),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),

                      // Content
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Orders Overview Section
                              _SectionTitle(
                                title: languageProvider.getText('Orders Overview', 'ஆர்டர் கண்ணோட்டம்'),
                                icon: Icons.shopping_cart_outlined,
                              ),
                              const SizedBox(height: 12),

                              // Orders Stats Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      label: languageProvider.getText("Today's Orders", 'இன்றைய ஆர்டர்கள்'),
                                      value: '${_stats['todayOrders']}',
                                      icon: Icons.today,
                                      color: const Color(0xFF1976D2),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => OrdersScreen(token: widget.token)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetricCard(
                                      label: languageProvider.getText('Pending', 'நிலுவை'),
                                      value: '${_stats['pendingOrders']}',
                                      icon: Icons.pending_actions,
                                      color: const Color(0xFFE65100),
                                      highlight: (_stats['pendingOrders'] as int) > 0,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => OrdersScreen(token: widget.token)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetricCard(
                                      label: languageProvider.getText('Total', 'மொத்தம்'),
                                      value: '${_stats['totalOrders']}',
                                      icon: Icons.receipt_long,
                                      color: const Color(0xFF5E35B1),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => OrdersScreen(token: widget.token)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Revenue Section
                              _SectionTitle(
                                title: languageProvider.getText('Revenue', 'வருவாய்'),
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: _RevenueCard(
                                      label: languageProvider.getText("Today", 'இன்று'),
                                      value: _formatCurrency(_stats['todayRevenue'] as double),
                                      icon: Icons.currency_rupee,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RevenueCard(
                                      label: languageProvider.getText('This Month', 'இந்த மாதம்'),
                                      value: _formatCurrency(_stats['monthlyRevenue'] as double),
                                      icon: Icons.calendar_month,
                                      color: const Color(0xFF00796B),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Inventory Section
                              _SectionTitle(
                                title: languageProvider.getText('Inventory', 'சரக்கு'),
                                icon: Icons.inventory_2_outlined,
                              ),
                              const SizedBox(height: 12),

                              // Stock Overview Card
                              _InventoryCard(
                                totalProducts: _stats['totalProducts'] as int,
                                lowStock: _stats['lowStockProducts'] as int,
                                outOfStock: _stats['outOfStockProducts'] as int,
                                languageProvider: languageProvider,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => InventoryScreen(token: widget.token)),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Quick Actions
                              _SectionTitle(
                                title: languageProvider.getText('Quick Actions', 'விரைவு செயல்கள்'),
                                icon: Icons.flash_on_outlined,
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionCard(
                                      icon: Icons.receipt_long_outlined,
                                      label: languageProvider.orders,
                                      color: const Color(0xFF1976D2),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => OrdersScreen(token: widget.token)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ActionCard(
                                      icon: Icons.category_outlined,
                                      label: languageProvider.getText('Products', 'பொருட்கள்'),
                                      color: const Color(0xFF7B1FA2),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => ProductsScreen(token: widget.token)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionCard(
                                      icon: Icons.account_balance_wallet_outlined,
                                      label: languageProvider.getText('Payments', 'பணம்'),
                                      color: const Color(0xFF2E7D32),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => PaymentsScreen(token: widget.token)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ActionCard(
                                      icon: Icons.local_offer_outlined,
                                      label: languageProvider.promoCodes,
                                      color: const Color(0xFFE65100),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const PromoCodesScreen()),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Combos Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionCard(
                                      icon: Icons.card_giftcard,
                                      label: languageProvider.getText('Combos', 'காம்போக்கள்'),
                                      color: const Color(0xFFD32F2F),
                                      onTap: () {
                                        if (_shopId != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ComboListScreen(shopId: _shopId!),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Loading shop data...')),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ActionCard(
                                      icon: Icons.inventory_2_outlined,
                                      label: languageProvider.getText('Inventory', 'சரக்கு'),
                                      color: const Color(0xFF455A64),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => InventoryScreen(token: widget.token)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),
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

  void _showLogoutDialog(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(languageProvider.logout),
        content: Text(languageProvider.getText(
          'Are you sure you want to logout?',
          'நீங்கள் வெளியேற விரும்புகிறீர்களா?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.getText('Cancel', 'ரத்து செய்')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text(languageProvider.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Section Title Widget
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF424242)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
      ],
    );
  }
}

// Metric Card Widget
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? color.withOpacity(0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight ? color : Colors.grey.shade200,
              width: highlight ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Revenue Card Widget
class _RevenueCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _RevenueCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '₹',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Inventory Card Widget
class _InventoryCard extends StatelessWidget {
  final int totalProducts;
  final int lowStock;
  final int outOfStock;
  final LanguageProvider languageProvider;
  final VoidCallback onTap;

  const _InventoryCard({
    required this.totalProducts,
    required this.lowStock,
    required this.outOfStock,
    required this.languageProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlert = lowStock > 0 || outOfStock > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasAlert ? Colors.orange.shade300 : Colors.grey.shade200,
              width: hasAlert ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Main Stats Row
              Row(
                children: [
                  // Total Products
                  Expanded(
                    child: _InventoryStat(
                      label: languageProvider.getText('Total', 'மொத்தம்'),
                      value: '$totalProducts',
                      color: const Color(0xFF7B1FA2),
                      icon: Icons.inventory_2,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey.shade200,
                  ),
                  // Low Stock
                  Expanded(
                    child: _InventoryStat(
                      label: languageProvider.getText('Low Stock', 'குறைவான கையிருப்பு'),
                      value: '$lowStock',
                      color: lowStock > 0 ? Colors.orange : Colors.grey,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey.shade200,
                  ),
                  // Out of Stock
                  Expanded(
                    child: _InventoryStat(
                      label: languageProvider.getText('Out of Stock', 'கையிருப்பு இல்லை'),
                      value: '$outOfStock',
                      color: outOfStock > 0 ? Colors.red : Colors.grey,
                      icon: Icons.error_outline,
                    ),
                  ),
                ],
              ),

              // Alert Banner
              if (hasAlert) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          languageProvider.getText(
                            'Stock needs attention! Tap to manage.',
                            'கையிருப்பு கவனம் தேவை! நிர்வகிக்க தட்டவும்.',
                          ),
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.orange.shade700, size: 14),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Inventory Stat Widget
class _InventoryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _InventoryStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Action Card Widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
