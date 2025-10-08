import '../config/app_config.dart';

class ApiConfig {
  // Use centralized config - DO NOT hardcode URLs here
  static String get baseUrl => AppConfig.baseUrl;

  // Legacy support - all URLs come from AppConfig now

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