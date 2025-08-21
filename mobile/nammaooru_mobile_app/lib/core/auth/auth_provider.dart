import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../storage/secure_storage.dart';

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
  bool get isCustomer => _userRole == 'CUSTOMER';
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
  }) async {
    _setLoading();
    
    final result = await AuthService.register(
      name: name,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      role: role,
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
  
  void _setLoading() {
    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
  }
  
  String getHomeRoute() {
    switch (_userRole) {
      case 'CUSTOMER':
        return '/customer/dashboard';
      case 'SHOP_OWNER':
        return '/shop-owner/dashboard';
      case 'DELIVERY_PARTNER':
        return '/delivery-partner/dashboard';
      default:
        return '/login';
    }
  }
}