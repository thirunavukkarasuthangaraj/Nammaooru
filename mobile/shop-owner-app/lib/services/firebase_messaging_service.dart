import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'api_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Initialize Firebase Messaging
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Initialize local notifications
        await _initializeLocalNotifications();

        // Get FCM token
        String? token = await getToken();
        if (token != null) {
          await _registerTokenWithServer(token);
        }

        // Set up message handlers
        _setupMessageHandlers();

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((token) {
          debugPrint('FCM Token refreshed: $token');
          _registerTokenWithServer(token);
        });

        _initialized = true;
        debugPrint('Firebase Messaging initialized successfully');
      } else {
        debugPrint('Notification permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        final data = jsonDecode(payload);
        debugPrint('Notification tapped with payload: $data');

        // Handle navigation based on notification type
        _handleNotificationNavigation(data);
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  // Set up Firebase message handlers
  static void _setupMessageHandlers() {
    // Handle messages when app is in background and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show local notification
      await _showLocalNotification(
        title: notification.title ?? 'NammaOoru Shop Owner',
        body: notification.body ?? 'You have a new notification',
        payload: jsonEncode(data),
        data: data,
      );
    }

    // Save notification to local storage
    await _saveNotificationLocally(message);
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message tapped: ${message.messageId}');
    _handleNotificationNavigation(message.data);
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    // Determine notification channel based on type
    String channelId = 'default';
    String channelName = 'Default Notifications';
    String channelDescription = 'General notifications';

    if (data != null) {
      String notificationType = data['type'] ?? 'general';
      switch (notificationType) {
        case 'new_order':
          channelId = 'orders';
          channelName = 'New Orders';
          channelDescription = 'Notifications for new orders';
          break;
        case 'order_update':
          channelId = 'order_updates';
          channelName = 'Order Updates';
          channelDescription = 'Updates on existing orders';
          break;
        case 'low_stock':
          channelId = 'inventory';
          channelName = 'Inventory Alerts';
          channelDescription = 'Low stock and inventory alerts';
          break;
        case 'payment':
          channelId = 'payments';
          channelName = 'Payments';
          channelDescription = 'Payment related notifications';
          break;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      sound: _getNotificationSound(data?['type']),
      styleInformation: const BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Get notification sound based on type
  static RawResourceAndroidNotificationSound? _getNotificationSound(String? type) {
    switch (type) {
      case 'new_order':
        return const RawResourceAndroidNotificationSound('new_order');
      case 'low_stock':
        return const RawResourceAndroidNotificationSound('urgent_alert');
      case 'payment':
        return const RawResourceAndroidNotificationSound('payment_received');
      default:
        return const RawResourceAndroidNotificationSound('success_chime');
    }
  }

  // Handle notification navigation
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? targetScreen = data['targetScreen'];
    final String? orderId = data['orderId'];
    final String? productId = data['productId'];

    // This would typically use a navigation service or global navigator
    // For now, we'll just log the intended navigation
    debugPrint('Navigate to: $targetScreen with type: $type');

    switch (type) {
      case 'new_order':
        debugPrint('Navigate to order details: $orderId');
        break;
      case 'order_update':
        debugPrint('Navigate to order management: $orderId');
        break;
      case 'low_stock':
        debugPrint('Navigate to inventory: $productId');
        break;
      case 'payment':
        debugPrint('Navigate to finances');
        break;
      default:
        debugPrint('Navigate to dashboard');
    }
  }

  // Save notification locally
  static Future<void> _saveNotificationLocally(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications
      final String? notificationsJson = prefs.getString('shop_notifications');
      List<Map<String, dynamic>> notifications = [];

      if (notificationsJson != null) {
        notifications = List<Map<String, dynamic>>.from(
          jsonDecode(notificationsJson)
        );
      }

      // Add new notification
      notifications.insert(0, {
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'Notification',
        'body': message.notification?.body ?? 'You have a new notification',
        'type': message.data['type'] ?? 'general',
        'data': message.data,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });

      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications = notifications.take(100).toList();
      }

      // Save back to storage
      await prefs.setString('shop_notifications', jsonEncode(notifications));

      debugPrint('Notification saved locally');
    } catch (e) {
      debugPrint('Error saving notification locally: $e');
    }
  }

  // Get FCM token
  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Register token with server
  static Future<void> _registerTokenWithServer(String token) async {
    try {
      // Get user info
      final userId = "1"; // await StorageService.getUserId();
      if (userId == null) {
        debugPrint('No user ID found, skipping token registration');
        return;
      }

      // Register token with backend
      await ApiService.registerFCMToken(token, 'shop_owner');

      debugPrint('FCM token registered with server successfully');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  // Get saved notifications
  static Future<List<Map<String, dynamic>>> getSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString('shop_notifications');

      if (notificationsJson != null) {
        return List<Map<String, dynamic>>.from(
          jsonDecode(notificationsJson)
        );
      }
      return [];
    } catch (e) {
      debugPrint('Error getting saved notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString('shop_notifications');

      if (notificationsJson != null) {
        List<Map<String, dynamic>> notifications = List<Map<String, dynamic>>.from(
          jsonDecode(notificationsJson)
        );

        for (var notification in notifications) {
          if (notification['id'] == notificationId) {
            notification['read'] = true;
            break;
          }
        }

        await prefs.setString('shop_notifications', jsonEncode(notifications));
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('shop_notifications');
      debugPrint('All notifications cleared');
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  // Handle background messages (top-level function required for Firebase)
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('Handling background message: ${message.messageId}');
    // Save notification locally even when app is terminated
    await _saveNotificationLocally(message);
  }
}