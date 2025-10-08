import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import '../models/delivery_partner.dart';
import '../config/app_config.dart';

class WebSocketService {
  static String get _baseUrl => AppConfig.wsBaseUrl;
  static const int _reconnectInterval = 5; // seconds
  static const int _maxReconnectAttempts = 10;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  String? _partnerId;

  // Stream controllers for different message types
  final StreamController<Map<String, dynamic>> _orderStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _statusStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _emergencyStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();

  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // Getters for streams
  Stream<Map<String, dynamic>> get orderStream => _orderStreamController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusStreamController.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;
  Stream<Map<String, dynamic>> get emergencyStream => _emergencyStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;

  bool get isConnected => _isConnected;
  String? get partnerId => _partnerId;

  /// Connect to WebSocket with delivery partner ID
  Future<void> connect(String partnerId) async {
    _partnerId = partnerId;
    _shouldReconnect = true;
    await _establishConnection();
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (_channel != null) {
      await _channel!.sink.close(status.normalClosure);
      _channel = null;
    }

    _isConnected = false;
    _connectionStreamController.add(false);
    debugPrint('WebSocket disconnected');
  }

  /// Establish WebSocket connection
  Future<void> _establishConnection() async {
    if (_partnerId == null) return;

    try {
      debugPrint('Connecting to WebSocket: $_baseUrl/ws');

      _channel = WebSocketChannel.connect(
        Uri.parse('$_baseUrl/ws'),
        protocols: ['stomp'],
      );

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleConnectionClosed,
      );

      // Send connection frame for STOMP protocol
      _sendStompConnect();

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStreamController.add(true);

      // Start heartbeat
      _startHeartbeat();

      debugPrint('WebSocket connected successfully');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _handleConnectionError();
    }
  }

  /// Send STOMP CONNECT frame
  void _sendStompConnect() {
    const connectFrame = 'CONNECT\n'
        'accept-version:1.0,1.1,2.0\n'
        'heart-beat:10000,10000\n'
        '\n'
        '\x00';

    _channel?.sink.add(connectFrame);

    // Subscribe to partner-specific topics after connection
    Timer(const Duration(seconds: 1), () {
      _subscribeToTopics();
    });
  }

  /// Subscribe to relevant topics
  void _subscribeToTopics() {
    if (_partnerId == null) return;

    // Subscribe to partner-specific queues
    _sendStompSubscribe('/user/$_partnerId/queue/partner/orders', 'orders');
    _sendStompSubscribe('/user/$_partnerId/queue/partner/notifications', 'notifications');
    _sendStompSubscribe('/user/$_partnerId/queue/partner/status', 'status');
    _sendStompSubscribe('/user/$_partnerId/queue/partner/emergency', 'emergency');

    // Subscribe to general topics
    _sendStompSubscribe('/topic/delivery/announcements', 'announcements');
    _sendStompSubscribe('/topic/delivery/orders', 'general-orders');
    _sendStompSubscribe('/topic/tracking/location', 'location-tracking');

    debugPrint('Subscribed to WebSocket topics');
  }

  /// Send STOMP SUBSCRIBE frame
  void _sendStompSubscribe(String destination, String id) {
    final subscribeFrame = 'SUBSCRIBE\n'
        'id:$id\n'
        'destination:$destination\n'
        '\n'
        '\x00';

    _channel?.sink.add(subscribeFrame);
  }

  /// Send STOMP message
  void _sendStompMessage(String destination, Map<String, dynamic> body) {
    if (!_isConnected || _channel == null) {
      debugPrint('Cannot send message: WebSocket not connected');
      return;
    }

    final messageFrame = 'SEND\n'
        'destination:$destination\n'
        'content-type:application/json\n'
        '\n'
        '${jsonEncode(body)}\x00';

    _channel!.sink.add(messageFrame);
  }

  /// Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        if (message.startsWith('CONNECTED')) {
          debugPrint('STOMP connection established');
          return;
        }

        if (message.startsWith('MESSAGE')) {
          _parseStompMessage(message);
        }
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  /// Parse STOMP MESSAGE frame
  void _parseStompMessage(String message) {
    try {
      final lines = message.split('\n');
      String? destination;
      String? subscription;

      // Parse headers
      for (final line in lines) {
        if (line.startsWith('destination:')) {
          destination = line.substring('destination:'.length);
        } else if (line.startsWith('subscription:')) {
          subscription = line.substring('subscription:'.length);
        }
      }

      // Find message body (after empty line)
      final emptyLineIndex = lines.indexOf('');
      if (emptyLineIndex != -1 && emptyLineIndex < lines.length - 1) {
        final bodyLines = lines.sublist(emptyLineIndex + 1);
        final body = bodyLines.join('\n').replaceAll('\x00', '');

        if (body.isNotEmpty) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          _routeMessage(destination, subscription, data);
        }
      }
    } catch (e) {
      debugPrint('Error parsing STOMP message: $e');
    }
  }

  /// Route message to appropriate stream
  void _routeMessage(String? destination, String? subscription, Map<String, dynamic> data) {
    debugPrint('Received message: $subscription - $data');

    switch (subscription) {
      case 'orders':
      case 'general-orders':
        _orderStreamController.add(data);
        break;
      case 'notifications':
      case 'announcements':
        _notificationStreamController.add(data);
        break;
      case 'status':
        _statusStreamController.add(data);
        break;
      case 'emergency':
        _emergencyStreamController.add(data);
        break;
      default:
        debugPrint('Unknown message type: $subscription');
    }
  }

  /// Handle connection errors
  void _handleError(error) {
    debugPrint('WebSocket error: $error');
    _handleConnectionError();
  }

  /// Handle connection closed
  void _handleConnectionClosed() {
    debugPrint('WebSocket connection closed');
    _isConnected = false;
    _connectionStreamController.add(false);
    _handleConnectionError();
  }

  /// Handle connection errors and attempt reconnection
  void _handleConnectionError() {
    _isConnected = false;
    _connectionStreamController.add(false);
    _heartbeatTimer?.cancel();

    if (_shouldReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      debugPrint('Attempting to reconnect (${_reconnectAttempts}/$_maxReconnectAttempts)...');

      _reconnectTimer = Timer(Duration(seconds: _reconnectInterval), () {
        _establishConnection();
      });
    } else {
      debugPrint('Max reconnection attempts reached or reconnection disabled');
    }
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _partnerId != null) {
        sendPing();
      }
    });
  }

  /// Send ping message
  void sendPing() {
    _sendStompMessage('/app/partner/$_partnerId/ping', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Update delivery partner status
  void updateStatus({
    required String status,
    String? location,
    bool? isAvailable,
  }) {
    if (_partnerId == null) return;

    _sendStompMessage('/app/partner/$_partnerId/status', {
      'status': status,
      'location': location,
      'isAvailable': isAvailable,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Accept an order
  void acceptOrder(String orderId) {
    if (_partnerId == null) return;

    _sendStompMessage('/app/partner/$_partnerId/order/$orderId/accept', {
      'orderId': orderId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Update order status
  void updateOrderStatus({
    required String orderId,
    required String status,
    String? location,
    String? notes,
  }) {
    if (_partnerId == null) return;

    _sendStompMessage('/app/partner/$_partnerId/order/$orderId/status', {
      'status': status,
      'location': location,
      'notes': notes,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send location update
  void sendLocationUpdate({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    String? orderId,
  }) {
    if (_partnerId == null) return;

    _sendStompMessage('/app/partner/$_partnerId/location', {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'orderId': orderId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send emergency alert
  void sendEmergencyAlert({
    required String type,
    required String message,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? additionalData,
  }) {
    if (_partnerId == null) return;

    final data = {
      'type': type,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    _sendStompMessage('/app/partner/$_partnerId/emergency', data);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _orderStreamController.close();
    _statusStreamController.close();
    _notificationStreamController.close();
    _emergencyStreamController.close();
    _connectionStreamController.close();
  }
}