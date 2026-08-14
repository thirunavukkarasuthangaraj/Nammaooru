import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/order_service.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/language_provider.dart';
import 'order_details_screen.dart';
import '../orders/order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  OrdersResponse _ordersResponse = OrdersResponse.empty();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String? _selectedStatus;

  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _orderTabs = [
    {'key': '', 'label': 'All'},
    {'key': 'PENDING', 'label': 'Pending'},
    {'key': 'PREPARING', 'label': 'Preparing'},
    {'key': 'OUT_FOR_DELIVERY', 'label': 'Delivering'},
    {'key': 'DELIVERED', 'label': 'Delivered'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _orderTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final selectedTab = _orderTabs[_tabController.index];
      _selectedStatus = selectedTab['key']!.isEmpty ? null : selectedTab['key'];
      _loadOrders(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        _ordersResponse.hasNext &&
        !_isLoadingMore) {
      _loadMoreOrders();
    }
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      if (refresh) {
        _ordersResponse = OrdersResponse.empty();
      }
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _orderService.getOrders(
        page: refresh ? 0 : _ordersResponse.currentPage,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _ordersResponse = result['data'] as OrdersResponse;
          } else {
            final newResponse = result['data'] as OrdersResponse;
            _ordersResponse = OrdersResponse(
              orders: [..._ordersResponse.orders, ...newResponse.orders],
              totalPages: newResponse.totalPages,
              currentPage: newResponse.currentPage,
              totalElements: newResponse.totalElements,
              hasNext: newResponse.hasNext,
              hasPrevious: _ordersResponse.hasPrevious || newResponse.hasPrevious,
            );
          }
          _error = result['success'] ? null : result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load orders';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _orderService.getOrders(
        page: _ordersResponse.currentPage + 1,
        status: _selectedStatus,
      );

      if (mounted) {
        final newResponse = result['data'] as OrdersResponse;
        setState(() {
          _ordersResponse = OrdersResponse(
            orders: [..._ordersResponse.orders, ...newResponse.orders],
            totalPages: newResponse.totalPages,
            currentPage: newResponse.currentPage,
            totalElements: newResponse.totalElements,
            hasNext: newResponse.hasNext,
            hasPrevious: newResponse.hasPrevious,
          );
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        _showSnackBar('Failed to load more orders', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(orderId: order.id),
      ),
    ).then((_) => _loadOrders(refresh: true));
  }

  void _trackOrder(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(
          orderNumber: order.orderNumber,
          order: order,
        ),
      ),
    );
  }

  String _getTabLabel(String key, bool isTamil) {
    if (isTamil) {
      switch (key) {
        case '':
          return 'அனைத்தும்';
        case 'PENDING':
          return 'நிலுவையில்';
        case 'PREPARING':
          return 'தயாரிக்கப்படுகிறது';
        case 'OUT_FOR_DELIVERY':
          return 'டெலிவரி';
        case 'DELIVERED':
          return 'டெலிவரி ஆனது';
        default:
          return key;
      }
    } else {
      switch (key) {
        case '':
          return 'All';
        case 'PENDING':
          return 'Pending';
        case 'PREPARING':
          return 'Preparing';
        case 'OUT_FOR_DELIVERY':
          return 'Delivering';
        case 'DELIVERED':
          return 'Delivered';
        default:
          return key;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Show login prompt for guest users
    if (!authProvider.isAuthenticated) {
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
          appBar: AppBar(
            title: Text(
              languageProvider.showTamil ? 'எனது ஆர்டர்கள்' : 'My Orders',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          body: _buildLoginPrompt(),
        ),
      );
    }

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
        appBar: AppBar(
          title: Text(
            languageProvider.showTamil ? 'எனது ஆர்டர்கள்' : 'My Orders',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: _orderTabs.map((tab) => Tab(text: _getTabLabel(tab['key']!, languageProvider.showTamil))).toList(),
          ),
        ),
        body: _isLoading && _ordersResponse.orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _ordersResponse.orders.isEmpty
                ? _buildErrorWidget()
                : _ordersResponse.orders.isEmpty
                    ? _buildEmptyOrdersWidget()
                    : _buildOrdersList(),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'Register to View Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please register or log in to view your order history and track your deliveries',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/register');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VillageTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Login / Sign Up',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 70,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load orders',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? 'Please try again',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadOrders(refresh: true),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // Simple no-data state. Orders is a bottom-nav root tab, so the old
  // "Start Shopping" button's Navigator.pop() had nothing to pop and froze
  // the app — no navigation from here.
  Widget _buildEmptyOrdersWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No data found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: () => _loadOrders(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _ordersResponse.orders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _ordersResponse.orders.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOrderCard(_ordersResponse.orders[index]),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.orderNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(order),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(order.orderDate),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.items.take(2).map((item) => item.productName).join(', ') +
                              (order.items.length > 2 ? '...' : ''),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.paymentMethod.replaceAll('_', ' '),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (order.canBeTracked)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton.icon(
                          onPressed: () => _trackOrder(order),
                          icon: const Icon(Icons.location_on, size: 18),
                          label: const Text('Track', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Cancel moved inside Order Details — a red Cancel on every
                  // card invited accidental taps. View opens details, where
                  // the existing Cancel Order flow lives.
                  if (order.canBeCancelled)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton.icon(
                          onPressed: () => _viewOrderDetails(order),
                          icon: const Icon(Icons.receipt_long, size: 18),
                          label: const Text('View', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade400, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!order.canBeTracked && !order.canBeCancelled)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton.icon(
                          onPressed: () => _reorderItems(order),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reorder', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade400, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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

  Widget _buildStatusChip(Order order) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (order.statusColor) {
      case 'orange':
        backgroundColor = Colors.orange;
        break;
      case 'blue':
        backgroundColor = Colors.blue;
        break;
      case 'purple':
        backgroundColor = Colors.purple;
        break;
      case 'green':
        backgroundColor = Colors.green;
        break;
      case 'red':
        backgroundColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        languageProvider.getOrderStatus(order.status),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Server sends UTC time, convert to IST (UTC+5:30)
    final istDate = date.add(const Duration(hours: 5, minutes: 30));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(istDate.year, istDate.month, istDate.day);
    final difference = today.difference(orderDay).inDays;

    if (difference == 0) {
      return 'Today, ${_formatTime(istDate)}';
    } else if (difference == 1) {
      return 'Yesterday, ${_formatTime(istDate)}';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${istDate.day}/${istDate.month}/${istDate.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _reorderItems(Order order) async {
    try {
      final result = await _orderService.reorderItems(order.id);

      if (result['success']) {
        _showSnackBar('Items added to cart', Colors.green);
      } else {
        _showSnackBar(result['message'] ?? 'Failed to add items to cart', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to add items to cart', Colors.red);
    }
  }
}
