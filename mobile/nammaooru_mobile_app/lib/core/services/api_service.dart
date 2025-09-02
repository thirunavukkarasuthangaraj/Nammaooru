import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';

class ApiService {
  static const String _baseUrl = 'https://api.nammaoorudelivary.in/api';
  late Dio _dio;
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  // Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Register user
  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      final response = await _dio.post('/auth/register', data: request.toJson());
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registration successful! Please check your email for OTP verification.',
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Registration failed',
        };
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Send OTP to email
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _dio.post('/auth/send-otp', data: {
        'email': email,
      });
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'OTP sent successfully to your email',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to send OTP',
        };
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(OtpVerificationRequest request) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: request.toJson());
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Email verified successfully!',
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'OTP verification failed',
        };
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/auth/login', data: request.toJson());
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data['data']);
        
        return {
          'success': true,
          'message': 'Login successful!',
          'data': authResponse,
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Login failed',
        };
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data['data']);
        
        return {
          'success': true,
          'data': user,
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to get user profile',
        };
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Handle Dio errors
  Map<String, dynamic> _handleDioError(DioException e) {
    String message = 'An error occurred';
    
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Unable to connect to server. Please check your internet connection.';
    } else if (e.response != null) {
      final statusCode = e.response?.statusCode ?? 0;
      final responseData = e.response?.data;
      
      if (responseData is Map<String, dynamic> && responseData['message'] != null) {
        message = responseData['message'];
      } else if (statusCode == 401) {
        message = 'Invalid credentials. Please try again.';
      } else if (statusCode == 403) {
        message = 'Access denied. Please contact support.';
      } else if (statusCode == 404) {
        message = 'Service not found. Please try again later.';
      } else if (statusCode >= 500) {
        message = 'Server error. Please try again later.';
      }
    }
    
    return {
      'success': false,
      'message': message,
    };
  }
}