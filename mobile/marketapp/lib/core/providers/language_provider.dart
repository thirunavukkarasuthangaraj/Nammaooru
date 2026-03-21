import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  bool _showTamil = false;
  static const String _keyShowTamil = 'show_tamil';

  bool get showTamil => _showTamil;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showTamil = prefs.getBool(_keyShowTamil) ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  Future<void> toggleLanguage() async {
    _showTamil = !_showTamil;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowTamil, _showTamil);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  String getProductName(dynamic product) {
    if (product == null) return '';

    if (_showTamil && product['nameTamil'] != null && product['nameTamil'].toString().isNotEmpty) {
      return product['nameTamil'];
    }

    return product['name'] ?? '';
  }

  // Get display name for shop products (checks masterProduct.nameTamil)
  String getDisplayName(dynamic product) {
    if (product == null) return '';

    // If Tamil is selected, try to show Tamil name from masterProduct
    if (_showTamil && product['masterProduct'] != null) {
      final nameTamil = product['masterProduct']['nameTamil'];
      if (nameTamil != null && nameTamil.toString().trim().isNotEmpty) {
        return nameTamil.toString();
      }
    }

    // Fall back to English name from masterProduct or displayName
    if (product['masterProduct'] != null && product['masterProduct']['name'] != null) {
      return product['masterProduct']['name'].toString();
    }

    return product['displayName']?.toString() ?? '';
  }

  // Get order status display text based on language preference
  String getOrderStatus(String status) {
    if (_showTamil) {
      switch (status.toUpperCase()) {
        case 'PENDING':
          return 'ஆர்டர் செய்யப்பட்டது';
        case 'CONFIRMED':
          return 'உறுதி செய்யப்பட்டது';
        case 'PREPARING':
          return 'தயாரிக்கப்படுகிறது';
        case 'READY_FOR_PICKUP':
          return 'எடுத்துச் செல்ல தயார்';
        case 'OUT_FOR_DELIVERY':
          return 'டெலிவரி செய்யப்படுகிறது';
        case 'DELIVERED':
          return 'டெலிவரி செய்யப்பட்டது';
        case 'CANCELLED':
          return 'ரத்து செய்யப்பட்டது';
        case 'REFUNDED':
          return 'பணம் திருப்பித் தரப்பட்டது';
        default:
          return status;
      }
    } else {
      // English text
      switch (status.toUpperCase()) {
        case 'PENDING':
          return 'Order Placed';
        case 'CONFIRMED':
          return 'Confirmed';
        case 'PREPARING':
          return 'Being Prepared';
        case 'READY_FOR_PICKUP':
          return 'Ready for Pickup';
        case 'OUT_FOR_DELIVERY':
          return 'Out for Delivery';
        case 'DELIVERED':
          return 'Delivered';
        case 'CANCELLED':
          return 'Cancelled';
        case 'REFUNDED':
          return 'Refunded';
        default:
          return status;
      }
    }
  }
}
