class ApiConfig {
  // Base URL for API calls
  static const String baseUrl = 'http://172.25.224.1:8080/api';

  // Web URL for Chrome testing
  static const String webBaseUrl = 'http://172.25.224.1:8080/api';

  // Production URL (LOCAL TESTING)
  static const String prodBaseUrl = 'http://172.25.224.1:8080/api';

  // Environment detection
  static bool get isWeb => identical(0, 0.0);
  static bool get isProduction => false; // LOCAL MODE

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
