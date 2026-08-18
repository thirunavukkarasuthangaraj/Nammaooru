import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/order_model.dart';
import '../../../services/order_api_service.dart';
import '../../../core/services/shop_service.dart';

class OrderProcessingScreen extends StatefulWidget {
  const OrderProcessingScreen({super.key});

  @override
  State<OrderProcessingScreen> createState() => _OrderProcessingScreenState();
}

class _OrderProcessingScreenState extends State<OrderProcessingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  String _sortBy = 'newest';
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  final OrderApiService _orderApiService = OrderApiService();
  final ShopService _shopService = ShopService();
  // Resolved from /shops/my-shop for the logged-in owner — never hardcode:
  // a fixed ID shows another shop's (usually empty) order list.
  // _shopId is the business shop code (used by /shops/{shopId}/orders);
  // _shopNumericId is the DB id (used by PUT /shops/{id}).
  String? _shopId;
  String? _shopNumericId;
  // True when this shop delivers orders itself (no delivery partner search)
  bool _selfDeliveryEnabled = false;
  bool _isUpdatingSelfDelivery = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      // Resolve the logged-in owner's shop ID once, then reuse it
      if (_shopId == null || _shopId!.isEmpty) {
        final shop = await _shopService.getMyShop();
        _shopId = shop.shopId;
        _shopNumericId = shop.id.toString();
        _selfDeliveryEnabled = shop.selfDeliveryEnabled;
        if (_shopId == null || _shopId!.isEmpty) {
          throw Exception('No shop linked to this account');
        }
      }

      final response = await _orderApiService.getShopOrders(
        shopId: _shopId!,
        page: 0,
        size: 100, // Load more orders for shop owner view
        sortBy: 'createdAt',
        sortDir: 'desc',
      );
      
      if (response['success'] == true) {
        final ordersData = response['data']['content'] as List<dynamic>;
        
        setState(() {
          _orders = ordersData.map((orderJson) {
            return OrderModel.fromJson(orderJson);
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders: ${response['message']}');
      }
    } catch (e) {
      print('Error loading shop orders: $e');
      setState(() {
        _orders = []; // Show empty state on error
        _isLoading = false;
      });
      
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load orders: $e', isError: true);
      }
    }
  }


  List<OrderModel> get _filteredOrders {
    List<OrderModel> filtered = _orders;

    // Filter by tab
    switch (_tabController.index) {
      case 0: // All
        break;
      case 1: // Pending
        filtered = filtered.where((o) => o.status == OrderStatus.pending).toList();
        break;
      case 2: // Accepted
        filtered = filtered.where((o) => o.status == OrderStatus.accepted).toList();
        break;
      case 3: // Preparing
        filtered = filtered.where((o) => o.status == OrderStatus.preparing).toList();
        break;
      case 4: // Ready
        filtered = filtered.where((o) => o.status == OrderStatus.readyForPickup).toList();
        break;
    }

    // Sort
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.orderDate.compareTo(b.orderDate));
        break;
      case 'amount_high':
        filtered.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'amount_low':
        filtered.sort((a, b) => a.total.compareTo(b.total));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF9800); // Orange theme for shop owners

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Order Management',
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            onPressed: _showFilterSortDialog,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(primaryColor),
          _buildStatsRow(),
          _buildSelfDeliveryBanner(primaryColor),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color primaryColor) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: primaryColor,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        onTap: (index) => setState(() {}),
        tabs: [
          Tab(text: 'All (${_orders.length})'),
          Tab(text: 'Pending (${_orders.where((o) => o.status == OrderStatus.pending).length})'),
          Tab(text: 'Accepted (${_orders.where((o) => o.status == OrderStatus.accepted).length})'),
          Tab(text: 'Preparing (${_orders.where((o) => o.status == OrderStatus.preparing).length})'),
          Tab(text: 'Ready (${_orders.where((o) => o.status == OrderStatus.readyForPickup).length})'),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final todayOrders = _orders.where((o) => 
      o.orderDate.day == DateTime.now().day &&
      o.orderDate.month == DateTime.now().month &&
      o.orderDate.year == DateTime.now().year
    ).toList();

    final todayRevenue = todayOrders.fold<double>(0, (sum, order) => sum + order.total);
    final avgOrderValue = todayOrders.isNotEmpty ? todayRevenue / todayOrders.length : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Today\'s Orders',
              todayOrders.length.toString(),
              Icons.shopping_bag,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Revenue',
              Helpers.formatCurrency(todayRevenue),
              Icons.currency_rupee,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Avg Order',
              Helpers.formatCurrency(avgOrderValue),
              Icons.trending_up,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelfDeliveryBanner(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.delivery_dining, color: primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Self Delivery',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  _selfDeliveryEnabled
                      ? 'You deliver orders yourself — no delivery partner search'
                      : 'Off — orders search for a delivery partner',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _selfDeliveryEnabled,
            activeColor: primaryColor,
            onChanged: _isUpdatingSelfDelivery ? null : _toggleSelfDelivery,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSelfDelivery(bool value) async {
    if (_shopNumericId == null || _shopNumericId!.isEmpty) return;

    setState(() => _isUpdatingSelfDelivery = true);
    try {
      await _shopService.updateSelfDelivery(_shopNumericId!, value);
      setState(() {
        _selfDeliveryEnabled = value;
        _isUpdatingSelfDelivery = false;
      });
      Helpers.showSnackBar(
        context,
        value ? 'Self delivery turned on' : 'Self delivery turned off',
      );
    } catch (e) {
      setState(() => _isUpdatingSelfDelivery = false);
      print('Error updating self delivery: $e');
      Helpers.showSnackBar(context, 'Failed to update self delivery: $e', isError: true);
    }
  }

  Widget _buildOrdersList() {
    final filteredOrders = _filteredOrders;

    if (filteredOrders.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          title: 'No orders found',
          message: 'Orders will appear here when customers place them',
          icon: Icons.receipt_long,
          action: null,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    const primaryColor = Color(0xFFFF9800);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(order.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        Helpers.formatDateTime(order.orderDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      order.customerPhone,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      Helpers.formatCurrency(order.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (order.specialInstructions != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.specialInstructions!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _buildOrderActions(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActions(OrderModel order) {
    switch (order.status) {
      case OrderStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _rejectOrder(order),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _acceptOrder(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept'),
              ),
            ),
          ],
        );

      case OrderStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _startPreparing(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Preparing'),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _callCustomer(order),
              icon: const Icon(Icons.phone),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );

      case OrderStatus.preparing:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _markReady(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mark Ready'),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _callCustomer(order),
              icon: const Icon(Icons.phone),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );

      case OrderStatus.readyForPickup:
        // Self-delivery shop: owner leaves with the order themselves, no driver search
        if (_selfDeliveryEnabled) {
          return Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startSelfDelivery(order),
                  icon: const Icon(Icons.delivery_dining, size: 18),
                  label: const Text('Start Delivery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _callCustomer(order),
                icon: const Icon(Icons.phone),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Text(
                'Waiting for delivery partner pickup',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _callCustomer(order),
              icon: const Icon(Icons.phone),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );

      case OrderStatus.outForDelivery:
        // Self-delivery shop: owner marks delivered after handing over to the customer
        if (_selfDeliveryEnabled) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _completeSelfDelivery(order),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Mark Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          );
        }
        return Text(
          'Out for delivery',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        );

      case OrderStatus.delivered:
        return Text(
          'Delivered',
          style: TextStyle(
            color: Colors.green[600],
            fontWeight: FontWeight.bold,
          ),
        );

      case OrderStatus.cancelled:
        return Text(
          'Cancelled',
          style: TextStyle(
            color: Colors.red[600],
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.readyForPickup:
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.accepted:
        return 'ACCEPTED';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.readyForPickup:
        return 'READY';
      case OrderStatus.outForDelivery:
        return 'OUT FOR DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  void _showFilterSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Newest First'),
                leading: Radio<String>(
                  value: 'newest',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Oldest First'),
                leading: Radio<String>(
                  value: 'oldest',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Amount: High to Low'),
                leading: Radio<String>(
                  value: 'amount_high',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Amount: Low to High'),
                leading: Radio<String>(
                  value: 'amount_low',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _acceptOrder(OrderModel order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Order'),
        content: Text('Accept order #${order.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final orderId = int.parse(order.id);
        await _orderApiService.acceptOrder(orderId);
        
        setState(() {
          final index = _orders.indexWhere((o) => o.id == order.id);
          if (index != -1) {
            _orders[index] = order.copyWith(status: OrderStatus.accepted);
          }
        });
        
        Helpers.showSnackBar(context, 'Order accepted successfully');
      } catch (e) {
        print('Error accepting order: $e');
        Helpers.showSnackBar(context, 'Failed to accept order: $e', isError: true);
      }
    }
  }

  Future<void> _rejectOrder(OrderModel order) async {
    // Show rejection reason dialog
    String? reason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reject order #${order.id}?'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                reason = controller.text;
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final orderId = int.parse(order.id);
        await _orderApiService.rejectOrder(orderId, reason: reason);
        
        setState(() {
          final index = _orders.indexWhere((o) => o.id == order.id);
          if (index != -1) {
            _orders[index] = order.copyWith(status: OrderStatus.cancelled);
          }
        });
        
        Helpers.showSnackBar(context, 'Order rejected');
      } catch (e) {
        print('Error rejecting order: $e');
        Helpers.showSnackBar(context, 'Failed to reject order: $e', isError: true);
      }
    }
  }

  Future<void> _startPreparing(OrderModel order) async {
    try {
      final orderId = int.parse(order.id);
      await _orderApiService.startPreparingOrder(orderId);
      
      setState(() {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = order.copyWith(status: OrderStatus.preparing);
        }
      });
      
      Helpers.showSnackBar(context, 'Order preparation started');
    } catch (e) {
      print('Error starting preparation: $e');
      Helpers.showSnackBar(context, 'Failed to start preparation: $e', isError: true);
    }
  }

  Future<void> _markReady(OrderModel order) async {
    try {
      final orderId = int.parse(order.id);
      await _orderApiService.markOrderReady(orderId);
      
      setState(() {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = order.copyWith(status: OrderStatus.readyForPickup);
        }
      });
      
      Helpers.showSnackBar(context, 'Order marked as ready for pickup');
    } catch (e) {
      print('Error marking order ready: $e');
      Helpers.showSnackBar(context, 'Failed to mark order ready: $e', isError: true);
    }
  }

  // Self-delivery: shop owner leaves the shop with the order
  Future<void> _startSelfDelivery(OrderModel order) async {
    try {
      final orderId = int.parse(order.id);
      await _orderApiService.startSelfDelivery(orderId);

      setState(() {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = order.copyWith(status: OrderStatus.outForDelivery);
        }
      });

      Helpers.showSnackBar(context, 'Order is out for delivery');
    } catch (e) {
      print('Error starting self delivery: $e');
      Helpers.showSnackBar(context, 'Failed to start delivery: $e', isError: true);
    }
  }

  // Self-delivery: shop owner handed the order to the customer
  Future<void> _completeSelfDelivery(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Delivered'),
        content: Text('Confirm that order #${order.id} has been handed over to the customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Delivered'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final orderId = int.parse(order.id);
      await _orderApiService.completeSelfDelivery(orderId);

      setState(() {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = order.copyWith(status: OrderStatus.delivered);
        }
      });

      Helpers.showSnackBar(context, 'Order delivered successfully');
    } catch (e) {
      print('Error completing self delivery: $e');
      Helpers.showSnackBar(context, 'Failed to mark as delivered: $e', isError: true);
    }
  }

  void _callCustomer(OrderModel order) {
    // TODO: Implement phone call functionality
    Helpers.showSnackBar(context, 'Calling ${order.customerName}...');
  }
}