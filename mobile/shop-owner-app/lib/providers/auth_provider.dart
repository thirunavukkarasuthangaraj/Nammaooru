import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;

  // Initialize the auth provider
  Future<void> initialize() async {
    try {
      await StorageService.init();
      await _checkAuthStatus();
    } catch (e) {
      _setState(AuthState.error, errorMessage: 'Failed to initialize: ${e.toString()}');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      await StorageService.init();
      final isLoggedIn = StorageService.isLoggedIn();
      final token = StorageService.getToken();
      final userData = StorageService.getUser();

      if (isLoggedIn && token != null && userData != null) {
        _user = User.fromJson(userData);
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      _setState(AuthState.error, errorMessage: e.toString());
      return false;
    }
  }

  // Login method
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setState(AuthState.loading);

      final response = await ApiService.login(
        email: email,
        password: password,
      );

      if (response.isSuccess) {
        final data = response.data;
        final token = data['token'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;

        if (token != null && userData != null) {
          // Save to storage
          await StorageService.saveToken(token);
          if (refreshToken != null) {
            await StorageService.saveRefreshToken(refreshToken);
          }
          await StorageService.saveUser(userData);
          await StorageService.setLoggedIn(true);

          // Update state
          _user = User.fromJson(userData);
          _setState(AuthState.authenticated);

          _setLoading(false);
          return true;
        } else {
          _setState(AuthState.error, errorMessage: 'Invalid response format');
          _setLoading(false);
          return false;
        }
      } else {
        _setState(AuthState.error, errorMessage: response.error ?? 'Login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setState(AuthState.error, errorMessage: 'Login error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      _setLoading(true);

      // Call logout API (optional, continue even if it fails)
      try {
        await ApiService.logout();
      } catch (e) {
        print('Logout API call failed: $e');
      }

      // Clear local storage
      await StorageService.clearAuthData();

      // Update state
      _user = null;
      _setState(AuthState.unauthenticated);
      _setLoading(false);
    } catch (e) {
      _setState(AuthState.error, errorMessage: 'Logout error: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Refresh token method
  Future<bool> refreshToken() async {
    try {
      final refreshToken = StorageService.getRefreshToken();
      if (refreshToken == null) {
        await logout();
        return false;
      }

      // Call refresh token API
      // This would be implemented based on your backend API
      // For now, we'll simulate it

      // If refresh successful, update tokens and return true
      // If refresh failed, logout and return false
      await logout();
      return false;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      _setLoading(true);

      final response = await ApiService.updateShopProfile(updates);

      if (response.isSuccess) {
        final updatedUserData = response.data['user'] as Map<String, dynamic>?;
        if (updatedUserData != null) {
          await StorageService.saveUser(updatedUserData);
          _user = User.fromJson(updatedUserData);
          notifyListeners();
        }
        _setLoading(false);
        return true;
      } else {
        _setState(AuthState.error, errorMessage: response.error ?? 'Update failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setState(AuthState.error, errorMessage: 'Update error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Check authentication status
  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await this.isLoggedIn();
    if (!isLoggedIn) {
      _setState(AuthState.unauthenticated);
    }
  }

  // Helper methods
  void _setState(AuthState newState, {String? errorMessage}) {
    _state = newState;
    _errorMessage = errorMessage;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _setState(_user != null ? AuthState.authenticated : AuthState.unauthenticated);
    }
    notifyListeners();
  }

  // Mock user data for testing
  Future<bool> loginWithMockData() async {
    try {
      _setLoading(true);
      _setState(AuthState.loading);

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      final mockUserData = {
        'id': 'user_123',
        'email': 'thiru278@example.com',
        'name': 'thiru278',
        'phone': '+919876543210',
        'profileImage': null,
        'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'metadata': {
          'shopId': 'shop_456',
          'shopName': 'Thirunavukkarasu Shop',
          'shopStatus': 'APPROVED',
        },
      };

      const mockToken = 'mock_jwt_token_12345';

      // Save to storage
      await StorageService.saveToken(mockToken);
      await StorageService.saveUser(mockUserData);
      await StorageService.setLoggedIn(true);

      // Update state
      _user = User.fromJson(mockUserData);
      _setState(AuthState.authenticated);

      _setLoading(false);
      return true;
    } catch (e) {
      _setState(AuthState.error, errorMessage: 'Mock login error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}