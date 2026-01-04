import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../shared/models/notification_model.dart';
import '../app/routes.dart';
import 'notification_api_service.dart';
import 'local_notification_service.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  static FirebaseNotificationService get instance => _instance;

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final List<NotificationModel> _localNotifications = [];
  static final List<Function(NotificationModel)> _listeners = [];

  /// Initialize Firebase messaging (without requesting permissions)
  static Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('Firebase messaging not supported on web');
      return;
    }

    try {
      // Setup message handlers
      _setupMessageHandlers();

      debugPrint('✅ Firebase Notification Service initialized (permissions not requested yet)');
    } catch (e) {
      debugPrint('❌ Firebase Notification Service initialization failed: $e');
    }
  }

  /// Initialize with permissions (call this after login)
  static Future<void> initializeWithPermissions() async {
    if (kIsWeb) {
      debugPrint('Firebase messaging not supported on web');
      return;
    }

    try {
      // Request permission
      await _requestPermission();

      // Get FCM token
      final token = await getToken();
      debugPrint('🔥 FCM Token: $token');

      debugPrint('✅ Firebase Notification Service fully initialized with permissions');
    } catch (e) {
      debugPrint('❌ Firebase Notification Service permission setup failed: $e');
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 Permission granted: ${settings.authorizationStatus}');
  }

  /// Setup message handlers for different app states
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle messages when app is opened from terminated state
    _handleInitialMessage();
  }

  /// Handle messages when app is in foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Foreground message: ${message.notification?.title}');

    final notification = _convertToNotificationModel(message);
    _addLocalNotification(notification);

    // Display the notification using local notifications
    await _displayNotification(message, notification);

    // Show in-app notification or update UI
    _notifyListeners(notification);
  }

  /// Handle messages when app is opened from background
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('🔄 Message opened app: ${message.notification?.title}');

    final notification = _convertToNotificationModel(message);
    _addLocalNotification(notification);
    _notifyListeners(notification);

    // Navigate to specific screen if needed
    _handleNotificationTap(notification);
  }

  /// Handle initial message when app is opened from terminated state
  static Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('🚀 Initial message: ${initialMessage.notification?.title}');

      final notification = _convertToNotificationModel(initialMessage);
      _addLocalNotification(notification);
      _notifyListeners(notification);
      _handleNotificationTap(notification);
    }
  }

  /// Handle background messages (when app is terminated)
  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🌙 Background message: ${message.notification?.title}');

    // This runs in a separate isolate, so we can't update UI directly
    // We can only perform background tasks here
  }

  /// Display notification using local notifications
  static Future<void> _displayNotification(RemoteMessage message, NotificationModel notification) async {
    if (kIsWeb) {
      debugPrint('Local notifications not supported on web');
      return;
    }

    try {
      final title = message.notification?.title ?? notification.title;
      final body = message.notification?.body ?? notification.body;
      final type = notification.type.toLowerCase();

      // Determine which type of notification to show based on the type
      switch (type) {
        case 'order':
        case 'order_update':
          await LocalNotificationService.instance.showOrderNotification(
            orderNumber: message.data['orderNumber'] ?? 'N/A',
            status: message.data['status'] ?? 'Updated',
            message: body,
          );
          break;

        case 'delivery':
        case 'delivery_update':
          await LocalNotificationService.instance.showDeliveryNotification(
            orderId: message.data['orderId'] ?? 'N/A',
            status: message.data['status'] ?? 'Updated',
            message: body,
          );
          break;

        case 'promotion':
        case 'promo':
          await LocalNotificationService.instance.showPromotionNotification(
            title: title,
            message: body,
          );
          break;

        default:
          await LocalNotificationService.instance.showGeneralNotification(
            title: title,
            message: body,
            payload: type,
          );
          break;
      }

      debugPrint('✅ Notification displayed successfully');
    } catch (e) {
      debugPrint('❌ Error displaying notification: $e');
    }
  }

  /// Convert Firebase message to NotificationModel
  static NotificationModel _convertToNotificationModel(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'general',
      createdAt: DateTime.now(),
      isRead: false,
      data: message.data.isNotEmpty ? message.data : null,
    );
  }

  /// Add notification to local storage
  static void _addLocalNotification(NotificationModel notification) {
    _localNotifications.insert(0, notification); // Latest first

    // Keep only last 100 notifications
    if (_localNotifications.length > 100) {
      _localNotifications.removeRange(100, _localNotifications.length);
    }
  }

  /// Notify all listeners about new notification
  static void _notifyListeners(NotificationModel notification) {
    for (final listener in _listeners) {
      try {
        listener(notification);
      } catch (e) {
        debugPrint('Error notifying listener: $e');
      }
    }
  }

  /// Handle notification tap actions
  static void _handleNotificationTap(NotificationModel notification) {
    debugPrint('🔔 Handling notification tap: ${notification.type}');

    // Get the navigator context
    final navigatorState = AppRouter.navigatorKey.currentState;
    if (navigatorState == null) {
      debugPrint('❌ Navigator state is null, cannot navigate');
      return;
    }

    // Navigate based on notification type
    switch (notification.type.toLowerCase()) {
      case 'order':
      case 'order_update':
        // Navigate to orders screen
        debugPrint('Navigate to orders: ${notification.data?['orderId']}');
        AppRouter.router.go('/customer/orders');
        break;
      case 'delivery':
      case 'delivery_update':
        // Navigate to orders/tracking
        debugPrint('Navigate to delivery: ${notification.data?['deliveryId']}');
        AppRouter.router.go('/customer/orders');
        break;
      case 'shop':
        // Navigate to shop details
        debugPrint('Navigate to shop: ${notification.data?['shopId']}');
        final shopId = notification.data?['shopId'];
        if (shopId != null) {
          AppRouter.router.go('/customer/shop/$shopId');
        } else {
          AppRouter.router.go('/notifications');
        }
        break;
      case 'promotion':
      case 'promo':
        // Navigate to notifications to see the promo
        debugPrint('Navigate to promotions');
        AppRouter.router.go('/notifications');
        break;
      default:
        // Navigate to notifications screen for all other types
        debugPrint('Navigate to notifications list');
        AppRouter.router.go('/notifications');
        break;
    }
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();

      // Send token to backend for user association
      if (token != null) {
        await _sendTokenToBackend(token);
      }

      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Send FCM token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      debugPrint('📤 Sending FCM token to backend: $token');

      final response = await NotificationApiService.instance.updateFcmToken(token);

      if (response['statusCode'] == '0000') {
        debugPrint('✅ FCM token sent to backend successfully');
      } else {
        debugPrint('❌ Failed to send FCM token: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Error sending token to backend: $e');
    }
  }

  /// Subscribe to topic for targeted notifications
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Subscribe to user-specific topics
  static Future<void> subscribeToUserTopics(String userId, String userRole) async {
    // Subscribe to user-specific notifications
    await subscribeToTopic('user_$userId');

    // Subscribe to role-based notifications
    switch (userRole.toLowerCase()) {
      case 'customer':
        await subscribeToTopic('customers');
        await subscribeToTopic('promotions');
        break;
      case 'shop_owner':
        await subscribeToTopic('shop_owners');
        await subscribeToTopic('shop_updates');
        break;
      case 'delivery_partner':
        await subscribeToTopic('delivery_partners');
        await subscribeToTopic('delivery_updates');
        break;
    }
  }

  /// Add listener for new notifications
  static void addListener(Function(NotificationModel) listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  static void removeListener(Function(NotificationModel) listener) {
    _listeners.remove(listener);
  }

  /// Get local notifications
  static List<NotificationModel> getLocalNotifications() {
    return List.unmodifiable(_localNotifications);
  }

  /// Get unread count from local notifications
  static int getUnreadCount() {
    return _localNotifications.where((n) => !n.isRead).length;
  }

  /// Mark notification as read locally
  static void markAsReadLocally(String notificationId) {
    final index = _localNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _localNotifications[index] = NotificationModel(
        id: _localNotifications[index].id,
        title: _localNotifications[index].title,
        body: _localNotifications[index].body,
        type: _localNotifications[index].type,
        createdAt: _localNotifications[index].createdAt,
        isRead: true,
        data: _localNotifications[index].data,
      );
    }
  }

  /// Clear all local notifications
  static void clearLocalNotifications() {
    _localNotifications.clear();
  }
}