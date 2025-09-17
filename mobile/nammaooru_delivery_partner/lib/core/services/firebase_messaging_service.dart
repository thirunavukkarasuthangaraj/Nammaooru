import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  static FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  /// Initialize Firebase messaging
  static Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp();

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

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission for notifications');
    } else {
      print('User declined or has not accepted permission for notifications');
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Set up message handlers
    _setupMessageHandlers();

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      // TODO: Send token to backend
      await _sendTokenToBackend(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      print('FCM Token refreshed: $token');
      _sendTokenToBackend(token);
    });
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for different types of notifications
  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
      'order_notifications',
      'Order Notifications',
      description: 'Notifications for new orders and order updates',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('order_sound'),
    );

    const AndroidNotificationChannel locationChannel = AndroidNotificationChannel(
      'location_notifications',
      'Location Tracking',
      description: 'Background location tracking notifications',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    const AndroidNotificationChannel emergencyChannel = AndroidNotificationChannel(
      'emergency_notifications',
      'Emergency Alerts',
      description: 'Critical emergency notifications',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('emergency_sound'),
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(locationChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(emergencyChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  /// Set up message handlers
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    FirebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'NammaOoru Delivery',
        body: notification.body ?? '',
        data: data,
      );
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');

    final data = message.data;
    final notificationType = data['type'];

    // Navigate based on notification type
    switch (notificationType) {
      case 'ORDER_ASSIGNED':
        _navigateToOrderDetails(data['orderId']);
        break;
      case 'ORDER_STATUS_CHANGE':
        _navigateToOrderDetails(data['orderId']);
        break;
      case 'LOCATION_UPDATE':
        _navigateToLocationScreen();
        break;
      case 'EMERGENCY':
        _navigateToEmergencyScreen();
        break;
      case 'ANNOUNCEMENT':
        _navigateToAnnouncementScreen();
        break;
      default:
        _navigateToMainScreen();
        break;
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'NammaOoru Delivery',
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Show order notification with custom styling
  static Future<void> showOrderNotification({
    required String title,
    required String body,
    required String orderId,
    String? actionType,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'order_notifications',
      'Order Notifications',
      channelDescription: 'Notifications for new orders and order updates',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'New Order',
      icon: '@drawable/ic_order',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: Colors.blue,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.blue,
      ledOnMs: 1000,
      ledOffMs: 500,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'view_order',
          'View Order',
          titleColor: Colors.blue,
        ),
        if (actionType == 'new_order') ...[
          AndroidNotificationAction(
            'accept_order',
            'Accept',
            titleColor: Colors.green,
          ),
          AndroidNotificationAction(
            'reject_order',
            'Reject',
            titleColor: Colors.red,
          ),
        ],
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'order_sound.wav',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      int.parse(orderId),
      title,
      body,
      platformDetails,
      payload: jsonEncode({
        'type': 'order',
        'orderId': orderId,
        'actionType': actionType,
      }),
    );
  }

  /// Show emergency notification
  static Future<void> showEmergencyNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'emergency_notifications',
      'Emergency Alerts',
      channelDescription: 'Critical emergency notifications',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'EMERGENCY',
      icon: '@drawable/ic_emergency',
      largeIcon: DrawableResourceAndroidBitmap('@drawable/ic_emergency_large'),
      color: Colors.red,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.red,
      ledOnMs: 200,
      ledOffMs: 200,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'emergency_sound.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      999999, // High ID for emergency
      title,
      body,
      platformDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        final type = data['type'];

        switch (type) {
          case 'order':
            _navigateToOrderDetails(data['orderId']);
            break;
          default:
            _navigateToMainScreen();
            break;
        }
      } catch (e) {
        print('Error parsing notification payload: $e');
        _navigateToMainScreen();
      }
    }
  }

  /// Navigation helper methods
  static void _navigateToOrderDetails(String? orderId) {
    // TODO: Implement navigation to order details
    print('Navigate to order details: $orderId');
  }

  static void _navigateToLocationScreen() {
    // TODO: Implement navigation to location screen
    print('Navigate to location screen');
  }

  static void _navigateToEmergencyScreen() {
    // TODO: Implement navigation to emergency screen
    print('Navigate to emergency screen');
  }

  static void _navigateToAnnouncementScreen() {
    // TODO: Implement navigation to announcements
    print('Navigate to announcements');
  }

  static void _navigateToMainScreen() {
    // TODO: Implement navigation to main screen
    print('Navigate to main screen');
  }

  /// Send FCM token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      // TODO: Implement API call to send token to backend
      print('Sending FCM token to backend: $token');

      // Example API call:
      // await ApiService().post('/api/delivery-partners/fcm-token', {
      //   'token': token,
      //   'platform': Platform.isAndroid ? 'android' : 'ios',
      // });
    } catch (e) {
      print('Error sending FCM token to backend: $e');
    }
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Clear notification by ID
  static Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');

  // Handle background processing if needed
  final data = message.data;
  final type = data['type'];

  switch (type) {
    case 'LOCATION_UPDATE':
      // Handle location update in background
      break;
    case 'ORDER_ASSIGNED':
      // Show high-priority notification for new order
      await FirebaseMessagingService.showOrderNotification(
        title: message.notification?.title ?? 'New Order',
        body: message.notification?.body ?? 'You have a new order assignment',
        orderId: data['orderId'] ?? '0',
        actionType: 'new_order',
      );
      break;
    case 'EMERGENCY':
      // Show emergency notification
      await FirebaseMessagingService.showEmergencyNotification(
        title: message.notification?.title ?? 'Emergency Alert',
        body: message.notification?.body ?? 'Emergency situation detected',
        data: data,
      );
      break;
  }
}