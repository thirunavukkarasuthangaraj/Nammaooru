class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String category;
  final String shopId;
  final String shopName;
  final List<String> images;
  final int stockQuantity;
  final String unit;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic>? nutritionInfo;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.category,
    required this.shopId,
    required this.shopName,
    this.images = const [],
    this.stockQuantity = 0,
    this.unit = 'piece',
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.nutritionInfo,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      discountPrice: json['discountPrice']?.toDouble(),
      category: json['category'] ?? '',
      shopId: json['shopId'] ?? '',
      shopName: json['shopName'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      stockQuantity: json['stockQuantity'] ?? 0,
      unit: json['unit'] ?? 'piece',
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      nutritionInfo: json['nutritionInfo'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'category': category,
      'shopId': shopId,
      'shopName': shopName,
      'images': images,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'nutritionInfo': nutritionInfo,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  double get effectivePrice => discountPrice ?? price;
  
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  
  double get discountPercentage {
    if (!hasDiscount) return 0.0;
    return ((price - discountPrice!) / price) * 100;
  }
  
  bool get isInStock => stockQuantity > 0;
  
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? category,
    String? shopId,
    String? shopName,
    List<String>? images,
    int? stockQuantity,
    String? unit,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? nutritionInfo,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      category: category ?? this.category,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      images: images ?? this.images,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}