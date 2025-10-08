import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static String get _baseUrl => AppConfig.apiUrl;

  static String get _deliveryPartnerEndpoint => AppConfig.mobileApiUrl;
  static String get _assignmentEndpoint => '${AppConfig.apiUrl}/assignments';

  static const String _tokenKey = 'delivery_partner_token';
  static const String _partnerIdKey = 'delivery_partner_id';

  // Headers with authentication token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response and errors
  Map<String, dynamic> _handleResponse(http.Response response) {
    // Check status code first before parsing JSON
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } catch (e) {
        throw ApiException('Invalid JSON response from server', response.statusCode);
      }
    } else {
      // For error responses, try to parse JSON but handle plain text too
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        throw ApiException(
          data['message'] ?? 'An error occurred',
          response.statusCode,
        );
      } catch (e) {
        // If response is not JSON (e.g., plain text error), use the body as message
        throw ApiException(
          response.body.isNotEmpty ? response.body : 'An error occurred',
          response.statusCode,
        );
      }
    }
  }

  // Authentication Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Don't send Authorization header for login (no token yet!)
    final response = await http.post(
      Uri.parse('$_deliveryPartnerEndpoint/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final data = _handleResponse(response);

    // Save token and partner ID if login successful
    if (data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token']);
      await prefs.setString(_partnerIdKey, data['partnerId'].toString());
    }

    return data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_partnerIdKey);
  }

  // Profile Methods
  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    final response = await http.get(
      Uri.parse('$_deliveryPartnerEndpoint/profile/$partnerId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateOnlineStatus(bool isOnline) async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    final response = await http.post(
      Uri.parse('$_deliveryPartnerEndpoint/status/$partnerId'),
      headers: await _getHeaders(),
      body: json.encode({'isOnline': isOnline}),
    );

    return _handleResponse(response);
  }

  // Order Methods
  Future<Map<String, dynamic>> getAvailableOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    // Get assignments available for this partner - corrected endpoint
    final response = await http.get(
      Uri.parse('$_deliveryPartnerEndpoint/orders/$partnerId/available'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getActiveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    // Get active assignments for this partner - corrected endpoint
    final response = await http.get(
      Uri.parse('$_deliveryPartnerEndpoint/orders/$partnerId/active'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Alias for getActiveOrders
  Future<Map<String, dynamic>> getCurrentOrders() async {
    return await getActiveOrders();
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    // Use the correct backend endpoint for accepting assignments
    final response = await http.post(
      Uri.parse('$_deliveryPartnerEndpoint/orders/$orderId/accept'),
      headers: await _getHeaders(),
      body: json.encode({'partnerId': partnerId}),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> rejectOrder(String orderId, {String reason = 'No reason provided'}) async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    // Use the correct backend endpoint for rejecting assignments
    final response = await http.post(
      Uri.parse('$_deliveryPartnerEndpoint/orders/$orderId/reject'),
      headers: await _getHeaders(),
      body: json.encode({'partnerId': partnerId, 'reason': reason}),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    String endpoint = '';
    Map<String, dynamic> requestBody = {'partnerId': partnerId};

    if (status == 'PICKED_UP') {
      endpoint = '$_deliveryPartnerEndpoint/orders/$orderId/pickup';
    } else if (status == 'DELIVERED') {
      endpoint = '$_deliveryPartnerEndpoint/orders/$orderId/deliver';
      requestBody['deliveryNotes'] = 'Order delivered successfully';
    } else {
      // For other status updates, we might need a different endpoint
      endpoint = '$_deliveryPartnerEndpoint/orders/$orderId/status';
      requestBody['status'] = status;
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: await _getHeaders(),
      body: json.encode(requestBody),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getOrderHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    final response = await http.get(
      Uri.parse('$_deliveryPartnerEndpoint/orders/$partnerId/history'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Earnings Methods
  Future<Map<String, dynamic>> getEarnings({String? period}) async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    String url = '$_deliveryPartnerEndpoint/earnings/$partnerId';
    if (period != null) {
      url += '?period=$period';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Dashboard Methods
  Future<Map<String, dynamic>> getDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    final response = await http.get(
      Uri.parse('$_deliveryPartnerEndpoint/dashboard/$partnerId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Leaderboard
  Future<Map<String, dynamic>> getLeaderboard() async {
    final response = await http.get(
      Uri.parse('$_deliveryPartnerEndpoint/leaderboard'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_deliveryPartnerEndpoint/forgot-password'),
      headers: await _getHeaders(),
      body: json.encode({
        'email': email,
      }),
    );

    return _handleResponse(response);
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    final response = await http.put(
      Uri.parse('$_deliveryPartnerEndpoint/change-password'),
      headers: await _getHeaders(),
      body: json.encode({
        'partnerId': partnerId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  // Generic HTTP methods
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse(endpoint),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // OTP Verification for Pickup
  Future<Map<String, dynamic>> verifyPickupOTP(String orderId, String otp) async {
    final response = await http.post(
      Uri.parse('$_deliveryPartnerEndpoint/verify-pickup-otp'),
      headers: await _getHeaders(),
      body: json.encode({
        'orderId': orderId,
        'otp': otp,
      }),
    );

    return _handleResponse(response);
  }

  // Request new OTP for pickup
  Future<Map<String, dynamic>> requestNewPickupOTP(String orderId) async {
    final response = await http.post(
      Uri.parse('$_deliveryPartnerEndpoint/request-pickup-otp'),
      headers: await _getHeaders(),
      body: json.encode({
        'orderId': orderId,
      }),
    );

    return _handleResponse(response);
  }

  // Location Tracking Methods
  Future<Map<String, dynamic>> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    double? altitude,
    int? batteryLevel,
    String? networkType,
    int? assignmentId,
    String? orderStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found', 401);
    }

    final response = await http.put(
      Uri.parse('$_deliveryPartnerEndpoint/update-location/$partnerId'),
      headers: await _getHeaders(),
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        if (altitude != null) 'altitude': altitude,
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
        if (networkType != null) 'networkType': networkType,
        if (assignmentId != null) 'assignmentId': assignmentId,
        if (orderStatus != null) 'orderStatus': orderStatus,
      }),
    );

    return _handleResponse(response);
  }

  // Utility Methods
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  Future<String?> getPartnerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_partnerIdKey);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
