import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      // Load persisted notifications from SharedPreferences
      await loadPersistedNotifications();

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

    // Firebase can rotate a device's token at any time in the background (not just
    // on login). Without this listener the backend keeps the stale token forever
    // and pushes silently fail with NotRegistered once Firebase invalidates it.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed: $newToken');
      _sendTokenToBackend(newToken);
    });
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

      // Get image URL from FCM notification or data payload
      final imageUrl = message.notification?.android?.imageUrl
          ?? message.notification?.apple?.imageUrl
          ?? message.data['imageUrl']
          ?? '';

      // Build payload for routing on tap
      final category = message.data['category'] ?? '';
      final referenceId = message.data['referenceId'] ?? '';

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
          // Check if this is actually a post notification with category data
          if (category.isNotEmpty && category != 'PROMOTION') {
            await LocalNotificationService.instance.showGeneralNotification(
              title: title,
              message: body,
              payload: 'post/$category/$referenceId',
              imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
            );
          } else {
            await LocalNotificationService.instance.showPromotionNotification(
              title: title,
              message: body,
              imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
            );
          }
          break;

        case 'marketplace':
        case 'farmer_products':
        case 'labours':
        case 'travels':
        case 'parcels':
        case 'real_estate':
          await LocalNotificationService.instance.showGeneralNotification(
            title: title,
            message: body,
            payload: 'post/$category/$referenceId',
            imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          );
          break;

        default:
          // Check if category data is present for routing
          if (category.isNotEmpty) {
            await LocalNotificationService.instance.showGeneralNotification(
              title: title,
              message: body,
              payload: 'post/$category/$referenceId',
              imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
            );
          } else {
            await LocalNotificationService.instance.showGeneralNotification(
              title: title,
              message: body,
              payload: type,
              imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
            );
          }
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

  /// Add notification to local storage and persist to SharedPreferences
  static void _addLocalNotification(NotificationModel notification) {
    // Avoid duplicates
    if (_localNotifications.any((n) => n.id == notification.id)) return;

    _localNotifications.insert(0, notification); // Latest first

    // Keep only last 100 notifications
    if (_localNotifications.length > 100) {
      _localNotifications.removeRange(100, _localNotifications.length);
    }

    // Persist to SharedPreferences
    _persistNotifications();
  }

  /// Persist all local notifications to SharedPreferences
  static Future<void> _persistNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _localNotifications.map((n) => json.encode(n.toJson())).toList();
      await prefs.setStringList('firebase_local_notifications', jsonList);
    } catch (e) {
      debugPrint('Error persisting notifications: $e');
    }
  }

  /// Load persisted notifications from SharedPreferences on startup
  static Future<void> loadPersistedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('firebase_local_notifications') ?? [];

      // Clean up notifications older than 7 days
      final cutoff = DateTime.now().subtract(const Duration(days: 7));

      for (final jsonStr in jsonList) {
        try {
          final map = json.decode(jsonStr) as Map<String, dynamic>;
          final notification = NotificationModel.fromJson(map);
          if (notification.createdAt.isAfter(cutoff) &&
              !_localNotifications.any((n) => n.id == notification.id)) {
            _localNotifications.add(notification);
          }
        } catch (e) {
          // Skip malformed entries
        }
      }

      // Sort latest first
      _localNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Re-persist cleaned list
      await _persistNotifications();
      debugPrint('Loaded ${_localNotifications.length} persisted notifications');
    } catch (e) {
      debugPrint('Error loading persisted notifications: $e');
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
    debugPrint('🔔 Notification data: ${notification.data}');

    // Get the navigator context
    final navigatorState = AppRouter.navigatorKey.currentState;
    if (navigatorState == null) {
      debugPrint('❌ Navigator state is null, cannot navigate');
      return;
    }

    // Try to get the route from notification data category first
    final category = notification.data?['category']?.toString().toUpperCase() ?? '';
    final route = _getRouteForCategory(category);
    if (route != null) {
      debugPrint('Navigate to post listing: $route (category=$category)');
      AppRouter.router.go(route);
      return;
    }

    // Navigate based on notification type
    switch (notification.type.toLowerCase()) {
      case 'order':
      case 'order_update':
        debugPrint('Navigate to orders: ${notification.data?['orderId']}');
        AppRouter.router.go('/customer/orders');
        break;
      case 'delivery':
      case 'delivery_update':
        debugPrint('Navigate to delivery: ${notification.data?['deliveryId']}');
        AppRouter.router.go('/customer/orders');
        break;
      case 'shop':
        debugPrint('Navigate to shop: ${notification.data?['shopId']}');
        final shopId = notification.data?['shopId'];
        if (shopId != null) {
          AppRouter.router.go('/customer/shop/$shopId');
        } else {
          AppRouter.router.go('/notifications');
        }
        break;
      case 'marketplace':
        AppRouter.router.go('/customer/marketplace');
        break;
      case 'farmer_products':
        AppRouter.router.go('/customer/farmer-products');
        break;
      case 'labours':
        AppRouter.router.go('/customer/labours');
        break;
      case 'travels':
        AppRouter.router.go('/customer/travels');
        break;
      case 'parcels':
        AppRouter.router.go('/customer/parcels');
        break;
      case 'real_estate':
        AppRouter.router.go('/customer/marketplace');
        break;
      case 'promotion':
      case 'promo':
        debugPrint('Navigate to promotions');
        AppRouter.router.go('/notifications');
        break;
      default:
        debugPrint('Navigate to notifications list');
        AppRouter.router.go('/notifications');
        break;
    }
  }

  /// Get route from notification category
  static String? _getRouteForCategory(String category) {
    switch (category) {
      case 'MARKETPLACE':
        return '/customer/marketplace';
      case 'FARMER_PRODUCTS':
        return '/customer/farmer-products';
      case 'LABOURS':
        return '/customer/labours';
      case 'TRAVELS':
        return '/customer/travels';
      case 'PARCELS':
        return '/customer/parcels';
      case 'REAL_ESTATE':
        return '/customer/marketplace';
      default:
        return null;
    }
  }

  /// Get FCM token and register it with the backend for the current user.
  /// Called on every successful login and app restart — Firebase usually
  /// returns the SAME token after logout/login, so onTokenRefresh never fires
  /// and this explicit fetch is the only way the backend learns the new
  /// user <-> token association.
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('🔥 FCM current token fetched');

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

  /// Send FCM token to backend, retrying transient failures so a flaky
  /// network at login doesn't leave the device unregistered.
  static Future<void> _sendTokenToBackend(String token) async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await NotificationApiService.instance.updateFcmToken(token);

        if (response['statusCode'] == '0000') {
          debugPrint('✅ FCM token registered for current user');
          return;
        }
        debugPrint('❌ FCM registration API failed (attempt $attempt/$maxAttempts): ${response['message']}');
      } catch (e) {
        debugPrint('❌ FCM registration API failed (attempt $attempt/$maxAttempts): $e');
      }
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    debugPrint('❌ FCM registration API failed after $maxAttempts attempts, giving up');
  }

  /// Remove the backend association between the current FCM token and the
  /// logged-in user. Must run BEFORE the JWT/session is cleared. The token
  /// itself stays valid on the device (we do NOT call deleteToken) so it can
  /// be re-registered by the next login.
  static Future<void> unregisterFromBackend() async {
    if (kIsWeb) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('FCM logout: no token on device, nothing to unregister');
        return;
      }

      final response = await NotificationApiService.instance.removeFcmToken(token);
      if (response['statusCode'] == '0000') {
        debugPrint('✅ FCM token association removed during logout');
      } else {
        debugPrint('❌ Failed to remove FCM token association: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
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

  /// Unsubscribe from user-specific topics (mirror of subscribeToUserTopics).
  /// Called on logout so the logged-out user stops receiving topic pushes.
  static Future<void> unsubscribeFromUserTopics(String userId, String userRole) async {
    await unsubscribeFromTopic('user_$userId');

    switch (userRole.toLowerCase()) {
      case 'customer':
      case 'user':
        await unsubscribeFromTopic('customers');
        await unsubscribeFromTopic('promotions');
        break;
      case 'shop_owner':
        await unsubscribeFromTopic('shop_owners');
        await unsubscribeFromTopic('shop_updates');
        await unsubscribeFromTopic('shop_owner_$userId');
        break;
      case 'delivery_partner':
        await unsubscribeFromTopic('delivery_partners');
        await unsubscribeFromTopic('delivery_updates');
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

  /// Mark notification as read locally and persist
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
      _persistNotifications();
    }
  }

  /// Clear all local notifications
  static void clearLocalNotifications() {
    _localNotifications.clear();
    _persistNotifications();
  }
}