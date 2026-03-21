import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../app/routes.dart';

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
    debugPrint('🔔 Local notification tapped: ${response.payload}');

    // Handle navigation based on payload
    if (response.payload != null && response.payload!.isNotEmpty) {
      final payload = response.payload!;
      debugPrint('Navigate to: $payload');

      // Parse payload and navigate accordingly
      if (payload.startsWith('order/')) {
        AppRouter.router.go('/customer/orders');
      } else if (payload.startsWith('delivery/')) {
        AppRouter.router.go('/customer/orders');
      } else if (payload.startsWith('post/')) {
        // Post notification: payload format is "post/CATEGORY/referenceId"
        final parts = payload.split('/');
        final category = parts.length > 1 ? parts[1].toUpperCase() : '';
        final route = _getRouteForCategory(category);
        if (route != null) {
          AppRouter.router.go(route);
        } else {
          AppRouter.router.go('/notifications');
        }
      } else if (payload == 'promotions') {
        AppRouter.router.go('/notifications');
      } else {
        AppRouter.router.go('/notifications');
      }
    } else {
      AppRouter.router.go('/notifications');
    }
  }

  /// Get route from notification category
  String? _getRouteForCategory(String category) {
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

  /// Download image from URL and return as bytes
  Future<Uint8List?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('❌ Error downloading notification image: $e');
    }
    return null;
  }

  /// Show a local notification (with optional image support)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
    String? imageUrl,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    if (!_initialized) {
      debugPrint('⚠️ Local notifications not initialized yet');
      await initialize();
    }

    try {
      // Try to download image for BigPictureStyle
      BigPictureStyleInformation? bigPictureStyle;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final imageBytes = await _downloadImage(imageUrl);
        if (imageBytes != null) {
          bigPictureStyle = BigPictureStyleInformation(
            ByteArrayAndroidBitmap(imageBytes),
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: true,
          );
          debugPrint('🖼️ Image loaded for notification: $imageUrl');
        }
      }

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
        styleInformation: bigPictureStyle,
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
    String? imageUrl,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: message,
      payload: 'promotions',
      channelId: 'promotion_notifications',
      channelName: 'Promotions',
      channelDescription: 'Promotional offers and discounts',
      imageUrl: imageUrl,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  /// Show general notification
  Future<void> showGeneralNotification({
    required String title,
    required String message,
    String? payload,
    String? imageUrl,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: message,
      payload: payload,
      channelId: 'general_notifications',
      channelName: 'General',
      channelDescription: 'General app notifications',
      imageUrl: imageUrl,
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
