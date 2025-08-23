import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/order_model.dart';

class OrderService {
  // Customer methods
  static Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final response = await ApiClient.get(ApiEndpoints.userOrders(userId));
      final List<dynamic> data = response.data;
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }
  
  static Future<OrderModel> getOrderDetails(String orderId) async {
    try {
      final response = await ApiClient.get(ApiEndpoints.orderDetails(orderId));
      return OrderModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load order details: $e');
    }
  }
  
  static Future<OrderModel> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.orders,
        data: orderData,
      );
      return OrderModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }
  
  static Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      await ApiClient.put(
        ApiEndpoints.updateOrderStatus(orderId),
        data: {
          'status': 'CANCELLED',
          'reason': reason,
        },
      );
      return true;
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }
  
  // Shop owner methods
  static Future<List<OrderModel>> getShopOrders(String shopId) async {
    try {
      final response = await ApiClient.get(ApiEndpoints.shopOrders(shopId));
      final List<dynamic> data = response.data;
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load shop orders: $e');
    }
  }
  
  static Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await ApiClient.put(
        ApiEndpoints.updateOrderStatus(orderId),
        data: {'status': status},
      );
      return true;
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
  
  // Delivery partner methods
  static Future<List<OrderModel>> getDeliveryOrders(String deliveryPartnerId) async {
    try {
      final response = await ApiClient.get(ApiEndpoints.deliveryOrders(deliveryPartnerId));
      final List<dynamic> data = response.data;
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load delivery orders: $e');
    }
  }
  
  static Future<List<OrderModel>> getAvailableDeliveries() async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.orders,
        queryParameters: {'status': 'READY_FOR_PICKUP', 'unassigned': true},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load available deliveries: $e');
    }
  }
  
  static Future<bool> acceptDelivery(String orderId, String deliveryPartnerId) async {
    try {
      await ApiClient.post(
        '${ApiEndpoints.orders}/$orderId/assign',
        data: {'deliveryPartnerId': deliveryPartnerId},
      );
      return true;
    } catch (e) {
      throw Exception('Failed to accept delivery: $e');
    }
  }
  
  static Future<bool> completeDelivery(String orderId) async {
    try {
      await ApiClient.put(
        ApiEndpoints.updateOrderStatus(orderId),
        data: {
          'status': 'DELIVERED',
          'deliveredAt': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      throw Exception('Failed to complete delivery: $e');
    }
  }
  
  // Tracking
  static Future<OrderTracking> trackOrder(String orderId) async {
    try {
      final response = await ApiClient.get(ApiEndpoints.orderTracking(orderId));
      return OrderTracking.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to track order: $e');
    }
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String shopId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String? deliveryPartnerId;
  final DeliveryAddress deliveryAddress;
  final PaymentInfo paymentInfo;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  
  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.shopId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.deliveryPartnerId,
    required this.deliveryAddress,
    required this.paymentInfo,
    required this.createdAt,
    this.deliveredAt,
  });
  
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      shopId: json['shopId'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      deliveryPartnerId: json['deliveryPartnerId'],
      deliveryAddress: DeliveryAddress.fromJson(json['deliveryAddress'] ?? {}),
      paymentInfo: PaymentInfo.fromJson(json['paymentInfo'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'shopId': shopId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'deliveryPartnerId': deliveryPartnerId,
      'deliveryAddress': deliveryAddress.toJson(),
      'paymentInfo': paymentInfo.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;
  
  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });
  
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}

class DeliveryAddress {
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  
  DeliveryAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.latitude,
    this.longitude,
  });
  
  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      landmark: json['landmark'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class PaymentInfo {
  final String method;
  final String status;
  final String? transactionId;
  final DateTime? paidAt;
  
  PaymentInfo({
    required this.method,
    required this.status,
    this.transactionId,
    this.paidAt,
  });
  
  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      method: json['method'] ?? 'CASH',
      status: json['status'] ?? 'PENDING',
      transactionId: json['transactionId'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'status': status,
      'transactionId': transactionId,
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}

class OrderTracking {
  final String orderId;
  final String status;
  final List<TrackingEvent> events;
  final LocationInfo? currentLocation;
  final String? estimatedDeliveryTime;
  
  OrderTracking({
    required this.orderId,
    required this.status,
    required this.events,
    this.currentLocation,
    this.estimatedDeliveryTime,
  });
  
  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      orderId: json['orderId'] ?? '',
      status: json['status'] ?? '',
      events: (json['events'] as List<dynamic>?)
          ?.map((event) => TrackingEvent.fromJson(event))
          .toList() ?? [],
      currentLocation: json['currentLocation'] != null 
          ? LocationInfo.fromJson(json['currentLocation']) 
          : null,
      estimatedDeliveryTime: json['estimatedDeliveryTime'],
    );
  }
}

class TrackingEvent {
  final String status;
  final String description;
  final DateTime timestamp;
  
  TrackingEvent({
    required this.status,
    required this.description,
    required this.timestamp,
  });
  
  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
  
  LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });
  
  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}