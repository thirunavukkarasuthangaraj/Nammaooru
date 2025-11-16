import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  static LocalNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize local notifications
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('Local notifications not supported on web');
      return;
    }

    if (_initialized) {
      debugPrint('Local notifications already initialized');
      return;
    }

    try {
      // Android initialization settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      debugPrint('✅ Local Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Local Notification Service initialization failed: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');

    // Handle navigation based on payload
    if (response.payload != null && response.payload!.isNotEmpty) {
      // You can use a global navigator or callback to handle navigation
      // For now, just log the action
      debugPrint('Navigate to: ${response.payload}');
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    if (!_initialized) {
      debugPrint('⚠️ Local notifications not initialized yet');
      await initialize();
    }

    try {
      // Android notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId ?? 'nammaooru_notifications',
        channelName ?? 'NammaOoru Notifications',
        channelDescription: channelDescription ?? 'Notifications for NammaOoru app events',
        importance: importance,
        priority: priority,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('📬 Local notification displayed: $title');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Show order notification
  Future<void> showOrderNotification({
    required String orderNumber,
    required String status,
    required String message,
  }) async {
    await showNotification(
      id: orderNumber.hashCode,
      title: 'Order $status',
      body: message,
      payload: 'order/$orderNumber',
      channelId: 'order_notifications',
      channelName: 'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  /// Show delivery notification
  Future<void> showDeliveryNotification({
    required String orderId,
    required String status,
    required String message,
  }) async {
    await showNotification(
      id: orderId.hashCode,
      title: 'Delivery $status',
      body: message,
      payload: 'delivery/$orderId',
      channelId: 'delivery_notifications',
      channelName: 'Delivery Updates',
      channelDescription: 'Notifications for delivery status updates',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  /// Show promotion notification
  Future<void> showPromotionNotification({
    required String title,
    required String message,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: message,
      payload: 'promotions',
      channelId: 'promotion_notifications',
      channelName: 'Promotions',
      channelDescription: 'Promotional offers and discounts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  /// Show general notification
  Future<void> showGeneralNotification({
    required String title,
    required String message,
    String? payload,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: message,
      payload: payload,
      channelId: 'general_notifications',
      channelName: 'General',
      channelDescription: 'General app notifications',
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('🗑️ Notification cancelled: $id');
    } catch (e) {
      debugPrint('❌ Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('🗑️ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  /// Get pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Get active notifications (Android only)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (!Platform.isAndroid) {
      debugPrint('Active notifications only available on Android');
      return [];
    }

    try {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        return await androidImplementation.getActiveNotifications();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error getting active notifications: $e');
      return [];
    }
  }
}
