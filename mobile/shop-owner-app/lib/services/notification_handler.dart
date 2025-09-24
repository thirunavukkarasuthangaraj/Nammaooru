import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart';
import 'audio_service.dart';
import 'websocket_service.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../models/notification.dart' as app_notification;
import '../utils/constants.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  bool _isInitialized = false;
  BuildContext? _context;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    _context = context;

    // Initialize notification service
    await NotificationService.initialize();

    // Setup notification listeners
    _setupNotificationListeners();

    _isInitialized = true;
  }

  void _setupNotificationListeners() {
    if (_context == null) return;

    final notificationService = NotificationService();
    final websocketService = WebSocketService.instance;

    // Listen for Firebase messages
    notificationService.onMessageReceived.listen((message) {
      _handleFirebaseMessage(message);
    });

    // Listen for notification taps
    notificationService.onNotificationTapped.listen((payload) {
      _handleNotificationTapped(payload);
    });

    // Listen for foreground messages
    notificationService.onForegroundMessage.listen((message) {
      _handleForegroundMessage(message);
    });

    // Listen for WebSocket messages
    websocketService.messageStream.listen((message) {
      _handleWebSocketMessage(message);
    });

    // Listen for WebSocket state changes
    websocketService.stateStream.listen((state) {
      _handleWebSocketStateChange(state);
    });
  }

  Future<void> _handleFirebaseMessage(Map<String, dynamic> message) async {
    if (_context == null) return;

    try {
      final notificationProvider = Provider.of<NotificationProvider>(_context!, listen: false);
      final audioService = AudioService();

      // Parse message data
      final data = message['data'] ?? {};
      final notification = message['notification'] ?? {};

      final title = notification['title'] ?? data['title'] ?? 'New Notification';
      final body = notification['body'] ?? data['body'] ?? '';
      final type = data['type'] ?? 'general';
      final orderId = data['orderId'];

      // Create app notification
      final appNotification = app_notification.Notification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      // Add to provider
      notificationProvider.addNotification(appNotification);

      // Show local notification
      await NotificationService.showNotification(
        id: appNotification.id.hashCode,
        title: title,
        body: body,
        payload: orderId,
      );

      // Play sound and vibration
      await _handleNotificationSound(type);

      // Update order if it's an order notification
      if (orderId != null && type.contains('order')) {
        final orderProvider = Provider.of<OrderProvider>(_context!, listen: false);
        await orderProvider.loadOrders();
      }

    } catch (e) {
      debugPrint('Error handling Firebase message: $e');
    }
  }

  Future<void> _handleForegroundMessage(Map<String, dynamic> message) async {
    if (_context == null) return;

    final data = message['data'] ?? {};
    final notification = message['notification'] ?? {};
    final type = data['type'] ?? 'general';

    // Show in-app notification
    _showInAppNotification(
      title: notification['title'] ?? 'New Notification',
      body: notification['body'] ?? '',
      type: type,
    );

    // Handle the message
    await _handleFirebaseMessage(message);
  }

  void _showInAppNotification({
    required String title,
    required String body,
    required String type,
  }) {
    if (_context == null) return;

    final overlay = Overlay.of(_context!);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _InAppNotificationWidget(
        title: title,
        body: body,
        type: type,
        onDismiss: () => overlayEntry.remove(),
        onTap: () {
          overlayEntry.remove();
          // Handle notification tap
          _handleNotificationAction(type, null);
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _handleWebSocketMessage(Map<String, dynamic> message) async {
    if (_context == null) return;

    try {
      final type = message['type'] ?? '';
      final data = message['data'] ?? message;

      switch (type) {
        case 'new_order':
          await _handleNewOrderMessage(data);
          break;
        case 'order_updated':
          await _handleOrderUpdateMessage(data);
          break;
        case 'payment_confirmed':
          await _handlePaymentMessage(data);
          break;
        case 'order_cancelled':
          await _handleOrderCancelMessage(data);
          break;
        case 'inventory_alert':
          await _handleInventoryAlert(data);
          break;
        case 'system_notification':
          await _handleSystemNotification(data);
          break;
        case 'customer_message':
          await _handleCustomerMessage(data);
          break;
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  void _handleWebSocketStateChange(WebSocketState state) {
    if (_context == null) return;

    switch (state) {
      case WebSocketState.connected:
        _showConnectionStatus('Connected to real-time updates', Colors.green);
        break;
      case WebSocketState.disconnected:
        _showConnectionStatus('Disconnected from updates', Colors.grey);
        break;
      case WebSocketState.error:
        _showConnectionStatus('Connection error', Colors.red);
        break;
      case WebSocketState.reconnecting:
        _showConnectionStatus('Reconnecting...', Colors.orange);
        break;
      default:
        break;
    }
  }

  void _showConnectionStatus(String message, Color color) {
    if (_context == null) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
      ),
    );
  }

  Future<void> _handleNewOrderMessage(Map<String, dynamic> data) async {
    final orderId = data['orderId'] ?? data['order_id'] ?? '';
    final customerName = data['customerName'] ?? data['customer_name'] ?? 'Unknown Customer';
    final amount = data['amount'] ?? data['total_amount'] ?? 0.0;

    // Create notification
    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Order Received!',
      body: 'Order from $customerName - ₹${amount.toStringAsFixed(2)}',
      type: 'new_order',
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    // Add to provider
    final notificationProvider = Provider.of<NotificationProvider>(_context!, listen: false);
    notificationProvider.addNotification(notification);

    // Show local notification
    await NotificationService.showNotification(
      id: orderId.hashCode,
      title: notification.title,
      body: notification.body,
      payload: 'order_$orderId',
    );

    // Play sound and vibration
    await _handleNotificationSound('new_order');

    // Update orders
    final orderProvider = Provider.of<OrderProvider>(_context!, listen: false);
    await orderProvider.loadOrders();

    // Show in-app notification
    _showInAppNotification(
      title: notification.title,
      body: notification.body,
      type: 'new_order',
    );
  }

  Future<void> _handleOrderUpdateMessage(Map<String, dynamic> data) async {
    final orderId = data['orderId'] ?? data['order_id'] ?? '';
    final status = data['status'] ?? 'updated';
    final customerName = data['customerName'] ?? data['customer_name'] ?? 'Customer';

    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Order Updated',
      body: 'Order #$orderId for $customerName is now $status',
      type: 'order_update',
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    final notificationProvider = Provider.of<NotificationProvider>(_context!, listen: false);
    notificationProvider.addNotification(notification);

    await NotificationService.showNotification(
      id: 'update_$orderId'.hashCode,
      title: notification.title,
      body: notification.body,
      payload: 'order_$orderId',
    );

    await _handleNotificationSound('order_update');

    final orderProvider = Provider.of<OrderProvider>(_context!, listen: false);
    await orderProvider.loadOrders();
  }

  Future<void> _handlePaymentMessage(Map<String, dynamic> data) async {
    final orderId = data['orderId'] ?? data['order_id'] ?? '';
    final amount = data['amount'] ?? data['payment_amount'] ?? 0.0;

    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Payment Received',
      body: 'Payment of ₹${amount.toStringAsFixed(2)} received for Order #$orderId',
      type: 'payment_received',
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    final notificationProvider = Provider.of<NotificationProvider>(_context!, listen: false);
    notificationProvider.addNotification(notification);

    await NotificationService.showNotification(
      id: 'payment_$orderId'.hashCode,
      title: notification.title,
      body: notification.body,
      payload: 'payment',
    );

    await _handleNotificationSound('payment_received');

    // Update orders and finance data
    final orderProvider = Provider.of<OrderProvider>(_context!, listen: false);
    await orderProvider.loadOrders();
  }

  Future<void> _handleOrderCancelMessage(Map<String, dynamic> data) async {
    final orderId = data['orderId'] ?? data['order_id'] ?? '';
    final reason = data['reason'] ?? 'No reason provided';

    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Order Cancelled',
      body: 'Order #$orderId was cancelled. Reason: $reason',
      type: 'order_cancelled',
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    final notificationProvider = Provider.of<NotificationProvider>(_context!, listen: false);
    notificationProvider.addNotification(notification);

    await NotificationService.showNotification(
      id: 'cancel_$orderId'.hashCode,
      title: notification.title,
      body: notification.body,
      payload: 'order_$orderId',
    );

    await _handleNotificationSound('order_update');

    final orderProvider = Provider.of<OrderProvider>(_context!, listen: false);
    await orderProvider.loadOrders();
  }

  Future<void> _handleInventoryAlert(Map<String, dynamic> data) async {
    final productName = data['productName'] ?? data['product_name'] ?? 'Product';
    final currentStock = data['currentStock'] ?? data['current_stock'] ?? 0;
    final minStock = data['minStock'] ?? data['min_stock'] ?? 0;

    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Low Stock Alert',
      body: '$productName is running low ($currentStock/$minStock remaining)',
      type: 'low_stock',
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    final notificationProvider = Provider.of<NotificationProvider>(_context!, listen: false);
    notificationProvider.addNotification(notification);

    await NotificationService.showNotification(
      id: 'stock_$productName'.hashCode,
      title: notification.title,
      body: notification.body,
      payload: 'low_stock',
    );

    await _handleNotificationSound('low_stock');

    // Update products
    final productProvider = Provider.of<ProductProvider>(_context!, listen: false);
    await productProvider.loadProducts();
  }

  Future<void> _handleSystemNotification(Map<String, dynamic> data) async {
    final title = data['title'] ?? 'System Notification';
    final body = data['message'] ?? data['body'] ?? '';

    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: 'system',
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    final notificationProvider = Provider.of<NotificationProvider>(_context!, listen: false);
    notificationProvider.addNotification(notification);

    await NotificationService.showNotification(
      id: title.hashCode,
      title: title,
      body: body,
      payload: 'system',
    );

    await _handleNotificationSound('general');
  }

  Future<void> _handleCustomerMessage(Map<String, dynamic> data) async {
    final customerName = data['customerName'] ?? data['customer_name'] ?? 'Customer';
    final message = data['message'] ?? 'Sent you a message';

    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Message',
      body: '$customerName: $message',
      type: 'customer_message',
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    final notificationProvider = Provider.of<NotificationProvider>(_context!, listen: false);
    notificationProvider.addNotification(notification);

    await NotificationService.showNotification(
      id: 'message_${customerName}'.hashCode,
      title: notification.title,
      body: notification.body,
      payload: 'customer_message',
    );

    await _handleNotificationSound('general');
  }

  Future<void> _handleNotificationTapped(String? payload) async {
    if (_context == null || payload == null) return;

    // Navigate based on payload
    if (payload.contains('order_')) {
      final orderId = payload.replaceFirst('order_', '');
      _navigateToOrderDetails(orderId);
    }
  }

  Future<void> _handleNotificationSound(String type) async {
    final audioService = AudioService();

    switch (type) {
      case 'new_order':
        await audioService.playNewOrderSound();
        await audioService.vibratePattern([0, 500, 200, 500]);
        break;
      case 'order_update':
        await audioService.playOrderUpdateSound();
        await audioService.vibratePattern([0, 300, 100, 300]);
        break;
      case 'low_stock':
        await audioService.playLowStockAlert();
        await audioService.vibratePattern([0, 200, 100, 200, 100, 200]);
        break;
      case 'payment_received':
        await audioService.playSuccessSound();
        await audioService.vibratePattern([0, 100, 50, 100]);
        break;
      default:
        await audioService.playGeneralNotification();
        await audioService.vibratePattern([0, 200]);
    }
  }

  void _handleNotificationAction(String type, String? data) {
    if (_context == null) return;

    switch (type) {
      case 'new_order':
      case 'order_update':
        if (data != null) {
          _navigateToOrderDetails(data);
        } else {
          _navigateToOrders();
        }
        break;
      case 'low_stock':
        _navigateToProducts();
        break;
      case 'payment_received':
        _navigateToFinance();
        break;
    }
  }

  void _navigateToOrderDetails(String orderId) {
    if (_context == null) return;
    // Navigator navigation would be implemented here
    // This would typically use a navigation service or global navigator
  }

  void _navigateToOrders() {
    if (_context == null) return;
    // Navigate to orders screen
  }

  void _navigateToProducts() {
    if (_context == null) return;
    // Navigate to products screen
  }

  void _navigateToFinance() {
    if (_context == null) return;
    // Navigate to finance screen
  }

  // Utility methods for sending notifications
  static Future<void> sendOrderNotification({
    required String orderId,
    required String title,
    required String body,
    String type = 'new_order',
  }) async {
    final notificationService = NotificationService();

    await notificationService.sendPushNotification(
      title: title,
      body: body,
      data: {
        'type': type,
        'orderId': orderId,
      },
    );

    // Also show local notification
    await NotificationService.showNotification(
      id: orderId.hashCode,
      title: title,
      body: body,
      payload: 'order_$orderId',
    );
  }

  static Future<void> sendLowStockAlert({
    required String productName,
    required int currentStock,
    required int minStock,
  }) async {
    final title = 'Low Stock Alert';
    final body = '$productName is running low (${currentStock}/${minStock})';

    await NotificationService.showNotification(
      id: productName.hashCode,
      title: title,
      body: body,
      payload: 'low_stock',
    );
  }

  static Future<void> sendPaymentNotification({
    required String orderId,
    required double amount,
  }) async {
    final title = 'Payment Received';
    final body = 'Received ₹${amount.toStringAsFixed(2)} for Order #$orderId';

    await NotificationService.showNotification(
      id: 'payment_$orderId'.hashCode,
      title: title,
      body: body,
      payload: 'payment',
    );
  }

  // Schedule notifications
  static Future<void> scheduleOrderReminder({
    required String orderId,
    required String customerName,
    required DateTime scheduledTime,
  }) async {
    await NotificationService.scheduleNotification(
      id: 'reminder_$orderId'.hashCode,
      title: 'Order Reminder',
      body: 'Follow up on order for $customerName',
      scheduledTime: scheduledTime,
      payload: 'order_$orderId',
    );
  }

  static Future<void> scheduleStockReminder({
    required String productName,
    required DateTime scheduledTime,
  }) async {
    await NotificationService.scheduleNotification(
      id: 'stock_$productName'.hashCode,
      title: 'Stock Reminder',
      body: 'Check stock level for $productName',
      scheduledTime: scheduledTime,
      payload: 'stock_reminder',
    );
  }

  // Clear notifications
  static Future<void> clearAllNotifications() async {
    await NotificationService.clearAllNotifications();
  }

  static Future<void> clearNotification(int id) async {
    await NotificationService.clearNotification(id);
  }
}

class _InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _InAppNotificationWidget({
    required this.title,
    required this.body,
    required this.type,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_InAppNotificationWidget> createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<_InAppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getNotificationColor() {
    switch (widget.type) {
      case 'new_order':
        return AppColors.success;
      case 'order_update':
        return AppColors.info;
      case 'low_stock':
        return AppColors.warning;
      case 'payment_received':
        return AppColors.primary;
      default:
        return AppColors.secondary;
    }
  }

  IconData _getNotificationIcon() {
    switch (widget.type) {
      case 'new_order':
        return Icons.shopping_cart;
      case 'order_update':
        return Icons.update;
      case 'low_stock':
        return Icons.warning;
      case 'payment_received':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getNotificationColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationIcon(),
                      color: _getNotificationColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.body,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}