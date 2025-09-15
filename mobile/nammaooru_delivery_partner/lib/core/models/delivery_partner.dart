class DeliveryPartner {
  final String partnerId;
  final String name;
  final String phoneNumber;
  final bool isOnline;
  final bool isAvailable;
  final String? profileImageUrl;
  final double earnings;
  final int totalDeliveries;
  final double rating;

  DeliveryPartner({
    required this.partnerId,
    required this.name,
    required this.phoneNumber,
    required this.isOnline,
    required this.isAvailable,
    this.profileImageUrl,
    required this.earnings,
    required this.totalDeliveries,
    required this.rating,
  });

  factory DeliveryPartner.fromJson(Map<String, dynamic> json) {
    return DeliveryPartner(
      partnerId: json['partnerId']?.toString() ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isOnline: json['isOnline'] ?? false,
      isAvailable: json['isAvailable'] ?? false,
      profileImageUrl: json['profileImageUrl'],
      earnings: (json['earnings'] ?? 0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partnerId': partnerId,
      'name': name,
      'phoneNumber': phoneNumber,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'profileImageUrl': profileImageUrl,
      'earnings': earnings,
      'totalDeliveries': totalDeliveries,
      'rating': rating,
    };
  }
}

class DeliveryOrder {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String pickupAddress;
  final String deliveryAddress;
  final double orderValue;
  final double deliveryFee;
  final String status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;

  DeliveryOrder({
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.orderValue,
    required this.deliveryFee,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
    required this.items,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      orderId: json['orderNumber'] ?? json['orderId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      pickupAddress: json['shopAddress'] ?? json['pickupAddress'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      orderValue: (json['totalAmount'] ?? json['orderValue'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      items: (json['items'] as List? ?? []).map((item) => OrderItem.fromJson(item)).toList(),
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

class Earnings {
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double totalEarnings;
  final int todayDeliveries;
  final int weeklyDeliveries;
  final int monthlyDeliveries;
  final int totalDeliveries;
  final List<EarningEntry> recentEarnings;

  Earnings({
    required this.todayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.totalEarnings,
    required this.todayDeliveries,
    required this.weeklyDeliveries,
    required this.monthlyDeliveries,
    required this.totalDeliveries,
    required this.recentEarnings,
  });

  factory Earnings.fromJson(Map<String, dynamic> json) {
    return Earnings(
      todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
      weeklyEarnings: (json['weeklyEarnings'] ?? 0).toDouble(),
      monthlyEarnings: (json['monthlyEarnings'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      todayDeliveries: json['todayDeliveries'] ?? 0,
      weeklyDeliveries: json['weeklyDeliveries'] ?? 0,
      monthlyDeliveries: json['monthlyDeliveries'] ?? 0,
      totalDeliveries: json['totalDeliveries'] ?? 0,
      recentEarnings: (json['recentEarnings'] as List? ?? [])
          .map((entry) => EarningEntry.fromJson(entry))
          .toList(),
    );
  }
}

class EarningEntry {
  final String orderId;
  final double amount;
  final DateTime date;

  EarningEntry({
    required this.orderId,
    required this.amount,
    required this.date,
  });

  factory EarningEntry.fromJson(Map<String, dynamic> json) {
    return EarningEntry(
      orderId: json['orderId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}