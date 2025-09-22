import '../core/services/api_service.dart';
import '../core/utils/logger.dart';

class ShopApiService {
  final ApiService _apiService = ApiService();

  // Get Active Shops
  Future<Map<String, dynamic>> getActiveShops({
    int page = 0,
    int size = 20,
    String sortBy = 'distance',
    String sortDir = 'asc',
    String? city,
    String? category,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Logger.api('Fetching active shops - page: $page, size: $size');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
        'sortBy': sortBy,
        'sortDir': sortDir,
      };
      
      if (city != null) queryParams['city'] = city;
      if (category != null) queryParams['category'] = category;
      if (latitude != null) queryParams['lat'] = latitude.toString();
      if (longitude != null) queryParams['lng'] = longitude.toString();
      
      final response = await _apiService.get(
        '/customer/shops',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch active shops', 'SHOP', e);
      rethrow;
    }
  }

  // Search Shops
  Future<Map<String, dynamic>> searchShops({
    required String query,
    int page = 0,
    int size = 20,
    String sortBy = 'name',
    String sortDir = 'asc',
  }) async {
    try {
      Logger.api('Searching shops: $query');
      
      final response = await _apiService.get(
        '/shops/search',
        queryParams: {
          'q': query,
          'page': page.toString(),
          'size': size.toString(),
          'sortBy': sortBy,
          'sortDir': sortDir,
        },
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to search shops', 'SHOP', e);
      rethrow;
    }
  }

  // Get Nearby Shops
  Future<Map<String, dynamic>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {
    try {
      Logger.api('Fetching nearby shops - lat: $latitude, lng: $longitude, radius: $radius');
      
      final response = await _apiService.get(
        '/shops/nearby',
        queryParams: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
          'radius': radius.toString(),
        },
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch nearby shops', 'SHOP', e);
      rethrow;
    }
  }

  // Get Featured Shops
  Future<Map<String, dynamic>> getFeaturedShops() async {
    try {
      Logger.api('Fetching featured shops');
      
      final response = await _apiService.get(
        '/shops/featured',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch featured shops', 'SHOP', e);
      rethrow;
    }
  }

  // Get Shop by ID
  Future<Map<String, dynamic>> getShopById(int shopId) async {
    try {
      Logger.api('Fetching shop details: $shopId');
      
      final response = await _apiService.get(
        '/customer/shops/$shopId',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch shop details', 'SHOP', e);
      rethrow;
    }
  }

  // Get Shop by Shop ID
  Future<Map<String, dynamic>> getShopByShopId(String shopId) async {
    try {
      Logger.api('Fetching shop by shop ID: $shopId');
      
      final response = await _apiService.get(
        '/shops/shop-id/$shopId',
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch shop by shop ID', 'SHOP', e);
      rethrow;
    }
  }

  // Get Shop Categories
  Future<Map<String, dynamic>> getShopCategories(int shopId) async {
    try {
      Logger.api('Fetching shop categories: $shopId');

      final response = await _apiService.get(
        '/customer/shops/$shopId/categories',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch shop categories', 'SHOP', e);
      rethrow;
    }
  }

  // Get Available Cities
  Future<Map<String, dynamic>> getCities() async {
    try {
      Logger.api('Fetching available cities');
      
      final response = await _apiService.get(
        '/shops/cities',
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch cities', 'SHOP', e);
      rethrow;
    }
  }

  // Get Shop Products
  Future<Map<String, dynamic>> getShopProducts({
    required String shopId,
    int page = 0,
    int size = 20,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    String sortBy = 'name',
    String sortDir = 'asc',
  }) async {
    try {
      Logger.api('Fetching shop products: $shopId with category: $category');

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (category != null) {
        queryParams['category'] = category;
        Logger.api('Added category parameter: $category');
      } else {
        Logger.api('No category parameter - category is null');
      }
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (inStock != null) queryParams['inStock'] = inStock.toString();
      
      final response = await _apiService.get(
        '/customer/shops/$shopId/products',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch shop products', 'SHOP', e);
      rethrow;
    }
  }

  // Search Shop Products
  Future<Map<String, dynamic>> searchShopProducts({
    required String shopId,
    required String query,
    int page = 0,
    int size = 20,
  }) async {
    try {
      Logger.api('Searching shop products: $shopId - $query');
      
      final response = await _apiService.get(
        '/customer/shops/$shopId/products/search',
        queryParams: {
          'q': query,
          'page': page.toString(),
          'size': size.toString(),
        },
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to search shop products', 'SHOP', e);
      rethrow;
    }
  }

  // Get Product Categories
  Future<Map<String, dynamic>> getProductCategories() async {
    try {
      Logger.api('Fetching product categories');
      
      final response = await _apiService.get(
        '/product-categories',
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch product categories', 'SHOP', e);
      rethrow;
    }
  }

  // Get Master Products
  Future<Map<String, dynamic>> getMasterProducts({
    int page = 0,
    int size = 20,
    String? category,
  }) async {
    try {
      Logger.api('Fetching master products');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      
      if (category != null) queryParams['category'] = category;
      
      final response = await _apiService.get(
        '/master-products',
        queryParams: queryParams,
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch master products', 'SHOP', e);
      rethrow;
    }
  }

  // Get Shop Product by ID
  Future<Map<String, dynamic>> getShopProductById(int productId) async {
    try {
      Logger.api('Fetching shop product: $productId');
      
      final response = await _apiService.get(
        '/shop-products/$productId',
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch shop product', 'SHOP', e);
      rethrow;
    }
  }
}