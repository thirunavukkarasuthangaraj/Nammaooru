import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { 
  initial, 
  loading, 
  authenticated, 
  unauthenticated, 
  registrationPending,
  otpVerificationPending 
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  String? _successMessage;
  String? _pendingEmail; // For OTP verification
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get pendingEmail => _pendingEmail;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;

  // Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set status
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _errorMessage = error;
    _successMessage = null;
    notifyListeners();
  }

  // Set success
  void _setSuccess(String success) {
    _successMessage = success;
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize auth state
  Future<void> initializeAuth() async {
    try {
      _setLoading(true);
      
      final isLoggedIn = await StorageService.isLoggedIn();
      if (isLoggedIn) {
        final token = await StorageService.getAccessToken();
        if (token != null) {
          _apiService.setAuthToken(token);
          
          // Try to get user profile
          final result = await _apiService.getUserProfile();
          if (result['success']) {
            _user = result['data'];
            _setStatus(AuthStatus.authenticated);
          } else {
            // Token might be expired, clear auth data
            await logout();
          }
        }
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
    } finally {
      _setLoading(false);
    }
  }

  // Register user
  Future<bool> register(RegisterRequest request) async {
    try {
      _setLoading(true);
      clearMessages();
      
      // Validate passwords match
      if (request.password != request.confirmPassword) {
        _setError('Passwords do not match');
        return false;
      }
      
      final result = await _apiService.register(request);
      
      if (result['success']) {
        // Save email for OTP verification
        _pendingEmail = request.email;
        await StorageService.saveRegistrationEmail(request.email);
        
        _setSuccess(result['message']);
        _setStatus(AuthStatus.otpVerificationPending);
        
        // Auto send OTP
        await sendOtp(request.email);
        
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send OTP
  Future<bool> sendOtp(String email) async {
    try {
      _setLoading(true);
      clearMessages();
      
      final result = await _apiService.sendOtp(email);
      
      if (result['success']) {
        _setSuccess(result['message']);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to send OTP: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String otp) async {
    try {
      _setLoading(true);
      clearMessages();
      
      final email = _pendingEmail ?? await StorageService.getRegistrationEmail();
      if (email == null) {
        _setError('Email not found. Please register again.');
        return false;
      }
      
      final request = OtpVerificationRequest(email: email, otp: otp);
      final result = await _apiService.verifyOtp(request);
      
      if (result['success']) {
        _setSuccess(result['message']);
        
        // Clear pending email
        _pendingEmail = null;
        await StorageService.clearRegistrationEmail();
        
        _setStatus(AuthStatus.unauthenticated);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('OTP verification failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login(LoginRequest request, {bool rememberMe = false}) async {
    try {
      _setLoading(true);
      clearMessages();
      
      final result = await _apiService.login(request);
      
      if (result['success']) {
        final authResponse = result['data'] as AuthResponse;
        
        // Save auth data
        await StorageService.saveAuthData(authResponse);
        
        // Save remember me preference
        await StorageService.saveRememberMe(rememberMe, authResponse.email);
        
        // Set API token
        _apiService.setAuthToken(authResponse.accessToken);
        
        // Create user object
        _user = User(
          id: 0, // Will be updated from profile API
          username: authResponse.username,
          email: authResponse.email,
          role: authResponse.role,
          isActive: true,
        );
        
        _setSuccess(result['message']);
        _setStatus(AuthStatus.authenticated);
        
        // Get full user profile
        getUserProfile();
        
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get user profile
  Future<void> getUserProfile() async {
    try {
      final result = await _apiService.getUserProfile();
      
      if (result['success']) {
        _user = result['data'];
        await StorageService.saveUserData(_user!);
        notifyListeners();
      }
    } catch (e) {
      // Profile fetch failed, but user is still logged in
      debugPrint('Failed to get user profile: $e');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);
      
      // Clear API token
      _apiService.clearAuthToken();
      
      // Clear storage
      await StorageService.clearAuthData();
      
      // Reset state
      _user = null;
      _pendingEmail = null;
      _setStatus(AuthStatus.unauthenticated);
      
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Resume registration (if user closed app during OTP)
  Future<void> resumeRegistration() async {
    try {
      final email = await StorageService.getRegistrationEmail();
      if (email != null) {
        _pendingEmail = email;
        _setStatus(AuthStatus.otpVerificationPending);
      }
    } catch (e) {
      // Ignore error
    }
  }

  // Cancel registration
  Future<void> cancelRegistration() async {
    try {
      _pendingEmail = null;
      await StorageService.clearRegistrationEmail();
      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      // Ignore error
    }
  }
}