import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../storage/secure_storage.dart';
import '../../services/firebase_notification_service.dart';

enum AuthState {
  loading,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  AuthState _authState = AuthState.loading;
  String? _userRole;
  String? _userId;
  String? _errorMessage;
  
  AuthState get authState => _authState;
  String? get userRole => _userRole;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isCustomer => _userRole == 'CUSTOMER' || _userRole == 'USER';  // USER is customer role from backend
  bool get isShopOwner => _userRole == 'SHOP_OWNER';
  bool get isDeliveryPartner => _userRole == 'DELIVERY_PARTNER';
  
  AuthProvider() {
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        _userRole = await AuthService.getCurrentUserRole();
        _userId = await AuthService.getCurrentUserId();
        _authState = AuthState.authenticated;
      } else {
        _authState = AuthState.unauthenticated;
      }
    } catch (e) {
      _authState = AuthState.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
    _setLoading();

    final result = await AuthService.login(email, password);

    if (result.isSuccess) {
      _userRole = result.userRole;
      _userId = result.userId;
      _authState = AuthState.authenticated;
      _errorMessage = null;

      // Register FCM token for push notifications
      await _registerFcmToken();

      notifyListeners();
      return true;
    } else {
      _authState = AuthState.unauthenticated;
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
    required String username,
    String? gender,
  }) async {
    _setLoading();

    final result = await AuthService.register(
      name: name,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      role: role,
      username: username,
      gender: gender,
    );
    
    if (result.isSuccess) {
      _authState = AuthState.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _authState = AuthState.unauthenticated;
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading();

    final result = await AuthService.verifyOtp(email, otp);

    if (result.isSuccess) {
      _userRole = result.userRole;
      _userId = result.userId;
      _authState = AuthState.authenticated;
      _errorMessage = null;

      // Register FCM token after successful OTP verification
      await _registerFcmToken();

      notifyListeners();
      return true;
    } else {
      _authState = AuthState.unauthenticated;
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> resendOtp(String email) async {
    _setLoading();
    
    final result = await AuthService.resendOtp(email);
    
    if (result.isSuccess) {
      _authState = AuthState.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _authState = AuthState.unauthenticated;
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await AuthService.logout();
    _authState = AuthState.unauthenticated;
    _userRole = null;
    _userId = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<void> refreshAuthState() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        _userRole = await AuthService.getCurrentUserRole();
        _userId = await AuthService.getCurrentUserId();
        _authState = AuthState.authenticated;
        _errorMessage = null;
      } else {
        _authState = AuthState.unauthenticated;
        _userRole = null;
        _userId = null;
      }
    } catch (e) {
      _authState = AuthState.unauthenticated;
      _userRole = null;
      _userId = null;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
  
  void _setLoading() {
    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
  }
  
  String getHomeRoute() {
    switch (_userRole) {
      case 'CUSTOMER':
      case 'USER':  // Backend returns USER for customers
        return '/customer/dashboard';
      case 'SHOP_OWNER':
        return '/shop-owner/dashboard';
      case 'DELIVERY_PARTNER':
        return '/delivery-partner/dashboard';
      default:
        return '/login';
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      // First, initialize Firebase with permissions (this will ask for notification permission)
      await FirebaseNotificationService.initializeWithPermissions();

      // Get FCM token
      final token = await FirebaseNotificationService.getToken();
      if (token != null) {
        debugPrint('📱 Registering FCM token for user: $_userId with role: $_userRole');

        // Subscribe to user-specific and role-based topics
        if (_userId != null && _userRole != null) {
          await FirebaseNotificationService.subscribeToUserTopics(_userId!, _userRole!);

          // For shop owners, also subscribe to their shop-specific topic
          if (_userRole == 'SHOP_OWNER' || _userRole == 'shop_owner') {
            // Subscribe to shop-specific notifications
            // The shop ID will be linked on the backend
            await FirebaseNotificationService.subscribeToTopic('shop_owner_$_userId');
          }
        }
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }
}