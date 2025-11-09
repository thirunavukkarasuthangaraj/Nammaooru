import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../storage/secure_storage.dart';
import '../storage/local_storage.dart';
import '../config/env_config.dart';
import '../constants/app_constants.dart';

class ApiService {
  static const String _baseUrl = EnvConfig.baseUrl + '/api';
  late Dio _dio;
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
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

  // Generic GET method
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      // Set auth token if required
      if (includeAuth) {
        try {
          // Ensure SharedPreferences is initialized
          await LocalStorage.init();
          final token = await SecureStorage.getAuthToken();
          if (token != null && token.isNotEmpty) {
            _dio.options.headers['Authorization'] = 'Bearer $token';
            if (kDebugMode) {
              print('ApiService: Adding auth token for $path');
            }
          } else {
            if (kDebugMode) {
              print('ApiService: No auth token found for $path');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('ApiService: Error getting auth token for $path: $e');
          }
        }
      } else {
        _dio.options.headers.remove('Authorization');
      }

      final response = await _dio.get(
        path,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data ?? {};
        // Check API response status code
        if (responseData['statusCode'] == AppConstants.successCode) {
          return responseData;
        } else {
          return {
            'statusCode': responseData['statusCode'] ?? AppConstants.failureCode,
            'message': responseData['message'] ?? AppConstants.errorCodes[responseData['statusCode']] ?? AppConstants.failureMessage,
            'success': false,
          };
        }
      } else {
        return {
          'statusCode': AppConstants.failureCode,
          'message': response.data?['message'] ?? 'Request failed',
          'success': false,
        };
      }
    } on DioException catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': _handleDioError(e)['message'],
        'success': false,
      };
    } catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'success': false,
      };
    }
  }

  // Generic POST method
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      // Set auth token if required
      if (includeAuth) {
        try {
          // Ensure SharedPreferences is initialized
          await LocalStorage.init();
          final token = await SecureStorage.getAuthToken();
          if (token != null && token.isNotEmpty) {
            _dio.options.headers['Authorization'] = 'Bearer $token';
            if (kDebugMode) {
              print('ApiService: Adding auth token for $path');
            }
          } else {
            if (kDebugMode) {
              print('ApiService: No auth token found for $path');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('ApiService: Error getting auth token for $path: $e');
          }
        }
      } else {
        _dio.options.headers.remove('Authorization');
      }

      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data ?? {};
        // Check API response status code
        if (responseData['statusCode'] == AppConstants.successCode) {
          return responseData;
        } else {
          return {
            'statusCode': responseData['statusCode'] ?? AppConstants.failureCode,
            'message': responseData['message'] ?? AppConstants.errorCodes[responseData['statusCode']] ?? AppConstants.failureMessage,
            'success': false,
          };
        }
      } else {
        return {
          'statusCode': AppConstants.failureCode,
          'message': response.data?['message'] ?? 'Request failed',
          'success': false,
        };
      }
    } on DioException catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': _handleDioError(e)['message'],
        'success': false,
      };
    } catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'success': false,
      };
    }
  }

  // Register user
  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      final response = await _dio.post('/auth/register', data: request.toJson());
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data ?? {};
        if (responseData['statusCode'] == AppConstants.successCode) {
          return {
            'success': true,
            'statusCode': AppConstants.successCode,
            'message': responseData['message'] ?? 'Registration successful! Please check your email for OTP verification.',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': false,
            'statusCode': responseData['statusCode'] ?? AppConstants.failureCode,
            'message': responseData['message'] ?? AppConstants.errorCodes[responseData['statusCode']] ?? 'Registration failed',
          };
        }
      } else {
        return {
          'success': false,
          'statusCode': AppConstants.failureCode,
          'message': response.data?['message'] ?? 'Registration failed',
        };
      }
    } on DioException catch (e) {
      // Special handling for registration errors to extract server messages
      if (e.response?.statusCode == 500 && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData['message'] != null) {
          return {
            'success': false,
            'message': responseData['message'].toString(),
          };
        }
      }
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
        // Check if the response indicates success
        final responseData = response.data;
        if (responseData != null && 
            (responseData['status'] == 'success' || 
             responseData['message']?.toString().toLowerCase().contains('verified') == true ||
             responseData['message']?.toString().toLowerCase().contains('success') == true)) {
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Email verified successfully!',
            'data': responseData,
          };
        } else {
          return {
            'success': false,
            'message': responseData?['message'] ?? 'OTP verification failed',
          };
        }
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
        final responseData = response.data ?? {};
        if (responseData['statusCode'] == AppConstants.successCode) {
          final authResponse = AuthResponse.fromJson(responseData['data']);
          
          return {
            'success': true,
            'statusCode': AppConstants.successCode,
            'message': responseData['message'] ?? 'Login successful!',
            'data': authResponse,
          };
        } else {
          return {
            'success': false,
            'statusCode': responseData['statusCode'] ?? AppConstants.failureCode,
            'message': responseData['message'] ?? AppConstants.errorCodes[responseData['statusCode']] ?? 'Login failed',
          };
        }
      } else {
        return {
          'success': false,
          'statusCode': AppConstants.failureCode,
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

  // Send password reset OTP
  Future<Map<String, dynamic>> sendPasswordResetOtp(String identifier) async {
    try {
      final response = await _dio.post('/auth/forgot-password/send-otp', data: {
        'identifier': identifier,  // Support both email and mobile number
      });
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'statusCode': AppConstants.failureCode,
          'message': response.data?['message'] ?? 'Failed to send OTP',
        };
      }
    } on DioException catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': _handleDioError(e)['message'],
        'success': false,
      };
    } catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'success': false,
      };
    }
  }

  // Verify password reset OTP
  Future<Map<String, dynamic>> verifyPasswordResetOtp(String identifier, String otp) async {
    try {
      final response = await _dio.post('/auth/forgot-password/verify-otp', data: {
        'identifier': identifier,  // Support both email and mobile number
        'otp': otp,
      });
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'statusCode': AppConstants.failureCode,
          'message': response.data?['message'] ?? 'Invalid or expired OTP',
        };
      }
    } on DioException catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': _handleDioError(e)['message'],
        'success': false,
      };
    } catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'success': false,
      };
    }
  }

  // Reset password with OTP
  Future<Map<String, dynamic>> resetPasswordWithOtp(String identifier, String otp, String newPassword) async {
    try {
      final response = await _dio.post('/auth/forgot-password/reset-password', data: {
        'identifier': identifier,  // Support both email and mobile number
        'otp': otp,
        'newPassword': newPassword,
      });
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'statusCode': AppConstants.failureCode,
          'message': response.data?['message'] ?? 'Failed to reset password',
        };
      }
    } on DioException catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': _handleDioError(e)['message'],
        'success': false,
      };
    } catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'success': false,
      };
    }
  }

  // Resend password reset OTP
  Future<Map<String, dynamic>> resendPasswordResetOtp(String identifier) async {
    try {
      final response = await _dio.post('/auth/forgot-password/resend-otp', data: {
        'identifier': identifier,  // Support both email and mobile number
      });
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'statusCode': AppConstants.failureCode,
          'message': response.data?['message'] ?? 'Failed to resend OTP',
        };
      }
    } on DioException catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': _handleDioError(e)['message'],
        'success': false,
      };
    } catch (e) {
      return {
        'statusCode': AppConstants.failureCode,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'success': false,
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
      
      // Try to extract server error message
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('message') && responseData['message'] != null && responseData['message'].toString().trim().isNotEmpty) {
          message = responseData['message'].toString();
        } else if (responseData.containsKey('error') && responseData['error'] != null && responseData['error'].toString().trim().isNotEmpty) {
          message = responseData['error'].toString();
        }
      }
      
      // If no server message found, use status code defaults
      if (message == 'An error occurred') {
        if (statusCode == 401) {
          message = 'Invalid credentials. Please try again.';
        } else if (statusCode == 403) {
          message = 'Access denied. Please contact support.';
        } else if (statusCode == 404) {
          message = 'Service not found. Please try again later.';
        } else if (statusCode >= 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = 'Something went wrong. Please try again.';
        }
      }
    }
    
    return {
      'success': false,
      'message': message,
    };
  }
}