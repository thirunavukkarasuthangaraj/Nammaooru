class ApiConfig {
  // Local development
  static const String baseUrl = 'http://192.168.1.2:8080'; // Updated IP

  // Production URL
  // static const String baseUrl = 'https://api.nammaooru.com';

  // API Endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';

  // Delivery Partner Endpoints
  static const String deliveryPartnerProfile = '/api/delivery-partner/profile';
  static const String activeDeliveries = '/api/delivery-partner/deliveries/active';
  static const String deliveryHistory = '/api/delivery-partner/deliveries/history';
  static const String acceptDelivery = '/api/delivery-partner/deliveries/accept';
  static const String updateDeliveryStatus = '/api/delivery-partner/deliveries/status';
  static const String earnings = '/api/delivery-partner/earnings';

  // Notification Endpoints
  static const String updateFcmToken = '/api/delivery-partner/notifications/fcm-token';
  static const String notifications = '/api/delivery-partner/notifications';

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
}