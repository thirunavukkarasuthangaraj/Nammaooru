import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/services/api_service.dart';
import '../core/utils/logger.dart';

class ShopApiService {
  final ApiService _apiService = ApiService();

  // Get Active Shops
  Future<Map<String, dynamic>> getActiveShops({
    int page = 0,
    int size = 20,
    String sortBy = 'name',
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

      // City filter removed - location-based filtering will be added later
      // if (city != null) queryParams['city'] = city;
      if (category != null) queryParams['category'] = category;
      // TEMPORARILY DISABLED: Location-based filtering
      // if (latitude != null) queryParams['lat'] = latitude.toString();
      // if (longitude != null) queryParams['lng'] = longitude.toString();
      
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

  /// Search villages/towns where registered shops exist — resolves places
  /// like "Mittur" from our own shop addresses when geocoders don't know them.
  Future<List<Map<String, dynamic>>> searchShopLocations(String query) async {
    try {
      final response = await _apiService.get(
        '/shops/locations/search',
        queryParams: {'q': query},
        includeAuth: true,
      );
      final data = response['data'];
      final locations = (data is Map ? data['locations'] : null) as List?;
      if (locations == null) return [];
      return locations
          .whereType<Map>()
          .map((l) => {
                'name': l['name']?.toString() ?? '',
                'latitude': (l['latitude'] as num?)?.toDouble(),
                'longitude': (l['longitude'] as num?)?.toDouble(),
              })
          .where((l) =>
              (l['name'] as String).isNotEmpty &&
              l['latitude'] != null &&
              l['longitude'] != null)
          .toList();
    } catch (e) {
      Logger.e('Shop location search failed', 'SHOP', e);
      return [];
    }
  }

  // Nearest registered shop's city/pincode/state for a raw coordinate — used
  // as a fallback when on-device reverse geocoding returns no postal code
  // for a rural pin, which is common outside well-mapped towns.
  Future<Map<String, String>?> getNearestShopLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiService.get(
        '/shops/locations/nearest',
        queryParams: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
        },
        includeAuth: true,
      );
      final data = response['data'];
      if (data is! Map || data['postalCode'] == null) return null;
      return {
        'city': data['city']?.toString() ?? '',
        'postalCode': data['postalCode'].toString(),
        'state': data['state']?.toString() ?? '',
      };
    } catch (e) {
      Logger.e('Nearest shop location lookup failed', 'SHOP', e);
      return null;
    }
  }

  // Whether the "Register Your Shop" CTA should be hidden for this village
  // name + category (admin-configured per-village in Villages management).
  // Fails open (false = show the button) on any error, since a broken check
  // shouldn't silently hide a real CTA from customers.
  Future<bool> isShopRegistrationCtaHidden({
    required String villageName,
    required String category,
  }) async {
    try {
      final response = await _apiService.get(
        '/villages/registration-cta-hidden',
        queryParams: {
          'name': villageName,
          'category': category,
        },
        includeAuth: false,
      );
      return response['data'] == true;
    } catch (e) {
      Logger.e('Registration CTA visibility check failed', 'SHOP', e);
      return false;
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

  // Register a new shop (self-service). Hits the same POST /api/shops
  // endpoint the website's "Add New Shop" form uses, so registrations made
  // here show up identically in the admin/shop-owner web apps and trigger
  // the same confirmation email.
  Future<Map<String, dynamic>> createShop({
    required String name,
    String? description,
    String? businessName,
    required String businessType,
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
    required String addressLine1,
    required String city,
    required String state,
    required String postalCode,
    String country = 'India',
    double? latitude,
    double? longitude,
    double? minOrderAmount,
    double? deliveryRadius,
    double? freeDeliveryAbove,
    bool selfDeliveryEnabled = false,
  }) async {
    try {
      Logger.api('Registering new shop: $name ($businessType)');

      final data = <String, dynamic>{
        'name': name,
        'businessName': (businessName != null && businessName.isNotEmpty) ? businessName : name,
        'businessType': businessType,
        'ownerName': ownerName,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
        'addressLine1': addressLine1,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
        'selfDeliveryEnabled': selfDeliveryEnabled,
      };

      if (description != null && description.isNotEmpty) data['description'] = description;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (minOrderAmount != null) data['minOrderAmount'] = minOrderAmount;
      if (deliveryRadius != null) data['deliveryRadius'] = deliveryRadius;
      if (freeDeliveryAbove != null) data['freeDeliveryAbove'] = freeDeliveryAbove;

      final response = await _apiService.post(
        '/shops',
        data: data,
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to register shop', 'SHOP', e);
      rethrow;
    }
  }

  // Upload a verification document (owner photo / shop photo / FSSAI certificate)
  // for a newly registered shop. Requires the caller to be logged in as the
  // shop's owner (ApiClient attaches the auth token automatically).
  Future<Map<String, dynamic>> uploadShopDocument({
    required int shopId,
    required String documentType,
    required String documentName,
    required File file,
  }) async {
    try {
      Logger.api('Uploading shop document: $documentType for shop $shopId');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
        'documentType': documentType,
        'documentName': documentName,
      });

      final response = await ApiClient.post(
        '/documents/shop/$shopId/upload',
        data: formData,
      );

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      Logger.e('Failed to upload shop document', 'SHOP', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? e.response?.data?['error'] ?? 'Failed to upload document',
      };
    } catch (e) {
      Logger.e('Failed to upload shop document', 'SHOP', e);
      return {'success': false, 'message': 'Failed to upload document: $e'};
    }
  }

  // Get Shop Categories
  Future<Map<String, dynamic>> getShopCategories(int shopId) async {
    try {
      Logger.api('Fetching shop categories: $shopId');

      // includeSubgroups: newer backend returns the shop's subcategories
      // (e.g. Rice Bag under Rice) even before products are assigned to them,
      // so the app can render them as filter chips.
      final response = await _apiService.get(
        '/customer/shops/$shopId/categories?includeSubgroups=true',
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
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    String sortBy = 'name',
    String sortDir = 'asc',
  }) async {
    try {
      Logger.api('Fetching shop products: $shopId with category: $category, search: $search');

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
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
        Logger.api('Added search parameter: $search');
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
  // NOTE: this hits /shop-products/{id}, which is restricted to SHOP_OWNER/ADMIN
  // on the backend and always 403s for customer accounts. Kept as-is since nothing
  // outside this class called it before; use getCustomerProductDetails for customer-facing code.
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

  // Get a single product's current details the way a customer is actually allowed to -
  // no SHOP_OWNER/ADMIN role required, unlike getShopProductById above.
  Future<Map<String, dynamic>> getCustomerProductDetails(int shopId, int productId) async {
    try {
      Logger.api('Fetching customer product details: shop $shopId, product $productId');

      final response = await _apiService.get(
        '/customer/shops/$shopId/products/$productId',
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch customer product details', 'SHOP', e);
      rethrow;
    }
  }
}