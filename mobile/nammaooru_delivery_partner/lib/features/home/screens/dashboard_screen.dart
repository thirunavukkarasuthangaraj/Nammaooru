import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/order_provider.dart';
import '../widgets/status_toggle_widget.dart';
import '../widgets/stats_summary_widget.dart';
import '../widgets/order_card_widget.dart';
import '../../../core/models/order_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.loadAvailableOrders();
    await orderProvider.loadActiveOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Section
          _buildHeader(),
          
          // Content Section
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Summary
                    const StatsSummaryWidget(),
                    
                    const SizedBox(height: 20),
                    
                    // Order Sections
                    _buildOrderSections(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final partner = authProvider.partner;
        if (partner == null) return const SizedBox.shrink();
        
        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
              child: Column(
                children: [
                  // Top Row - Status Toggle & Actions
                  Row(
                    children: [
                      Expanded(
                        child: StatusToggleWidget(
                          isOnline: partner.isOnline,
                          onToggle: (isOnline) {
                            authProvider.updatePartnerStatus(isOnline);
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      
                      // Action Buttons
                      Row(
                        children: [
                          _buildHeaderButton(
                            icon: Icons.history,
                            onTap: () => Navigator.pushNamed(context, '/history'),
                          ),
                          const SizedBox(width: 10),
                          _buildHeaderButton(
                            icon: Icons.notifications,
                            onTap: _showNotifications,
                            badge: 3,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Partner Info
                  Row(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          partner.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 15),
                      
                      // Partner Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '👋 Hello, ${partner.name.split(' ').first}!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '📍 Ready for deliveries in Bangalore',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            if (badge != null && badge > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badge.toString(),
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
      ),
    );
  }

  Widget _buildOrderSections() {
    return Consumer2<OrderProvider, AuthProvider>(
      builder: (context, orderProvider, authProvider, child) {
        final partner = authProvider.partner;
        if (partner == null) return const SizedBox.shrink();
        
        return Column(
          children: [
            // New Orders Section
            _buildOrderSection(
              title: '🔔 NEW ORDERS',
              count: partner.isOnline ? orderProvider.availableOrders.length : 0,
              orders: partner.isOnline ? orderProvider.availableOrders : [],
              isNewOrderSection: true,
              emptyMessage: partner.isOnline 
                  ? 'No new orders available right now' 
                  : 'Go online to receive new orders',
              emptyIcon: partner.isOnline ? Icons.inbox : Icons.wifi_off,
            ),
            
            const SizedBox(height: 20),
            
            // Active Orders Section
            _buildOrderSection(
              title: '🚚 ACTIVE DELIVERIES',
              count: orderProvider.activeOrders.length,
              orders: orderProvider.activeOrders,
              isNewOrderSection: false,
              emptyMessage: 'No active deliveries',
              emptyIcon: Icons.local_shipping,
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderSection({
    required String title,
    required int count,
    required List<Order> orders,
    required bool isNewOrderSection,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              children: [
                Text(
                  '$title ($count)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isNewOrderSection ? AppColors.warning : AppColors.info,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Orders List or Empty State
          if (orders.isEmpty)
            _buildEmptyState(emptyMessage, emptyIcon)
          else
            Column(
              children: orders.map((order) => OrderCardWidget(
                order: order,
                isNewOrder: isNewOrderSection,
                onAccept: isNewOrderSection ? () => _acceptOrder(order) : null,
                onReject: isNewOrderSection ? () => _rejectOrder(order) : null,
                onMarkPickedUp: !isNewOrderSection && order.status == OrderStatus.accepted
                    ? () => _markPickedUp(order) : null,
                onMarkDelivered: !isNewOrderSection && order.status == OrderStatus.pickedUp
                    ? () => _markDelivered(order) : null,
                onCall: () => _callCustomer(order),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 15),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedTabIndex,
      onTap: (index) {
        setState(() => _selectedTabIndex = index);
        
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            Navigator.pushNamed(context, '/earnings');
            break;
          case 2:
            Navigator.pushNamed(context, '/stats');
            break;
          case 3:
            Navigator.pushNamed(context, '/profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Earnings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Stats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  // Order Action Methods
  Future<void> _acceptOrder(Order order) async {
    // Show time selection dialog
    final selectedTime = await _showTimeSelectionDialog();
    if (selectedTime != null) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.acceptOrder(order.orderNumber, selectedTime);

      _showSuccessMessage('✅ Order ${order.orderNumber} accepted! Prep time: $selectedTime');
    }
  }

  Future<void> _rejectOrder(Order order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.rejectOrder(order.orderNumber);

    _showMessage('❌ Order ${order.orderNumber} rejected!', AppColors.error);
  }

  Future<void> _markPickedUp(Order order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.markOrderPickedUp(order.orderNumber);

    _showSuccessMessage('📦 Order ${order.orderNumber} picked up! Navigate to delivery location.');
  }

  Future<void> _markDelivered(Order order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.markOrderDelivered(order.orderNumber);

    _showSuccessMessage('✅ Order ${order.orderNumber} delivered successfully! Payment received.');
  }

  void _callCustomer(Order order) {
    // In real app, would use url_launcher to make a call
    _showMessage('📞 Calling ${order.customer.name}...', AppColors.info);
  }

  Future<String?> _showTimeSelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accept Order'),
          content: const Text('How long will it take to prepare?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ...['15 mins', '30 mins', '45 mins'].map(
              (time) => TextButton(
                onPressed: () => Navigator.of(context).pop(time),
                child: Text(time),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• New order available in HSR Layout'),
            Text('• Your weekly earnings report is ready'),
            Text('• Update your vehicle insurance (expires soon)'),
            Text('• Rate your last customer'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    _showMessage(message, AppColors.success);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}