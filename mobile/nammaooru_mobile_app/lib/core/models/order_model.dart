class Order {
  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final String status;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final List<OrderItem> items;
  final DeliveryAddress deliveryAddress;
  final String? deliveryInstructions;
  final DateTime? estimatedDeliveryTime;
  final List<OrderStatusHistory> statusHistory;
  final String? trackingUrl;
  final String? cancellationReason;

  Order({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    required this.deliveryAddress,
    this.deliveryInstructions,
    this.estimatedDeliveryTime,
    required this.statusHistory,
    this.trackingUrl,
    this.cancellationReason,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber'] ?? '',
      orderDate: DateTime.parse(json['orderDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'PENDING',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'CASH_ON_DELIVERY',
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      deliveryAddress: DeliveryAddress.fromJson(json['deliveryAddress'] ?? {}),
      deliveryInstructions: json['deliveryInstructions'],
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : null,
      statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
          .map((history) => OrderStatusHistory.fromJson(history as Map<String, dynamic>))
          .toList(),
      trackingUrl: json['trackingUrl'],
      cancellationReason: json['cancellationReason'],
    );
  }

  String get statusDisplayText {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Order Placed';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Being Prepared';
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'orange';
      case 'CONFIRMED':
      case 'PREPARING':
        return 'blue';
      case 'READY_FOR_PICKUP':
      case 'OUT_FOR_DELIVERY':
        return 'purple';
      case 'DELIVERED':
        return 'green';
      case 'CANCELLED':
      case 'REFUNDED':
        return 'red';
      default:
        return 'grey';
    }
  }

  bool get canBeCancelled {
    final cancellableStatuses = ['PENDING', 'CONFIRMED'];
    return cancellableStatuses.contains(status.toUpperCase());
  }

  bool get canBeTracked {
    final trackableStatuses = ['PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY'];
    return trackableStatuses.contains(status.toUpperCase());
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double totalPrice;
  final String shopId;
  final String shopName;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.totalPrice,
    required this.shopId,
    required this.shopName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      shopId: json['shopId']?.toString() ?? '',
      shopName: json['shopName'] ?? '',
    );
  }
}

class DeliveryAddress {
  final String name;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final String type;

  DeliveryAddress({
    required this.name,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.type,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      type: json['type'] ?? 'HOME',
    );
  }

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      if (landmark.isNotEmpty) landmark,
      city,
      state,
      pincode,
    ];
    return parts.join(', ');
  }
}

class OrderStatusHistory {
  final String status;
  final String description;
  final DateTime timestamp;
  final String? location;

  OrderStatusHistory({
    required this.status,
    required this.description,
    required this.timestamp,
    this.location,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      location: json['location'],
    );
  }
}

class OrdersResponse {
  final List<Order> orders;
  final int totalPages;
  final int currentPage;
  final int totalElements;
  final bool hasNext;
  final bool hasPrevious;

  OrdersResponse({
    required this.orders,
    required this.totalPages,
    required this.currentPage,
    required this.totalElements,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      orders: (json['content'] as List<dynamic>? ?? [])
          .map((order) => Order.fromJson(order as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['number'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      hasNext: !(json['last'] ?? true),
      hasPrevious: !(json['first'] ?? true),
    );
  }

  factory OrdersResponse.empty() {
    return OrdersResponse(
      orders: [],
      totalPages: 0,
      currentPage: 0,
      totalElements: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }
}