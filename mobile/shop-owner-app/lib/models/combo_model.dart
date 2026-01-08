class Combo {
  final int? id;
  final int shopId;
  final String? shopName;
  final String name;
  final String? nameTamil;
  final String? description;
  final String? descriptionTamil;
  final String? bannerImageUrl;
  final double comboPrice;
  final double originalPrice;
  final double? savings;
  final double? discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int maxQuantityPerOrder;
  final int? totalQuantityAvailable;
  final int totalSold;
  final int displayOrder;
  final int itemCount;
  final List<ComboItem> items;
  final String status;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Combo({
    this.id,
    required this.shopId,
    this.shopName,
    required this.name,
    this.nameTamil,
    this.description,
    this.descriptionTamil,
    this.bannerImageUrl,
    required this.comboPrice,
    required this.originalPrice,
    this.savings,
    this.discountPercentage,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.maxQuantityPerOrder = 5,
    this.totalQuantityAvailable,
    this.totalSold = 0,
    this.displayOrder = 0,
    this.itemCount = 0,
    this.items = const [],
    this.status = 'ACTIVE',
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory Combo.fromJson(Map<String, dynamic> json) {
    return Combo(
      id: json['id'],
      shopId: json['shopId'] ?? 0,
      shopName: json['shopName'],
      name: json['name'] ?? '',
      nameTamil: json['nameTamil'],
      description: json['description'],
      descriptionTamil: json['descriptionTamil'],
      bannerImageUrl: json['bannerImageUrl'],
      comboPrice: (json['comboPrice'] ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      savings: json['savings']?.toDouble(),
      discountPercentage: json['discountPercentage']?.toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now().add(const Duration(days: 7)),
      isActive: json['isActive'] ?? true,
      maxQuantityPerOrder: json['maxQuantityPerOrder'] ?? 5,
      totalQuantityAvailable: json['totalQuantityAvailable'],
      totalSold: json['totalSold'] ?? 0,
      displayOrder: json['displayOrder'] ?? 0,
      itemCount: json['itemCount'] ?? 0,
      items: json['items'] != null
          ? (json['items'] as List).map((e) => ComboItem.fromJson(e)).toList()
          : [],
      status: json['status'] ?? 'ACTIVE',
      isAvailable: json['isAvailable'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'nameTamil': nameTamil,
      'description': description,
      'descriptionTamil': descriptionTamil,
      'bannerImageUrl': bannerImageUrl,
      'comboPrice': comboPrice,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'isActive': isActive,
      'maxQuantityPerOrder': maxQuantityPerOrder,
      'totalQuantityAvailable': totalQuantityAvailable,
      'displayOrder': displayOrder,
      'items': items.map((e) => e.toRequestJson()).toList(),
    };
  }

  Combo copyWith({
    int? id,
    int? shopId,
    String? shopName,
    String? name,
    String? nameTamil,
    String? description,
    String? descriptionTamil,
    String? bannerImageUrl,
    double? comboPrice,
    double? originalPrice,
    double? savings,
    double? discountPercentage,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? maxQuantityPerOrder,
    int? totalQuantityAvailable,
    int? totalSold,
    int? displayOrder,
    int? itemCount,
    List<ComboItem>? items,
    String? status,
    bool? isAvailable,
  }) {
    return Combo(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      name: name ?? this.name,
      nameTamil: nameTamil ?? this.nameTamil,
      description: description ?? this.description,
      descriptionTamil: descriptionTamil ?? this.descriptionTamil,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      comboPrice: comboPrice ?? this.comboPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      savings: savings ?? this.savings,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      maxQuantityPerOrder: maxQuantityPerOrder ?? this.maxQuantityPerOrder,
      totalQuantityAvailable:
          totalQuantityAvailable ?? this.totalQuantityAvailable,
      totalSold: totalSold ?? this.totalSold,
      displayOrder: displayOrder ?? this.displayOrder,
      itemCount: itemCount ?? this.itemCount,
      items: items ?? this.items,
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'INACTIVE':
        return 'Inactive';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'EXPIRED':
        return 'Expired';
      case 'OUT_OF_STOCK':
        return 'Out of Stock';
      default:
        return status;
    }
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isScheduled => DateTime.now().isBefore(startDate);
  bool get isCurrentlyActive =>
      isActive && !isExpired && !isScheduled && isAvailable;
}

class ComboItem {
  final int? id;
  final int shopProductId;
  final String productName;
  final String? productNameTamil;
  final String? productDescription;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? unit;
  final String? imageUrl;
  final int? stockQuantity;
  final bool inStock;
  final int displayOrder;

  ComboItem({
    this.id,
    required this.shopProductId,
    required this.productName,
    this.productNameTamil,
    this.productDescription,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.unit,
    this.imageUrl,
    this.stockQuantity,
    this.inStock = true,
    this.displayOrder = 0,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      id: json['id'],
      shopProductId: json['shopProductId'] ?? 0,
      productName: json['productName'] ?? '',
      productNameTamil: json['productNameTamil'],
      productDescription: json['productDescription'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      unit: json['unit'],
      imageUrl: json['imageUrl'],
      stockQuantity: json['stockQuantity'],
      inStock: json['inStock'] ?? true,
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'shopProductId': shopProductId,
      'quantity': quantity,
      'displayOrder': displayOrder,
    };
  }

  ComboItem copyWith({
    int? id,
    int? shopProductId,
    String? productName,
    String? productNameTamil,
    String? productDescription,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? unit,
    String? imageUrl,
    int? stockQuantity,
    bool? inStock,
    int? displayOrder,
  }) {
    return ComboItem(
      id: id ?? this.id,
      shopProductId: shopProductId ?? this.shopProductId,
      productName: productName ?? this.productName,
      productNameTamil: productNameTamil ?? this.productNameTamil,
      productDescription: productDescription ?? this.productDescription,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? (this.unitPrice * (quantity ?? this.quantity)),
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      inStock: inStock ?? this.inStock,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
