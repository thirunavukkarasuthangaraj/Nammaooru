class EnvConfig {
  // Base API Configuration - Using centralized AppConfig
  static String get baseUrl => 'http://192.168.1.10:8080'; // Use AppConfig instead
  static const String apiVersion = '';
  static String get fullApiUrl => '$baseUrl/api';

  // Google Services - Same API key as customer app
  static const String googleMapsApiKey = 'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U';

  // Firebase Configuration
  static const String firebaseProjectId = 'nammaooru-delivery';
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';

  // Push Notifications
  static const String fcmServerKey = 'YOUR_FCM_SERVER_KEY';

  // App Configuration
  static const String appName = 'Namma Ooru Delivery Partner';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Location Configuration
  static const double locationAccuracyThreshold = 10.0; // meters
  static const int idleLocationInterval = 300; // 5 minutes in seconds
  static const int activeLocationInterval = 30; // 30 seconds

  // Map Configuration - Cost saving settings
  static const bool useGoogleDirectionsAPI = false; // Set to false to save costs
  static const bool useSimplePolylines = true; // Use straight line polylines
  static const int maxPolylinePoints = 50; // Limit points for performance
  static const double polylineSimplificationTolerance = 0.0001; // Simplify routes

  // Delivery Configuration
  static const double shopProximityThreshold = 50.0; // meters
  static const double customerProximityThreshold = 50.0; // meters
  static const double defaultDeliverySpeed = 25.0; // km/h for ETA calculation

  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableBatteryOptimization = true;
  static const bool enableVoiceNavigation = false; // Disable to save resources

  // Performance Configuration
  static const int requestTimeoutSeconds = 30;
  static const int maxLocationHistoryPoints = 1000; // Limit stored points

  // Environment Check
  static bool get isProduction => baseUrl.contains('api.nammaooru.com');
  static bool get isDevelopment => baseUrl.contains('192.168') || baseUrl.contains('localhost');

  // Get environment-specific configuration
  static Map<String, dynamic> getConfig() {
    return {
      'baseUrl': baseUrl,
      'apiVersion': apiVersion,
      'isProduction': isProduction,
      'isDevelopment': isDevelopment,
      'appName': appName,
      'appVersion': appVersion,
      'buildNumber': appBuildNumber,
      'useGoogleDirectionsAPI': useGoogleDirectionsAPI,
      'idleLocationInterval': idleLocationInterval,
      'activeLocationInterval': activeLocationInterval,
    };
  }

  // Get API headers
  static Map<String, String> getApiHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': appVersion,
      'X-Platform': 'delivery-partner',
      'X-Client': 'flutter',
    };
  }
}