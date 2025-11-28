class ShopModel {
  final int id;
  final String name;
  final String description;
  final String? shopId;
  final String? slug;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;
  final String? businessName;
  final String? businessType;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final double? minOrderAmount;
  final double? deliveryRadius;
  final double? deliveryFee;
  final double? freeDeliveryAbove;
  final double? commissionRate;
  final String? gstNumber;
  final String? panNumber;
  final String? status;
  final bool isActive;
  final bool isVerified;
  final bool isFeatured;
  final double? rating;
  final int? totalOrders;
  final double? totalRevenue;
  final int? productCount;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ShopImage>? images;

  ShopModel({
    required this.id,
    required this.name,
    required this.description,
    this.shopId,
    this.slug,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    this.businessName,
    this.businessType,
    this.addressLine1,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    this.minOrderAmount,
    this.deliveryRadius,
    this.deliveryFee,
    this.freeDeliveryAbove,
    this.commissionRate,
    this.gstNumber,
    this.panNumber,
    this.status,
    required this.isActive,
    required this.isVerified,
    required this.isFeatured,
    this.rating,
    this.totalOrders,
    this.totalRevenue,
    this.productCount,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.images,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      shopId: json['shopId'],
      slug: json['slug'],
      ownerName: json['ownerName'],
      ownerEmail: json['ownerEmail'],
      ownerPhone: json['ownerPhone'],
      businessName: json['businessName'],
      businessType: json['businessType'],
      addressLine1: json['addressLine1'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      minOrderAmount: json['minOrderAmount']?.toDouble(),
      deliveryRadius: json['deliveryRadius']?.toDouble(),
      deliveryFee: json['deliveryFee']?.toDouble(),
      freeDeliveryAbove: json['freeDeliveryAbove']?.toDouble(),
      commissionRate: json['commissionRate']?.toDouble(),
      gstNumber: json['gstNumber'],
      panNumber: json['panNumber'],
      status: json['status'],
      isActive: json['isActive'] ?? false,
      isVerified: json['isVerified'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      rating: json['rating']?.toDouble(),
      totalOrders: json['totalOrders'],
      totalRevenue: json['totalRevenue']?.toDouble(),
      productCount: json['productCount'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      images: json['images'] != null
          ? (json['images'] as List).map((img) => ShopImage.fromJson(img)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'shopId': shopId,
      'slug': slug,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPhone': ownerPhone,
      'businessName': businessName,
      'businessType': businessType,
      'addressLine1': addressLine1,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'minOrderAmount': minOrderAmount,
      'deliveryRadius': deliveryRadius,
      'deliveryFee': deliveryFee,
      'freeDeliveryAbove': freeDeliveryAbove,
      'commissionRate': commissionRate,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'status': status,
      'isActive': isActive,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'rating': rating,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'productCount': productCount,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get displayAddress {
    List<String> addressParts = [];
    if (addressLine1 != null && addressLine1!.isNotEmpty) addressParts.add(addressLine1!);
    if (city != null && city!.isNotEmpty) addressParts.add(city!);
    if (state != null && state!.isNotEmpty) addressParts.add(state!);
    return addressParts.join(', ');
  }

  String get ratingText {
    if (rating == null) return 'New';
    return rating!.toStringAsFixed(1);
  }

  String get deliveryText {
    if (deliveryFee == null || deliveryFee == 0) {
      return 'Free Delivery';
    }
    if (freeDeliveryAbove != null && freeDeliveryAbove! > 0) {
      return 'Free above ₹${freeDeliveryAbove!.toStringAsFixed(0)}';
    }
    return '₹${deliveryFee!.toStringAsFixed(0)} delivery';
  }

  String get minOrderText {
    if (minOrderAmount == null || minOrderAmount == 0) {
      return 'No minimum order';
    }
    return 'Min order ₹${minOrderAmount!.toStringAsFixed(0)}';
  }

  /// Get the shop logo URL
  String? get logoUrl {
    if (images == null || images!.isEmpty) return null;
    // Find LOGO type first, then primary, then first image
    final logo = images!.firstWhere(
      (img) => img.imageType == 'LOGO',
      orElse: () => images!.firstWhere(
        (img) => img.isPrimary == true,
        orElse: () => images!.first,
      ),
    );
    return logo.imageUrl;
  }
}

class ShopListResponse {
  final List<ShopModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final bool hasNext;
  final bool hasPrevious;

  ShopListResponse({
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

  factory ShopListResponse.fromJson(Map<String, dynamic> json) {
    return ShopListResponse(
      content: (json['content'] as List<dynamic>?)
              ?.map((item) => ShopModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      page: json['number'] ?? json['page'] ?? 0,  // Backend uses 'number' instead of 'page'
      size: json['size'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      first: json['first'] ?? true,
      last: json['last'] ?? true,
      hasNext: !(json['last'] ?? true),  // Calculate hasNext based on 'last'
      hasPrevious: !(json['first'] ?? true),  // Calculate hasPrevious based on 'first'
    );
  }
}

class ShopImage {
  final int id;
  final String imageUrl;
  final String? imageType;
  final bool? isPrimary;
  final DateTime? createdAt;

  ShopImage({
    required this.id,
    required this.imageUrl,
    this.imageType,
    this.isPrimary,
    this.createdAt,
  });

  factory ShopImage.fromJson(Map<String, dynamic> json) {
    return ShopImage(
      id: json['id'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      imageType: json['imageType'],
      isPrimary: json['isPrimary'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'imageType': imageType,
      'isPrimary': isPrimary,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}