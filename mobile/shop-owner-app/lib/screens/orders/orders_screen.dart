import 'package:flutter/material.dart';
import '../../services/api_service_simple.dart';

class OrdersScreen extends StatefulWidget {
  final String token;

  const OrdersScreen({super.key, required this.token});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  late TabController _tabController;
  String _selectedFilter = 'ALL';

  final List<String> _statusFilters = ['ALL', 'PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getOrders(
        shopId: '1',
        page: 0,
        size: 50,
      );
      if (response.isSuccess && response.data != null) {
        setState(() {
          _orders = response.data['content'] ?? response.data ?? [];
          _isLoading = false;
        });
      } else {
        _setMockData();
      }
    } catch (e) {
      print('Error fetching orders: $e');
      _setMockData();
    }
  }

  void _setMockData() {
    setState(() {
      _orders = [
        {
          'id': 1, 'orderNumber': 'ORD001', 'customerName': 'Rajesh Kumar', 'customerPhone': '+91 98765 43210',
          'totalAmount': 450.00, 'status': 'PENDING', 'paymentStatus': 'PAID',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          'items': [{'productName': 'Basmati Rice', 'quantity': 2, 'price': 180.00}, {'productName': 'Milk', 'quantity': 1, 'price': 32.00}],
          'address': 'Koramangala, Bangalore - 560034',
        },
        {
          'id': 2, 'orderNumber': 'ORD002', 'customerName': 'Priya Sharma', 'customerPhone': '+91 87654 32109',
          'totalAmount': 320.00, 'status': 'CONFIRMED', 'paymentStatus': 'PAID',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'items': [{'productName': 'Cookies', 'quantity': 3, 'price': 25.00}, {'productName': 'Salt', 'quantity': 1, 'price': 22.00}],
          'address': 'Indiranagar, Bangalore - 560038',
        },
        {
          'id': 3, 'orderNumber': 'ORD003', 'customerName': 'Amit Singh', 'customerPhone': '+91 76543 21098',
          'totalAmount': 675.00, 'status': 'PREPARING', 'paymentStatus': 'PAID',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'items': [{'productName': 'Rice Premium', 'quantity': 3, 'price': 180.00}, {'productName': 'Oil', 'quantity': 1, 'price': 135.00}],
          'address': 'Whitefield, Bangalore - 560066',
        },
        {
          'id': 4, 'orderNumber': 'ORD004', 'customerName': 'Sneha Reddy', 'customerPhone': '+91 65432 10987',
          'totalAmount': 180.00, 'status': 'DELIVERED', 'paymentStatus': 'PAID',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'items': [{'productName': 'Tea Powder', 'quantity': 1, 'price': 145.00}],
          'address': 'HSR Layout, Bangalore - 560102',
        },
      ];
      _isLoading = false;
    });
  }

  List<dynamic> get _filteredOrders {
    if (_selectedFilter == 'ALL') return _orders;
    return _orders.where((order) => order['status'] == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED': return Colors.blue;
      case 'PREPARING': return Colors.purple;
      case 'READY': return Colors.teal;
      case 'OUT_FOR_DELIVERY': return Colors.indigo;
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING': return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'PREPARING': return 'Preparing';
      case 'READY': return 'Ready';
      case 'OUT_FOR_DELIVERY': return 'Out for Delivery';
      case 'DELIVERED': return 'Delivered';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    if (difference.inHours > 0) return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    return 'Just now';
  }

  Future<void> _updateOrderStatus(dynamic order, String newStatus) async {
    try {
      final response = await ApiService.updateOrderStatus(
        order['id'].toString(),
        newStatus,
      );

      if (response.isSuccess) {
        setState(() {
          final index = _orders.indexWhere((o) => o['id'] == order['id']);
          if (index != -1) _orders[index]['status'] = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order ${order['orderNumber']} updated to ${_getStatusText(newStatus)}'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order: ${response.error ?? 'Unknown error'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error updating order status: $e');
      // Fallback to local update for demo
      setState(() {
        final index = _orders.indexWhere((o) => o['id'] == order['id']);
        if (index != -1) _orders[index]['status'] = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${order['orderNumber']} updated locally'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showOrderActions(dynamic order) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Order ${order['orderNumber']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (order['status'] == 'PENDING') ...[
              ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _updateOrderStatus(order, 'CONFIRMED'); },
                icon: const Icon(Icons.check), label: const Text('Accept Order'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _updateOrderStatus(order, 'CANCELLED'); },
                icon: const Icon(Icons.cancel), label: const Text('Cancel Order'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
            if (order['status'] == 'CONFIRMED') ...[
              ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _updateOrderStatus(order, 'PREPARING'); },
                icon: const Icon(Icons.kitchen), label: const Text('Start Preparing'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
            if (order['status'] == 'PREPARING') ...[
              ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _updateOrderStatus(order, 'READY'); },
                icon: const Icon(Icons.check_circle), label: const Text('Mark as Ready'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
            if (order['status'] == 'READY') ...[
              ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _updateOrderStatus(order, 'OUT_FOR_DELIVERY'); },
                icon: const Icon(Icons.local_shipping), label: const Text('Out for Delivery'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              ),
            ],
            const SizedBox(height: 10),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) => setState(() => _selectedFilter = _statusFilters[index]),
          tabs: _statusFilters.map((status) => Tab(text: status)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFilter == 'ALL' ? 'No orders found' : 'No ${_selectedFilter.toLowerCase()} orders',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showOrderActions(order),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(order['orderNumber'] ?? 'Unknown Order', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(order['customerName'] ?? 'Unknown Customer', style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(order['status']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: _getStatusColor(order['status'])),
                                      ),
                                      child: Text(_getStatusText(order['status']), style: TextStyle(color: _getStatusColor(order['status']), fontWeight: FontWeight.w500)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(_formatDateTime(order['createdAt'] ?? DateTime.now().toIso8601String()), style: TextStyle(color: Colors.grey[600])),
                                    const Spacer(),
                                    Text('₹${order['totalAmount'] ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                                if (order['items'] != null && (order['items'] as List).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  Text(
                                    'Items: ${(order['items'] as List).map((item) => '${item['productName']} (${item['quantity']})').join(', ')}',
                                    style: TextStyle(color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (order['address'] != null && order['address'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(order['address'], style: TextStyle(color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}