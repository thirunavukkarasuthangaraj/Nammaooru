import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../services/api_service_simple.dart';
import '../../services/sound_service.dart';
import '../../utils/js_helper.dart' if (dart.library.html) '../../utils/js_helper_web.dart' as js_helper;
import '../../utils/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import '../../providers/language_provider.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBackToDashboard;

  const OrdersScreen({super.key, required this.token, this.onBackToDashboard});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _orders = [];
  List<dynamic> _allOrders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;
  late TabController _tabController;
  late ScrollController _scrollController;
  String _selectedFilter = 'ALL';
  DateTime? _startDate;
  DateTime? _endDate;
  Timer? _pollingTimer;
  int _previousPendingCount = 0;
  Set<String> _updatingOrders = {}; // Track orders being updated

  final List<String> _statusFilters = ['ALL', 'SELF_PICKUP', 'PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _scrollController = ScrollController()..addListener(_onScroll);
    _fetchOrders();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _startPolling() {
    // Poll for new orders every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchOrders(silent: true);
    });
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMore = true;
      });
    }

    try {
      // Don't pass SELF_PICKUP as status filter (it's a delivery type filter)
      final statusFilter = (_selectedFilter != 'ALL' && _selectedFilter != 'SELF_PICKUP')
          ? _selectedFilter
          : null;

      final response = await ApiService.getShopOrders(
        page: 0,
        size: _pageSize,
        status: statusFilter,
      );

      print('Shop Orders API response: ${response.isSuccess}');

      if (response.isSuccess && response.data != null) {
        final data = response.data;

        // Handle nested data structure: {statusCode, message, data: {orders: [...]}}
        final ordersData = data['data'] ?? data;
        final ordersList = ordersData['orders'] ?? ordersData['content'] ?? [];

        print('Orders count: ${ordersList.length}');

        // Map API response to UI format
        final mappedOrders = ordersList.map((order) {
          return {
            'id': order['id'],
            'orderNumber': order['orderNumber'],
            'customerName': order['customerName'] ?? 'Unknown Customer',
            'customerPhone': order['customerPhone'] ?? order['deliveryPhone'] ?? '',
            'totalAmount': (order['totalAmount'] ?? 0).toDouble(),
            'status': order['status'] ?? 'PENDING',
            'paymentStatus': order['paymentStatus'] ?? 'PENDING',
            'createdAt': order['createdAt'] ?? DateTime.now().toIso8601String(),
            'items': order['orderItems'] ?? order['items'] ?? [],
            'address': order['fullDeliveryAddress'] ?? order['deliveryAddress'] ?? '',
            'deliveryType': order['deliveryType'] ?? 'HOME_DELIVERY', // ADD THIS
            'assignedToDeliveryPartner': order['assignedToDeliveryPartner'] ?? false, // ADD THIS
            'paymentMethod': order['paymentMethod'] ?? 'CASH_ON_DELIVERY', // ADD THIS
          };
        }).toList();

        // Check for new pending orders and show notification
        final newPendingCount = mappedOrders.where((order) => order['status'] == 'PENDING').length;
        if (silent && newPendingCount > _previousPendingCount) {
          print('🔔 New order detected!');

          // Play browser notification sound for web
          if (kIsWeb) {
            js_helper.showBrowserNotification(
              'New Order!',
              'You have received a new order. Tap to view.'
            );
          }

          // Show visual notification
          if (mounted) {
            // Remove any existing snackbar first
            ScaffoldMessenger.of(context).clearSnackBars();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔔 NEW ORDER RECEIVED!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap VIEW to see pending orders',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange.shade800,
                duration: Duration(seconds: 30),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                action: SnackBarAction(
                  label: 'VIEW NOW',
                  textColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  onPressed: () {
                    // Clear the snackbar
                    ScaffoldMessenger.of(context).clearSnackBars();

                    // Set filter to PENDING and scroll to top
                    setState(() {
                      _selectedFilter = 'PENDING';
                      _tabController.index = _statusFilters.indexOf('PENDING');
                    });
                    _applyFilters();
                  },
                ),
              ),
            );
          }
        }
        _previousPendingCount = newPendingCount;

        setState(() {
          _allOrders = mappedOrders;
          _orders = mappedOrders;
          _hasMore = mappedOrders.length >= _pageSize;
          _currentPage = 0;
          _applyFilters();
          _isLoading = false;
        });
      } else {
        print('API error: ${response.error}');
        if (!silent) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching orders: $e');
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      // Don't pass SELF_PICKUP as status filter (it's a delivery type filter)
      final statusFilter = (_selectedFilter != 'ALL' && _selectedFilter != 'SELF_PICKUP')
          ? _selectedFilter
          : null;

      final response = await ApiService.getShopOrders(
        page: nextPage,
        size: _pageSize,
        status: statusFilter,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final ordersData = data['data'] ?? data;
        final ordersList = ordersData['orders'] ?? ordersData['content'] ?? [];

        final mappedOrders = ordersList.map((order) {
          return {
            'id': order['id'],
            'orderNumber': order['orderNumber'],
            'customerName': order['customerName'] ?? 'Unknown Customer',
            'customerPhone': order['customerPhone'] ?? order['deliveryPhone'] ?? '',
            'totalAmount': (order['totalAmount'] ?? 0).toDouble(),
            'status': order['status'] ?? 'PENDING',
            'paymentStatus': order['paymentStatus'] ?? 'PENDING',
            'createdAt': order['createdAt'] ?? DateTime.now().toIso8601String(),
            'items': order['orderItems'] ?? order['items'] ?? [],
            'address': order['fullDeliveryAddress'] ?? order['deliveryAddress'] ?? '',
            'deliveryType': order['deliveryType'] ?? 'HOME_DELIVERY', // ADD THIS
            'assignedToDeliveryPartner': order['assignedToDeliveryPartner'] ?? false, // ADD THIS
            'paymentMethod': order['paymentMethod'] ?? 'CASH_ON_DELIVERY', // ADD THIS
          };
        }).toList();

        setState(() {
          _allOrders.addAll(mappedOrders);
          _hasMore = mappedOrders.length >= _pageSize;
          _currentPage = nextPage;
          _applyFilters();
          _isLoadingMore = false;
        });

        print('Loaded page $nextPage with ${mappedOrders.length} orders');
      } else {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more orders: $e');
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _orders = _allOrders.where((order) {
        // Only apply date range filter here
        // Status filter is handled by API call
        return _matchesDateRange(order);
      }).toList();
    });
  }

  bool _matchesDateRange(dynamic order) {
    if (_startDate == null && _endDate == null) {
      return true; // No date filter applied
    }

    try {
      final orderDate = DateTime.parse(order['createdAt']);
      final orderDateOnly = DateTime(orderDate.year, orderDate.month, orderDate.day);

      if (_startDate != null) {
        final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (orderDateOnly.isBefore(startDateOnly)) {
          return false;
        }
      }

      if (_endDate != null) {
        final endDateOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        if (orderDateOnly.isAfter(endDateOnly)) {
          return false;
        }
      }

      return true;
    } catch (error) {
      print('Error in date filtering: $error');
      return true; // Return true if there's an error to show the order
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  List<dynamic> get _filteredOrders {
    // Special filter for SELF_PICKUP - show ONLY self-pickup orders
    if (_selectedFilter == 'SELF_PICKUP') {
      return _orders.where((order) =>
        order['deliveryType']?.toString().toUpperCase() == 'SELF_PICKUP'
      ).toList();
    }

    // For ALL other status tabs - EXCLUDE self-pickup orders
    // Only show HOME_DELIVERY orders in status tabs
    return _orders.where((order) =>
      order['deliveryType']?.toString().toUpperCase() != 'SELF_PICKUP'
    ).toList();
  }

  Color _getStatusColor(String status) {
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

  String _getStatusText(String status) {
    switch (status) {
      case 'ALL': return 'All';
      case 'SELF_PICKUP': return 'Self Pickup';
      case 'PENDING': return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'PREPARING': return 'Preparing';
      case 'READY_FOR_PICKUP': return 'Ready for Pickup';
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
    final orderId = order['id'].toString();

    // Add loading state
    setState(() {
      _updatingOrders.add(orderId);
    });

    // Stop notification sound when accepting/confirming order
    if (kIsWeb && (newStatus == 'CONFIRMED' || newStatus == 'PREPARING')) {
      js_helper.stopNotificationSound();
    }

    try {
      final response = await ApiService.updateOrderStatus(
        orderId,
        newStatus,
      );

      if (response.isSuccess) {
        setState(() {
          // Update in both _orders and _allOrders to persist across polling refreshes
          final index = _orders.indexWhere((o) => o['id'] == order['id']);
          if (index != -1) _orders[index]['status'] = newStatus;

          final allIndex = _allOrders.indexWhere((o) => o['id'] == order['id']);
          if (allIndex != -1) _allOrders[allIndex]['status'] = newStatus;

          // Remove loading state
          _updatingOrders.remove(orderId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order ${order['orderNumber']} updated to ${_getStatusText(newStatus)}'), backgroundColor: Colors.green),
        );
      } else {
        setState(() {
          // Remove loading state
          _updatingOrders.remove(orderId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order: ${response.error ?? 'Unknown error'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error updating order status: $e');
      // Fallback to local update for demo
      setState(() {
        // Update in both _orders and _allOrders to persist across polling refreshes
        final index = _orders.indexWhere((o) => o['id'] == order['id']);
        if (index != -1) _orders[index]['status'] = newStatus;

        final allIndex = _allOrders.indexWhere((o) => o['id'] == order['id']);
        if (allIndex != -1) _allOrders[allIndex]['status'] = newStatus;

        // Remove loading state
        _updatingOrders.remove(orderId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${order['orderNumber']} updated locally'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showOTPVerificationDialog(dynamic order) {
    final TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Pickup OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the OTP shown by the delivery partner for order ${order['orderNumber']}'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Enter 4-digit OTP',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.isEmpty || otp.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 4-digit OTP'), backgroundColor: Colors.red),
                );
                return;
              }

              try {
                final response = await ApiService.verifyPickupOTP(
                  order['id'].toString(),
                  otp,
                );

                Navigator.pop(context); // Close dialog

                if (response.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('OTP verified! Order handed over to delivery partner.'), backgroundColor: Colors.green),
                  );
                  _fetchOrders(); // Refresh orders
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid OTP: ${response.error ?? 'Please try again'}'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _handoverSelfPickupOrder(dynamic order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Handover'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you ready to handover this order to the customer?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order['orderNumber']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Customer: ${order['customerName']}'),
                  const SizedBox(height: 8),

                  // Promo Code Info (if applied)
                  if (order['couponCode'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, style: BorderStyle.solid, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_offer, color: Colors.blue, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Platform Promo: ${order['couponCode']}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Order Amount:', style: TextStyle(fontSize: 13)),
                              Text(
                                '₹${((order['totalAmount'] ?? 0) + (order['discountAmount'] ?? 0)).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 14, color: Colors.orange),
                                    SizedBox(width: 4),
                                    Text(
                                      'Platform Discount:',
                                      style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Text(
                                  '- ₹${(order['discountAmount'] ?? 0).toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 8, thickness: 2, color: Colors.blue),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '💰 Collect from Customer:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                    ),
                                    Text(
                                      '₹${(order['totalAmount'] ?? 0).toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '✓ You receive full ₹${((order['totalAmount'] ?? 0) + (order['discountAmount'] ?? 0)).toStringAsFixed(0)} (Platform covers ₹${(order['discountAmount'] ?? 0).toStringAsFixed(0)})',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    Text('Total: ₹${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}'),
                    const SizedBox(height: 4),
                  ],

                  if (order['paymentMethod'] == 'CASH_ON_DELIVERY' && order['couponCode'] == null) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '💰 Collect payment from customer',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Handover'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Call API to mark order as handed over
        final response = await ApiService.handoverSelfPickup(order['id'].toString());

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (response.isSuccess && mounted) {
          // Refresh orders
          _fetchOrders();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Order handed over successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to handover order: ${response.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showOrderActions(dynamic order) {
    // Debug: Print order details
    print('📋 Order Details:');
    print('   Status: ${order['status']}');
    print('   DeliveryType: ${order['deliveryType']}');
    print('   AssignedToDeliveryPartner: ${order['assignedToDeliveryPartner']}');
    print('   PaymentMethod: ${order['paymentMethod']}');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
        ),
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: AppTheme.roundedRound,
              ),
            ),
            Text('Order ${order['orderNumber']}', style: AppTheme.h4, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.space20),
            if (order['status'] == 'PENDING') ...[
              ModernButton(
                text: 'Accept Order',
                icon: Icons.check,
                variant: ButtonVariant.success,
                size: ButtonSize.large,
                fullWidth: true,
                useGradient: true,
                onPressed: () { Navigator.pop(context); _updateOrderStatus(order, 'CONFIRMED'); },
              ),
              const SizedBox(height: AppTheme.space12),
              ModernButton(
                text: 'Cancel Order',
                icon: Icons.cancel,
                variant: ButtonVariant.error,
                size: ButtonSize.large,
                fullWidth: true,
                onPressed: () { Navigator.pop(context); _updateOrderStatus(order, 'CANCELLED'); },
              ),
            ],
            if (order['status'] == 'CONFIRMED') ...[
              ModernButton(
                text: 'Start Preparing',
                icon: Icons.restaurant,
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                fullWidth: true,
                useGradient: true,
                onPressed: () { Navigator.pop(context); _updateOrderStatus(order, 'PREPARING'); },
              ),
            ],
            if (order['status'] == 'PREPARING') ...[
              ModernButton(
                text: 'Mark Ready for Pickup',
                icon: Icons.inventory_2,
                variant: ButtonVariant.success,
                size: ButtonSize.large,
                fullWidth: true,
                useGradient: true,
                onPressed: () { Navigator.pop(context); _updateOrderStatus(order, 'READY_FOR_PICKUP'); },
              ),
            ],
            if (order['status'] == 'READY_FOR_PICKUP') ...[
              if (order['deliveryType'] == 'SELF_PICKUP') ...[
                // Self-pickup order - show handover button
                ModernButton(
                  text: 'Handover to Customer',
                  icon: Icons.how_to_reg,
                  variant: ButtonVariant.success,
                  size: ButtonSize.large,
                  fullWidth: true,
                  useGradient: true,
                  onPressed: () {
                    Navigator.pop(context);
                    _handoverSelfPickupOrder(order);
                  },
                ),
              ] else ...[
                // Home delivery order - show delivery partner buttons
                if (order['assignedToDeliveryPartner'] == true) ...[
                  ModernButton(
                    text: 'Verify Pickup OTP',
                    icon: Icons.lock_open,
                    variant: ButtonVariant.warning,
                    size: ButtonSize.large,
                    fullWidth: true,
                    onPressed: () {
                      Navigator.pop(context);
                      _showOTPVerificationDialog(order);
                    },
                  ),
                ] else ...[
                  // Waiting for delivery partner assignment
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.hourglass_empty, color: Colors.orange, size: 32),
                        SizedBox(height: AppTheme.space8),
                        Text(
                          'Waiting for Delivery Partner',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        SizedBox(height: AppTheme.space4),
                        Text(
                          'The system is assigning a delivery partner to this order',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
            const SizedBox(height: AppTheme.space12),
            ModernButton(
              text: 'Close',
              variant: ButtonVariant.outline,
              size: ButtonSize.large,
              fullWidth: true,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppTheme.space8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveLayout.getResponsivePadding(context);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBackToDashboard,
            ),
            title: Text(
              languageProvider.orders,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _startDate != null || _endDate != null ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: Colors.white,
                ),
                onPressed: _selectDateRange,
              ),
              if (_startDate != null || _endDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: _clearDateFilter,
                ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onTap: (index) {
                setState(() => _selectedFilter = _statusFilters[index]);
                _fetchOrders(); // Fetch from API with new filter
              },
              tabs: _statusFilters.map((status) {
                return Tab(text: languageProvider.getOrderStatus(status));
              }).toList(),
            ),
          ),
          body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green.shade700))
          : _filteredOrders.isEmpty
              ? Center(
                  child: Padding(
                    padding: padding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 80, color: AppTheme.textHint),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          _selectedFilter == 'ALL'
                              ? languageProvider.getText('No orders found', 'ஆர்டர்கள் இல்லை')
                              : languageProvider.getText('No ${_selectedFilter.toLowerCase()} orders', '${languageProvider.getOrderStatus(_selectedFilter)} ஆர்டர்கள் இல்லை'),
                          style: AppTheme.h4.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          languageProvider.getText('Orders will appear here once placed', 'ஆர்டர்கள் இடப்பட்டவுடன் இங்கே தோன்றும்'),
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textHint),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: padding,
                    itemCount: _filteredOrders.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredOrders.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppTheme.space16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final order = _filteredOrders[index];
                      final orderStatus = (order['status'] ?? 'PENDING').toString();
                      final deliveryType = order['deliveryType']?.toString();
                      final orderId = order['id']?.toString() ?? '';
                      final isUpdating = _updatingOrders.contains(orderId);

                      return OrderCard(
                        orderNumber: order['orderNumber'] ?? 'Unknown Order',
                        customerName: order['customerName'] ?? 'Unknown Customer',
                        status: orderStatus,
                        totalAmount: (order['totalAmount'] ?? 0).toDouble(),
                        orderDate: order['createdAt'] != null
                            ? DateTime.parse(order['createdAt'])
                            : DateTime.now(),
                        itemCount: (order['items'] as List?)?.length ?? 0,
                        items: order['items'] as List?, // Pass items to show product details
                        deliveryType: deliveryType, // Pass delivery type
                        isLoading: isUpdating, // Pass loading state
                        onTap: () {
                          // Navigate to order details screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(
                                orderId: order['id']?.toString() ?? order['orderNumber'] ?? '',
                                orderData: order,
                              ),
                            ),
                          );
                        },
                        // PENDING status: Show Accept/Reject buttons
                        onAccept: orderStatus == 'PENDING' ? () => _updateOrderStatus(order, 'CONFIRMED') : null,
                        onReject: orderStatus == 'PENDING' ? () => _updateOrderStatus(order, 'CANCELLED') : null,

                        // CONFIRMED status: Show Start Preparing button
                        onStartPreparing: orderStatus == 'CONFIRMED' ? () => _updateOrderStatus(order, 'PREPARING') : null,

                        // PREPARING status: Only show Ready button (no skipping to OUT_FOR_DELIVERY)
                        onMarkReady: orderStatus == 'PREPARING' ? () => _updateOrderStatus(order, 'READY_FOR_PICKUP') : null,
                        onOutForDelivery: null, // Shop owners cannot skip to OUT_FOR_DELIVERY

                        // READY_FOR_PICKUP status: Show specific buttons based on delivery type
                        onHandoverSelfPickup: (orderStatus == 'READY_FOR_PICKUP' && deliveryType == 'SELF_PICKUP')
                            ? () => _handoverSelfPickupOrder(order)
                            : null,
                        onVerifyPickupOTP: (orderStatus == 'READY_FOR_PICKUP' && deliveryType == 'HOME_DELIVERY')
                            ? () => _showOTPVerificationDialog(order)
                            : null,

                        // OUT_FOR_DELIVERY status: No buttons (only driver can deliver)
                        // Shop owners cannot mark HOME_DELIVERY orders as delivered
                        onMarkDelivered: null,
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}