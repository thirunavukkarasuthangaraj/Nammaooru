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

    // Handle nested masterProduct structure (shop products from JSON)
    if (product is Map && product['masterProduct'] != null) {
      if (_showTamil &&
          product['masterProduct']['nameTamil'] != null &&
          product['masterProduct']['nameTamil'].toString().isNotEmpty) {
        return product['masterProduct']['nameTamil'];
      }
      return product['masterProduct']['name'] ?? product['displayName'] ?? product['productName'] ?? '';
    }

    // Handle direct product structure (master products from JSON)
    if (product is Map) {
      if (_showTamil && product['nameTamil'] != null && product['nameTamil'].toString().isNotEmpty) {
        return product['nameTamil'];
      }
      return product['name'] ?? product['productName'] ?? '';
    }

    return '';
  }

  // Get display name for shop products
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

    return product['displayName']?.toString() ?? product['productName']?.toString() ?? '';
  }

  // ============================================
  // COMMON APP TRANSLATIONS
  // ============================================

  // Navigation & Menu
  String get dashboard => getText('Dashboard', 'டாஷ்போர்டு');
  String get products => getText('Products', 'பொருட்கள்');
  String get orders => getText('Orders', 'ஆர்டர்கள்');
  String get notifications => getText('Notifications', 'அறிவிப்புகள்');
  String get profile => getText('Profile', 'சுயவிவரம்');
  String get settings => getText('Settings', 'அமைப்புகள்');
  String get inventory => getText('Inventory', 'சரக்கு');

  // Common Actions
  String get search => getText('Search', 'தேடு');
  String get searchProducts => getText('Search products...', 'பொருட்களைத் தேடுங்கள்...');
  String get add => getText('Add', 'சேர்');
  String get edit => getText('Edit', 'திருத்து');
  String get delete => getText('Delete', 'நீக்கு');
  String get save => getText('Save', 'சேமி');
  String get cancel => getText('Cancel', 'ரத்து');
  String get confirm => getText('Confirm', 'உறுதிப்படுத்து');
  String get logout => getText('Logout', 'வெளியேறு');
  String get retry => getText('Retry', 'மீண்டும் முயற்சி');
  String get close => getText('Close', 'மூடு');
  String get done => getText('Done', 'முடிந்தது');
  String get yes => getText('Yes', 'ஆம்');
  String get no => getText('No', 'இல்லை');

  // Profile Screen
  String get shopDetails => getText('Shop Details', 'கடை விவரங்கள்');
  String get shopOwner => getText('Shop Owner', 'கடை உரிமையாளர்');
  String get address => getText('Address', 'முகவரி');
  String get city => getText('City', 'நகரம்');
  String get pincode => getText('Pincode', 'அஞ்சல் குறியீடு');
  String get phone => getText('Phone', 'தொலைபேசி');
  String get email => getText('Email', 'மின்னஞ்சல்');
  String get language => getText('Language', 'மொழி');
  String get businessHours => getText('Business Hours', 'வணிக நேரம்');
  String get paymentSettings => getText('Payment Settings', 'பணம் செலுத்தும் அமைப்புகள்');
  String get analytics => getText('Analytics', 'பகுப்பாய்வு');
  String get support => getText('Support', 'ஆதரவு');
  String get promoCodes => getText('Promo Codes', 'சலுகை குறியீடுகள்');

  // Orders Screen
  String get all => getText('All', 'அனைத்தும்');
  String get selfPickup => getText('Self Pickup', 'சுய பிக்அப்');
  String get pending => getText('Pending', 'நிலுவையில்');
  String get confirmed => getText('Confirmed', 'உறுதிப்படுத்தப்பட்டது');
  String get preparing => getText('Preparing', 'தயாரிக்கப்படுகிறது');
  String get readyForPickup => getText('Ready for Pickup', 'எடுத்துச் செல்ல தயார்');
  String get outForDelivery => getText('Out for Delivery', 'டெலிவரிக்கு');
  String get delivered => getText('Delivered', 'டெலிவரி ஆனது');
  String get cancelled => getText('Cancelled', 'ரத்து');
  String get returnedToShop => getText('Returned', 'திரும்பியது');
  String get delivery => getText('Delivery', 'டெலிவரி');
  String get pickup => getText('Pickup', 'பிக்அப்');

  // Order Actions
  String get accept => getText('Accept', 'ஏற்றுக்கொள்');
  String get reject => getText('Reject', 'நிராகரி');
  String get startPreparing => getText('Start Preparing', 'தயாரிக்க தொடங்கு');
  String get markReady => getText('Mark Ready', 'தயார் எனக் குறி');
  String get handoverToCustomer => getText('Handover to Customer', 'வாடிக்கையாளருக்கு ஒப்படை');
  String get verifyOTP => getText('Verify OTP', 'OTP சரிபார்');

  // Products Screen
  String get categories => getText('Categories', 'வகைகள்');
  String get allItems => getText('All Items', 'அனைத்து பொருட்கள்');
  String get addProduct => getText('Add Product', 'பொருள் சேர்');
  String get noProducts => getText('No products found', 'பொருட்கள் இல்லை');
  String get inStock => getText('In Stock', 'கையிருப்பில் உள்ளது');
  String get outOfStock => getText('Out of Stock', 'கையிருப்பில் இல்லை');
  String get lowStock => getText('Low Stock', 'குறைந்த கையிருப்பு');
  String get price => getText('Price', 'விலை');
  String get quantity => getText('Quantity', 'அளவு');
  String get item => getText('item', 'பொருள்');
  String get items => getText('items', 'பொருட்கள்');

  // Inventory Screen
  String get totalProducts => getText('Total Products', 'மொத்த பொருட்கள்');
  String get totalValue => getText('Total Value', 'மொத்த மதிப்பு');
  String get updateStock => getText('Update Stock', 'கையிருப்பு புதுப்பிக்க');

  // Dashboard
  String get todayOrders => getText("Today's Orders", 'இன்றைய ஆர்டர்கள்');
  String get totalRevenue => getText('Total Revenue', 'மொத்த வருவாய்');
  String get pendingOrders => getText('Pending Orders', 'நிலுவையில் உள்ள ஆர்டர்கள்');
  String get completedOrders => getText('Completed Orders', 'முடிந்த ஆர்டர்கள்');

  // Common Messages
  String get loading => getText('Loading...', 'ஏற்றுகிறது...');
  String get noDataFound => getText('No data found', 'தரவு இல்லை');
  String get somethingWentWrong => getText('Something went wrong', 'ஏதோ தவறு நடந்தது');
  String get success => getText('Success', 'வெற்றி');
  String get error => getText('Error', 'பிழை');
  String get comingSoon => getText('Coming soon!', 'விரைவில் வருகிறது!');

  // Order status translation
  String getOrderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ALL':
        return all;
      case 'SELF_PICKUP':
        return selfPickup;
      case 'PENDING':
        return pending;
      case 'CONFIRMED':
        return confirmed;
      case 'PREPARING':
        return preparing;
      case 'READY_FOR_PICKUP':
        return readyForPickup;
      case 'OUT_FOR_DELIVERY':
        return outForDelivery;
      case 'DELIVERED':
        return delivered;
      case 'CANCELLED':
        return cancelled;
      case 'RETURNED_TO_SHOP':
        return returnedToShop;
      case 'RETURNING_TO_SHOP':
        return getText('Returning', 'திரும்புகிறது');
      default:
        return status;
    }
  }
}
