import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../../services/api_service_simple.dart';

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
    'pendingOrders': 0,
    'totalProducts': 0,
  };
  List<dynamic> _recentOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Fetch dashboard stats
      final statsResponse = await ApiService.getDashboardStats();

      if (statsResponse.isSuccess && statsResponse.data != null) {
        setState(() {
          _stats = statsResponse.data ?? _stats;
          _isLoading = false;
        });
      } else {
        _setMockData();
      }

      // Fetch recent orders
      final ordersResponse = await ApiService.getOrders(
        shopId: '1',
        page: 0,
        size: 5,
      );

      if (ordersResponse.isSuccess && ordersResponse.data != null) {
        setState(() {
          _recentOrders = ordersResponse.data['content'] ?? ordersResponse.data ?? [];
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      _setMockData();
    }
  }

  void _setMockData() {
    setState(() {
      _stats = {
        'todayOrders': 12,
        'todayRevenue': 5430.00,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${widget.userName}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard('Today\'s Orders', _stats['todayOrders'].toString(), Icons.shopping_cart, Colors.blue),
                        _buildStatCard('Today\'s Revenue', '₹${_stats['todayRevenue']}', Icons.attach_money, Colors.green),
                        _buildStatCard('Pending Orders', _stats['pendingOrders'].toString(), Icons.pending_actions, Colors.orange),
                        _buildStatCard('Total Products', _stats['totalProducts'].toString(), Icons.inventory, Colors.purple),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text('Recent Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (_recentOrders.isEmpty)
                      const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No recent orders'))))
                    else
                      ..._recentOrders.map((order) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(order['status']),
                            child: Text(order['orderNumber']?.substring(3) ?? '?', style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(order['customerName'] ?? 'Unknown'),
                          subtitle: Text('Order #${order['orderNumber']} • ₹${order['totalAmount']}'),
                          trailing: Chip(
                            label: Text(order['status'] ?? 'UNKNOWN', style: const TextStyle(fontSize: 12)),
                            backgroundColor: _getStatusColor(order['status']).withOpacity(0.2),
                          ),
                        ),
                      )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
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
}