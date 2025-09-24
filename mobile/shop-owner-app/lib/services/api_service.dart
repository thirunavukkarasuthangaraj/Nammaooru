import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/app_config.dart';
import '../models/api_response.dart';
import '../models/models.dart';
import 'storage_service.dart';
import 'mock_data_service.dart';

class ApiService {
  static const String baseUrl = ApiEndpoints.baseUrl;
  static const Duration timeout = Duration(seconds: 30);

  // Mock mode configuration - uses AppConfig
  static bool get _useMockData => AppConfig.useMockData;

  static Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> get _authHeaders {
    final token = StorageService.getToken();
    final headers = Map<String, String>.from(_defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Authentication endpoints
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock login validation
      if (email == 'ananya@gmail.com' && password == 'password123') {
        final user = MockDataService.mockUser;
        final token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';

        // Store mock token
        await StorageService.setToken(token);
        await StorageService.setUser(user.toJson());

        return ApiResponse.success({
          'user': user.toJson(),
          'token': token,
          'message': 'Login successful'
        });
      } else {
        return ApiResponse.error('Invalid email or password');
      }
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiEndpoints.login}'),
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

  static Future<ApiResponse> logout() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiEndpoints.logout}'),
            headers: _authHeaders,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Shop profile endpoints
  static Future<ApiResponse> getShopProfile() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final shop = MockDataService.mockShop;
      return ApiResponse.success({'shop': shop.toJson()});
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiEndpoints.shopProfile}'),
            headers: _authHeaders,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> updateShopProfile(Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl${ApiEndpoints.shopProfile}'),
            headers: _authHeaders,
            body: json.encode(data),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Products endpoints
  static Future<ApiResponse> getProducts({
    String? shopId,
    int page = 1,
    int size = 20,
    String? search,
    String? category,
    String? status,
  }) async {
    final limit = size;
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));

      var products = MockDataService.mockProducts;

      // Apply filters
      if (search != null && search.isNotEmpty) {
        products = products.where((p) =>
          p.name.toLowerCase().contains(search.toLowerCase()) ||
          p.description.toLowerCase().contains(search.toLowerCase()) ||
          p.brand.toLowerCase().contains(search.toLowerCase())
        ).toList();
      }

      if (category != null && category.isNotEmpty) {
        products = products.where((p) => p.category == category).toList();
      }

      if (status != null && status.isNotEmpty) {
        if (status == 'active') {
          products = products.where((p) => p.isActive && p.stockQuantity > 0).toList();
        } else if (status == 'inactive') {
          products = products.where((p) => !p.isActive).toList();
        } else if (status == 'out_of_stock') {
          products = products.where((p) => p.stockQuantity <= 0).toList();
        } else if (status == 'low_stock') {
          products = products.where((p) => p.stockQuantity <= p.minStockLevel && p.stockQuantity > 0).toList();
        }
      }

      // Apply pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      final paginatedProducts = products.length > startIndex
          ? products.sublist(startIndex, endIndex.clamp(0, products.length))
          : <dynamic>[];

      return ApiResponse.success( {
        'products': paginatedProducts.map((p) => p is Product ? p.toJson() : p).toList(),
        'totalCount': products.length,
        'currentPage': page,
        'totalPages': (products.length / limit).ceil(),
        'hasNextPage': endIndex < products.length,
      });
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl${ApiEndpoints.products}')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _authHeaders)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiEndpoints.products}'),
            headers: _authHeaders,
            body: json.encode(data),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl${ApiEndpoints.products}/$id'),
            headers: _authHeaders,
            body: json.encode(data),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> deleteProduct(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl${ApiEndpoints.products}/$id'),
            headers: _authHeaders,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Orders endpoints
  static Future<ApiResponse> getOrders({
    String? shopId,
    int page = 1,
    int size = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final limit = size;
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));

      // Simple mock data return
      final mockOrders = [
        {
          'id': 1, 'orderNumber': 'ORD001', 'customerName': 'Rajesh Kumar',
          'totalAmount': 450.00, 'status': 'PENDING', 'paymentStatus': 'PAID',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          'items': [{'productName': 'Basmati Rice', 'quantity': 2}],
          'address': 'Koramangala, Bangalore',
        },
        {
          'id': 2, 'orderNumber': 'ORD002', 'customerName': 'Priya Sharma',
          'totalAmount': 320.00, 'status': 'CONFIRMED', 'paymentStatus': 'PAID',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'items': [{'productName': 'Cookies', 'quantity': 3}],
          'address': 'Indiranagar, Bangalore',
        },
      ];

      return ApiResponse.success({
        'content': mockOrders,
        'totalCount': mockOrders.length,
        'currentPage': page,
        'totalPages': 1,
      });
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl${ApiEndpoints.orders}')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _authHeaders)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> updateOrderStatus(String orderId, String status) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real implementation, this would update the order in the database
      // For mock, we'll just return success
      return ApiResponse.success( {
        'message': 'Order status updated successfully',
        'orderId': orderId,
        'newStatus': status,
      });
    }

    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl${ApiEndpoints.orders}/$orderId/status'),
            headers: _authHeaders,
            body: json.encode({'status': status}),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Finance endpoints
  static Future<ApiResponse> getFinanceData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));

      final analytics = MockDataService.mockAnalytics;
      return ApiResponse.success( analytics);
    }

    try {
      final queryParams = <String, String>{};

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl${ApiEndpoints.finance}')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _authHeaders)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Notifications endpoints
  static Future<ApiResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));

      var notifications = MockDataService.mockNotifications;

      // Apply filters
      if (isRead != null) {
        notifications = notifications.where((n) => n.isRead == isRead).toList();
      }

      // Sort by timestamp (newest first)
      notifications.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

      // Apply pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      final paginatedNotifications = notifications.length > startIndex
          ? notifications.sublist(startIndex, endIndex.clamp(0, notifications.length))
          : <dynamic>[];

      return ApiResponse.success( {
        'notifications': paginatedNotifications.map((n) => n is NotificationModel ? n.toJson() : n).toList(),
        'totalCount': notifications.length,
        'unreadCount': MockDataService.mockNotifications.where((n) => !n.isRead).length,
        'currentPage': page,
        'totalPages': (notifications.length / limit).ceil(),
        'hasNextPage': endIndex < notifications.length,
      });
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (isRead != null) {
        queryParams['isRead'] = isRead.toString();
      }

      final uri = Uri.parse('$baseUrl${ApiEndpoints.notifications}')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _authHeaders)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> markNotificationAsRead(String notificationId) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl${ApiEndpoints.notifications}/$notificationId/read'),
            headers: _authHeaders,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Category endpoints
  static Future<ApiResponse> getCategories() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));

      final categories = MockDataService.mockCategories;
      return ApiResponse.success( {
        'categories': categories.map((c) => c.toJson()).toList(),
      });
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/categories'),
            headers: _authHeaders,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Dashboard endpoints
  static Future<ApiResponse> getDashboardStats() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      final orders = MockDataService.mockOrders;
      final analytics = MockDataService.mockAnalytics;

      return ApiResponse.success( {
        'stats': analytics['dashboard_stats'],
        'recentOrders': orders.take(5).map((o) => o.toJson()).toList(),
        'orderStats': _getOrderStats(orders),
      });
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/dashboard/stats'),
            headers: _authHeaders,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Generic helper methods
  static Map<String, dynamic> _getOrderStats(List<dynamic> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return {
      'totalOrders': orders.length,
      'pendingOrders': orders.where((o) => (o as dynamic)?.status == 'PENDING').length,
      'confirmedOrders': orders.where((o) => (o as dynamic)?.status == 'CONFIRMED').length,
      'outForDeliveryOrders': orders.where((o) => (o as dynamic)?.status == 'OUT_FOR_DELIVERY').length,
      'deliveredOrders': orders.where((o) => (o as dynamic)?.status == 'DELIVERED').length,
      'cancelledOrders': orders.where((o) => (o as dynamic)?.status == 'CANCELLED').length,
      'todayOrders': orders.where((o) => (o as dynamic)?.orderDate != null && (o as dynamic).orderDate.isAfter(today)).length,
      'totalRevenue': orders
          .where((o) => (o as dynamic)?.status == 'DELIVERED')
          .fold<double>(0, (sum, o) => sum + ((o as dynamic)?.totalAmount ?? 0)),
      'todayRevenue': orders
          .where((o) => (o as dynamic)?.status == 'DELIVERED' && (o as dynamic)?.orderDate != null && (o as dynamic).orderDate.isAfter(today))
          .fold<double>(0, (sum, o) => sum + ((o as dynamic)?.totalAmount ?? 0)),
      'averageOrderValue': orders.isNotEmpty
          ? orders.fold<double>(0, (sum, o) => sum + ((o as dynamic)?.totalAmount ?? 0)) / orders.length
          : 0.0,
    };
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

  // File upload helper
  static Future<ApiResponse> uploadFile(String endpoint, File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      request.headers.addAll(_authHeaders);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('File upload failed: ${e.toString()}');
    }
  }
}

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

  T? getData<T>() {
    if (success && data is T) {
      return data as T;
    }
    return null;
  }

  @override
  String toString() {
    if (success) {
      return 'ApiResponse.success( $data)';
    } else {
      return 'ApiResponse.error(error: $error, statusCode: $statusCode)';
    }
  }
}