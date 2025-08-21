import 'product_model.dart';

class CartItem {
  final String id;
  final ProductModel product;
  final int quantity;
  final DateTime addedAt;
  final Map<String, dynamic>? selectedVariants;
  final String? specialInstructions;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
    this.selectedVariants,
    this.specialInstructions,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      product: ProductModel.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 1,
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
      selectedVariants: json['selectedVariants'],
      specialInstructions: json['specialInstructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'selectedVariants': selectedVariants,
      'specialInstructions': specialInstructions,
    };
  }

  double get totalPrice => product.effectivePrice * quantity;
  double get originalTotalPrice => product.price * quantity;
  double get totalSavings => originalTotalPrice - totalPrice;

  CartItem copyWith({
    String? id,
    ProductModel? product,
    int? quantity,
    DateTime? addedAt,
    Map<String, dynamic>? selectedVariants,
    String? specialInstructions,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      selectedVariants: selectedVariants ?? this.selectedVariants,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

class CartSummary {
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double promoDiscount;
  final double total;
  final int itemCount;
  final String? promoCode;

  CartSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.promoDiscount,
    required this.total,
    required this.itemCount,
    this.promoCode,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0.0).toDouble(),
      promoDiscount: (json['promoDiscount'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      itemCount: json['itemCount'] ?? 0,
      promoCode: json['promoCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'taxAmount': taxAmount,
      'promoDiscount': promoDiscount,
      'total': total,
      'itemCount': itemCount,
      'promoCode': promoCode,
    };
  }
}