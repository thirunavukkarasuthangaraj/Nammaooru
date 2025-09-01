import 'dart:convert';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../storage/secure_storage.dart';
import 'jwt_helper.dart';

class AuthService {
  static Future<AuthResult> login(String username, String password) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );
      
      final data = response.data;
      final token = data['accessToken'];
      final refreshToken = data['refreshToken'];
      
      if (token != null && refreshToken != null) {
        await SecureStorage.saveAuthToken(token);
        await SecureStorage.saveRefreshToken(refreshToken);
        
        final userRole = JwtHelper.getUserRole(token);
        final userId = JwtHelper.getUserId(token);
        
        if (userRole != null && userId != null) {
          await SecureStorage.saveUserRole(userRole);
          await SecureStorage.saveUserId(userId);
          
          return AuthResult.success(
            token: token,
            userRole: userRole,
            userId: userId,
          );
        }
      }
      
      return AuthResult.failure('Invalid response from server');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }
  
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
  }) async {
    try {
      // Split name into username (using email prefix or name)
      final username = email.split('@')[0];
      
      final response = await ApiClient.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'role': 'USER', // Force USER role for customer registration
        },
      );
      
      return AuthResult.success(message: 'Registration successful');
    } catch (e) {
      return AuthResult.failure(e.toString());
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
        
        final userRole = JwtHelper.getUserRole(token);
        final userId = JwtHelper.getUserId(token);
        
        if (userRole != null && userId != null) {
          await SecureStorage.saveUserRole(userRole);
          await SecureStorage.saveUserId(userId);
          
          return AuthResult.success(
            token: token,
            userRole: userRole,
            userId: userId,
          );
        }
      }
      
      return AuthResult.failure('Invalid response from server');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }
  
  static Future<AuthResult> resendOtp(String email) async {
    try {
      await ApiClient.post(
        ApiEndpoints.sendOtp,
        data: {
          'email': email,
        },
      );
      
      return AuthResult.success(message: 'OTP sent successfully');
    } catch (e) {
      return AuthResult.failure(e.toString());
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
    final token = await SecureStorage.getAuthToken();
    if (token == null) return null;
    
    return JwtHelper.getUserRole(token);
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