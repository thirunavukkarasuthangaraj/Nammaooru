import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';
  bool _showTamil = false;
  static const String _keyShowTamil = 'show_tamil';
  static const String _keyCurrentLanguage = 'current_language';

  String get currentLanguage => _currentLanguage;
  bool get showTamil => _showTamil;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showTamil = prefs.getBool(_keyShowTamil) ?? false;
      _currentLanguage = prefs.getString(_keyCurrentLanguage) ?? 'en';

      // Sync showTamil with currentLanguage
      if (_currentLanguage == 'ta') {
        _showTamil = true;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  Future<void> toggleLanguage() async {
    _showTamil = !_showTamil;
    _currentLanguage = _showTamil ? 'ta' : 'en';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowTamil, _showTamil);
      await prefs.setString(_keyCurrentLanguage, _currentLanguage);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  void setLanguage(String language) {
    _currentLanguage = language;
    _showTamil = language == 'ta';
    notifyListeners();

    // Save to preferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyCurrentLanguage, language);
      prefs.setBool(_keyShowTamil, _showTamil);
    });
  }
  
  // Get localized text based on current language
  String getText(String englishText, String tamilText) {
    return _currentLanguage == 'ta' ? tamilText : englishText;
  }

  // Get product name based on language preference
  String getProductName(dynamic product) {
    if (product == null) return '';

    // Handle nested masterProduct structure (shop products)
    if (product['masterProduct'] != null) {
      if (_showTamil &&
          product['masterProduct']['nameTamil'] != null &&
          product['masterProduct']['nameTamil'].toString().isNotEmpty) {
        return product['masterProduct']['nameTamil'];
      }
      return product['masterProduct']['name'] ?? product['displayName'] ?? '';
    }

    // Handle direct product structure (master products)
    if (_showTamil && product['nameTamil'] != null && product['nameTamil'].toString().isNotEmpty) {
      return product['nameTamil'];
    }

    return product['name'] ?? '';
  }

  // Get display name for shop products (uses displayName field but respects language toggle)
  String getDisplayName(dynamic product) {
    if (product == null) return '';

    print('DEBUG: getDisplayName called - showTamil=$_showTamil');
    print('DEBUG: product has masterProduct: ${product['masterProduct'] != null}');

    // If Tamil is selected, try to show Tamil name from masterProduct
    if (_showTamil && product['masterProduct'] != null) {
      final nameTamil = product['masterProduct']['nameTamil'];
      print('DEBUG: nameTamil value = $nameTamil');
      if (nameTamil != null && nameTamil.toString().trim().isNotEmpty) {
        print('DEBUG: Returning Tamil name: $nameTamil');
        return nameTamil.toString();
      }
    }

    // Fall back to English name from masterProduct or displayName
    if (product['masterProduct'] != null && product['masterProduct']['name'] != null) {
      final englishName = product['masterProduct']['name'].toString();
      print('DEBUG: Returning English name: $englishName');
      return englishName;
    }

    final displayName = product['displayName']?.toString() ?? '';
    print('DEBUG: Returning displayName: $displayName');
    return displayName;
  }
  
  // Common app translations
  String get appName => getText('NammaOoru', 'நம்மூரு');
  String get welcome => getText('Welcome!', 'வணக்கம்!');
  String get login => getText('Sign In', 'உள்நுழைய');
  String get register => getText('Create Account', 'கணக்கு உருவாக்க');
  String get email => getText('Email', 'மின்னஞ்சல்');
  String get password => getText('Password', 'கடவுச்சொல்');
  String get firstName => getText('First Name', 'முதல் பெயர்');
  String get lastName => getText('Last Name', 'கடைசி பெயர்');
  String get phone => getText('Phone Number', 'தொலைபேசி எண்');
  String get profile => getText('Profile', 'சுயவிவரம்');
  String get shops => getText('Shops', 'கடைகள்');
  String get cart => getText('Cart', 'வண்டி');
  String get orders => getText('Orders', 'ஆர்டர்கள்');
  String get logout => getText('Logout', 'வெளியேறு');
  String get rememberMe => getText('Remember me', 'நினைவில் வைத்துக்கொள்');
  String get forgotPassword => getText('Forgot Password?', 'கடவுச்சொல் மறந்தீர்களா?');
  String get newToApp => getText('New to NammaOoru?', 'நம்மூருவில் புதிதா?');
  String get alreadyHaveAccount => getText('Already have an account?', 'ஏற்கனவே கணக்கு உள்ளதா?');
  String get termsAndConditions => getText('Terms of Service', 'சேவை விதிமுறைகள்');
  String get privacyPolicy => getText('Privacy Policy', 'தனியுரிமை கொள்கை');
  String get agreeToTerms => getText('I agree to the', 'நான் ஒப்புக்கொள்கிறேன்');
  String get and => getText('and', 'மற்றும்');

  // Order status translations
  String getOrderStatus(String status) {
    switch (status) {
      case 'PENDING':
        return getText('Pending', 'நிலுவையில்');
      case 'CONFIRMED':
        return getText('Confirmed', 'உறுதிப்படுத்தப்பட்டது');
      case 'PREPARING':
        return getText('Preparing', 'தயாரிக்கப்படுகிறது');
      case 'READY_FOR_PICKUP':
        return getText('Ready for Pickup', 'எடுத்துச் செல்ல தயார்');
      case 'OUT_FOR_DELIVERY':
        return getText('Out for Delivery', 'விநியோகத்திற்காக');
      case 'DELIVERED':
        return getText('Delivered', 'வழங்கப்பட்டது');
      case 'CANCELLED':
        return getText('Cancelled', 'ரத்து செய்யப்பட்டது');
      default:
        return status;
    }
  }
}