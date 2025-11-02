import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Environment configuration
  static const bool kIsProduction = bool.fromEnvironment('dart.vm.product');

  // API configuration
  static const bool useMockData = false; // Use real API
  static const bool enableApiLogging =
      !kIsProduction; // Enable API logging in debug mode

  // Feature flags
  static const bool enableWebSocket = true;
  static const bool enablePushNotifications = true;
  static const bool enableAudio = true;
  static const bool enableLocationServices = true;

  // App behavior configuration
  static const bool showDebugInfo = !kIsProduction;
  static const bool enableCrashReporting = kIsProduction;
  static const bool enableAnalytics = kIsProduction;

  // Performance configuration
  static const int cacheExpirationHours = kIsProduction ? 24 : 1;
  static const int requestTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // UI configuration
  static const bool enableAnimations = true;
  static const bool enableHapticFeedback = true;
  static const bool enableDarkMode = false;

  // Development helpers
  static const bool showWidgetInspector = !kIsProduction;
  static const bool enablePerformanceOverlay = false;

  // Mock data configuration
  static const int mockDelay = 500; // milliseconds
  static const bool simulateNetworkErrors = false;
  static const double networkErrorRate = 0.1; // 10% chance of error

  // Business logic configuration
  static const int maxProductsPerPage = 20;
  static const int maxOrdersPerPage = 20;
  static const int maxNotificationsPerPage = 20;
  static const int lowStockThreshold = 5;
  static const int criticalStockThreshold = 2;

  // Validation configuration
  static const int minPasswordLength = 6;
  static const int maxProductNameLength = 100;
  static const int maxDescriptionLength = 500;

  // File upload configuration
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Notification configuration
  static const bool enableNotificationSounds = true;
  static const bool enableNotificationVibration = true;
  static const int notificationRetentionDays = 30;

  // Timezone configuration
  static const String defaultTimezone = 'Asia/Kolkata'; // Indian Standard Time

  // Security configuration
  static const int sessionTimeoutMinutes =
      kIsProduction ? 60 : 1440; // 1 hour in prod, 24 hours in dev
  static const bool enableBiometricAuth = true;
  static const bool requirePinForOrders = false;

  // Helper methods
  static bool get isDebugMode => !kIsProduction;
  static bool get isReleaseMode => kIsProduction;

  static String get buildMode => kIsProduction ? 'Production' : 'Development';

  // Environment Label (Optional)
  static String get environmentLabel => kIsProduction ? 'PROD' : 'DEV';

  // ============================
  //   Environment-Aware URLs
  // ============================

  static String get apiBaseUrl {
    if (kIsWeb) {
      return kIsProduction
          ? 'https://nammaoorudelivary.in/api'
          : 'http://localhost:8080/api';
    }
    return kIsProduction
        ? 'https://nammaoorudelivary.in/api'
        : 'http://192.168.1.3:8080/api'; // your LAN IP for mobile testing
  }

  static String get serverBaseUrl {
    if (kIsWeb) {
      return kIsProduction
          ? 'https://nammaoorudelivary.in'
          : 'http://localhost:8080';
    }
    return kIsProduction
        ? 'https://nammaoorudelivary.in'
        : 'http://192.168.1.3:8080';
  }

  static String get webSocketUrl {
    if (kIsWeb) {
      return kIsProduction
          ? 'wss://nammaoorudelivary.in/ws'
          : 'ws://localhost:8080/ws';
    }
    return kIsProduction
        ? 'wss://nammaoorudelivary.in/ws'
        : 'ws://192.168.1.3:8080/ws';
  }

  // ============================
  //   Helper Functions
  // ============================

  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // Otherwise, prepend the server base URL
    return '$serverBaseUrl$imagePath';
  }

  // Configuration validation
  static bool get isValidConfiguration {
    // Add any configuration validation logic here
    return true;
  }

  // Print configuration summary for debugging
  static void printConfiguration() {
    if (!kIsProduction) {
      print('''
=== App Configuration ===
Build Mode: $buildMode
Environment: $environmentLabel
Use Mock Data: $useMockData
Enable API Logging: $enableApiLogging
API Base URL: $apiBaseUrl
Server Base URL: $serverBaseUrl
WebSocket URL: $webSocketUrl
Session Timeout: ${sessionTimeoutMinutes} min
========================
''');
    }
  }
}
