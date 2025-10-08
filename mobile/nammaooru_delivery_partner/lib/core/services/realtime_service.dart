import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../services/api_service.dart';
import '../models/simple_order_model.dart';
import '../config/app_config.dart';

/// Real-time service for handling WebSocket connections and live updates
class RealtimeService {
  static const String _wsBaseUrl = AppConfig.wsApiBaseUrl;

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  String? _partnerId;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = AppConfig.maxReconnectAttempts;

  // Event streams
  final StreamController<OrderModel> _newOrderController = StreamController<OrderModel>.broadcast();
  final StreamController<Map<String, dynamic>> _orderUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _systemMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  // Singleton pattern
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  // Stream getters
  Stream<OrderModel> get newOrderStream => _newOrderController.stream;
  Stream<Map<String, dynamic>> get orderUpdateStream => _orderUpdateController.stream;
  Stream<Map<String, dynamic>> get systemMessageStream => _systemMessageController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected => _isConnected;
  String? get partnerId => _partnerId;

  /// Connect to WebSocket server
  Future<void> connect(String partnerId) async {
    if (_isConnected && _partnerId == partnerId) {
      print('🌐 Already connected to real-time service');
      return;
    }

    _partnerId = partnerId;
    await _connectToServer();
  }

  /// Internal WebSocket connection logic
  Future<void> _connectToServer() async {
    try {
      // Close existing connection if any
      await disconnect();

      final wsUrl = '$_wsBaseUrl/delivery-partner/$_partnerId';
      print('🔌 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to connection
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Send initial authentication
      _sendMessage({
        'type': 'auth',
        'partnerId': _partnerId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Start ping timer to keep connection alive
      _startPingTimer();

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);

      print('✅ WebSocket connected successfully');

    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message.toString());
      final messageType = data['type'] as String?;

      print('📨 Received message: $messageType');

      switch (messageType) {
        case 'auth_success':
          print('🔐 Authentication successful');
          break;

        case 'new_order':
          _handleNewOrder(data);
          break;

        case 'order_update':
          _handleOrderUpdate(data);
          break;

        case 'order_assigned':
          _handleOrderAssigned(data);
          break;

        case 'order_cancelled':
          _handleOrderCancelled(data);
          break;

        case 'system_message':
          _handleSystemMessage(data);
          break;

        case 'location_update_ack':
          // Location update acknowledged
          break;

        case 'pong':
          // Keep-alive response
          break;

        default:
          print('⚠️ Unknown message type: $messageType');
      }

    } catch (e) {
      print('❌ Failed to parse WebSocket message: $e');
    }
  }

  /// Handle new order assignment
  void _handleNewOrder(Map<String, dynamic> data) {
    try {
      final orderData = data['order'];
      if (orderData != null) {
        final order = OrderModel.fromJson(orderData);
        _newOrderController.add(order);

        print('🆕 New order received: ${order.id}');
        print('   Customer: ${order.customerName}');
        print('   Address: ${order.deliveryAddress}');

        // Show notification
        _showOrderNotification(order, 'New Order Available');
      }
    } catch (e) {
      print('❌ Failed to handle new order: $e');
    }
  }

  /// Handle order status updates
  void _handleOrderUpdate(Map<String, dynamic> data) {
    try {
      _orderUpdateController.add(data);

      final orderId = data['orderId'];
      final status = data['status'];

      print('🔄 Order update: $orderId -> $status');

    } catch (e) {
      print('❌ Failed to handle order update: $e');
    }
  }

  /// Handle order assigned to driver
  void _handleOrderAssigned(Map<String, dynamic> data) {
    try {
      final orderData = data['order'];
      if (orderData != null) {
        final order = OrderModel.fromJson(orderData);
        _newOrderController.add(order);

        print('📋 Order assigned: ${order.id}');
        _showOrderNotification(order, 'Order Assigned to You');
      }
    } catch (e) {
      print('❌ Failed to handle order assignment: $e');
    }
  }

  /// Handle order cancellation
  void _handleOrderCancelled(Map<String, dynamic> data) {
    try {
      final orderId = data['orderId'];
      final reason = data['reason'] ?? 'No reason provided';

      _orderUpdateController.add({
        'type': 'cancelled',
        'orderId': orderId,
        'reason': reason,
      });

      print('❌ Order cancelled: $orderId - $reason');

    } catch (e) {
      print('❌ Failed to handle order cancellation: $e');
    }
  }

  /// Handle system messages
  void _handleSystemMessage(Map<String, dynamic> data) {
    try {
      _systemMessageController.add(data);

      final message = data['message'] ?? '';
      final priority = data['priority'] ?? 'normal';

      print('📢 System message [$priority]: $message');

    } catch (e) {
      print('❌ Failed to handle system message: $e');
    }
  }

  /// Show local notification for orders
  void _showOrderNotification(OrderModel order, String title) {
    // This would integrate with a notification service
    // For now, just log the notification
    print('🔔 Notification: $title');
    print('   Order: ${order.id}');
    print('   Customer: ${order.customerName}');
    print('   Amount: ₹${order.totalAmount}');
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('❌ WebSocket error: $error');
    _isConnected = false;
    _connectionStatusController.add(false);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    print('🔌 WebSocket disconnected');
    _isConnected = false;
    _connectionStatusController.add(false);
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  /// Send message to WebSocket server
  void _sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(message));
      } catch (e) {
        print('❌ Failed to send WebSocket message: $e');
      }
    }
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(AppConfig.pingInterval, (timer) {
      if (_isConnected) {
        _sendMessage({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max reconnection attempts reached. Giving up.');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: AppConfig.reconnectDelay.inSeconds * (_reconnectAttempts + 1)); // Exponential backoff

    print('🔄 Scheduling reconnect in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      if (_partnerId != null) {
        _connectToServer();
      }
    });
  }

  /// Send location update via WebSocket
  void sendLocationUpdate({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    int? batteryLevel,
    String? networkType,
    String? orderStatus,
    int? assignmentId,
  }) {
    _sendMessage({
      'type': 'location_update',
      'partnerId': _partnerId,
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
      if (networkType != null) 'networkType': networkType,
      if (orderStatus != null) 'orderStatus': orderStatus,
      if (assignmentId != null) 'assignmentId': assignmentId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    print('🔌 Disconnecting from WebSocket...');

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }

    _isConnected = false;
    _partnerId = null;
    _reconnectAttempts = 0;
    _connectionStatusController.add(false);

    print('✅ WebSocket disconnected');
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _newOrderController.close();
    _orderUpdateController.close();
    _systemMessageController.close();
    _connectionStatusController.close();
  }
}