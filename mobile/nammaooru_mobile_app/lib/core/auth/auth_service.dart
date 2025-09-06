import 'dart:convert';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../storage/secure_storage.dart';
import 'jwt_helper.dart';

class AuthService {
  static Future<AuthResult> login(String email, String password) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final data = response.data;
      
      // Check for error statusCode (9999 indicates failure)
      final statusCode = data['statusCode']?.toString();
      if (statusCode != null && statusCode != '0000' && statusCode != '200') {
        return AuthResult.failure(data['message'] ?? 'Login failed');
      }
      
      final token = data['accessToken'];
      final refreshToken = data['refreshToken'];
      
      if (token != null) {
        await SecureStorage.saveAuthToken(token);
        if (refreshToken != null) {
          await SecureStorage.saveRefreshToken(refreshToken);
        }
        
        // Try to get role from response first, fallback to JWT
        final userRole = data['role'] ?? JwtHelper.getUserRole(token);
        // Try to get userId from JWT using 'sub' field or from response as username
        final userId = JwtHelper.getUserId(token) ?? data['username'];
        
        if (userRole != null && userId != null) {
          await SecureStorage.saveUserRole(userRole);
          await SecureStorage.saveUserId(userId);
          
          return AuthResult.success(
            token: token,
            userRole: userRole,
            userId: userId,
            message: data['message'] ?? 'Login successful!',
          );
        }
      }
      
      return AuthResult.failure('Invalid response from server');
    } on DioException catch (e) {
      return AuthResult.failure(_extractErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Login failed. Please try again.');
    }
  }
  
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
    required String username,
  }) async {
    try {
      // Split the full name into first and last name
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      
      final response = await ApiClient.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'mobileNumber': phoneNumber,
          'role': 'USER', // Force USER role for customer registration
        },
      );
      
      return AuthResult.success(message: 'Registration successful');
    } on DioException catch (e) {
      return AuthResult.failure(_extractErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Registration failed. Please try again.');
    }
  }
  
  static Future<AuthResult> verifyOtp(String email, String otp) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.verifyOtp,
        data: {
          'email': email,
          'otp': otp,
        },
      );
      
      final data = response.data;
      final token = data['accessToken'];
      final refreshToken = data['refreshToken'];
      
      if (token != null) {
        await SecureStorage.saveAuthToken(token);
        if (refreshToken != null) {
          await SecureStorage.saveRefreshToken(refreshToken);
        }
        
        // Try to get role from response first, fallback to JWT
        final userRole = data['role'] ?? JwtHelper.getUserRole(token);
        // Try to get userId from JWT using 'sub' field or from response as username
        final userId = JwtHelper.getUserId(token) ?? data['username'];
        
        if (userRole != null && userId != null) {
          await SecureStorage.saveUserRole(userRole);
          await SecureStorage.saveUserId(userId);
          
          return AuthResult.success(
            token: token,
            userRole: userRole,
            userId: userId,
            message: data['message'] ?? 'Email verified successfully!',
          );
        }
      }
      
      return AuthResult.failure('Invalid response from server');
    } on DioException catch (e) {
      return AuthResult.failure(_extractErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('OTP verification failed. Please try again.');
    }
  }
  
  static Future<AuthResult> resendOtp(String email) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.sendOtp,
        data: {
          'email': email,
        },
      );
      
      final message = response.data?['message'] ?? 'OTP sent successfully';
      return AuthResult.success(message: message);
    } on DioException catch (e) {
      return AuthResult.failure(_extractErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Failed to send OTP. Please try again.');
    }
  }
  
  static Future<void> logout() async {
    await SecureStorage.clearAuthData();
  }
  
  static Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getAuthToken();
    if (token == null) return false;
    
    return JwtHelper.isValidToken(token);
  }
  
  static Future<String?> getCurrentUserRole() async {
    // Get role from SecureStorage, not from JWT (JWT doesn't contain role)
    return await SecureStorage.getUserRole();
  }
  
  static Future<String?> getCurrentUserId() async {
    return await SecureStorage.getUserId();
  }
  
  static Future<AuthResult> refreshAuthToken() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        return AuthResult.failure('No refresh token available');
      }
      
      final response = await ApiClient.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      
      final newToken = response.data['accessToken'];
      if (newToken != null) {
        await SecureStorage.saveAuthToken(newToken);
        return AuthResult.success(token: newToken);
      }
      
      return AuthResult.failure('Failed to refresh token');
    } catch (e) {
      await SecureStorage.clearAuthData();
      return AuthResult.failure(e.toString());
    }
  }

  // Helper function to extract user-friendly error messages from server responses
  static String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final responseData = e.response!.data;
      
      // Handle different response formats
      if (responseData is Map<String, dynamic>) {
        // Check for message field first (most common)
        if (responseData.containsKey('message') && 
            responseData['message'] != null && 
            responseData['message'].toString().trim().isNotEmpty) {
          return responseData['message'].toString();
        }
        
        // Check for error field
        if (responseData.containsKey('error') && 
            responseData['error'] != null && 
            responseData['error'].toString().trim().isNotEmpty) {
          return responseData['error'].toString();
        }
        
        // Check for errors array (validation errors)
        if (responseData.containsKey('errors') && responseData['errors'] is List) {
          final errors = responseData['errors'] as List;
          if (errors.isNotEmpty) {
            return errors.first.toString();
          }
        }
      }
    }
    
    // Fallback to status code based messages
    final statusCode = e.response?.statusCode ?? 0;
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Invalid credentials. Please try again.';
      case 403:
        return 'Access denied. Please contact support.';
      case 404:
        return 'Service not found. Please try again later.';
      case 409:
        return 'Conflict occurred. Please try again.';
      case 422:
        return 'Invalid data provided. Please check your input.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable. Please try again.';
      default:
        // Handle network errors
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          return 'Unable to connect. Please check your internet connection.';
        } else {
          return 'Something went wrong. Please try again.';
        }
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final String? message;
  final String? token;
  final String? userRole;
  final String? userId;
  
  AuthResult._({
    required this.isSuccess,
    this.message,
    this.token,
    this.userRole,
    this.userId,
  });
  
  factory AuthResult.success({
    String? message,
    String? token,
    String? userRole,
    String? userId,
  }) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      token: token,
      userRole: userRole,
      userId: userId,
    );
  }
  
  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      message: message,
    );
  }
}