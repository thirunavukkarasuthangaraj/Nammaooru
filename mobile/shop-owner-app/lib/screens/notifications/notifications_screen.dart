import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service_simple.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_card.dart';

class ShopNotification {
  final int id;
  final String title;
  final String message;
  final String type; // order, customer, inventory, system, info, success, warning, error
  final String priority; // low, medium, high, urgent
  final String status; // unread, read, archived, processing
  final DateTime createdAt;
  final DateTime? readAt;
  final bool actionRequired;
  final String? actionUrl;
  final Map<String, dynamic>? relatedEntity;
  final Map<String, dynamic>? orderData;

  ShopNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.readAt,
    required this.actionRequired,
    this.actionUrl,
    this.relatedEntity,
    this.orderData,
  });

  ShopNotification copyWith({
    String? status,
    DateTime? readAt,
  }) {
    return ShopNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      priority: priority,
      status: status ?? this.status,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      actionRequired: actionRequired,
      actionUrl: actionUrl,
      relatedEntity: relatedEntity,
      orderData: orderData,
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  final String token;

  const NotificationsScreen({
    super.key,
    required this.token,
    this.onBackToDashboard,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<ShopNotification> _notifications = [];
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all'; // all, unread, read
  Timer? _autoRefreshTimer;
  final SoundService _soundService = SoundService();
  Set<int> _previousPendingOrderIds = {}; // Track previous PENDING order IDs
  Set<int> _readNotificationIds = {}; // Track locally read notification IDs

  @override
  void initState() {
    super.initState();
    _loadSavedReadStatus().then((_) {
      _loadNotifications();
    });

    // Auto-refresh every 30 seconds like Angular version (recurring)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadNotifications(silent: true); // Silent refresh without loading indicator
      }
    });
  }

  Future<void> _loadSavedReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList('read_notification_ids') ?? [];
      _readNotificationIds = savedIds.map((id) => int.parse(id)).toSet();
      print('Loaded ${_readNotificationIds.length} read notification IDs');
    } catch (e) {
      print('Error loading saved read status: $e');
    }
  }

  Future<void> _saveReadStatus(int notificationId) async {
    try {
      _readNotificationIds.add(notificationId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'read_notification_ids',
        _readNotificationIds.map((id) => id.toString()).toList(),
      );
      print('Saved read notification ID: $notificationId');
    } catch (e) {
      print('Error saving read status: $e');
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool refresh = false, bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      // Load orders from API (like Angular version does)
      final response = await ApiService.getShopOrders(
        page: 0,
        size: 50,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        print('=== NOTIFICATIONS DEBUG ===');
        print('Full response data: $data');

        final ordersData = data['data'] ?? data;
        print('Orders data: $ordersData');

        // Check if orders are in 'orders' field instead of 'content'
        final content = ordersData['orders'] ?? ordersData['content'] ?? ordersData ?? [];
        print('Content (orders list): $content');
        print('Content type: ${content.runtimeType}');
        print('Content length: ${content is List ? content.length : 'NOT A LIST'}');

        final List<ShopNotification> notifications = [];

        if (content is List) {
          print('Processing ${content.length} orders...');
          for (var order in content) {
            String title = '';
            String message = '';
            String type = 'order';
            String priority = 'medium';
            bool actionRequired = false;

            // Set notification details based on order status (same as Angular)
            switch(order['status']?.toString() ?? '') {
              case 'PENDING':
                title = '🆕 New Order Received';
                message = 'New order ${order['orderNumber']} from ${order['customerName']} - ₹${order['totalAmount']}';
                type = 'order';
                priority = 'high';
                actionRequired = true;
                break;
              case 'ACCEPTED':
                title = '✅ Order Accepted';
                message = 'Order ${order['orderNumber']} has been accepted and is being prepared';
                type = 'success';
                priority = 'medium';
                break;
              case 'READY_FOR_PICKUP':
                title = '📦 Order Ready for Pickup';
                message = 'Order ${order['orderNumber']} is ready and waiting for pickup';
                type = 'info';
                priority = 'medium';
                break;
              case 'OUT_FOR_DELIVERY':
                title = '🚚 Order Out for Delivery';
                message = 'Order ${order['orderNumber']} is out for delivery to ${order['customerName']}';
                type = 'info';
                priority = 'low';
                break;
              case 'DELIVERED':
                title = '✔️ Order Delivered';
                message = 'Order ${order['orderNumber']} has been successfully delivered - ₹${order['totalAmount']}';
                type = 'success';
                priority = 'low';
                break;
              case 'SELF_PICKUP_COLLECTED':
                title = '✅ Self-Pickup Collected';
                message = 'Order ${order['orderNumber']} has been collected by ${order['customerName']} - ₹${order['totalAmount']}';
                type = 'success';
                priority = 'low';
                break;
              case 'CANCELLED':
                title = '❌ Order Cancelled';
                message = 'Order ${order['orderNumber']} has been cancelled by ${order['cancelledBy'] ?? 'customer'}';
                type = 'warning';
                priority = 'high';
                break;
              case 'REJECTED':
                title = '🚫 Order Rejected';
                message = 'Order ${order['orderNumber']} was rejected';
                type = 'error';
                priority = 'medium';
                break;
              case 'RETURNED':
                title = '↩️ Order Returned';
                message = 'Order ${order['orderNumber']} has been returned by customer';
                type = 'warning';
                priority = 'high';
                break;
              case 'REFUNDED':
                title = '💰 Order Refunded';
                message = 'Order ${order['orderNumber']} has been refunded - ₹${order['totalAmount']}';
                type = 'info';
                priority = 'medium';
                break;
              default:
                title = 'Order Update';
                message = 'Order ${order['orderNumber']} status: ${order['status']}';
                type = 'info';
                priority = 'low';
            }

            // Determine if notification is unread
            final orderDate = DateTime.parse(order['createdAt'] ?? DateTime.now().toIso8601String());
            final yesterday = DateTime.now().subtract(const Duration(days: 1));
            final isRecent = orderDate.isAfter(yesterday);
            final orderId = order['id'] ?? 0;

            // Check if user has already marked this as read locally
            final isLocallyRead = _readNotificationIds.contains(orderId);
            // If locally marked as read, use 'read', otherwise use original logic
            final notificationStatus = isLocallyRead
                ? 'read'
                : ((order['status'] == 'PENDING' || isRecent) ? 'unread' : 'read');

            notifications.add(ShopNotification(
              id: orderId,
              title: title,
              message: message,
              type: type,
              priority: priority,
              status: notificationStatus,
              createdAt: orderDate,
              actionRequired: actionRequired,
              actionUrl: '/orders/${order['id']}',
              relatedEntity: {
                'type': 'order',
                'id': order['id'],
                'name': order['orderNumber'],
              },
              orderData: order,
            ));
          }
        }

        // Sort notifications by date, newest first
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Detect new PENDING orders and play sound
        final currentPendingOrderIds = notifications
            .where((n) => n.orderData?['status'] == 'PENDING')
            .map((n) => n.id)
            .toSet();

        // Check if there are any new PENDING orders
        final newPendingOrders = currentPendingOrderIds.difference(_previousPendingOrderIds);

        if (newPendingOrders.isNotEmpty && _previousPendingOrderIds.isNotEmpty) {
          // Play sound only if this is not the first load (silent refresh)
          print('🔔 New PENDING orders detected: $newPendingOrders - Playing sound!');
          _soundService.playNewOrderSound();
        }

        // Update the previous PENDING order IDs
        _previousPendingOrderIds = currentPendingOrderIds;

        setState(() {
          _notifications = notifications;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      _showError('Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(ShopNotification notification) async {
    if (notification.status == 'unread') {
      // Save read status locally first (so it persists across API refreshes)
      await _saveReadStatus(notification.id);

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(
            status: 'read',
            readAt: DateTime.now(),
          );
        }
      });

      try {
        // Also call API to persist read status on backend
        final response = await ApiService.markNotificationAsRead(notification.id);
        if (!response.isSuccess) {
          print('Backend mark as read failed: ${response.error}');
        }
      } catch (e) {
        print('Error calling backend markAsRead: $e');
        // Local status is already saved, so no need to show error
      }
    }
  }

  Future<void> _markAllAsRead() async {
    // Save all unread notification IDs locally first
    for (final notification in _notifications) {
      if (notification.status == 'unread') {
        _readNotificationIds.add(notification.id);
      }
    }

    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'read_notification_ids',
        _readNotificationIds.map((id) => id.toString()).toList(),
      );
    } catch (e) {
      print('Error saving all read statuses: $e');
    }

    setState(() {
      _notifications = _notifications.map((notification) {
        if (notification.status == 'unread') {
          return notification.copyWith(
            status: 'read',
            readAt: DateTime.now(),
          );
        }
        return notification;
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );

    // Try to call backend API (but don't fail if it doesn't work)
    try {
      final user = StorageService.getUser();
      if (user != null && user['id'] != null) {
        final userId = user['id'] as int;
        await ApiService.markAllNotificationsAsRead(userId);
      }
    } catch (e) {
      print('Error calling backend markAllAsRead: $e');
    }
  }

  List<ShopNotification> _getFilteredNotifications() {
    switch (_selectedFilter) {
      case 'unread':
        return _notifications.where((n) => n.status == 'unread').toList();
      case 'read':
        return _notifications.where((n) => n.status == 'read').toList();
      default:
        return _notifications;
    }
  }

  int _getUnreadCount() {
    return _notifications.where((n) => n.status == 'unread').length;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _getFilteredNotifications();
    final unreadCount = _getUnreadCount();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () {
            if (widget.onBackToDashboard != null) {
              widget.onBackToDashboard!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Row(
          children: [
            Text('Notifications', style: AppTheme.h5.copyWith(color: AppTheme.textWhite)),
            if (unreadCount > 0) ...[
              const SizedBox(width: AppTheme.space12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: AppTheme.roundedRound,
                  boxShadow: AppTheme.shadowSmall,
                ),
                child: Text(
                  '$unreadCount',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.green.shade700,
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark All Read',
              color: AppTheme.textWhite,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadNotifications(refresh: true),
            tooltip: 'Refresh',
            color: AppTheme.textWhite,
          ),
          const SizedBox(width: AppTheme.space8),
        ],
      ),
      body: _isLoading && _notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Tabs
                Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    boxShadow: AppTheme.shadowSmall,
                  ),
                  child: Row(
                    children: [
                      ModernChip(
                        label: 'All ${_notifications.length}',
                        icon: Icons.all_inbox,
                        selected: _selectedFilter == 'all',
                        onTap: () => setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      ModernChip(
                        label: 'Unread $unreadCount',
                        icon: Icons.mark_email_unread,
                        selected: _selectedFilter == 'unread',
                        selectedColor: AppTheme.accent,
                        onTap: () => setState(() => _selectedFilter = 'unread'),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      ModernChip(
                        label: 'Read ${_notifications.where((n) => n.status == 'read').length}',
                        icon: Icons.done_all,
                        selected: _selectedFilter == 'read',
                        selectedColor: AppTheme.success,
                        onTap: () => setState(() => _selectedFilter = 'read'),
                      ),
                    ],
                  ),
                ),

                // Notifications List
                Expanded(
                  child: filteredNotifications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => _loadNotifications(refresh: true),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final notification = filteredNotifications[index];
                              return _buildNotificationCard(notification);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationCard(ShopNotification notification) {
    final orderData = notification.orderData;
    final orderItems = orderData != null ? (orderData['orderItems'] as List?) ?? [] : [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
      elevation: notification.status == 'unread' ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.status == 'unread'
            ? BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 2)
            : BorderSide.none,
      ),
      color: notification.status == 'unread'
          ? AppTheme.primary.withOpacity(0.05)
          : AppTheme.surface,
      child: InkWell(
          onTap: () => _markAsRead(notification),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _getNotificationGradient(notification.type),
                      borderRadius: AppTheme.roundedMedium,
                      boxShadow: AppTheme.shadowSmall,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: AppTheme.textWhite,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),

                  // Title and Message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: notification.status == 'unread'
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          notification.message,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status and Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space8,
                          vertical: AppTheme.space4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getPriorityColor(notification.priority),
                              _getPriorityColor(notification.priority).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: AppTheme.roundedMedium,
                        ),
                        child: Text(
                          notification.priority.toUpperCase(),
                          style: AppTheme.overline.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Order Items Section (if available)
              if (orderItems.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space16),
                Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: AppTheme.space16),

                // Items Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Order Items (${orderItems.length})',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.success, AppTheme.success.withOpacity(0.7)],
                        ),
                        borderRadius: AppTheme.roundedMedium,
                      ),
                      child: Text(
                        '₹${orderData!['totalAmount'] ?? 0}',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),

                  // Items List (show first 3 items)
                  ...orderItems.take(3).map((item) {
                    final productName = item['productName'] ?? item['product']?['name'] ?? 'Unknown Product';
                    final quantity = item['quantity'] ?? 0;
                    final price = (item['unitPrice'] ?? item['price'] ?? 0).toDouble();
                    final imageUrl = item['productImageUrl'] ?? item['product']?['primaryImageUrl'] ?? item['imageUrl'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Product Image
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: AppTheme.roundedMedium,
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl != null && imageUrl.toString().isNotEmpty
                                  ? Image.network(
                                      imageUrl.toString().startsWith('http')
                                          ? imageUrl.toString()
                                          : '${AppConfig.serverBaseUrl}${imageUrl.toString()}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.inventory_2,
                                          size: 20,
                                          color: Colors.grey,
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.inventory_2,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: AppTheme.bodySmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Qty: $quantity',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Item Price
                          Text(
                            '₹${(price * quantity).toStringAsFixed(0)}',
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  // Show more indicator
                  if (orderItems.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${orderItems.length - 3} more items',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],

                // View Details Button (always show for all orders)
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _showFullOrderDetails(notification),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: Text(orderItems.length > 3 ? 'View All Items' : 'View Order Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),

              // Action Buttons Row
              if (notification.actionRequired) ...[
                const SizedBox(height: AppTheme.space16),
                Row(
                  children: [
                    Expanded(
                      child: ModernButton(
                        text: notification.status == 'processing' ? 'Processing...' : 'Accept',
                        icon: Icons.check_circle,
                        variant: ButtonVariant.success,
                        size: ButtonSize.medium,
                        fullWidth: true,
                        useGradient: true,
                        onPressed: notification.status == 'processing'
                            ? null
                            : () => _acceptOrder(notification),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: ModernButton(
                        text: 'Reject',
                        icon: Icons.cancel,
                        variant: ButtonVariant.error,
                        size: ButtonSize.medium,
                        fullWidth: true,
                        onPressed: notification.status == 'processing'
                            ? null
                            : () => _rejectOrder(notification),
                      ),
                    ),
                  ],
                ),
              ],

                // Order Status Badge (if not pending)
                if (orderData != null && !notification.actionRequired) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orderData['status']?.toString() ?? '').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getStatusColor(orderData['status']?.toString() ?? ''),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(orderData['status']?.toString() ?? ''),
                          size: 14,
                          color: _getStatusColor(orderData['status']?.toString() ?? ''),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          orderData['status']?.toString() ?? 'UNKNOWN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(orderData['status']?.toString() ?? ''),
                            letterSpacing: 0.3,
                          ),
                        ),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.schedule;
      case 'CONFIRMED':
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'PREPARING':
        return Icons.restaurant;
      case 'READY_FOR_PICKUP':
      case 'READY':
        return Icons.shopping_bag;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.done_all;
      case 'SELF_PICKUP_COLLECTED':
        return Icons.how_to_reg;
      case 'CANCELLED':
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  LinearGradient _getNotificationGradient(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return const LinearGradient(
          colors: [Color(0xFF10b981), Color(0xFF34d399)],
        );
      case 'success':
        return const LinearGradient(
          colors: [Color(0xFF10b981), Color(0xFF059669)],
        );
      case 'warning':
        return const LinearGradient(
          colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)],
        );
      case 'error':
        return const LinearGradient(
          colors: [Color(0xFFef4444), Color(0xFFdc2626)],
        );
      case 'info':
        return const LinearGradient(
          colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF6b7280), Color(0xFF9ca3af)],
        );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFF9800); // Orange - bright and visible
      case 'CONFIRMED':
      case 'ACCEPTED':
        return const Color(0xFF4CAF50); // Green - success color
      case 'PREPARING':
        return const Color(0xFF9C27B0); // Purple - distinct color
      case 'READY_FOR_PICKUP':
      case 'READY':
        return const Color(0xFF2196F3); // Blue - ready to go
      case 'OUT_FOR_DELIVERY':
        return const Color(0xFF00BCD4); // Cyan - in transit
      case 'DELIVERED':
        return const Color(0xFF4CAF50); // Green - completed
      case 'SELF_PICKUP_COLLECTED':
        return const Color(0xFF4CAF50); // Green - collected
      case 'CANCELLED':
        return const Color(0xFFF44336); // Red - cancelled
      default:
        return const Color(0xFF9E9E9E); // Gray - default
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFc62828);
      case 'high':
        return const Color(0xFFe65100);
      case 'medium':
        return const Color(0xFF1565c0);
      case 'low':
        return const Color(0xFF6b7280);
      default:
        return const Color(0xFF6b7280);
    }
  }

  void _showFullOrderDetails(ShopNotification notification) {
    final orderData = notification.orderData;
    if (orderData == null) return;

    final orderItems = (orderData['orderItems'] as List?) ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Details',
                            style: AppTheme.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            orderData['orderNumber'] ?? 'Order',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Order Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                orderData['customerName'] ?? 'N/A',
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Amount',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${orderData['totalAmount'] ?? 0}',
                              style: AppTheme.h3.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orderItems.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = orderItems[index];
                    final productName = item['productName'] ?? item['product']?['name'] ?? 'Unknown';
                    final quantity = item['quantity'] ?? 0;
                    final price = (item['unitPrice'] ?? item['price'] ?? 0).toDouble();
                    final imageUrl = item['productImageUrl'] ?? item['product']?['primaryImageUrl'] ?? item['imageUrl'];

                    return Row(
                      children: [
                        // Product Image
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl != null && imageUrl.toString().isNotEmpty
                                ? Image.network(
                                    imageUrl.toString().startsWith('http')
                                        ? imageUrl.toString()
                                        : '${AppConfig.serverBaseUrl}${imageUrl.toString()}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.inventory_2, size: 24, color: Colors.grey);
                                    },
                                  )
                                : const Icon(Icons.inventory_2, size: 24, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₹$price',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    ' × $quantity',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Total Price
                        Text(
                          '₹${(price * quantity).toStringAsFixed(0)}',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // Footer with actions
              if (notification.actionRequired)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _acceptOrder(notification);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Accept Order', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _rejectOrder(notification);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: Icon(Icons.close, color: AppTheme.error),
                          label: Text('Reject', style: TextStyle(color: AppTheme.error)),
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

  void _acceptOrder(ShopNotification notification) async {
    if (notification.relatedEntity == null) return;

    final orderId = notification.relatedEntity!['id'];
    final orderNumber = notification.relatedEntity!['name'];

    // Show processing state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accepting order $orderNumber...'),
        backgroundColor: AppTheme.primary,
      ),
    );

    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(status: 'processing');
      }
    });

    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? widget.token;

      // Call accept order API (same as Angular: POST /api/shops/orders/{orderId}/accept)
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/shops/orders/$orderId/accept'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'estimatedPreparationTime': '30 minutes',
          'notes': 'Order accepted and will be prepared shortly',
        }),
      );

      print('Accept order API response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order $orderNumber accepted!'),
              backgroundColor: AppTheme.success,
            ),
          );

          // Mark as read and refresh
          setState(() {
            final index = _notifications.indexWhere((n) => n.id == notification.id);
            if (index != -1) {
              _notifications[index] = notification.copyWith(status: 'read');
            }
          });

          // Refresh notifications to get updated data
          _loadNotifications();
        }
      } else {
        throw Exception('Failed to accept order: ${response.body}');
      }
    } catch (e) {
      print('Error accepting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept order: $e'),
            backgroundColor: AppTheme.error,
          ),
        );

        // Revert processing state
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(status: 'unread');
          }
        });
      }
    }
  }

  void _rejectOrder(ShopNotification notification) async {
    if (notification.relatedEntity == null) return;

    final orderId = notification.relatedEntity!['id'];
    final orderNumber = notification.relatedEntity!['name'];

    // Show processing state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rejecting order $orderNumber...'),
        backgroundColor: AppTheme.error,
      ),
    );

    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(status: 'processing');
      }
    });

    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? widget.token;

      // Call reject order API (same as Angular: POST /api/shops/orders/{orderId}/reject)
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/shops/orders/$orderId/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'reason': 'Order rejected by shop owner',
        }),
      );

      print('Reject order API response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order $orderNumber rejected'),
              backgroundColor: AppTheme.warning,
            ),
          );

          // Mark as read and refresh
          setState(() {
            final index = _notifications.indexWhere((n) => n.id == notification.id);
            if (index != -1) {
              _notifications[index] = notification.copyWith(status: 'read');
            }
          });

          // Refresh notifications to get updated data
          _loadNotifications();
        }
      } else {
        throw Exception('Failed to reject order: ${response.body}');
      }
    } catch (e) {
      print('Error rejecting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject order: $e'),
            backgroundColor: AppTheme.error,
          ),
        );

        // Revert processing state
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(status: 'unread');
          }
        });
      }
    }
  }

  Widget _buildEmptyState() {
    String message = 'You\'re all caught up!';
    if (_selectedFilter == 'unread') {
      message = 'No unread notifications';
    } else if (_selectedFilter == 'read') {
      message = 'No read notifications';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppTheme.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.h3.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'unread'
                ? 'All caught up! 🎉'
                : 'Order notifications will appear here',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_bag;
      case 'customer':
        return Icons.person;
      case 'inventory':
        return Icons.inventory;
      case 'system':
        return Icons.settings;
      case 'info':
        return Icons.info;
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Server sends UTC time, convert to IST (UTC+5:30)
    final istDateTime = dateTime.add(const Duration(hours: 5, minutes: 30));
    final now = DateTime.now();
    final difference = now.difference(istDateTime);

    if (difference.inDays > 7) {
      return '${istDateTime.day}/${istDateTime.month}/${istDateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}