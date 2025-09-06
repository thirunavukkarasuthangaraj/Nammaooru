import '../core/services/api_service.dart';
import '../core/utils/logger.dart';

class AuthApiService {
  final ApiService _apiService = ApiService();

  // Customer Registration
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      Logger.auth('Registering customer: $email');
      
      final response = await _apiService.post(
        '/customers/register',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'mobileNumber': phone,
          'password': password,
        },
        includeAuth: false,
      );

      if (response['success'] == true) {
        // If registration includes auto-login
        if (response['token'] != null) {
          await _apiService.setAuthToken(response['token']);
        }
      }

      return response;
    } catch (e) {
      Logger.e('Registration failed', 'AUTH', e);
      rethrow;
    }
  }

  // Customer Login
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      Logger.auth('Logging in customer: $emailOrPhone');
      
      final response = await _apiService.post(
        '/auth/login',
        body: {
          'username': emailOrPhone,
          'password': password,
        },
        includeAuth: false,
      );

      if (response['token'] != null) {
        await _apiService.setAuthToken(response['token']);
        Logger.auth('Login successful, token saved');
      }

      return response;
    } catch (e) {
      Logger.e('Login failed', 'AUTH', e);
      rethrow;
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      Logger.auth('Logging out customer');
      
      final response = await _apiService.post('/auth/logout');
      
      // Clear local token regardless of API response
      await _apiService.clearAuthToken();
      Logger.auth('Logout successful, token cleared');
      
      return response;
    } catch (e) {
      // Clear token even if API call fails
      await _apiService.clearAuthToken();
      Logger.e('Logout error, but token cleared', 'AUTH', e);
      return {'success': true, 'message': 'Logged out locally'};
    }
  }

  // Validate Token
  Future<Map<String, dynamic>> validateToken() async {
    try {
      Logger.auth('Validating token');
      
      final response = await _apiService.get('/auth/validate');
      return response;
    } catch (e) {
      Logger.e('Token validation failed', 'AUTH', e);
      rethrow;
    }
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String? email,
  }) async {
    try {
      Logger.auth('Sending OTP to: $phone');
      
      final response = await _apiService.post(
        '/auth/send-otp',
        body: {
          'phone': phone,
          if (email != null) 'email': email,
        },
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Send OTP failed', 'AUTH', e);
      rethrow;
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    required String otpId,
  }) async {
    try {
      Logger.auth('Verifying OTP for: $phone');
      
      final response = await _apiService.post(
        '/auth/verify-otp',
        body: {
          'phone': phone,
          'otp': otp,
          'otpId': otpId,
        },
        includeAuth: false,
      );

      if (response['token'] != null) {
        await _apiService.setAuthToken(response['token']);
        Logger.auth('OTP verification successful, token saved');
      }

      return response;
    } catch (e) {
      Logger.e('OTP verification failed', 'AUTH', e);
      rethrow;
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      Logger.auth('Changing password');
      
      final response = await _apiService.post(
        '/auth/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      return response;
    } catch (e) {
      Logger.e('Change password failed', 'AUTH', e);
      rethrow;
    }
  }

  // Forgot Password
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      Logger.auth('Forgot password request for: $email');
      
      final response = await _apiService.post(
        '/auth/forgot-password',
        body: {
          'email': email,
        },
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Forgot password failed', 'AUTH', e);
      rethrow;
    }
  }

  // Reset Password
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      Logger.auth('Resetting password');
      
      final response = await _apiService.post(
        '/auth/reset-password',
        body: {
          'token': token,
          'newPassword': newPassword,
        },
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Reset password failed', 'AUTH', e);
      rethrow;
    }
  }

  // Social Login (Google)
  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  }) async {
    try {
      Logger.auth('Google login attempt');
      
      final response = await _apiService.post(
        '/auth/google-login',
        body: {
          'idToken': idToken,
        },
        includeAuth: false,
      );

      if (response['token'] != null) {
        await _apiService.setAuthToken(response['token']);
        Logger.auth('Google login successful, token saved');
      }

      return response;
    } catch (e) {
      Logger.e('Google login failed', 'AUTH', e);
      rethrow;
    }
  }
}