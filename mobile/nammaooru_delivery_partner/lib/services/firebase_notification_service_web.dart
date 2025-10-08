import 'package:flutter/foundation.dart';

// Web stub for Firebase Notification Service - no Firebase on web
class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  static FirebaseNotificationService get instance => _instance;

  static final List<NotificationModel> _localNotifications = [];
  static final List<Function(NotificationModel)> _listeners = [];

  static Future<void> initialize() async {
    debugPrint('Firebase messaging not supported on web - using stub');
  }

  static Future<String?> getToken() async {
    debugPrint('FCM token not available on web');
    return null;
  }

  static Future<void> subscribeToTopic(String topic) async {
    debugPrint('Topic subscription not available on web: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('Topic unsubscription not available on web: $topic');
  }

  static Future<void> subscribeToDeliveryPartnerTopics(String partnerId, String zone) async {
    debugPrint('Delivery partner topics not available on web');
  }

  static void addListener(Function(NotificationModel) listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function(NotificationModel) listener) {
    _listeners.remove(listener);
  }

  static List<NotificationModel> getLocalNotifications() {
    return List.unmodifiable(_localNotifications);
  }

  static int getUnreadCount() {
    return _localNotifications.where((n) => !n.isRead).length;
  }

  static int getPendingDeliveryCount() {
    return _localNotifications.where((n) =>
      !n.isRead &&
      (n.type == 'new_delivery' || n.type == 'urgent_delivery')
    ).length;
  }

  static void markAsReadLocally(String notificationId) {
    final index = _localNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _localNotifications[index] = _localNotifications[index].copyWith(isRead: true);
    }
  }

  static void clearLocalNotifications() {
    _localNotifications.clear();
  }

  static Future<void> updateAvailability(bool isAvailable) async {
    debugPrint('Availability update not supported on web: $isAvailable');
  }

  static Future<void> handleBackgroundMessage(dynamic message) async {
    debugPrint('Background messages not supported on web');
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
