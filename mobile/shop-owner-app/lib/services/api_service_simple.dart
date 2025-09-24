import 'dart:convert';
import 'package:http/http.dart' as http;
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
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  static const Duration timeout = Duration(seconds: 30);

  // Use AppConfig to determine if we should use mock data
  static bool get _useMockData => AppConfig.useMockData;

  static Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

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

  // Orders
  static Future<ApiResponse> getOrders({
    String? shopId,
    int page = 1,
    int size = 20,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));

      final mockOrders = [
        {
          'id': 1,
          'orderNumber': 'ORD001',
          'customerName': 'Rajesh Kumar',
          'totalAmount': 450.00,
          'status': 'PENDING',
          'paymentStatus': 'PAID',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          'items': [{'productName': 'Basmati Rice', 'quantity': 2}],
          'address': 'Koramangala, Bangalore',
        },
        {
          'id': 2,
          'orderNumber': 'ORD002',
          'customerName': 'Priya Sharma',
          'totalAmount': 320.00,
          'status': 'CONFIRMED',
          'paymentStatus': 'PAID',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'items': [{'productName': 'Cookies', 'quantity': 3}],
          'address': 'Indiranagar, Bangalore',
        },
      ];

      return ApiResponse.success({
        'content': mockOrders,
        'totalElements': mockOrders.length,
        'totalPages': 1,
        'currentPage': page,
      });
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final uri = Uri.parse('$baseUrl/orders/shop/$shopId')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _defaultHeaders)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Dashboard stats
  static Future<ApiResponse> getDashboardStats() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      return ApiResponse.success({
        'todayOrders': 12,
        'todayRevenue': 5430.00,
        'pendingOrders': 3,
        'totalProducts': 45,
      });
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/dashboard/stats'),
            headers: _defaultHeaders,
          )
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
      final response = await http
          .patch(
            Uri.parse('$baseUrl/orders/$orderId/status'),
            headers: _defaultHeaders,
            body: json.encode({'status': status}),
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