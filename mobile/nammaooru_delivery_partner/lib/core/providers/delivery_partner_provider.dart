import 'package:flutter/material.dart';
import '../models/delivery_partner.dart';
import '../models/simple_order_model.dart';
import '../services/api_service.dart';

class DeliveryPartnerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  DeliveryPartner? _currentPartner;
  List<OrderModel> _availableOrders = [];
  List<OrderModel> _activeOrders = [];
  List<OrderModel> _orderHistory = [];
  Earnings? _earnings;
  bool _isLoading = false;
  String? _error;

  // Getters
  DeliveryPartner? get currentPartner => _currentPartner;
  List<OrderModel> get availableOrders => _availableOrders;
  List<OrderModel> get activeOrders => _activeOrders;
  List<OrderModel> get currentOrders => _activeOrders;
  List<OrderModel> get orderHistory => _orderHistory;
  Earnings? get earnings => _earnings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentPartner != null;
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  // Authentication
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final response = await _apiService.login(email, password);
      
      if (response['success'] == true) {
        // Load partner profile after successful login
        await loadProfile();
        return true;
      } else {
        _setError(response['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Login with password change check
  Future<Map<String, dynamic>> loginWithPasswordCheck(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final response = await _apiService.login(email, password);
      
      if (response['success'] == true) {
        if (response['requiresPasswordChange'] != true) {
          // Only load profile if password change is not required
          await loadProfile();
        }
        return response;
      } else {
        _setError(response['message'] ?? 'Login failed');
        return response;
      }
    } catch (e) {
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> logout() async {
    try {
      await _apiService.logout();
      _currentPartner = null;
      _availableOrders = [];
      _orderHistory = [];
      _earnings = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Profile Management
  Future<void> loadProfile() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final response = await _apiService.getProfile();
      _currentPartner = DeliveryPartner.fromJson(response);
      
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> toggleOnlineStatus() async {
    if (_currentPartner == null) return;
    
    try {
      _setError(null);
      final newStatus = !_currentPartner!.isOnline;
      
      await _apiService.updateOnlineStatus(newStatus);
      
      // Update local state
      _currentPartner = DeliveryPartner(
        partnerId: _currentPartner!.partnerId,
        name: _currentPartner!.name,
        phoneNumber: _currentPartner!.phoneNumber,
        isOnline: newStatus,
        isAvailable: _currentPartner!.isAvailable,
        profileImageUrl: _currentPartner!.profileImageUrl,
        earnings: _currentPartner!.earnings,
        totalDeliveries: _currentPartner!.totalDeliveries,
        rating: _currentPartner!.rating,
      );
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Orders Management
  Future<void> loadAvailableOrders() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.getAvailableOrders();
      _availableOrders = (response['orders'] as List? ?? [])
          .map((order) => OrderModel.fromJson(order))
          .toList();

    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCurrentOrders() async {
    try {
      _setError(null);

      final response = await _apiService.getCurrentOrders();
      _activeOrders = (response['orders'] as List? ?? [])
          .map((order) => OrderModel.fromJson(order))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Alias for backwards compatibility
  Future<void> loadActiveOrders() async {
    await loadCurrentOrders();
  }
  
  Future<bool> acceptOrder(String orderId) async {
    try {
      _setError(null);
      
      final response = await _apiService.acceptOrder(orderId);
      
      if (response['success'] == true) {
        // Remove from available orders and refresh both available and active orders
        await loadAvailableOrders();
        await loadCurrentOrders();
        await loadOrderHistory();
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to accept order');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
  
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      _setError(null);

      final response = await _apiService.updateOrderStatus(orderId, status);

      if (response['success'] == true) {
        // Refresh all order data to update UI
        await loadCurrentOrders();
        await loadAvailableOrders();
        await loadOrderHistory();
        await loadEarnings();
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to update order status');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
  
  Future<void> loadOrderHistory() async {
    try {
      _setError(null);
      
      final response = await _apiService.getOrderHistory();
      _orderHistory = (response['orders'] as List? ?? [])
          .map((order) => OrderModel.fromJson(order))
          .toList();
          
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Earnings Management
  Future<void> loadEarnings({String? period}) async {
    try {
      _setError(null);
      
      final response = await _apiService.getEarnings(period: period);
      _earnings = Earnings.fromJson(response);
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Dashboard Data
  Future<void> loadDashboardData() async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Load all dashboard data concurrently
      await Future.wait([
        loadProfile(),
        loadAvailableOrders(),
        loadCurrentOrders(),
        loadEarnings(),
      ]);
      
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Check if user is already logged in
  Future<void> checkLoginStatus() async {
    try {
      final isLoggedIn = await _apiService.isLoggedIn();
      if (isLoggedIn) {
        await loadProfile();
      }
    } catch (e) {
      // Ignore errors during startup check
    }
  }
  
  // Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.forgotPassword(email);
      return response;
    } catch (e) {
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  // Change Password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final response = await _apiService.changePassword(currentPassword, newPassword);
      
      if (response['success'] == true) {
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to change password');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // OTP Verification for Pickup
  Future<bool> verifyPickupOTP(String orderId, String otp) async {
    try {
      _setError(null);

      final response = await _apiService.verifyPickupOTP(orderId, otp);

      if (response['success'] == true) {
        // Update order status to picked up after successful verification
        await updateOrderStatus(orderId, 'PICKED_UP');
        return true;
      } else {
        _setError(response['message'] ?? 'Invalid OTP');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Request new OTP for pickup
  Future<bool> requestNewPickupOTP(String orderId) async {
    try {
      _setError(null);

      final response = await _apiService.requestNewPickupOTP(orderId);

      if (response['success'] == true) {
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to request new OTP');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Add missing rejectOrder method
  Future<bool> rejectOrder(String orderId, String reason) async {
    try {
      _setError(null);

      final response = await _apiService.rejectOrder(orderId, reason: reason);

      if (response['success'] == true) {
        // Remove from available orders and refresh
        await loadAvailableOrders();
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to reject order');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await loadDashboardData();
    await loadOrderHistory();
  }
}