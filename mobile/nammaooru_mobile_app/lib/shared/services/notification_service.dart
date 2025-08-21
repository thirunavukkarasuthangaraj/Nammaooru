import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final List<NotificationModel> _notifications = [];
  static final List<Function(NotificationModel)> _listeners = [];
  
  static Future<void> initialize() async {
    await _requestPermission();
    await _configureFirebase();
    _setupMessageHandlers();
  }
  
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
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }
  
  static Future<void> _configureFirebase() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  
  static void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }
  
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = NotificationModel.fromRemoteMessage(message);
    _addNotification(notification);
    
    _showInAppNotification(notification);
  }
  
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    final notification = NotificationModel.fromRemoteMessage(message);
    _addNotification(notification);
  }
  
  static void _addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    
    for (final listener in _listeners) {
      listener(notification);
    }
  }
  
  static void _showInAppNotification(NotificationModel notification) {
    
  }
  
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
  
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
  
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
  
  static void addListener(Function(NotificationModel) listener) {
    _listeners.add(listener);
  }
  
  static void removeListener(Function(NotificationModel) listener) {
    _listeners.remove(listener);
  }
  
  static List<NotificationModel> getNotifications() {
    return List.unmodifiable(_notifications);
  }
  
  static List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }
  
  static void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }
  
  static void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }
  
  static void clearNotifications() {
    _notifications.clear();
  }
  
  static int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  
  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    required this.timestamp,
    this.isRead = false,
    this.type = 'general',
  });
  
  factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      data: message.data,
      timestamp: DateTime.now(),
      type: message.data['type'] ?? 'general',
    );
  }
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['imageUrl'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'general',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }
  
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}