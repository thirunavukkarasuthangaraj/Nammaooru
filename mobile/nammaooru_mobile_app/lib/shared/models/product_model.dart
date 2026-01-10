class ProductModel {
  final String id;
  final String name;
  final String? nameTamil;
  final String description;
  final double price;
  final double? discountPrice;
  final String category;
  final String shopId;  // String shop identifier (e.g., "SH616BAAB9")
  final int? shopDatabaseId;  // Numeric shop database ID (e.g., 4)
  final String shopName;
  final List<String> images;
  final int stockQuantity;
  final String unit;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic>? nutritionInfo;
  final List<String> tags;
  final int minStockLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.nameTamil,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.category,
    required this.shopId,
    this.shopDatabaseId,
    required this.shopName,
    this.images = const [],
    this.stockQuantity = 0,
    this.unit = 'piece',
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.nutritionInfo,
    this.tags = const [],
    this.minStockLevel = 5,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Extract Tamil name - check top level first, then masterProduct
    String? tamilName = json['nameTamil'] ??
        json['displayNameTamil'] ??
        (json['masterProduct'] != null ? json['masterProduct']['nameTamil'] : null);

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['displayName'] ?? json['name'] ?? '',
      nameTamil: tamilName,
      description: json['displayDescription'] ?? json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      discountPrice: json['discountPrice']?.toDouble() ?? json['originalPrice']?.toDouble(),
      category: json['category'] ?? '',
      shopId: json['shopId']?.toString() ?? '',
      shopDatabaseId: json['shopDatabaseId'] != null ? int.tryParse(json['shopDatabaseId'].toString()) : null,
      shopName: json['shopName'] ?? '',
      images: _extractImages(json),
      stockQuantity: json['stockQuantity'] ?? 0,
      unit: json['unit'] ?? json['baseUnit'] ?? 'piece',
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      nutritionInfo: json['nutritionInfo'],
      tags: _extractTags(json['tags']),
      minStockLevel: json['minStockLevel'] ?? 5,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static List<String> _extractImages(Map<String, dynamic> json) {
    // Try images array first
    if (json['images'] != null && json['images'] is List) {
      return List<String>.from(json['images']);
    }
    // Try primaryImageUrl
    if (json['primaryImageUrl'] != null) {
      return [json['primaryImageUrl']];
    }
    // Try shopImages
    if (json['shopImages'] != null && json['shopImages'] is List) {
      return (json['shopImages'] as List)
          .map((img) => img['imageUrl']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  static List<String> _extractTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) return List<String>.from(tags);
    if (tags is String) {
      return tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    }
    return [];
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameTamil': nameTamil,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'category': category,
      'shopId': shopId,
      'shopDatabaseId': shopDatabaseId,
      'shopName': shopName,
      'images': images,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'nutritionInfo': nutritionInfo,
      'tags': tags,
      'minStockLevel': minStockLevel,
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
    String? nameTamil,
    String? description,
    double? price,
    double? discountPrice,
    String? category,
    String? shopId,
    int? shopDatabaseId,
    String? shopName,
    List<String>? images,
    int? stockQuantity,
    String? unit,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? nutritionInfo,
    List<String>? tags,
    int? minStockLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameTamil: nameTamil ?? this.nameTamil,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      category: category ?? this.category,
      shopId: shopId ?? this.shopId,
      shopDatabaseId: shopDatabaseId ?? this.shopDatabaseId,
      shopName: shopName ?? this.shopName,
      images: images ?? this.images,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      tags: tags ?? this.tags,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}