// import 'package:firebase_messaging/firebase_messaging.dart';  // Disabled for web
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  // static final FirebaseMessaging _messaging = FirebaseMessaging.instance;  // Disabled for web
  static final List<NotificationModel> _notifications = [];
  static final List<Function(NotificationModel)> _listeners = [];
  
  static Future<void> initialize() async {
    if (!kIsWeb) {
      // Only initialize Firebase messaging on mobile platforms
      // await _requestPermission();
      // await _configureFirebase(); 
      // _setupMessageHandlers();
      debugPrint('NotificationService: Firebase messaging disabled for web');
    }
  }
  
  // Disabled for web compatibility
  static Future<void> _requestPermission() async {
    debugPrint('Permission request disabled for web');
  }
  
  // Disabled for web compatibility
  static Future<void> _configureFirebase() async {
    debugPrint('Firebase configuration disabled for web');
  }
  
  // Disabled for web compatibility
  static void _setupMessageHandlers() {
    debugPrint('Message handlers disabled for web');
  }
  
  // Disabled for web compatibility
  static Future<void> _handleForegroundMessage(dynamic message) async {
    debugPrint('Foreground message handling disabled for web');
  }
  
  // Disabled for web compatibility
  static Future<void> _handleBackgroundMessage(dynamic message) async {
    debugPrint('Background message handling disabled for web');
  }
  
  static void _addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    
    for (final listener in _listeners) {
      listener(notification);
    }
  }
  
  static void _showInAppNotification(NotificationModel notification) {
    
  }
  
  // Disabled for web compatibility
  static Future<String?> getToken() async {
    debugPrint('Token request disabled for web');
    return null;
  }
  
  // Disabled for web compatibility
  static Future<void> subscribeToTopic(String topic) async {
    debugPrint('Topic subscription disabled for web: $topic');
  }
  
  // Disabled for web compatibility
  static Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('Topic unsubscription disabled for web: $topic');
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
  
  // Disabled for web compatibility
  factory NotificationModel.fromRemoteMessage(dynamic message) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Web notification',
      body: 'Firebase messaging disabled for web',
      timestamp: DateTime.now(),
      type: 'general',
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