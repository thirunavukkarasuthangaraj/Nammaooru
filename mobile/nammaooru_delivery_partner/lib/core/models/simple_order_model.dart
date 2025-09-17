class OrderModel {
  final String id;
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

  OrderModel({
    required this.id,
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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
    };
  }
}