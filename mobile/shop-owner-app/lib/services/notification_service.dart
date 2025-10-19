import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/notification.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'audio_service.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._internal();

  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Stream controllers for notification events
  final StreamController<AppNotification> _notificationController =
      StreamController<AppNotification>.broadcast();
  final StreamController<Map<String, dynamic>> _actionController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  Stream<AppNotification> get notificationStream => _notificationController.stream;
  Stream<Map<String, dynamic>> get actionStream => _actionController.stream;

  // Initialize notification service
  static Future<void> initialize() async {
    await instance._initializeLocalNotifications();
    await instance._initializeFirebaseMessaging();
    await instance._requestPermissions();
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  // Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Configure Firebase Messaging
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      await StorageService.saveFcmToken(fcmToken);
      print('FCM Token: $fcmToken');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      StorageService.saveFcmToken(newToken);
      print('FCM Token refreshed: $newToken');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle initial message when app is launched from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  // Request permissions
  Future<void> _requestPermissions() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    print('Notification permission: $notificationStatus');

    // Request Firebase Messaging permission
    final messagingSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
    );
    print('Firebase Messaging permission: ${messagingSettings.authorizationStatus}');

    // Request exact alarm permission for Android
    if (Platform.isAndroid) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'shop_owner_notifications',
        'Shop Owner Notifications',
        description: 'General notifications for shop owner app',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'new_orders',
        'New Orders',
        description: 'Notifications for new orders',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('new_order'),
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFF1E88E5),
      ),
      AndroidNotificationChannel(
        'urgent_alerts',
        'Urgent Alerts',
        description: 'High priority urgent notifications',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('urgent_alert'),
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFFF44336),
      ),
      AndroidNotificationChannel(
        'payments',
        'Payment Notifications',
        description: 'Payment received notifications',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('payment_received'),
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'order_updates',
        'Order Updates',
        description: 'Order status update notifications',
        importance: Importance.defaultImportance,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // Show local notification
  Future<void> showNotification(AppNotification notification) async {
    final settings = StorageService.getNotificationSettings();
    final notificationSettings = NotificationSettings.fromJson(settings);

    // Check if notifications are enabled
    if (!notificationSettings.enabled) {
      return;
    }

    // Check if category is enabled
    if (!notificationSettings.isCategoryEnabled(notification.type)) {
      return;
    }

    // Play sound if enabled
    if (notificationSettings.soundEnabled) {
      final soundFile = notificationSettings.getSoundForCategory(notification.type);
      await AudioService.instance.playNotificationSound(soundFile);
    }

    // Show local notification
    await _showLocalNotification(notification);

    // Add to notification stream
    _notificationController.add(notification);
  }

  // Show local notification with proper styling
  Future<void> _showLocalNotification(AppNotification notification) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelName(notification.type),
      channelDescription: _getChannelDescription(notification.type),
      importance: notification.isHighPriority ? Importance.max : Importance.high,
      priority: notification.isHighPriority ? Priority.max : Priority.high,
      showWhen: true,
      when: notification.createdAt.millisecondsSinceEpoch,
      sound: RawResourceAndroidNotificationSound(_getSoundFile(notification.type)),
      enableVibration: true,
      enableLights: true,
      ledColor: _getNotificationColor(notification.type),
      largeIcon: notification.imageUrl != null
          ? NetworkAndroidBitmap(notification.imageUrl!)
          : null,
      styleInformation: BigTextStyleInformation(
        notification.body,
        htmlFormatBigText: true,
        contentTitle: notification.title,
        htmlFormatContentTitle: true,
      ),
      actions: notification.actions.map((action) => AndroidNotificationAction(
        action.id,
        action.title,
        icon: AndroidBitmap('drawable/${action.icon ?? 'ic_action'}'),
        contextual: action.style == 'SECONDARY',
        showsUserInterface: true,
      )).toList(),
      autoCancel: false,  // Don't auto-cancel, keep notification visible
      ongoing: notification.type == NotificationTypes.newOrder,  // New orders stay in notification tray
      category: AndroidNotificationCategory.message,
      fullScreenIntent: notification.isHighPriority && notification.type == NotificationTypes.newOrder,
      timeoutAfter: null,  // No timeout
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.aiff',
      badgeNumber: 1,
      categoryIdentifier: 'SHOP_OWNER_CATEGORY',
      interruptionLevel: InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: json.encode(notification.toJson()),
    );
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    instance._handleNotificationInteraction(response);
  }

  // Handle background notification tap
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    instance._handleNotificationInteraction(response);
  }

  // Handle notification interaction
  void _handleNotificationInteraction(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final notificationData = json.decode(response.payload!);
        final notification = AppNotification.fromJson(notificationData);

        // Handle action if present
        if (response.actionId != null) {
          _actionController.add({
            'notificationId': notification.id,
            'actionId': response.actionId!,
            'notification': notification,
          });
        } else {
          // Handle notification tap
          _actionController.add({
            'notificationId': notification.id,
            'actionId': 'tap',
            'notification': notification,
          });
        }
      }
    } catch (e) {
      print('Failed to handle notification interaction: $e');
    }
  }

  // Handle foreground Firebase messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground FCM message: ${message.data}');

    final notification = _createNotificationFromFirebase(message);
    if (notification != null) {
      showNotification(notification);
    }
  }

  // Handle background Firebase messages
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background FCM message: ${message.data}');

    final notification = _createNotificationFromFirebase(message);
    if (notification != null) {
      _notificationController.add(notification);
    }
  }

  // Create notification from Firebase message
  AppNotification? _createNotificationFromFirebase(RemoteMessage message) {
    try {
      final data = message.data;

      return AppNotification(
        id: data['notificationId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? data['title'] ?? '',
        body: message.notification?.body ?? data['body'] ?? '',
        type: data['type'] ?? 'general',
        orderId: data['orderId'],
        customerId: data['customerId'],
        productId: data['productId'],
        data: data,
        priority: data['priority'] ?? 'NORMAL',
        requiresAction: data['requiresAction'] == 'true',
        actions: _parseActions(data['actions']),
        createdAt: DateTime.now(),
        imageUrl: message.notification?.android?.imageUrl ??
                 message.notification?.apple?.imageUrl,
        sound: data['sound'],
      );
    } catch (e) {
      print('Failed to create notification from Firebase message: $e');
      return null;
    }
  }

  // Parse notification actions from Firebase data
  List<NotificationAction> _parseActions(String? actionsJson) {
    if (actionsJson == null) return [];

    try {
      final List<dynamic> actionsData = json.decode(actionsJson);
      return actionsData.map((action) => NotificationAction.fromJson(action)).toList();
    } catch (e) {
      print('Failed to parse notification actions: $e');
      return [];
    }
  }

  // Schedule notification
  Future<void> scheduleNotification(
    AppNotification notification,
    DateTime scheduledDate,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelName(notification.type),
      channelDescription: _getChannelDescription(notification.type),
      importance: notification.isHighPriority ? Importance.max : Importance.high,
      priority: notification.isHighPriority ? Priority.max : Priority.high,
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

    await _localNotifications.schedule(
      notification.id.hashCode,
      notification.title,
      notification.body,
      scheduledDate,
      notificationDetails,
      payload: json.encode(notification.toJson()),
    );
  }

  // Cancel notification
  Future<void> cancelNotification(String notificationId) async {
    await _localNotifications.cancel(notificationId.hashCode);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Helper methods for notification styling
  String _getChannelId(String notificationType) {
    switch (notificationType) {
      case NotificationTypes.newOrder:
        return 'new_orders';
      case NotificationTypes.paymentReceived:
        return 'payments';
      case 'urgent_alert':
      case 'time_alert':
        return 'urgent_alerts';
      case NotificationTypes.orderCancelled:
      case NotificationTypes.orderModified:
        return 'order_updates';
      default:
        return 'shop_owner_notifications';
    }
  }

  String _getChannelName(String notificationType) {
    switch (notificationType) {
      case NotificationTypes.newOrder:
        return 'New Orders';
      case NotificationTypes.paymentReceived:
        return 'Payment Notifications';
      case 'urgent_alert':
      case 'time_alert':
        return 'Urgent Alerts';
      case NotificationTypes.orderCancelled:
      case NotificationTypes.orderModified:
        return 'Order Updates';
      default:
        return 'Shop Owner Notifications';
    }
  }

  String _getChannelDescription(String notificationType) {
    switch (notificationType) {
      case NotificationTypes.newOrder:
        return 'Notifications for new incoming orders';
      case NotificationTypes.paymentReceived:
        return 'Notifications for payment confirmations';
      case 'urgent_alert':
      case 'time_alert':
        return 'High priority urgent notifications';
      case NotificationTypes.orderCancelled:
      case NotificationTypes.orderModified:
        return 'Order status update notifications';
      default:
        return 'General notifications for shop owner app';
    }
  }

  String _getSoundFile(String notificationType) {
    switch (notificationType) {
      case NotificationTypes.newOrder:
        return 'new_order';
      case NotificationTypes.paymentReceived:
        return 'payment_received';
      case NotificationTypes.orderCancelled:
        return 'order_cancelled';
      case 'urgent_alert':
      case 'time_alert':
        return 'urgent_alert';
      case NotificationTypes.customerMessage:
        return 'message_received';
      default:
        return 'notification';
    }
  }

  Color _getNotificationColor(String notificationType) {
    switch (notificationType) {
      case NotificationTypes.newOrder:
        return AppColors.success;
      case NotificationTypes.paymentReceived:
        return AppColors.primary;
      case NotificationTypes.orderCancelled:
        return AppColors.error;
      case 'urgent_alert':
      case 'time_alert':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  // Update FCM token on server
  Future<void> updateFcmTokenOnServer() async {
    try {
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        // Send token to your backend server
        // await ApiService.updateFcmToken(fcmToken);
        await StorageService.saveFcmToken(fcmToken);
      }
    } catch (e) {
      print('Failed to update FCM token on server: $e');
    }
  }

  // Check notification permissions
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    } else {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
  }

  // Open notification settings
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  // Dispose resources
  void dispose() {
    _notificationController.close();
    _actionController.close();
  }
}