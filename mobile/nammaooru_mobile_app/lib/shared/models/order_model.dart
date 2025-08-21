enum OrderStatus {
  pending,
  accepted,
  preparing,
  readyForPickup,
  outForDelivery,
  delivered,
  cancelled,
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String shopId;
  final String shopName;
  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final String? deliveryPartnerPhone;
  final List<OrderItem> items;
  final String deliveryAddress; // Simplified for now
  final OrderStatus status;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double total;
  final String? specialInstructions;
  final DateTime orderDate;
  final DateTime updatedAt;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final List<OrderStatusUpdate> statusHistory;
  
  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.shopId = '',
    this.shopName = '',
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    this.deliveryPartnerPhone,
    required this.items,
    required this.deliveryAddress,
    required this.status,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.total,
    this.specialInstructions,
    required this.orderDate,
    required this.updatedAt,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.statusHistory = const [],
  });

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? shopId,
    String? shopName,
    String? deliveryPartnerId,
    String? deliveryPartnerName,
    String? deliveryPartnerPhone,
    List<OrderItem>? items,
    String? deliveryAddress,
    OrderStatus? status,
    String? paymentMethod,
    String? paymentStatus,
    double? subtotal,
    double? deliveryFee,
    double? taxAmount,
    double? total,
    String? specialInstructions,
    DateTime? orderDate,
    DateTime? updatedAt,
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    List<OrderStatusUpdate>? statusHistory,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      deliveryPartnerId: deliveryPartnerId ?? this.deliveryPartnerId,
      deliveryPartnerName: deliveryPartnerName ?? this.deliveryPartnerName,
      deliveryPartnerPhone: deliveryPartnerPhone ?? this.deliveryPartnerPhone,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      orderDate: orderDate ?? this.orderDate,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
  
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      shopId: json['shopId'] ?? '',
      shopName: json['shopName'] ?? '',
      deliveryPartnerId: json['deliveryPartnerId'],
      deliveryPartnerName: json['deliveryPartnerName'],
      deliveryPartnerPhone: json['deliveryPartnerPhone'],
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      deliveryAddress: json['deliveryAddress'] ?? '',
      status: _statusFromString(json['status'] ?? 'pending'),
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      specialInstructions: json['specialInstructions'],
      orderDate: DateTime.parse(json['orderDate'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : null,
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.parse(json['actualDeliveryTime'])
          : null,
      statusHistory: (json['statusHistory'] as List? ?? [])
          .map((status) => OrderStatusUpdate.fromJson(status))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'shopId': shopId,
      'shopName': shopName,
      'deliveryPartnerId': deliveryPartnerId,
      'deliveryPartnerName': deliveryPartnerName,
      'deliveryPartnerPhone': deliveryPartnerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'deliveryAddress': deliveryAddress,
      'status': _statusToString(status),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'taxAmount': taxAmount,
      'total': total,
      'specialInstructions': specialInstructions,
      'orderDate': orderDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'actualDeliveryTime': actualDeliveryTime?.toIso8601String(),
      'statusHistory': statusHistory.map((status) => status.toJson()).toList(),
    };
  }

  static OrderStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'readyforpickup':
      case 'ready_for_pickup':
        return OrderStatus.readyForPickup;
      case 'outfordelivery':
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static String _statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.readyForPickup:
        return 'ready_for_pickup';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String unit;
  final double totalPrice;
  
  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.totalPrice,
  });
  
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? 'piece',
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'totalPrice': totalPrice,
    };
  }
}

class OrderAddress {
  final String street;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final String? landmark;
  
  OrderAddress({
    required this.street,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.landmark,
  });
  
  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      landmark: json['landmark'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'landmark': landmark,
    };
  }
  
  String get fullAddress {
    final parts = [street, area, city, state, pincode];
    return parts.where((part) => part.isNotEmpty).join(', ');
  }
}

class OrderStatusUpdate {
  final String status;
  final DateTime timestamp;
  final String? notes;
  final String? updatedBy;
  
  OrderStatusUpdate({
    required this.status,
    required this.timestamp,
    this.notes,
    this.updatedBy,
  });
  
  factory OrderStatusUpdate.fromJson(Map<String, dynamic> json) {
    return OrderStatusUpdate(
      status: json['status'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
      updatedBy: json['updatedBy'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'updatedBy': updatedBy,
    };
  }
}