class AppConfig {
  // ============================================
  // SINGLE SOURCE OF TRUTH - CHANGE ONLY HERE!
  // ============================================
  static const String _devBaseUrl = 'http://192.168.1.11:8080';
  static const String _prodBaseUrl = 'https://api.nammaooru.com';

  static const bool _isProduction = false; // Set to true for production

  // All URLs derived from single source
  static String get baseUrl => _isProduction ? _prodBaseUrl : _devBaseUrl;
  static String get apiUrl => '$baseUrl/api';
  static String get wsUrl => 'ws://${baseUrl.replaceAll('http://', '').replaceAll('https://', '')}/ws';
  static String get mobileApiUrl => '$apiUrl/mobile/delivery-partner';

  // WebSocket Configuration
  static String get wsBaseUrl => baseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://');
  static String get wsApiBaseUrl => '$wsBaseUrl/ws';

  // Real-time Configuration
  static const Duration pingInterval = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;

  // Google Maps Configuration
  static const String googleMapsApiKey = 'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U';

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}