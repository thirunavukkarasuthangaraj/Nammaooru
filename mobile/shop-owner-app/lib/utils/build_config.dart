import 'package:flutter/foundation.dart';

class BuildConfig {
  // Build information
  static const String buildVersion = '1.0.0';
  static const int buildNumber = 1;
  static const String buildDate = '2024-01-15';

  // Environment detection
  static const bool kIsProduction = bool.fromEnvironment('dart.vm.product');
  static const bool kIsProfile = bool.fromEnvironment('dart.vm.profile');
  static const bool kIsDebug = !kIsProduction && !kIsProfile;

  // Build configuration
  static const String buildMode = kIsProduction
      ? 'production'
      : kIsProfile
          ? 'profile'
          : 'debug';

  // API Configuration
  static const String productionApiUrl = 'https://nammaoorudelivary.in/api';
  static const String stagingApiUrl = 'https://staging-api.nammaooru.com';
  static const String developmentApiUrl = 'http://192.168.1.10:8080/api';

  static String get apiUrl {
    if (kIsProduction) {
      return productionApiUrl;
    } else if (kIsProfile) {
      return stagingApiUrl;
    } else {
      return developmentApiUrl;
    }
  }

  // Firebase Configuration
  static const String productionFirebaseProject = 'nammaooru-prod';
  static const String stagingFirebaseProject = 'nammaooru-staging';
  static const String developmentFirebaseProject = 'nammaooru-dev';

  static String get firebaseProject {
    if (kIsProduction) {
      return productionFirebaseProject;
    } else if (kIsProfile) {
      return stagingFirebaseProject;
    } else {
      return developmentFirebaseProject;
    }
  }

  // Feature flags
  static const bool enableCrashReporting = kIsProduction || kIsProfile;
  static const bool enableAnalytics = kIsProduction || kIsProfile;
  static const bool enablePerformanceMonitoring = !kIsProduction;
  static const bool enableDebugTools = kIsDebug;
  static const bool enableMockData = kIsDebug;

  // Security configuration
  static const bool enableCertificatePinning = kIsProduction;
  static const bool enforceHttps = kIsProduction || kIsProfile;
  static const bool enableBiometricAuth = true;

  // App behavior
  static const int sessionTimeoutMinutes = kIsProduction ? 60 : 1440;
  static const bool enableDeviceBinding = kIsProduction;
  static const bool requireAppLock = kIsProduction;

  // Network configuration
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 60;
  static const int maxRetryAttempts = kIsProduction ? 3 : 1;

  // Cache configuration
  static const int cacheExpirationHours = kIsProduction ? 24 : 1;
  static const int maxCacheSizeMB = 100;
  static const bool enableOfflineMode = true;

  // Logging configuration
  static const bool enableDetailedLogging = !kIsProduction;
  static const bool enableNetworkLogging = kIsDebug;
  static const bool enablePerformanceLogging = !kIsProduction;

  // Build optimization flags
  static const bool enableTreeShaking = kIsProduction;
  static const bool enableObfuscation = kIsProduction;
  static const bool enableMinification = kIsProduction;
  static const bool stripDebugInfo = kIsProduction;

  // Asset configuration
  static const bool enableAssetOptimization = kIsProduction;
  static const bool enableImageCompression = kIsProduction;
  static const bool enableFontSubsetting = kIsProduction;

  // Update configuration
  static const bool enableForceUpdate = kIsProduction;
  static const bool enableInAppUpdates = kIsProduction;
  static const String minimumSupportedVersion = '1.0.0';

  // Print build configuration
  static void printConfiguration() {
    if (kDebugMode) {
      print('=== Build Configuration ===');
      print('Version: $buildVersion ($buildNumber)');
      print('Build Date: $buildDate');
      print('Build Mode: $buildMode');
      print('API URL: $apiUrl');
      print('Firebase Project: $firebaseProject');
      print('Crash Reporting: $enableCrashReporting');
      print('Analytics: $enableAnalytics');
      print('Performance Monitoring: $enablePerformanceMonitoring');
      print('Debug Tools: $enableDebugTools');
      print('Mock Data: $enableMockData');
      print('===========================');
    }
  }

  // Validate configuration
  static bool validateConfiguration() {
    // Ensure required configurations are set
    if (apiUrl.isEmpty) {
      throw Exception('API URL not configured');
    }

    if (firebaseProject.isEmpty) {
      throw Exception('Firebase project not configured');
    }

    // Validate version format
    if (!_isValidVersion(buildVersion)) {
      throw Exception('Invalid version format: $buildVersion');
    }

    return true;
  }

  static bool _isValidVersion(String version) {
    final regex = RegExp(r'^\d+\.\d+\.\d+$');
    return regex.hasMatch(version);
  }

  // Get build info map
  static Map<String, dynamic> getBuildInfo() {
    return {
      'version': buildVersion,
      'buildNumber': buildNumber,
      'buildDate': buildDate,
      'buildMode': buildMode,
      'isProduction': kIsProduction,
      'isProfile': kIsProfile,
      'isDebug': kIsDebug,
      'apiUrl': apiUrl,
      'firebaseProject': firebaseProject,
    };
  }
}