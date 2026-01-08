import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_config.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse._(success: true, data: data);
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse._(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
}

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const Duration timeout = Duration(seconds: 30);

  // Use AppConfig to determine if we should use mock data
  static bool get _useMockData => AppConfig.useMockData;

  static Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Get headers with authentication token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final headers = Map<String, String>.from(_defaultHeaders);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('Added auth token to headers: ${token.substring(0, 20)}...');
      } else {
        print('No auth token found in storage');
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }
    return headers;
  }

  // Authentication
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      if (email == 'ananya@gmail.com' && password == 'password123') {
        return ApiResponse.success({
          'user': {'name': 'Ananya Sharma', 'email': email},
          'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'message': 'Login successful'
        });
      } else {
        return ApiResponse.error('Invalid email or password');
      }
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _defaultHeaders,
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Dashboard Stats
  static Future<ApiResponse> getDashboardStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/dashboard/stats'),
            headers: headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get Shop Orders (for shop owner)
  static Future<ApiResponse> getShopOrders({
    int page = 0,
    int size = 50,
    String? status,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      // First get shop ID
      final shopResponse = await http.get(
        Uri.parse('$baseUrl/shops/my-shop'),
        headers: headers,
      ).timeout(timeout);

      if (shopResponse.statusCode != 200) {
        return ApiResponse.error('Failed to fetch shop info');
      }

      final shopData = jsonDecode(shopResponse.body);
      if (shopData['statusCode'] != '0000' || shopData['data'] == null) {
        return ApiResponse.error('Invalid shop response');
      }

      final shopId = shopData['data']['shopId'];

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (status != null && status.isNotEmpty && status != 'ALL') {
        queryParams['status'] = status;
      }

      // Then get orders
      final uri = Uri.parse('$baseUrl/shops/$shopId/orders')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Orders
  static Future<ApiResponse> getOrders({
    String? shopId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$baseUrl/orders/shop/$shopId')
          .replace(queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      });

      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get My Products (for shop owner)
  static Future<ApiResponse> getMyProducts({
    int page = 0,
    int size = 50,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final uri = Uri.parse('$baseUrl/shop-products/my-products')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Products
  static Future<ApiResponse> getProducts({
    String? shopId,
    int page = 1,
    int size = 20,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));

      final mockProducts = [
        {
          'id': 'prod_001',
          'name': 'Basmati Rice Premium',
          'price': 180.00,
          'category': 'Grains & Cereals',
          'stockQuantity': 25,
          'isActive': true,
        },
        {
          'id': 'prod_002',
          'name': 'Amul Fresh Milk',
          'price': 32.00,
          'category': 'Dairy Products',
          'stockQuantity': 12,
          'isActive': true,
        },
        {
          'id': 'prod_003',
          'name': 'Britannia Good Day Cookies',
          'price': 25.00,
          'category': 'Snacks & Beverages',
          'stockQuantity': 48,
          'isActive': true,
        },
      ];

      return ApiResponse.success({
        'content': mockProducts,
        'totalElements': mockProducts.length,
        'totalPages': 1,
        'currentPage': page,
      });
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final uri = Uri.parse('$baseUrl/products/shop/$shopId')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _defaultHeaders)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Update order status
  static Future<ApiResponse> updateOrderStatus(String orderId, String status) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      return ApiResponse.success({
        'message': 'Order status updated successfully',
        'orderId': orderId,
        'newStatus': status,
      });
    }

    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/orders/$orderId/status?status=$status'),
            headers: headers,
          )
          .timeout(timeout);

      // Handle empty response
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isEmpty) {
          return ApiResponse.success({
            'message': 'Order status updated successfully',
            'orderId': orderId,
            'newStatus': status,
          });
        }
        return _handleResponse(response);
      }

      return ApiResponse.error('Failed to update order status: ${response.statusCode}');
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Verify Pickup OTP
  static Future<ApiResponse> verifyPickupOTP(String orderId, String otp) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/orders/$orderId/verify-pickup-otp'),
            headers: headers,
            body: json.encode({'otp': otp}),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Handover self-pickup order to customer
  static Future<ApiResponse> handoverSelfPickup(String orderId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/orders/$orderId/handover-self-pickup'),
            headers: headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Retry driver search for order (shop owner retry when no driver found)
  static Future<ApiResponse> retryDriverSearch(String orderId) async {
    try {
      print('🔄 Retrying driver search for order: $orderId');

      final headers = await _getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/assignments/orders/$orderId/retry-driver-search'),
            headers: headers,
          )
          .timeout(timeout);

      print('✅ Retry driver search response status: ${response.statusCode}');
      print('📨 Retry driver search response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Retry driver search error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get Available Master Products (excluding ones already in shop)
  static Future<ApiResponse> getAvailableMasterProducts({
    int page = 0,
    int size = 12,
    String? categoryId,
    String? search,
    String? brand,
    String sortBy = 'updatedAt',
    String sortDirection = 'DESC',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      };

      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (brand != null && brand.isNotEmpty) {
        queryParams['brand'] = brand;
      }

      final uri = Uri.parse('$baseUrl/shop-products/available-master-products')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get Master Products (from catalog) - Legacy method
  static Future<ApiResponse> getMasterProducts({
    int page = 0,
    int size = 100,
    String? categoryId,
    String? search,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('$baseUrl/products/master')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get Categories (using shop categories endpoint to get imageUrl)
  static Future<ApiResponse> getCategories() async {
    try {
      final headers = await _getAuthHeaders();

      // First get shop ID
      final shopResponse = await http.get(
        Uri.parse('$baseUrl/shops/my-shop'),
        headers: headers,
      ).timeout(timeout);

      if (shopResponse.statusCode != 200) {
        return ApiResponse.error('Failed to fetch shop info');
      }

      final shopData = jsonDecode(shopResponse.body);
      if (shopData['statusCode'] != '0000' || shopData['data'] == null) {
        return ApiResponse.error('Invalid shop response');
      }

      final shopId = shopData['data']['id']; // Use numeric id, not shopId

      // Get categories for this shop (returns imageUrl instead of iconUrl)
      // Load all categories at once (size=2000) instead of paginated
      final uri = Uri.parse('$baseUrl/customer/shops/$shopId/categories?size=2000');

      print('🔄 Fetching all shop categories: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout);

      print('📥 Shop categories API response: ${response.statusCode}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Error fetching categories: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Create Master Product
  static Future<ApiResponse> createMasterProduct({
    required String name,
    String? nameTamil,
    required String description,
    required String sku,
    required int categoryId,
    required String brand,
    required String baseUnit,
    required bool isActive,
    required bool isFeatured,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'name': name,
        if (nameTamil != null && nameTamil.isNotEmpty) 'nameTamil': nameTamil,
        'description': description,
        'sku': sku,
        'categoryId': categoryId,
        'brand': brand,
        'baseUnit': baseUnit,
        'status': isActive ? 'ACTIVE' : 'INACTIVE',
        'isFeatured': isFeatured,
        'isGlobal': false, // Shop-specific product
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/products/master'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Create Shop Product (add master product to shop with custom price)
  static Future<ApiResponse> createShopProduct({
    required int masterProductId,
    required double price,
    int stockQuantity = 0,
    int minStockLevel = 5,
    double? originalPrice,
    double? costPrice,
    String? customName,
    String? customDescription,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
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
      if (customName != null) body['customName'] = customName;
      if (customDescription != null) body['customDescription'] = customDescription;

      final response = await http
          .post(
            Uri.parse('$baseUrl/shop-products/create'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Update Shop Product
  static Future<ApiResponse> updateShopProduct({
    required int productId,
    required int masterProductId,
    required double price,
    double? originalPrice,
    int? stockQuantity,
    int? minStockLevel,
    String? customName,
    String? customDescription,
    double? baseWeight,
    String? baseUnit,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'masterProductId': masterProductId,
        'price': price,
      };

      if (originalPrice != null) body['originalPrice'] = originalPrice;
      if (stockQuantity != null) body['stockQuantity'] = stockQuantity;
      if (minStockLevel != null) body['minStockLevel'] = minStockLevel;
      if (customName != null) body['customName'] = customName;
      if (customDescription != null) body['customDescription'] = customDescription;
      if (baseWeight != null) body['baseWeight'] = baseWeight;
      if (baseUnit != null) body['baseUnit'] = baseUnit;

      final response = await http
          .put(
            Uri.parse('$baseUrl/shop-products/$productId'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Remove Product from Shop
  static Future<ApiResponse> removeProductFromShop({
    required int productId,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      // First get the shop information to get shopId
      final shopResponse = await http
          .get(
            Uri.parse('$baseUrl/shops/my-shop'),
            headers: headers,
          )
          .timeout(timeout);

      if (shopResponse.statusCode != 200) {
        return ApiResponse.error('Failed to fetch shop information');
      }

      final shopData = jsonDecode(shopResponse.body);
      if (shopData['statusCode'] != '0000' || shopData['data'] == null) {
        return ApiResponse.error('Invalid shop data');
      }

      // Get the internal shop ID (numeric)
      final shopId = shopData['data']['id'];

      // Now delete the product using the correct endpoint
      final response = await http
          .delete(
            Uri.parse('$baseUrl/shops/$shopId/products/$productId'),
            headers: headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Upload product images
  static Future<ApiResponse> uploadMasterProductImages({
    required int masterProductId,
    required List images, // List of XFile
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        return ApiResponse.error('No authentication token found');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products/images/master/$masterProductId'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add images to request
      for (var image in images) {
        final bytes = await image.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: image.name,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get My Shop Info
  static Future<ApiResponse> getMyShop() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/shops/my-shop'),
            headers: headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Business Hours APIs

  // Get business hours for a shop
  static Future<ApiResponse> getBusinessHours(int shopId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/business-hours/shop/$shopId'),
            headers: headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get shop open/closed status
  static Future<ApiResponse> getShopStatus(int shopId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/business-hours/shop/$shopId/status'),
            headers: headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Create default business hours for a shop
  static Future<ApiResponse> createDefaultBusinessHours(int shopId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/business-hours/shop/$shopId/default'),
            headers: headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Bulk update business hours for a shop
  static Future<ApiResponse> bulkUpdateBusinessHours(
    int shopId,
    List<Map<String, dynamic>> businessHours,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/business-hours/shop/$shopId/bulk'),
            headers: headers,
            body: json.encode(businessHours),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Notification methods
  static Future<ApiResponse> markNotificationAsRead(int notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/notifications/$notificationId/read'),
            headers: headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> markAllNotificationsAsRead(int userId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/notifications/user/$userId/read-all'),
            headers: headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static ApiResponse _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data);
      } else {
        final message = data['message'] ?? 'Unknown error occurred';
        return ApiResponse.error(message, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: ${e.toString()}');
    }
  }
}