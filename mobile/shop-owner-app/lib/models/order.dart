enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final OrderAddress? deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? preparedAt;
  final DateTime? deliveredAt;
  final String? notes;
  final int estimatedPreparationTime;
  final String? cancellationReason;
  final Map<String, dynamic>? metadata;
  final String? address;
  final double totalAmount;
  final DateTime? orderDate;
  final DateTime? estimatedDelivery;
  final String? deliveryType;
  final bool? assignedToDeliveryPartner;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.preparedAt,
    this.deliveredAt,
    this.notes,
    this.estimatedPreparationTime = 0,
    this.cancellationReason,
    this.metadata,
    this.address,
    required this.totalAmount,
    this.orderDate,
    this.estimatedDelivery,
    this.deliveryType,
    this.assignedToDeliveryPartner,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      deliveryAddress: json['deliveryAddress'] != null
          ? OrderAddress.fromJson(json['deliveryAddress'])
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      paymentMethod: json['paymentMethod'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      preparedAt: json['preparedAt'] != null ? DateTime.parse(json['preparedAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      notes: json['notes'],
      estimatedPreparationTime: json['estimatedPreparationTime'] ?? 0,
      cancellationReason: json['cancellationReason'],
      metadata: json['metadata'],
      address: json['address'] ?? json['deliveryAddress']?.toString(),
      totalAmount: (json['totalAmount'] ?? json['total'] ?? 0).toDouble(),
      orderDate: json['orderDate'] != null ? DateTime.parse(json['orderDate']) : null,
      estimatedDelivery: json['estimatedDelivery'] != null ? DateTime.parse(json['estimatedDelivery']) : null,
      deliveryType: json['deliveryType'],
      assignedToDeliveryPartner: json['assignedToDeliveryPartner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'deliveryAddress': deliveryAddress?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'preparedAt': preparedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'notes': notes,
      'estimatedPreparationTime': estimatedPreparationTime,
      'cancellationReason': cancellationReason,
      'metadata': metadata,
      'address': address,
      'totalAmount': totalAmount,
      'orderDate': orderDate?.toIso8601String(),
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    OrderAddress? deliveryAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? tax,
    double? deliveryFee,
    double? discount,
    double? total,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? preparedAt,
    DateTime? deliveredAt,
    String? notes,
    int? estimatedPreparationTime,
    String? cancellationReason,
    Map<String, dynamic>? metadata,
    String? address,
    double? totalAmount,
    DateTime? orderDate,
    DateTime? estimatedDelivery,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      preparedAt: preparedAt ?? this.preparedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      estimatedPreparationTime: estimatedPreparationTime ?? this.estimatedPreparationTime,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      metadata: metadata ?? this.metadata,
      address: address ?? this.address,
      totalAmount: totalAmount ?? this.totalAmount,
      orderDate: orderDate ?? this.orderDate,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  bool get canBeAccepted => status == 'PENDING';
  bool get canBePrepared => status == 'CONFIRMED';
  bool get canBeCompleted => status == 'PREPARING';
  bool get canBeCancelled => ['PENDING', 'CONFIRMED'].contains(status);
  bool get isSelfPickup => deliveryType == 'SELF_PICKUP';
  bool get canBeHandedOver => status == 'READY_FOR_PICKUP' && isSelfPickup;

  @override
  String toString() {
    return 'Order(id: $id, customerName: $customerName, total: $total, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;
  final String? image;
  final String? notes;
  final Map<String, dynamic>? customizations;
  final String? productImage;
  final double price;

  double get totalPrice => price * quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.image,
    this.notes,
    this.customizations,
    this.productImage,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      image: json['image'],
      notes: json['notes'],
      customizations: json['customizations'],
      productImage: json['productImage'] ?? json['image'],
      price: (json['price'] ?? json['unitPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'image': image,
      'notes': notes,
      'customizations': customizations,
      'productImage': productImage,
      'price': price,
    };
  }

  OrderItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? total,
    String? image,
    String? notes,
    Map<String, dynamic>? customizations,
    String? productImage,
    double? price,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      image: image ?? this.image,
      notes: notes ?? this.notes,
      customizations: customizations ?? this.customizations,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
    );
  }

  @override
  String toString() {
    return 'OrderItem(productName: $productName, quantity: $quantity, total: $total)';
  }
}

class OrderAddress {
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final double? latitude;
  final double? longitude;

  OrderAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.latitude,
    this.longitude,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
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

  String get fullAddress {
    final parts = [street, landmark, city, state, pincode];
    return parts.where((part) => part != null && part.isNotEmpty).join(', ');
  }

  @override
  String toString() {
    return fullAddress;
  }
}