class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final String status;
  final String? image;
  final String? sku;
  final double? discountPercentage;
  final double? discountedPrice;
  final List<String> tags;
  final Map<String, dynamic>? attributes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int minStock;
  final String unit;
  final String brand;
  final int stockQuantity;
  final int minStockLevel;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.status,
    this.image,
    this.sku,
    this.discountPercentage,
    this.discountedPrice,
    this.tags = const [],
    this.attributes,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.minStock = 0,
    this.unit = 'pcs',
    this.brand = '',
    this.stockQuantity = 0,
    this.minStockLevel = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      category: json['category'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      image: json['image'],
      sku: json['sku'],
      discountPercentage: json['discountPercentage']?.toDouble(),
      discountedPrice: json['discountedPrice']?.toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      attributes: json['attributes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      minStock: json['minStock'] ?? 0,
      unit: json['unit'] ?? 'pcs',
      brand: json['brand'] ?? '',
      stockQuantity: json['stockQuantity'] ?? json['stock'] ?? 0,
      minStockLevel: json['minStockLevel'] ?? json['minStock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'status': status,
      'image': image,
      'sku': sku,
      'discountPercentage': discountPercentage,
      'discountedPrice': discountedPrice,
      'tags': tags,
      'attributes': attributes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'minStock': minStock,
      'unit': unit,
      'brand': brand,
      'stockQuantity': stockQuantity,
      'minStockLevel': minStockLevel,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    String? status,
    String? image,
    String? sku,
    double? discountPercentage,
    double? discountedPrice,
    List<String>? tags,
    Map<String, dynamic>? attributes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? minStock,
    String? unit,
    String? brand,
    int? stockQuantity,
    int? minStockLevel,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      status: status ?? this.status,
      image: image ?? this.image,
      sku: sku ?? this.sku,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      tags: tags ?? this.tags,
      attributes: attributes ?? this.attributes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      brand: brand ?? this.brand,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
    );
  }

  double get finalPrice => discountedPrice ?? price;

  bool get isLowStock => stock <= minStock;

  bool get isOutOfStock => stock <= 0;

  String get stockStatus {
    if (isOutOfStock) return 'OUT_OF_STOCK';
    if (isLowStock) return 'LOW_STOCK';
    return 'IN_STOCK';
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, stock: $stock, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}