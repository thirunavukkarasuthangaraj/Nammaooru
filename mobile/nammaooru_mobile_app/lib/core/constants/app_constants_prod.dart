class AppConstants {
  static const String appName = 'NammaOoru';
  static const String appVersion = '1.0.0';
  
  // Production API URL
  static const String baseUrl = 'https://api.nammaoorudelivary.in/api';
  
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 80;
  
  static const List<String> supportedLanguages = ['en', 'ta'];
  static const String defaultLanguage = 'en';
  
  static const Map<String, String> userRoles = {
    'CUSTOMER': 'Customer',
    'SHOP_OWNER': 'Shop Owner',
    'DELIVERY_PARTNER': 'Delivery Partner',
  };
  
  static const Map<String, String> orderStatuses = {
    'PENDING': 'Pending',
    'CONFIRMED': 'Confirmed',
    'PREPARING': 'Preparing',
    'READY_FOR_PICKUP': 'Ready for Pickup',
    'OUT_FOR_DELIVERY': 'Out for Delivery',
    'DELIVERED': 'Delivered',
    'CANCELLED': 'Cancelled',
  };
  
  static const Map<String, String> serviceCategories = {
    'GROCERY': 'Grocery',
    'FOOD': 'Food',
    'PARCEL': 'Parcel',
  };
}