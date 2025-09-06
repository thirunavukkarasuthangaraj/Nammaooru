import 'dart:convert';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';

class ShopService {

  Future<ShopListResponse> getShops({
    int page = 0,
    int size = 20,
    String? search,
    String? category,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await ApiClient.get(
        '/customer/shops',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Backend returns statusCode "0000" for success
        if (data['statusCode'] == '0000' && data['data'] != null) {
          return ShopListResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch shops');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch shops');
      }
    } catch (e) {
      throw Exception('Error fetching shops: $e');
    }
  }

  Future<ShopModel> getShopDetails(int shopId) async {
    try {
      final response = await ApiClient.get('/customer/shops/$shopId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['statusCode'] == '0000' && data['data'] != null) {
          return ShopModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch shop details');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch shop details');
      }
    } catch (e) {
      throw Exception('Error fetching shop details: $e');
    }
  }

  Future<List<ShopModel>> getFeaturedShops() async {
    try {
      final response = await ApiClient.get('/shops/featured');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final shops = data['data']['shops'] as List<dynamic>?;
          if (shops != null) {
            return shops.map((shop) => ShopModel.fromJson(shop)).toList();
          }
        }
        return [];
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch featured shops');
      }
    } catch (e) {
      throw Exception('Error fetching featured shops: $e');
    }
  }

  Future<List<ShopModel>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radius = 5.0,
  }) async {
    try {
      final response = await ApiClient.get('/shops/nearby', queryParameters: {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radius.toString(),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final shops = data['data']['shops'] as List<dynamic>?;
          if (shops != null) {
            return shops.map((shop) => ShopModel.fromJson(shop)).toList();
          }
        }
        return [];
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch nearby shops');
      }
    } catch (e) {
      throw Exception('Error fetching nearby shops: $e');
    }
  }

  Future<List<String>> getShopCategories(int shopId) async {
    try {
      final response = await ApiClient.get('/customer/shops/$shopId/categories');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['statusCode'] == '0000' && data['data'] != null) {
          return List<String>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching shop categories: $e');
    }
  }

  Future<ProductListResponse> getShopProducts({
    required int shopId,
    int page = 0,
    int size = 20,
    String? search,
    String? category,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await ApiClient.get(
        '/customer/shops/$shopId/products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['statusCode'] == '0000' && data['data'] != null) {
          return ProductListResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch products');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch products');
      }
    } catch (e) {
      throw Exception('Error fetching shop products: $e');
    }
  }

  Future<ProductModel> getProductDetails({
    required int shopId,
    required int productId,
  }) async {
    try {
      final response = await ApiClient.get('/customer/shops/$shopId/products/$productId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['statusCode'] == '0000' && data['data'] != null) {
          return ProductModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch product details');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch product details');
      }
    } catch (e) {
      throw Exception('Error fetching product details: $e');
    }
  }
}