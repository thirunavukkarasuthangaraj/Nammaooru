class ProductModel {
  final int id;
  final int shopId;
  final String shopName;
  final MasterProductModel? masterProduct;
  final double price;
  final double? originalPrice;
  final double? costPrice;
  final int stockQuantity;
  final int? minStockLevel;
  final int? maxStockLevel;
  final bool trackInventory;
  final String status;
  final bool isAvailable;
  final bool isFeatured;
  final String? customName;
  final String? customDescription;
  final String? customAttributes;
  final String displayName;
  final String displayDescription;
  final int? displayOrder;
  final String? tags;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ProductImageModel> shopImages;
  final String? primaryImageUrl;
  final bool inStock;
  final bool lowStock;
  final double? discountAmount;
  final double? discountPercentage;
  final double? profitMargin;

  ProductModel({
    required this.id,
    required this.shopId,
    required this.shopName,
    this.masterProduct,
    required this.price,
    this.originalPrice,
    this.costPrice,
    required this.stockQuantity,
    this.minStockLevel,
    this.maxStockLevel,
    required this.trackInventory,
    required this.status,
    required this.isAvailable,
    required this.isFeatured,
    this.customName,
    this.customDescription,
    this.customAttributes,
    required this.displayName,
    required this.displayDescription,
    this.displayOrder,
    this.tags,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    required this.shopImages,
    this.primaryImageUrl,
    required this.inStock,
    required this.lowStock,
    this.discountAmount,
    this.discountPercentage,
    this.profitMargin,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      shopId: json['shopId'] ?? 0,
      shopName: json['shopName'] ?? '',
      masterProduct: json['masterProduct'] != null
          ? MasterProductModel.fromJson(json['masterProduct'])
          : null,
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      costPrice: json['costPrice']?.toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      minStockLevel: json['minStockLevel'],
      maxStockLevel: json['maxStockLevel'],
      trackInventory: json['trackInventory'] ?? false,
      status: json['status'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      customName: json['customName'],
      customDescription: json['customDescription'],
      customAttributes: json['customAttributes'],
      displayName: json['displayName'] ?? '',
      displayDescription: json['displayDescription'] ?? '',
      displayOrder: json['displayOrder'],
      tags: json['tags'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      shopImages: (json['shopImages'] as List<dynamic>?)
              ?.map((item) => ProductImageModel.fromJson(item))
              .toList() ??
          [],
      primaryImageUrl: json['primaryImageUrl'],
      inStock: json['inStock'] ?? false,
      lowStock: json['lowStock'] ?? false,
      discountAmount: json['discountAmount']?.toDouble(),
      discountPercentage: json['discountPercentage']?.toDouble(),
      profitMargin: json['profitMargin']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'shopName': shopName,
      'masterProduct': masterProduct?.toJson(),
      'price': price,
      'originalPrice': originalPrice,
      'costPrice': costPrice,
      'stockQuantity': stockQuantity,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'trackInventory': trackInventory,
      'status': status,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'customName': customName,
      'customDescription': customDescription,
      'customAttributes': customAttributes,
      'displayName': displayName,
      'displayDescription': displayDescription,
      'displayOrder': displayOrder,
      'tags': tags,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'shopImages': shopImages.map((img) => img.toJson()).toList(),
      'primaryImageUrl': primaryImageUrl,
      'inStock': inStock,
      'lowStock': lowStock,
      'discountAmount': discountAmount,
      'discountPercentage': discountPercentage,
      'profitMargin': profitMargin,
    };
  }

  String get priceText {
    return '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';
  }

  String? get originalPriceText {
    if (originalPrice == null || originalPrice! <= price) return null;
    return '₹${originalPrice!.toStringAsFixed(originalPrice!.truncateToDouble() == originalPrice! ? 0 : 2)}';
  }

  String? get discountText {
    if (discountPercentage == null || discountPercentage! <= 0) return null;
    return '${discountPercentage!.toStringAsFixed(0)}% OFF';
  }

  String get stockText {
    if (!trackInventory) return 'In Stock';
    if (!inStock) return 'Out of Stock';
    if (lowStock) return 'Low Stock (${stockQuantity} left)';
    return 'In Stock (${stockQuantity})';
  }

  String get imageUrl {
    return primaryImageUrl ?? 'https://via.placeholder.com/300x300/f0f0f0/cccccc?text=No+Image';
  }
}

class MasterProductModel {
  final int id;
  final String name;
  final String? nameTamil;
  final String description;
  final String category;
  final String? subCategory;
  final String? brand;
  final String? model;
  final String? sku;
  final String? barcode;
  final String unit;
  final double? weight;
  final String? weightUnit;
  final Map<String, dynamic>? attributes;
  final List<ProductImageModel> images;

  MasterProductModel({
    required this.id,
    required this.name,
    this.nameTamil,
    required this.description,
    required this.category,
    this.subCategory,
    this.brand,
    this.model,
    this.sku,
    this.barcode,
    required this.unit,
    this.weight,
    this.weightUnit,
    this.attributes,
    required this.images,
  });

  factory MasterProductModel.fromJson(Map<String, dynamic> json) {
    return MasterProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameTamil: json['nameTamil'],
      description: json['description'] ?? '',
      category: json['category'] is Map<String, dynamic>
          ? (json['category']['name'] ?? '')
          : (json['category'] ?? ''),
      subCategory: json['subCategory'],
      brand: json['brand'],
      model: json['model'],
      sku: json['sku'],
      barcode: json['barcode'],
      unit: json['baseUnit'] ?? json['unit'] ?? '',
      weight: json['baseWeight']?.toDouble() ?? json['weight']?.toDouble(),
      weightUnit: json['weightUnit'],
      attributes: json['attributes'],
      images: (json['images'] as List<dynamic>?)
              ?.map((item) => ProductImageModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameTamil': nameTamil,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'brand': brand,
      'model': model,
      'sku': sku,
      'barcode': barcode,
      'unit': unit,
      'weight': weight,
      'weightUnit': weightUnit,
      'attributes': attributes,
      'images': images.map((img) => img.toJson()).toList(),
    };
  }
}

class ProductImageModel {
  final int id;
  final String imageUrl;
  final String? altText;
  final bool isPrimary;
  final int displayOrder;

  ProductImageModel({
    required this.id,
    required this.imageUrl,
    this.altText,
    required this.isPrimary,
    required this.displayOrder,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      altText: json['altText'],
      isPrimary: json['isPrimary'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'altText': altText,
      'isPrimary': isPrimary,
      'displayOrder': displayOrder,
    };
  }
}

class ProductListResponse {
  final List<ProductModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final bool hasNext;
  final bool hasPrevious;

  ProductListResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    return ProductListResponse(
      content: (json['content'] as List<dynamic>?)
              ?.map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      page: json['page'] ?? 0,
      size: json['size'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      first: json['first'] ?? true,
      last: json['last'] ?? true,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
    );
  }
}