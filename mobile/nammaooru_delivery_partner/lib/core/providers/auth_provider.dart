import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../constants/api_endpoints.dart';
import '../models/partner_model.dart';
import '../../services/notification_api_service.dart';

class AuthProvider with ChangeNotifier {
  Partner? _partner;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _token;

  Partner? get partner => _partner;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _isAuthenticated = prefs.getBool('isLoggedIn') ?? false;

    final partnerJson = prefs.getString('partner_data');
    if (partnerJson != null) {
      _partner = Partner.fromJson(json.decode(partnerJson));
    }

    // Re-register FCM token if already logged in (for returning users)
    if (_isAuthenticated && _token != null) {
      _registerFcmToken();
    }

    notifyListeners();
  }

  Future<bool> sendOtp(String phoneNumber) async {
    _setLoading(true);
    
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.sendOtp),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phoneNumber': '+91$phoneNumber',
          'userType': 'delivery_partner'
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      
      return false;
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Send OTP Error: $e');
      }
      // For demo purposes, always return true
      return true;
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    _setLoading(true);
    
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.verifyOtp),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phoneNumber': '+91$phoneNumber',
          'otp': otp,
          'userType': 'delivery_partner'
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success']) {
          _token = data['token'];
          _partner = Partner.fromJson(data['partner']);
          _isAuthenticated = true;

          await _saveAuthData();

          // Register FCM token after successful login
          await _registerFcmToken();

          _setLoading(false);
          notifyListeners();

          return true;
        }
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Verify OTP Error: $e');
      }
      
      // For demo purposes, simulate successful login
      _partner = Partner(
        id: 'DP001234',
        name: 'Rajesh Kumar',
        phoneNumber: '+91$phoneNumber',
        email: 'rajesh.kumar@gmail.com',
        profileImage: null,
        rating: 4.8,
        totalDeliveries: 186,
        joinDate: DateTime.now().subtract(const Duration(days: 90)),
        vehicleType: 'Motorcycle',
        licenseNumber: 'KA03MA1234',
        bankDetails: const BankDetails(
          bankName: 'HDFC Bank',
          accountNumber: '****1234',
          ifscCode: 'HDFC0001234',
        ),
        isOnline: false,
        currentLocation: null,
      );
      
      _isAuthenticated = true;
      _token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      
      await _saveAuthData();
      notifyListeners();
      
      return true;
    }
  }

  Future<void> logout() async {
    _partner = null;
    _isAuthenticated = false;
    _token = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_token != null) {
      await prefs.setString('auth_token', _token!);
    }
    
    await prefs.setBool('isLoggedIn', _isAuthenticated);
    
    if (_partner != null) {
      await prefs.setString('partner_data', json.encode(_partner!.toJson()));
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Register FCM token with backend after login
  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        debugPrint('🔔 Registering FCM token after login: ${fcmToken.substring(0, 50)}...');
        final result = await NotificationApiService.instance.updateDeliveryPartnerFcmToken(fcmToken);
        if (result['success'] == true) {
          debugPrint('✅ FCM token registered successfully after login');
        } else {
          debugPrint('⚠️ FCM token registration failed: ${result['message']}');
        }
      } else {
        debugPrint('⚠️ No FCM token available');
      }
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
    }
  }

  Future<void> updatePartnerStatus(bool isOnline) async {
    if (_partner != null) {
      _partner = _partner!.copyWith(isOnline: isOnline);
      await _saveAuthData();
      notifyListeners();
    }
  }

  Future<void> updateProfile(Partner updatedPartner) async {
    _partner = updatedPartner;
    await _saveAuthData();
    notifyListeners();
  }
}