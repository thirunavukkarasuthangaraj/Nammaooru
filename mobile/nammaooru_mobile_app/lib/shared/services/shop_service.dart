import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/shop_model.dart';

class ShopService {
  static Future<List<ShopModel>> getAllShops() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.shops);
      final List<dynamic> data = response.data;
      return data.map((json) => ShopModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load shops: $e');
    }
  }
  
  static Future<ShopModel> getShopDetails(String shopId) async {
    try {
      final response = await ApiClient.get('${ApiEndpoints.shops}/$shopId');
      return ShopModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load shop details: $e');
    }
  }
  
  static Future<List<ShopModel>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0,
  }) async {
    try {
      final response = await ApiClient.get(
        '${ApiEndpoints.shops}/nearby',
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radius': radiusInKm,
        },
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ShopModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load nearby shops: $e');
    }
  }
  
  static Future<List<ShopModel>> searchShops(String query) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.shops,
        queryParameters: {'search': query},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ShopModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search shops: $e');
    }
  }
  
  static Future<List<ShopModel>> getShopsByCategory(String category) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.shops,
        queryParameters: {'category': category},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ShopModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load shops by category: $e');
    }
  }
  
  static Future<bool> toggleFavorite(String shopId) async {
    try {
      final response = await ApiClient.post(
        '${ApiEndpoints.shops}/$shopId/favorite',
      );
      return response.data['isFavorite'] ?? false;
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }
  
  static Future<List<ShopModel>> getFavoriteShops() async {
    try {
      final response = await ApiClient.get('${ApiEndpoints.shops}/favorites');
      final List<dynamic> data = response.data;
      return data.map((json) => ShopModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load favorite shops: $e');
    }
  }
  
  // Shop owner methods
  static Future<ShopModel> updateShopDetails(String shopId, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put(
        '${ApiEndpoints.shops}/$shopId',
        data: data,
      );
      return ShopModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update shop details: $e');
    }
  }
  
  static Future<bool> updateShopStatus(String shopId, bool isOpen) async {
    try {
      await ApiClient.put(
        '${ApiEndpoints.shops}/$shopId/status',
        data: {'isOpen': isOpen},
      );
      return true;
    } catch (e) {
      throw Exception('Failed to update shop status: $e');
    }
  }
  
  static Future<ShopAnalytics> getShopAnalytics(String shopId) async {
    try {
      final response = await ApiClient.get(ApiEndpoints.shopAnalytics(shopId));
      return ShopAnalytics.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load shop analytics: $e');
    }
  }
}

class ShopModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String ownerId;
  final bool isOpen;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final String? phoneNumber;
  final String? email;
  final WorkingHours? workingHours;
  final double? minimumOrder;
  final double? deliveryCharge;
  final int? estimatedDeliveryTime;
  final bool isFavorite;
  
  ShopModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.ownerId,
    required this.isOpen,
    required this.isVerified,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.phoneNumber,
    this.email,
    this.workingHours,
    this.minimumOrder,
    this.deliveryCharge,
    this.estimatedDeliveryTime,
    this.isFavorite = false,
  });
  
  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      ownerId: json['ownerId'] ?? '',
      isOpen: json['isOpen'] ?? false,
      isVerified: json['isVerified'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      workingHours: json['workingHours'] != null
          ? WorkingHours.fromJson(json['workingHours'])
          : null,
      minimumOrder: json['minimumOrder']?.toDouble(),
      deliveryCharge: json['deliveryCharge']?.toDouble(),
      estimatedDeliveryTime: json['estimatedDeliveryTime'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'isOpen': isOpen,
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'phoneNumber': phoneNumber,
      'email': email,
      'workingHours': workingHours?.toJson(),
      'minimumOrder': minimumOrder,
      'deliveryCharge': deliveryCharge,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'isFavorite': isFavorite,
    };
  }
}

class WorkingHours {
  final String openTime;
  final String closeTime;
  final List<String> workingDays;
  
  WorkingHours({
    required this.openTime,
    required this.closeTime,
    required this.workingDays,
  });
  
  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      openTime: json['openTime'] ?? '09:00',
      closeTime: json['closeTime'] ?? '21:00',
      workingDays: List<String>.from(json['workingDays'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'openTime': openTime,
      'closeTime': closeTime,
      'workingDays': workingDays,
    };
  }
}

class ShopAnalytics {
  final int totalOrders;
  final int todayOrders;
  final double totalRevenue;
  final double todayRevenue;
  final int totalProducts;
  final int outOfStockProducts;
  final double averageRating;
  final int totalReviews;
  final Map<String, int> ordersByStatus;
  final List<DailySales> dailySales;
  final List<TopProduct> topProducts;
  
  ShopAnalytics({
    required this.totalOrders,
    required this.todayOrders,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.totalProducts,
    required this.outOfStockProducts,
    required this.averageRating,
    required this.totalReviews,
    required this.ordersByStatus,
    required this.dailySales,
    required this.topProducts,
  });
  
  factory ShopAnalytics.fromJson(Map<String, dynamic> json) {
    return ShopAnalytics(
      totalOrders: json['totalOrders'] ?? 0,
      todayOrders: json['todayOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      totalProducts: json['totalProducts'] ?? 0,
      outOfStockProducts: json['outOfStockProducts'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ordersByStatus: Map<String, int>.from(json['ordersByStatus'] ?? {}),
      dailySales: (json['dailySales'] as List<dynamic>?)
          ?.map((item) => DailySales.fromJson(item))
          .toList() ?? [],
      topProducts: (json['topProducts'] as List<dynamic>?)
          ?.map((item) => TopProduct.fromJson(item))
          .toList() ?? [],
    );
  }
}

class DailySales {
  final DateTime date;
  final int orders;
  final double revenue;
  
  DailySales({
    required this.date,
    required this.orders,
    required this.revenue,
  });
  
  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      orders: json['orders'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class TopProduct {
  final String productId;
  final String productName;
  final int soldCount;
  final double revenue;
  
  TopProduct({
    required this.productId,
    required this.productName,
    required this.soldCount,
    required this.revenue,
  });
  
  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      soldCount: json['soldCount'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}