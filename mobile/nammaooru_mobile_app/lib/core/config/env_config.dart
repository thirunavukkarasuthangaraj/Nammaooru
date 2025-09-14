class EnvConfig {
  // Base API Configuration
  // DEVELOPMENT: Local development
  static const String baseUrl = 'http://localhost:8080';

  // PRODUCTION: Use your deployed server
  // static const String baseUrl = 'https://api.nammaoorudelivary.in';so
  // static const String baseUrl = 'http://10.0.2.2:8080'; // Android Emulator
  // static const String baseUrl = 'http://192.168.1.100:8080'; // Local Network IP

  static const String apiVersion = '';
  static const String fullApiUrl = '$baseUrl/api';

  // Google Services
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String googlePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';

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
  static const String appName = 'NammaOoru';
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

  // Location Configuration
  static const double locationAccuracyThreshold = 10.0; // meters
  static const int locationUpdateInterval = 5000; // milliseconds
  static const int backgroundLocationInterval = 10000; // milliseconds

  // Order Configuration
  static const int orderCancellationWindow = 5; // minutes
  static const double deliveryRadiusKm = 25.0; // kilometers
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
