import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_config.dart';
import 'storage_service.dart';

enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._internal();

  WebSocketService._internal();

  WebSocketChannel? _channel;
  WebSocketState _state = WebSocketState.disconnected;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectInterval = const Duration(seconds: 5);
  final Duration _heartbeatInterval = const Duration(seconds: 30);

  // Event streams
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<WebSocketState> _stateController =
      StreamController<WebSocketState>.broadcast();

  // Getters
  WebSocketState get state => _state;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<WebSocketState> get stateStream => _stateController.stream;
  bool get isConnected => _state == WebSocketState.connected;

  // Initialize and connect
  Future<void> initialize() async {
    await connect();
  }

  // Connect to WebSocket
  Future<void> connect() async {
    if (_state == WebSocketState.connecting || _state == WebSocketState.connected) {
      return;
    }

    try {
      _updateState(WebSocketState.connecting);

      final token = StorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('${AppConfig.webSocketUrl}?token=$token');
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
        cancelOnError: false,
      );

      _updateState(WebSocketState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      print('WebSocket connected successfully');
    } catch (e) {
      _updateState(WebSocketState.error);
      print('WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    _stopHeartbeat();
    _stopReconnectTimer();

    await _channel?.sink.close();
    _channel = null;
    _updateState(WebSocketState.disconnected);

    print('WebSocket disconnected');
  }

  // Send message
  void sendMessage(Map<String, dynamic> message) {
    if (!isConnected) {
      print('Cannot send message: WebSocket not connected');
      return;
    }

    try {
      final jsonMessage = json.encode(message);
      _channel!.sink.add(jsonMessage);
      print('Message sent: $jsonMessage');
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  // Send authentication message
  void sendAuth() {
    final token = StorageService.getToken();
    if (token != null) {
      sendMessage({
        'type': 'auth',
        'token': token,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // Send heartbeat/ping
  void sendHeartbeat() {
    sendMessage({
      'type': 'ping',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Subscribe to specific events
  void subscribe(String eventType) {
    sendMessage({
      'type': 'subscribe',
      'event': eventType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Unsubscribe from events
  void unsubscribe(String eventType) {
    sendMessage({
      'type': 'unsubscribe',
      'event': eventType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Subscribe to all shop-related events
  void subscribeToShopEvents() {
    final events = [
      'new_order',
      'order_updated',
      'payment_confirmed',
      'order_cancelled',
      'customer_message',
      'inventory_alert',
      'system_notification',
    ];

    for (final event in events) {
      subscribe(event);
    }
  }

  // Handle incoming messages
  void _onMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = json.decode(message.toString());
      print('WebSocket message received: $data');

      // Handle different message types
      switch (data['type']) {
        case 'pong':
          // Heartbeat response
          break;
        case 'auth_success':
          print('WebSocket authentication successful');
          subscribeToShopEvents();
          break;
        case 'auth_failed':
          print('WebSocket authentication failed');
          _updateState(WebSocketState.error);
          break;
        case 'new_order':
        case 'order_updated':
        case 'payment_confirmed':
        case 'order_cancelled':
        case 'customer_message':
        case 'inventory_alert':
        case 'system_notification':
          // Forward event data to message stream
          _messageController.add(data);
          break;
        case 'error':
          print('WebSocket server error: ${data['message']}');
          break;
        default:
          // Forward unknown messages to stream
          _messageController.add(data);
      }
    } catch (e) {
      print('Failed to parse WebSocket message: $e');
    }
  }

  // Handle WebSocket errors
  void _onError(error) {
    print('WebSocket error: $error');
    _updateState(WebSocketState.error);
    _scheduleReconnect();
  }

  // Handle WebSocket disconnection
  void _onDisconnected() {
    print('WebSocket disconnected');
    _updateState(WebSocketState.disconnected);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      _updateState(WebSocketState.error);
      return;
    }

    if (_reconnectTimer?.isActive == true) {
      return;
    }

    _reconnectAttempts++;
    print('Scheduling reconnect attempt $_reconnectAttempts in ${_reconnectInterval.inSeconds}s');

    _updateState(WebSocketState.reconnecting);
    _reconnectTimer = Timer(_reconnectInterval, () {
      connect();
    });
  }

  // Start heartbeat timer
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected) {
        sendHeartbeat();
      } else {
        timer.cancel();
      }
    });
  }

  // Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Stop reconnect timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  // Update state and notify listeners
  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  // Get connection status text
  String get statusText {
    switch (_state) {
      case WebSocketState.disconnected:
        return 'Disconnected';
      case WebSocketState.connecting:
        return 'Connecting...';
      case WebSocketState.connected:
        return 'Connected';
      case WebSocketState.reconnecting:
        return 'Reconnecting... ($_reconnectAttempts/$_maxReconnectAttempts)';
      case WebSocketState.error:
        return 'Connection Error';
    }
  }

  // Get connection status color
  Color get statusColor {
    switch (_state) {
      case WebSocketState.disconnected:
        return Colors.grey;
      case WebSocketState.connecting:
      case WebSocketState.reconnecting:
        return Colors.orange;
      case WebSocketState.connected:
        return Colors.green;
      case WebSocketState.error:
        return Colors.red;
    }
  }

  // Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Reconnect if network is available
  Future<void> reconnectIfNeeded() async {
    if (_state == WebSocketState.error || _state == WebSocketState.disconnected) {
      final hasConnectivity = await _checkConnectivity();
      if (hasConnectivity) {
        _reconnectAttempts = 0; // Reset attempts if manually triggered
        await connect();
      }
    }
  }

  // Send order status update
  void sendOrderStatusUpdate(String orderId, String status) {
    sendMessage({
      'type': 'order_status_update',
      'orderId': orderId,
      'status': status,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Send shop status update
  void sendShopStatusUpdate(bool isOpen) {
    sendMessage({
      'type': 'shop_status_update',
      'isOpen': isOpen,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Send typing indicator for customer chat
  void sendTypingIndicator(String customerId, bool isTyping) {
    sendMessage({
      'type': 'typing_indicator',
      'customerId': customerId,
      'isTyping': isTyping,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Send location update
  void sendLocationUpdate(double latitude, double longitude) {
    sendMessage({
      'type': 'location_update',
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Dispose resources
  void dispose() {
    _stopHeartbeat();
    _stopReconnectTimer();
    _channel?.sink.close();
    _messageController.close();
    _stateController.close();
  }
}