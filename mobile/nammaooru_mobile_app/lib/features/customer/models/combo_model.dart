class CustomerCombo {
  final int id;
  final int shopId;
  final String? shopName;
  final String name;
  final String? nameTamil;
  final String? description;
  final String? descriptionTamil;
  final String? bannerImageUrl;
  final double comboPrice;
  final double originalPrice;
  final double savings;
  final double discountPercentage;
  final DateTime endDate;
  final int itemCount;
  final List<CustomerComboItem> items;
  final bool isAvailable;

  CustomerCombo({
    required this.id,
    required this.shopId,
    this.shopName,
    required this.name,
    this.nameTamil,
    this.description,
    this.descriptionTamil,
    this.bannerImageUrl,
    required this.comboPrice,
    required this.originalPrice,
    required this.savings,
    required this.discountPercentage,
    required this.endDate,
    required this.itemCount,
    this.items = const [],
    this.isAvailable = true,
  });

  factory CustomerCombo.fromJson(Map<String, dynamic> json) {
    return CustomerCombo(
      id: json['id'] ?? 0,
      shopId: json['shopId'] ?? 0,
      shopName: json['shopName'],
      name: json['name'] ?? '',
      nameTamil: json['nameTamil'],
      description: json['description'],
      descriptionTamil: json['descriptionTamil'],
      bannerImageUrl: json['bannerImageUrl'],
      comboPrice: (json['comboPrice'] ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      savings: (json['savings'] ?? 0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now().add(const Duration(days: 7)),
      itemCount: json['itemCount'] ?? 0,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => CustomerComboItem.fromJson(e))
              .toList()
          : [],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  String get displayName => nameTamil ?? name;
  String get displayDescription => descriptionTamil ?? description ?? '';
}

class CustomerComboItem {
  final int? id;
  final int shopProductId;
  final String productName;
  final String? productNameTamil;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? unit;
  final String? imageUrl;
  final bool inStock;

  CustomerComboItem({
    this.id,
    required this.shopProductId,
    required this.productName,
    this.productNameTamil,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.unit,
    this.imageUrl,
    this.inStock = true,
  });

  factory CustomerComboItem.fromJson(Map<String, dynamic> json) {
    return CustomerComboItem(
      id: json['id'],
      shopProductId: json['shopProductId'] ?? 0,
      productName: json['productName'] ?? '',
      productNameTamil: json['productNameTamil'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      unit: json['unit'],
      imageUrl: json['imageUrl'],
      inStock: json['inStock'] ?? true,
    );
  }

  String get displayName => productNameTamil ?? productName;
}
