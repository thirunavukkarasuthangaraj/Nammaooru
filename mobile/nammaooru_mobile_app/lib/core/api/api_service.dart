import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../storage/secure_storage.dart';
import '../utils/logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late http.Client _client;
  String? _authToken;

  // Initialize the API service
  void initialize() {
    _client = http.Client();
    _loadAuthToken();
  }

  // Load auth token from secure storage
  Future<void> _loadAuthToken() async {
    _authToken = await SecureStorage.getAuthToken();
  }

  // Set auth token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    await SecureStorage.setAuthToken(token);
  }

  // Clear auth token
  Future<void> clearAuthToken() async {
    _authToken = null;
    await SecureStorage.clearAuthToken();
  }

  // Get headers
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = EnvConfig.getApiHeaders();
    
    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    Logger.d('API Response: ${response.statusCode} - ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return json.decode(response.body);
    } else {
      final errorBody = response.body.isNotEmpty 
          ? json.decode(response.body) 
          : {'message': 'Unknown error occurred'};
      
      throw ApiException(
        statusCode: response.statusCode,
        message: errorBody['message'] ?? 'API Error',
        data: errorBody,
      );
    }
  }

  // GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      String url = '${EnvConfig.fullApiUrl}$endpoint';
      
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url += '?$query';
      }

      Logger.d('GET: $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: includeAuth),
      ).timeout(Duration(seconds: EnvConfig.requestTimeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      Logger.e('GET Error: $e');
      rethrow;
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final url = '${EnvConfig.fullApiUrl}$endpoint';
      Logger.d('POST: $url');
      Logger.d('Body: ${json.encode(body)}');

      final response = await _client.post(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: includeAuth),
        body: body != null ? json.encode(body) : null,
      ).timeout(Duration(seconds: EnvConfig.requestTimeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      Logger.e('POST Error: $e');
      rethrow;
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final url = '${EnvConfig.fullApiUrl}$endpoint';
      Logger.d('PUT: $url');
      Logger.d('Body: ${json.encode(body)}');

      final response = await _client.put(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: includeAuth),
        body: body != null ? json.encode(body) : null,
      ).timeout(Duration(seconds: EnvConfig.requestTimeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      Logger.e('PUT Error: $e');
      rethrow;
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final url = '${EnvConfig.fullApiUrl}$endpoint';
      Logger.d('DELETE: $url');

      final response = await _client.delete(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: includeAuth),
      ).timeout(Duration(seconds: EnvConfig.requestTimeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      Logger.e('DELETE Error: $e');
      rethrow;
    }
  }

  // Dispose resources
  void dispose() {
    _client.close();
  }
}

// API Exception class
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException: $statusCode - $message';
  }

  // Check if error is authentication related
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  // Check if error is network related
  bool get isNetworkError => statusCode >= 500;

  // Check if error is client related
  bool get isClientError => statusCode >= 400 && statusCode < 500;
}