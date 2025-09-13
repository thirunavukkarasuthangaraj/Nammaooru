class Order {
  final String id;
  final String orderNumber;
  final Customer customer;
  final Restaurant restaurant;
  final List<OrderItem> items;
  final double totalAmount;
  final double deliveryFee;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryTime;
  final Address deliveryAddress;
  final String? specialInstructions;
  final PaymentMethod paymentMethod;
  final double distance; // in km
  final Duration estimatedDuration;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.restaurant,
    required this.items,
    required this.totalAmount,
    required this.deliveryFee,
    required this.status,
    required this.createdAt,
    this.estimatedDeliveryTime,
    required this.deliveryAddress,
    this.specialInstructions,
    required this.paymentMethod,
    required this.distance,
    required this.estimatedDuration,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customer: Customer.fromJson(json['customer'] ?? {}),
      restaurant: Restaurant.fromJson(json['restaurant'] ?? {}),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : null,
      deliveryAddress: Address.fromJson(json['deliveryAddress'] ?? {}),
      specialInstructions: json['specialInstructions'],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      distance: (json['distance'] ?? 0.0).toDouble(),
      estimatedDuration: Duration(minutes: json['estimatedDurationMinutes'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customer': customer.toJson(),
      'restaurant': restaurant.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'deliveryAddress': deliveryAddress.toJson(),
      'specialInstructions': specialInstructions,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'distance': distance,
      'estimatedDurationMinutes': estimatedDuration.inMinutes,
    };
  }

  String get itemsDescription {
    if (items.isEmpty) return '';
    
    final grouped = <String, int>{};
    for (final item in items) {
      grouped[item.name] = (grouped[item.name] ?? 0) + item.quantity;
    }
    
    return grouped.entries
        .map((e) => '${e.value}x ${e.key}')
        .join(', ');
  }

  String get formattedCreatedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
  rejected,
}

enum PaymentMethod {
  cash,
  card,
  upi,
  wallet,
}

class Customer {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final double? rating;

  const Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.rating,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      rating: json['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'rating': rating,
    };
  }
}

class Restaurant {
  final String id;
  final String name;
  final String phoneNumber;
  final Address address;
  final String? imageUrl;

  const Restaurant({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.imageUrl,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: Address.fromJson(json['address'] ?? {}),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address.toJson(),
      'imageUrl': imageUrl,
    };
  }
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? specialInstructions;

  const OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.specialInstructions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
      specialInstructions: json['specialInstructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'specialInstructions': specialInstructions,
    };
  }
}

class Address {
  final String street;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String? landmark;

  const Address({
    required this.street,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.landmark,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
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
    final parts = [street, area, city, state, pincode].where((part) => part.isNotEmpty);
    return parts.join(', ');
  }

  String get shortAddress {
    return '$area, $city';
  }
}