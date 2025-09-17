import 'package:flutter/material.dart';
import 'dart:async';
import '../services/websocket_service.dart';
import '../services/firebase_messaging_service.dart';
import '../models/delivery_partner.dart';
import '../models/simple_order_model.dart';

class RealtimeProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  final List<StreamSubscription> _subscriptions = [];

  // Connection state
  bool _isWebSocketConnected = false;
  bool _isFirebaseInitialized = false;
  String? _lastError;

  // Real-time data
  List<Map<String, dynamic>> _realtimeNotifications = [];
  List<OrderModel> _newOrders = [];
  Map<String, dynamic>? _partnerStatus;
  List<Map<String, dynamic>> _emergencyAlerts = [];

  // Getters
  bool get isWebSocketConnected => _isWebSocketConnected;
  bool get isFirebaseInitialized => _isFirebaseInitialized;
  bool get isFullyConnected => _isWebSocketConnected && _isFirebaseInitialized;
  String? get lastError => _lastError;
  List<Map<String, dynamic>> get realtimeNotifications => _realtimeNotifications;
  List<OrderModel> get newOrders => _newOrders;
  Map<String, dynamic>? get partnerStatus => _partnerStatus;
  List<Map<String, dynamic>> get emergencyAlerts => _emergencyAlerts;
  int get unreadNotificationCount => _realtimeNotifications.where((n) => n['isRead'] != true).length;

  /// Initialize real-time communication services
  Future<void> initialize(String partnerId) async {
    try {
      _lastError = null;

      // Initialize Firebase Messaging
      await _initializeFirebase();

      // Initialize WebSocket
      await _initializeWebSocket(partnerId);

      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to initialize real-time services: $e';
      notifyListeners();
    }
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebase() async {
    try {
      await FirebaseMessagingService.initialize();
      _isFirebaseInitialized = true;
      print('Firebase messaging initialized successfully');
    } catch (e) {
      print('Firebase messaging initialization failed: $e');
      _isFirebaseInitialized = false;
    }
  }

  /// Initialize WebSocket connection
  Future<void> _initializeWebSocket(String partnerId) async {
    try {
      // Connect to WebSocket
      await _webSocketService.connect(partnerId);

      // Listen to connection status
      _subscriptions.add(
        _webSocketService.connectionStream.listen((isConnected) {
          _isWebSocketConnected = isConnected;
          if (isConnected) {
            _lastError = null;
          } else {
            _lastError = 'WebSocket connection lost';
          }
          notifyListeners();
        }),
      );

      // Listen to order updates
      _subscriptions.add(
        _webSocketService.orderStream.listen(_handleOrderUpdate),
      );

      // Listen to notifications
      _subscriptions.add(
        _webSocketService.notificationStream.listen(_handleNotification),
      );

      // Listen to status updates
      _subscriptions.add(
        _webSocketService.statusStream.listen(_handleStatusUpdate),
      );

      // Listen to emergency alerts
      _subscriptions.add(
        _webSocketService.emergencyStream.listen(_handleEmergencyAlert),
      );

      print('WebSocket listeners initialized');
    } catch (e) {
      print('WebSocket initialization failed: $e');
      _isWebSocketConnected = false;
      _lastError = 'WebSocket connection failed: $e';
    }
  }

  /// Handle incoming order updates
  void _handleOrderUpdate(Map<String, dynamic> data) {
    print('Received order update: $data');

    try {
      final type = data['type'];

      switch (type) {
        case 'ORDER_ASSIGNED':
          _handleNewOrderAssignment(data);
          break;
        case 'ORDER_STATUS_UPDATE':
          _handleOrderStatusUpdate(data);
          break;
        case 'ORDER_ACCEPTED_CONFIRMATION':
          _handleOrderAcceptedConfirmation(data);
          break;
        default:
          print('Unknown order update type: $type');
      }

      notifyListeners();
    } catch (e) {
      print('Error handling order update: $e');
    }
  }

  /// Handle new order assignment
  void _handleNewOrderAssignment(Map<String, dynamic> data) {
    try {
      final orderId = data['orderId']?.toString();
      final orderDetails = data['orderDetails'];

      if (orderId != null && orderDetails != null) {
        // Create order model from data
        final order = OrderModel.fromJson({
          'id': orderId,
          ...orderDetails,
        });

        // Add to new orders list
        _newOrders.insert(0, order);

        // Show local notification
        FirebaseMessagingService.showOrderNotification(
          title: 'New Order Assignment',
          body: 'You have been assigned order #$orderId',
          orderId: orderId,
          actionType: 'new_order',
        );

        // Add to notifications
        _addNotification({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'ORDER_ASSIGNED',
          'title': 'New Order Assignment',
          'message': 'You have been assigned order #$orderId',
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
          'isRead': false,
          'priority': 'HIGH',
        });
      }
    } catch (e) {
      print('Error handling new order assignment: $e');
    }
  }

  /// Handle order status update
  void _handleOrderStatusUpdate(Map<String, dynamic> data) {
    try {
      final orderId = data['orderId']?.toString();
      final status = data['status'];

      if (orderId != null && status != null) {
        // Update order in new orders list
        final orderIndex = _newOrders.indexWhere((order) => order.id == orderId);
        if (orderIndex != -1) {
          // Update the order status (you might need to modify OrderModel to support this)
          print('Updated order $orderId status to $status');
        }

        // Add to notifications
        _addNotification({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'ORDER_STATUS_UPDATE',
          'title': 'Order Status Updated',
          'message': 'Order #$orderId status: $status',
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
          'isRead': false,
          'priority': 'MEDIUM',
        });
      }
    } catch (e) {
      print('Error handling order status update: $e');
    }
  }

  /// Handle order accepted confirmation
  void _handleOrderAcceptedConfirmation(Map<String, dynamic> data) {
    try {
      final orderId = data['orderId']?.toString();

      if (orderId != null) {
        // Remove from new orders list since it's accepted
        _newOrders.removeWhere((order) => order.id == orderId);

        _addNotification({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'ORDER_ACCEPTED',
          'title': 'Order Accepted',
          'message': 'Successfully accepted order #$orderId',
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
          'isRead': false,
          'priority': 'MEDIUM',
        });
      }
    } catch (e) {
      print('Error handling order accepted confirmation: $e');
    }
  }

  /// Handle incoming notifications
  void _handleNotification(Map<String, dynamic> data) {
    print('Received notification: $data');

    try {
      _addNotification({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': data['type'] ?? 'GENERAL',
        'title': data['title'] ?? 'Notification',
        'message': data['message'] ?? '',
        'data': data,
        'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
        'isRead': false,
        'priority': data['priority'] ?? 'NORMAL',
      });

      // Show local notification for important messages
      final priority = data['priority'];
      if (priority == 'HIGH' || priority == 'URGENT') {
        FirebaseMessagingService._showLocalNotification(
          title: data['title'] ?? 'Important Notification',
          body: data['message'] ?? '',
          data: data,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error handling notification: $e');
    }
  }

  /// Handle status updates
  void _handleStatusUpdate(Map<String, dynamic> data) {
    print('Received status update: $data');

    try {
      _partnerStatus = data;
      notifyListeners();
    } catch (e) {
      print('Error handling status update: $e');
    }
  }

  /// Handle emergency alerts
  void _handleEmergencyAlert(Map<String, dynamic> data) {
    print('Received emergency alert: $data');

    try {
      _emergencyAlerts.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        ...data,
      });

      // Show emergency notification
      FirebaseMessagingService.showEmergencyNotification(
        title: data['title'] ?? '🚨 Emergency Alert',
        body: data['message'] ?? 'Emergency situation detected',
        data: data,
      );

      // Add to regular notifications as well
      _addNotification({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'EMERGENCY',
        'title': data['title'] ?? '🚨 Emergency Alert',
        'message': data['message'] ?? 'Emergency situation detected',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'priority': 'URGENT',
      });

      notifyListeners();
    } catch (e) {
      print('Error handling emergency alert: $e');
    }
  }

  /// Add notification to list
  void _addNotification(Map<String, dynamic> notification) {
    _realtimeNotifications.insert(0, notification);

    // Keep only last 100 notifications
    if (_realtimeNotifications.length > 100) {
      _realtimeNotifications = _realtimeNotifications.take(100).toList();
    }
  }

  /// Send WebSocket messages
  void updatePartnerStatus({
    required String status,
    String? location,
    bool? isAvailable,
  }) {
    _webSocketService.updateStatus(
      status: status,
      location: location,
      isAvailable: isAvailable,
    );
  }

  void acceptOrder(String orderId) {
    _webSocketService.acceptOrder(orderId);

    // Remove from new orders list optimistically
    _newOrders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  void updateOrderStatus({
    required String orderId,
    required String status,
    String? location,
    String? notes,
  }) {
    _webSocketService.updateOrderStatus(
      orderId: orderId,
      status: status,
      location: location,
      notes: notes,
    );
  }

  void sendLocationUpdate({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    String? orderId,
  }) {
    _webSocketService.sendLocationUpdate(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      orderId: orderId,
    );
  }

  void sendEmergencyAlert({
    required String type,
    required String message,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? additionalData,
  }) {
    _webSocketService.sendEmergencyAlert(
      type: type,
      message: message,
      latitude: latitude,
      longitude: longitude,
      additionalData: additionalData,
    );
  }

  /// Mark notification as read
  void markNotificationAsRead(String notificationId) {
    final index = _realtimeNotifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      _realtimeNotifications[index]['isRead'] = true;
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllNotificationsAsRead() {
    for (final notification in _realtimeNotifications) {
      notification['isRead'] = true;
    }
    notifyListeners();
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _realtimeNotifications.clear();
    notifyListeners();
  }

  /// Remove emergency alert
  void removeEmergencyAlert(String alertId) {
    _emergencyAlerts.removeWhere((alert) => alert['id'] == alertId);
    notifyListeners();
  }

  /// Disconnect from real-time services
  Future<void> disconnect() async {
    try {
      // Cancel all subscriptions
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();

      // Disconnect WebSocket
      await _webSocketService.disconnect();

      // Clear notification permissions and tokens
      await FirebaseMessagingService.clearAllNotifications();

      // Reset state
      _isWebSocketConnected = false;
      _isFirebaseInitialized = false;
      _realtimeNotifications.clear();
      _newOrders.clear();
      _partnerStatus = null;
      _emergencyAlerts.clear();
      _lastError = null;

      notifyListeners();
    } catch (e) {
      print('Error disconnecting real-time services: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}