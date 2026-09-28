import 'dart:convert';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';
import '../../shared/models/product_model.dart' as shop_owner_products;
import '../constants/app_constants.dart';

class ShopService {

  /// Get the current shop owner's shop details
  Future<ShopModel> getMyShop() async {
    try {
      final response = await ApiClient.get('/shops/my-shop');

      if (response.statusCode == 200) {
        final data = response.data;
        // Backend may return data directly or wrapped in ApiResponse
        if (data is Map<String, dynamic>) {
          // Check if it's wrapped in ApiResponse
          if (data['statusCode'] == AppConstants.successCode && data['data'] != null) {
            return ShopModel.fromJson(data['data']);
          }
          // If data has 'id' field, it's a direct ShopModel response
          if (data.containsKey('id')) {
            return ShopModel.fromJson(data);
          }
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch my shop');
      }
    } catch (e) {
      throw Exception('Error fetching my shop: $e');
    }
  }

  /// Fetch the current shop owner's own products (server resolves the shop
  /// from the authenticated user - no shop id needed here).
  Future<List<shop_owner_products.ProductModel>> getMyShopProducts({
    int page = 0,
    int size = 100,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await ApiClient.get(
        '/shop-products/my-products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['statusCode'] == AppConstants.successCode && data['data'] != null) {
          final content = data['data']['content'] as List<dynamic>? ?? [];
          return content
              .map((item) => shop_owner_products.ProductModel.fromJson(item))
              .toList();
        }
        return [];
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch my products');
      }
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e, 'Failed to fetch my products'));
    } catch (e) {
      throw Exception('Error fetching my products: $e');
    }
  }

  /// Browse the master catalog for products this shop hasn't added yet.
  /// Returns {'items': List<Map>, 'hasMore': bool}.
  Future<Map<String, dynamic>> getAvailableMasterProducts({
    int page = 0,
    int size = 20,
    int? categoryId,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };
      if (categoryId != null) queryParams['categoryId'] = categoryId.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await ApiClient.get(
        '/shop-products/available-master-products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['statusCode'] == AppConstants.successCode && data['data'] != null) {
          final pageData = data['data'];
          final content = pageData['content'] as List<dynamic>? ?? [];
          final totalPages = pageData['totalPages'] ?? 1;
          return {
            'items': content.cast<Map<String, dynamic>>(),
            'hasMore': (page + 1) < totalPages,
          };
        }
        return {'items': <Map<String, dynamic>>[], 'hasMore': false};
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch catalog products');
      }
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e, 'Failed to fetch catalog products'));
    } catch (e) {
      throw Exception('Error fetching catalog products: $e');
    }
  }

  /// Add a master-catalog product to this shop with the owner's own price.
  Future<void> addProductToShop({
    required int masterProductId,
    required double price,
    double? originalPrice,
    double? costPrice,
    int stockQuantity = 0,
    int minStockLevel = 5,
  }) async {
    try {
      final body = <String, dynamic>{
        'masterProductId': masterProductId,
        'price': price,
        'stockQuantity': stockQuantity,
        'minStockLevel': minStockLevel,
        'trackInventory': true,
        'status': 'ACTIVE',
        'isAvailable': true,
        'isFeatured': false,
      };
      if (originalPrice != null) body['originalPrice'] = originalPrice;
      if (costPrice != null) body['costPrice'] = costPrice;

      final response = await ApiClient.post('/shop-products/create', data: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('HTTP ${response.statusCode}: Failed to add product');
      }
      final data = response.data;
      if (data['statusCode'] != null && data['statusCode'] != AppConstants.successCode) {
        throw Exception(data['message'] ?? 'Failed to add product');
      }
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e, 'Failed to add product'));
    }
  }

  /// Partial update of price/MRP/stock for an existing shop product.
  /// Deliberately omits category fields to avoid the quick-update category-echo bug.
  Future<void> updateShopProductQuick(
    int productId, {
    double? price,
    double? originalPrice,
    int? stockQuantity,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (price != null) body['price'] = price;
      if (originalPrice != null) body['originalPrice'] = originalPrice;
      if (stockQuantity != null) body['stockQuantity'] = stockQuantity;

      final response = await ApiClient.patch(
        '/shop-products/$productId/quick-update',
        data: body,
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to update product');
      }
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e, 'Failed to update product'));
    }
  }

  /// Remove a product from this shop (server resolves the shop from the
  /// authenticated user, so no shop id is needed here).
  Future<void> deleteShopProduct(int productId) async {
    try {
      final response = await ApiClient.delete('/shop-products/$productId');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to delete product');
      }
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e, 'Failed to delete product'));
    }
  }

  String _dioErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (e.response?.statusCode == 403) {
      return 'Not authorized as a shop owner for this action';
    }
    return fallback;
  }

  /// Toggle self-delivery for the shop owner's own shop (owner delivers orders
  /// themselves instead of a delivery partner being searched).
  Future<void> updateSelfDelivery(String shopId, bool enabled) async {
    try {
      final response = await ApiClient.put(
        '/shops/$shopId',
        data: {'selfDeliveryEnabled': enabled},
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to update self-delivery setting');
      }
    } catch (e) {
      throw Exception('Error updating self-delivery setting: $e');
    }
  }

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
        // Backend returns ApiResponse with statusCode "0000" for success
        if (data['statusCode'] == AppConstants.successCode && data['data'] != null) {
          return ShopListResponse.fromJson(data['data']);
        } else {
          throw Exception(AppConstants.errorCodes[data['statusCode']] ?? data['message'] ?? 'Failed to fetch shops');
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
        if (data['statusCode'] == AppConstants.successCode && data['data'] != null) {
          return ShopModel.fromJson(data['data']);
        } else {
          throw Exception(AppConstants.errorCodes[data['statusCode']] ?? data['message'] ?? 'Failed to fetch shop details');
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
        if (data['statusCode'] == AppConstants.successCode && data['data'] != null) {
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
        if (data['statusCode'] == AppConstants.successCode && data['data'] != null) {
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
        if (data['statusCode'] == AppConstants.successCode && data['data'] != null) {
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
        if (data['statusCode'] == AppConstants.successCode && data['data'] != null) {
          return ProductListResponse.fromJson(data['data']);
        } else {
          throw Exception(AppConstants.errorCodes[data['statusCode']] ?? data['message'] ?? 'Failed to fetch products');
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
        if (data['statusCode'] == AppConstants.successCode && data['data'] != null) {
          return ProductModel.fromJson(data['data']);
        } else {
          throw Exception(AppConstants.errorCodes[data['statusCode']] ?? data['message'] ?? 'Failed to fetch product details');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch product details');
      }
    } catch (e) {
      throw Exception('Error fetching product details: $e');
    }
  }
}