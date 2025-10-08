class OrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerPhone;
  final String shopName;
  final String deliveryAddress;
  final String status;
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

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerPhone,
    required this.shopName,
    required this.deliveryAddress,
    required this.status,
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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber'] ?? json['order_number'] ?? 'ORD${json['id']?.toString() ?? ''}',
      customerName: json['customerName'] ?? json['customer_name'] ?? '',
      customerPhone: json['customerPhone'] ?? json['customer_phone'],
      shopName: json['shopName'] ?? json['shop_name'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? json['delivery_address'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null,
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
    );
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