class ApiConfig {
  // Base URL for API calls (using local IP for mobile testing)
  static const String baseUrl = 'http://192.168.1.10:8080/api';

  // Web URL for Chrome testing
  static const String webBaseUrl = 'http://192.168.1.10:8080/api';

  // Production URL (change when deploying)
  static const String prodBaseUrl = 'https://nammaoorudelivary.in/api';

  // Environment detection
  static bool get isWeb => identical(0, 0.0);
  static bool get isProduction => false; // Using LOCAL backend for testing

  // Get appropriate base URL based on environment
  static String get apiUrl {
    if (isProduction) {
      return prodBaseUrl;
    } else if (isWeb) {
      return webBaseUrl;
    } else {
      return baseUrl;
    }
  }

  // API Endpoints
  static const String deliveryFeesEndpoint = '/delivery-fees';
  static const String ordersEndpoint = '/orders';
  static const String shopsEndpoint = '/shops';
  static const String authEndpoint = '/auth';

  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Authentication headers (when needed)
  static Map<String, String> getAuthHeaders(String token) => {
        ...defaultHeaders,
        'Authorization': 'Bearer $token',
      };
}
