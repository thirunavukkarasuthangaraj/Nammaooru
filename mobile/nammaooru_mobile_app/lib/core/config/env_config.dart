class EnvConfig {
  // Base API Configuration
  // DEVELOPMENT: Local development - Point to localhost
  // static const String baseUrl = 'http://localhost:8080';
  // static const String apiUrl = 'http://localhost:8080'; // Alias for compatibility
  // static const String imageBaseUrl = 'http://localhost:8080';

  // PRODUCTION: Use your deployed server
  // static const String baseUrl = 'https://api.nammaoorudelivary.in';
  // static const String apiUrl = 'https://api.nammaoorudelivary.in'; // Alias for compatibility
  // static const String imageBaseUrl = 'https://nammaoorudelivary.in';

  // PRODUCTION: Use your deployed server
  static const String baseUrl = 'https://api.nammaoorudelivary.in';
  static const String apiUrl = 'https://api.nammaoorudelivary.in'; // Alias for compatibility
  static const String imageBaseUrl = 'https://api.nammaoorudelivary.in';

  static const String apiVersion = '';
  static const String fullApiUrl = '$baseUrl/api';

  // Google Serviceswhen
  static const String googleMapsApiKey =
      'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U';
  static const String googlePlacesApiKey =
      'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U';

  // Payment Gateway
  static const String razorpayKey = 'YOUR_RAZORPAY_KEY';
  static const String razorpaySecret = 'YOUR_RAZORPAY_SECRET';

  // Firebase Configuration
  static const String firebaseProjectId = 'nammaooru-delivery';
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';

  // Push Notifications
  static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
  static const String fcmServerKey = 'YOUR_FCM_SERVER_KEY';

  // App Configuration
  static const String appName = 'Namma Ooru Delivery';
  static const String appZone = 'Thirupattur';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Feature Flags
  static const bool enableBiometricAuth = true;
  static const bool enableVoiceSearch = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;

  // Cache Configuration
  static const int imageCacheDuration = 7; // days
  static const int apiCacheDuration = 30; // minutes
  static const int locationCacheDuration = 5; // minutes

  // Location Configuration - Thirupattur Zone
  static const String defaultCity = 'Thirupattur';
  static const String defaultState = 'Tamil Nadu';
  static const String defaultZone = 'Thirupattur';
  static const double locationAccuracyThreshold = 10.0; // meters
  static const int locationUpdateInterval = 5000; // milliseconds
  static const int backgroundLocationInterval = 10000; // milliseconds

  // Order Configuration - Thirupattur Zone
  static const int orderCancellationWindow = 5; // minutes
  static const double deliveryRadiusKm = 15.0; // kilometers within Thirupattur
  static const int maxOrderItems = 50;
  static const double minOrderAmount = 50.0; // rupees

  // Chat Configuration
  static const int maxChatMessageLength = 500;
  static const int chatHistoryDays = 30;

  // File Upload Configuration
  static const int maxImageSizeMB = 5;
  static const int maxImageResolution = 1920;
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp'
  ];

  // Environment Check
  static bool get isProduction => baseUrl.contains('api.nammaooru.com');
  static bool get isDevelopment =>
      baseUrl.contains('localhost') || baseUrl.contains('dev');
  static bool get isStaging => baseUrl.contains('staging');

  // Regional Configuration
  static const String defaultLanguage = 'en';
  static const String defaultCurrency = 'INR';
  static const String defaultCountryCode = '+91';
  static const String defaultTimezone = 'Asia/Kolkata';

  // Error Tracking
  static const String sentryDsn = 'YOUR_SENTRY_DSN';
  static const bool enableErrorReporting = true;

  // Social Login
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';

  // Deep Links
  static const String appScheme = 'nammaooru';
  static const String webUrl = 'https://nammaooru.com';

  // Development Configuration
  static const bool showDebugInfo = false;
  static const bool enableLogging = true;
  static const bool enableNetworkLogging = false;

  // Performance Configuration
  static const int maxConcurrentRequests = 5;
  static const int requestTimeoutSeconds = 30;
  static const int connectTimeoutSeconds = 15;

  // Business Rules
  static const double freeDeliveryThreshold = 500.0; // rupees
  static const double deliveryFeePerKm = 5.0; // rupees
  static const double platformCommissionRate = 0.15; // 15%
  static const double gstRate = 0.18; // 18%

  // Get environment-specific configuration
  static Map<String, dynamic> getConfig() {
    return {
      'baseUrl': baseUrl,
      'apiVersion': apiVersion,
      'isProduction': isProduction,
      'isDevelopment': isDevelopment,
      'isStaging': isStaging,
      'appName': appName,
      'appVersion': appVersion,
      'buildNumber': appBuildNumber,
      'enableLogging': enableLogging && !isProduction,
      'enableDebugInfo': showDebugInfo && !isProduction,
    };
  }

  // Validate required configuration
  static bool validateConfig() {
    final requiredKeys = [
      googleMapsApiKey,
      razorpayKey,
      firebaseProjectId,
    ];

    return requiredKeys
        .every((key) => key.isNotEmpty && !key.startsWith('YOUR_'));
  }

  // Get API headers
  static Map<String, String> getApiHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': appVersion,
      'X-Platform': 'mobile',
      'X-Client': 'flutter',
    };
  }
}
