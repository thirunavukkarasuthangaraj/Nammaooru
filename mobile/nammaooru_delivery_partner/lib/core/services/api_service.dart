import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8080/api';

  static const String _deliveryPartnerEndpoint =
      '$_baseUrl/mobile/delivery-partner';
  static const String _assignmentEndpoint = '$_baseUrl/assignments';

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
    final Map<String, dynamic> data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        data['message'] ?? 'An error occurred',
        response.statusCode,
      );
    }
  }

  // Authentication Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_deliveryPartnerEndpoint/login'),
      headers: await _getHeaders(),
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

    // Get assignments available for this partner
    final response = await http.get(
      Uri.parse('$_assignmentEndpoint/partner/$partnerId/available'),
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

    // Get active assignments for this partner
    final response = await http.get(
      Uri.parse('$_assignmentEndpoint/partner/$partnerId/active'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString(_partnerIdKey);

    if (partnerId == null) {
      throw ApiException('Partner ID not found. Please login again.', 401);
    }

    // Use the actual backend endpoint for accepting assignments
    final response = await http.post(
      Uri.parse('$_assignmentEndpoint/$orderId/accept?partnerId=$partnerId'),
      headers: await _getHeaders(),
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
    if (status == 'PICKED_UP') {
      endpoint = '$_assignmentEndpoint/$orderId/pickup?partnerId=$partnerId';
    } else if (status == 'DELIVERED') {
      endpoint = '$_assignmentEndpoint/$orderId/deliver?partnerId=$partnerId';
    } else {
      endpoint = '$_assignmentEndpoint/$orderId/status';
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: await _getHeaders(),
      body: status != 'PICKED_UP' && status != 'DELIVERED'
          ? json.encode({'status': status, 'partnerId': partnerId})
          : null,
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
