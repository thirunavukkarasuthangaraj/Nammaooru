import 'package:flutter/material.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/order_service.dart';
import 'order_details_screen.dart';

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
    {'key': '', 'label': 'All Orders'},
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
        content: Text(message),
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
    ).then((_) => _loadOrders(refresh: true)); // Refresh when returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: _orderTabs.map((tab) => Tab(text: tab['label'])).toList(),
        ),
      ),
      body: _isLoading && _ordersResponse.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _ordersResponse.orders.isEmpty
              ? _buildErrorWidget()
              : _ordersResponse.orders.isEmpty
                  ? _buildEmptyOrdersWidget()
                  : _buildOrdersList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load orders',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Please try again',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadOrders(refresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 96,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Start Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: () => _loadOrders(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _ordersResponse.orders.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _ordersResponse.orders.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return _buildOrderCard(_ordersResponse.orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _viewOrderDetails(order),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(order),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(order.orderDate),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.items.take(2).map((item) => item.productName).join(', ') +
                              (order.items.length > 2 ? '...' : ''),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.paymentMethod.replaceAll('_', ' '),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.canBeTracked)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewOrderDetails(order),
                        icon: const Icon(Icons.track_changes, size: 16),
                        label: const Text('Track'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (order.canBeTracked && order.canBeCancelled)
                    const SizedBox(width: 8),
                  if (order.canBeCancelled)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelDialog(order),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (!order.canBeTracked && !order.canBeCancelled)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _reorderItems(order),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reorder'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        order.statusDisplayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  void _showCancelDialog(Order order) {
    String reason = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel order #${order.orderNumber}?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'Why are you cancelling this order?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(order.id, reason);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String orderId, String reason) async {
    try {
      final result = await _orderService.cancelOrder(orderId, reason);
      
      if (result['success']) {
        _showSnackBar('Order cancelled successfully', Colors.orange);
        _loadOrders(refresh: true);
      } else {
        _showSnackBar(result['message'] ?? 'Failed to cancel order', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to cancel order', Colors.red);
    }
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