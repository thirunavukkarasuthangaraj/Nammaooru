import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'notification_api_service.dart';
import '../core/services/audio_service.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  static FirebaseNotificationService get instance => _instance;

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final List<NotificationModel> _localNotifications = [];
  static final List<Function(NotificationModel)> _listeners = [];

  /// Initialize Firebase messaging for delivery partner
  static Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('Firebase messaging not supported on web');
      return;
    }

    try {
      // Initialize audio service for notification sounds
      await AudioService.instance.initialize();

      // Request permission
      await _requestPermission();

      // Get FCM token
      final token = await getToken();
      debugPrint('🔥 FCM Token (Delivery Partner): $token');

      // Setup message handlers
      _setupMessageHandlers();

      debugPrint('✅ Firebase Notification Service initialized for Delivery Partner');
    } catch (e) {
      debugPrint('❌ Firebase Notification Service initialization failed: $e');
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

    // Show in-app notification or update UI
    _notifyListeners(notification);

    // Play sound for important delivery notifications
    final notificationType = notification.type.toLowerCase();
    if (notificationType == 'new_delivery' ||
        notificationType == 'urgent_delivery' ||
        notificationType == 'order_assigned' ||
        notificationType == 'order_assignment') {
      debugPrint('🔊 Playing notification sound for delivery alert');
      try {
        if (notificationType == 'urgent_delivery') {
          await AudioService.instance.playUrgentSound();
        } else {
          await AudioService.instance.playOrderAssignedSound();
        }
      } catch (e) {
        debugPrint('Error playing notification sound: $e');
      }
    }
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
    // For delivery partners, we might want to log location or update availability

    // Check if it's a delivery assignment
    if (message.data['type'] == 'new_delivery' || message.data['type'] == 'urgent_delivery') {
      debugPrint('📦 New delivery assignment received in background');
      // You can store the delivery info for later processing
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
      // Delivery-specific fields
      orderId: message.data['orderId'],
      shopName: message.data['shopName'],
      customerName: message.data['customerName'],
      deliveryAddress: message.data['deliveryAddress'],
      estimatedTime: message.data['estimatedTime'],
      deliveryFee: message.data['deliveryFee'],
      priority: message.data['priority'] ?? 'normal',
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

  /// Handle notification tap actions for delivery partner
  static void _handleNotificationTap(NotificationModel notification) {
    // Navigate based on notification type
    switch (notification.type.toLowerCase()) {
      case 'new_delivery':
      case 'urgent_delivery':
        // Navigate to delivery assignment details
        debugPrint('Navigate to new delivery: ${notification.data?['orderId']}');
        // TODO: Navigate to delivery assignment screen
        break;
      case 'delivery_cancelled':
      case 'order_cancelled':
        // Navigate to cancelled delivery info
        debugPrint('Order/Delivery cancelled: ${notification.data?['orderId']}');
        // Refresh orders list will be handled by listener
        break;
      case 'payment_received':
        // Navigate to earnings
        debugPrint('Navigate to earnings');
        break;
      case 'route_update':
        // Navigate to map/route
        debugPrint('Navigate to route: ${notification.data?['orderId']}');
        break;
      case 'support_message':
        // Navigate to support chat
        debugPrint('Navigate to support chat');
        break;
      case 'announcement':
        // Navigate to announcements
        debugPrint('Navigate to announcements');
        break;
      default:
        debugPrint('Navigate to notifications list');
        break;
    }
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();

      // Send token to backend for delivery partner association
      if (token != null) {
        await _sendTokenToBackend(token);
      }

      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Send FCM token to backend for delivery partner
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      debugPrint('📤 Sending FCM token to backend (Delivery Partner): $token');

      // Call delivery partner specific endpoint
      final response = await NotificationApiService.instance.updateDeliveryPartnerFcmToken(token);

      if (response['success'] == true) {
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

  /// Subscribe to delivery partner specific topics
  static Future<void> subscribeToDeliveryPartnerTopics(String partnerId, String zone) async {
    // Subscribe to partner-specific notifications
    await subscribeToTopic('delivery_partner_$partnerId');

    // Subscribe to all delivery partners topic
    await subscribeToTopic('delivery_partners');
    await subscribeToTopic('delivery_updates');

    // Subscribe to zone-specific notifications if applicable
    if (zone.isNotEmpty) {
      await subscribeToTopic('zone_$zone');
    }

    // Subscribe to urgent deliveries
    await subscribeToTopic('urgent_deliveries');

    // Subscribe to announcements
    await subscribeToTopic('partner_announcements');
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

  /// Get pending delivery notifications count
  static int getPendingDeliveryCount() {
    return _localNotifications.where((n) =>
      !n.isRead &&
      (n.type == 'new_delivery' || n.type == 'urgent_delivery')
    ).length;
  }

  /// Mark notification as read locally
  static void markAsReadLocally(String notificationId) {
    final index = _localNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _localNotifications[index] = _localNotifications[index].copyWith(isRead: true);
    }
  }

  /// Clear all local notifications
  static void clearLocalNotifications() {
    _localNotifications.clear();
  }

  /// Update delivery partner availability
  static Future<void> updateAvailability(bool isAvailable) async {
    if (isAvailable) {
      await subscribeToTopic('available_partners');
      await unsubscribeFromTopic('unavailable_partners');
    } else {
      await unsubscribeFromTopic('available_partners');
      await subscribeToTopic('unavailable_partners');
    }
  }
}

/// Notification model for delivery partner
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  // Delivery-specific fields
  final String? orderId;
  final String? shopName;
  final String? customerName;
  final String? deliveryAddress;
  final String? estimatedTime;
  final String? deliveryFee;
  final String? priority;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.data,
    this.orderId,
    this.shopName,
    this.customerName,
    this.deliveryAddress,
    this.estimatedTime,
    this.deliveryFee,
    this.priority,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      data: data,
      orderId: orderId,
      shopName: shopName,
      customerName: customerName,
      deliveryAddress: deliveryAddress,
      estimatedTime: estimatedTime,
      deliveryFee: deliveryFee,
      priority: priority,
    );
  }
}
