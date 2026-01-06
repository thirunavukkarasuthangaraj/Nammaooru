class OrderItemModel {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;

  OrderItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      name: json['productName'] ?? json['name'] ?? 'Product',
      quantity: json['quantity'] ?? 1,
      price: (json['unitPrice'] ?? json['price'] ?? json['totalPrice'] ?? 0.0).toDouble(),
      imageUrl: json['productImageUrl'] ?? json['imageUrl'],
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerPhone;
  final String shopName;
  final String deliveryAddress;
  final String status;
  final String? orderStatus; // The actual order status (for cancelled orders)
  final String? assignmentStatus; // The assignment status
  final DateTime? createdAt;
  final double? distance;
  final double? commission;
  final double? deliveryFee;
  final double? totalAmount;
  final String? assignmentId;
  final double? shopLatitude;
  final double? shopLongitude;
  final double? customerLatitude;
  final double? customerLongitude;
  final String? pickupOtp;
  final String? paymentMethod;
  final String? paymentStatus;
  final List<OrderItemModel>? items;

  /// Check if order is cancelled (either by status or orderStatus)
  bool get isCancelled => status.toLowerCase() == 'cancelled' ||
      orderStatus?.toLowerCase() == 'cancelled';

  /// Check if driver needs to return to shop
  bool get needsReturnToShop => isCancelled && assignmentStatus?.toLowerCase() != 'returned';

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerPhone,
    required this.shopName,
    required this.deliveryAddress,
    required this.status,
    this.orderStatus,
    this.assignmentStatus,
    this.createdAt,
    this.distance,
    this.commission,
    this.deliveryFee,
    this.totalAmount,
    this.assignmentId,
    this.shopLatitude,
    this.shopLongitude,
    this.customerLatitude,
    this.customerLongitude,
    this.pickupOtp,
    this.paymentMethod,
    this.paymentStatus,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse items from various possible field names
    List<OrderItemModel>? parsedItems;
    final itemsJson = json['items'] ?? json['orderItems'] ?? json['order_items'];
    if (itemsJson != null && itemsJson is List) {
      parsedItems = itemsJson.map((item) => OrderItemModel.fromJson(item)).toList();
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber'] ?? json['order_number'] ?? 'ORD${json['id']?.toString() ?? ''}',
      customerName: json['customerName'] ?? json['customer_name'] ?? '',
      customerPhone: json['customerPhone'] ?? json['customer_phone'],
      shopName: json['shopName'] ?? json['shop_name'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? json['delivery_address'] ?? '',
      status: json['status'] ?? 'pending',
      orderStatus: json['orderStatus'] ?? json['order_status'],
      assignmentStatus: json['assignmentStatus'] ?? json['assignment_status'],
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      distance: json['distance']?.toDouble(),
      commission: json['commission']?.toDouble(),
      deliveryFee: json['deliveryFee']?.toDouble() ?? json['delivery_fee']?.toDouble(),
      totalAmount: json['totalAmount']?.toDouble() ?? json['total_amount']?.toDouble(),
      assignmentId: json['assignmentId']?.toString() ?? json['assignment_id']?.toString(),
      shopLatitude: json['shopLatitude']?.toDouble() ?? json['shop_latitude']?.toDouble(),
      shopLongitude: json['shopLongitude']?.toDouble() ?? json['shop_longitude']?.toDouble(),
      customerLatitude: json['customerLatitude']?.toDouble() ?? json['customer_latitude']?.toDouble(),
      customerLongitude: json['customerLongitude']?.toDouble() ?? json['customer_longitude']?.toDouble(),
      pickupOtp: json['pickupOtp'] ?? json['pickup_otp'],
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      paymentStatus: json['paymentStatus'] ?? json['payment_status'],
      items: parsedItems,
    );
  }

  /// Parse datetime and convert UTC to local time (IST +5:30)
  static DateTime? _parseDateTime(dynamic dateStr) {
    if (dateStr == null) return null;

    final parsed = DateTime.tryParse(dateStr.toString());
    if (parsed == null) return null;

    // If the string doesn't contain timezone info, assume UTC and convert to local
    // Backend returns time without 'Z' suffix but it's actually UTC
    if (!dateStr.toString().contains('Z') && !dateStr.toString().contains('+')) {
      // Add 5:30 hours to convert UTC to IST
      return parsed.add(const Duration(hours: 5, minutes: 30));
    }

    // If it has timezone info, convert to local
    return parsed.toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'shopName': shopName,
      'deliveryAddress': deliveryAddress,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'distance': distance,
      'commission': commission,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'assignmentId': assignmentId,
      'shopLatitude': shopLatitude,
      'shopLongitude': shopLongitude,
      'customerLatitude': customerLatitude,
      'customerLongitude': customerLongitude,
      'pickupOtp': pickupOtp,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    };
  }
}