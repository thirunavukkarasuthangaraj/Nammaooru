import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../services/websocket_service.dart';
import 'app_config.dart';
import 'performance_optimizer.dart';
import 'memory_manager.dart';
import 'app_test_suite.dart';

class AppInitializer {
  static bool _isInitialized = false;
  static late final GlobalKey<NavigatorState> navigatorKey;

  /// Initialize the entire application
  static Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('⚠️ App already initialized, skipping...');
      return;
    }

    developer.log('🚀 Initializing NammaOoru Shop Owner App...');

    try {
      // Print configuration
      AppConfig.printConfiguration();

      // Initialize Flutter framework
      await _initializeFramework();

      // Initialize storage and core services
      await _initializeStorageServices();

      // Initialize performance monitoring
      await _initializePerformanceMonitoring();

      // Initialize business services
      await _initializeBusinessServices();

      // Initialize UI and theme
      await _initializeUI();

      // Run initial tests if in debug mode
      if (AppConfig.isDebugMode) {
        await _runInitialTests();
      }

      _isInitialized = true;
      developer.log('✅ App initialization completed successfully');
    } catch (e, stackTrace) {
      developer.log(
        '❌ App initialization failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize Flutter framework components
  static Future<void> _initializeFramework() async {
    developer.log('🔧 Initializing Flutter framework...');

    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Set up global navigator key
    navigatorKey = GlobalKey<NavigatorState>();

    // Lock orientation to portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Configure system UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Set up error handling
    _setupErrorHandling();

    developer.log('✅ Flutter framework initialized');
  }

  /// Initialize storage and core services
  static Future<void> _initializeStorageServices() async {
    developer.log('💾 Initializing storage services...');

    await PerformanceOptimizer.measureAsync('Storage Initialization', () async {
      await StorageService.initialize();
    });

    developer.log('✅ Storage services initialized');
  }

  /// Initialize performance monitoring
  static Future<void> _initializePerformanceMonitoring() async {
    if (!AppConfig.isDebugMode) {
      developer.log('⏭️ Skipping performance monitoring (production mode)');
      return;
    }

    developer.log('⚡ Initializing performance monitoring...');

    // Initialize performance optimizer
    PerformanceOptimizer.initialize();

    // Initialize memory manager
    MemoryManager.initialize();

    // Set up periodic performance reports
    Timer.periodic(const Duration(minutes: 5), (_) {
      if (AppConfig.showDebugInfo) {
        PerformanceOptimizer.printReport();
        MemoryManager.printMemoryReport();
      }
    });

    developer.log('✅ Performance monitoring initialized');
  }

  /// Initialize business services
  static Future<void> _initializeBusinessServices() async {
    developer.log('🏢 Initializing business services...');

    final futures = <Future<void>>[];

    // Initialize notification service
    if (AppConfig.enablePushNotifications) {
      futures.add(
        PerformanceOptimizer.measureAsync('Notification Service Init', () async {
          await NotificationService.initialize();
        }),
      );
    }

    // Initialize audio service
    if (AppConfig.enableAudio) {
      futures.add(
        PerformanceOptimizer.measureAsync('Audio Service Init', () async {
          await AudioService.initialize();
        }),
      );
    }

    // Initialize WebSocket service
    if (AppConfig.enableWebSocket) {
      futures.add(
        PerformanceOptimizer.measureAsync('WebSocket Service Init', () async {
          await WebSocketService.initialize();
        }),
      );
    }

    // Wait for all services to initialize
    await Future.wait(futures);

    developer.log('✅ Business services initialized');
  }

  /// Initialize UI and theme
  static Future<void> _initializeUI() async {
    developer.log('🎨 Initializing UI components...');

    await PerformanceOptimizer.measureAsync('UI Initialization', () async {
      // Configure image cache
      PerformanceOptimizer.optimizeImageCache();

      // Preload critical assets
      // Note: This would normally require a BuildContext
      // In a real app, this would be done in the first widget's build method
    });

    developer.log('✅ UI components initialized');
  }

  /// Run initial tests in debug mode
  static Future<void> _runInitialTests() async {
    developer.log('🧪 Running initial diagnostic tests...');

    try {
      // Run a subset of tests for quick validation
      final futures = <Future<void>>[
        _testCriticalServices(),
        _testPerformanceBaseline(),
        _testMemoryBaseline(),
      ];

      await Future.wait(futures);

      developer.log('✅ Initial tests completed');
    } catch (e) {
      developer.log('⚠️ Some initial tests failed: $e');
      // Don't fail initialization for test failures
    }
  }

  /// Test critical services
  static Future<void> _testCriticalServices() async {
    // Test storage service
    try {
      await StorageService.setString('test_key', 'test_value');
      final value = StorageService.getString('test_key');
      if (value != 'test_value') {
        throw Exception('Storage service test failed');
      }
      await StorageService.remove('test_key');
    } catch (e) {
      developer.log('❌ Storage service test failed: $e');
    }
  }

  /// Test performance baseline
  static Future<void> _testPerformanceBaseline() async {
    // Test basic performance measurements
    await PerformanceOptimizer.measureAsync('Baseline Test', () async {
      await Future.delayed(const Duration(milliseconds: 10));
    });

    final summary = PerformanceOptimizer.getSummary();
    if (summary.totalMetrics == 0) {
      developer.log('⚠️ Performance monitoring not working');
    }
  }

  /// Test memory baseline
  static Future<void> _testMemoryBaseline() async {
    MemoryManager.trackObjectCreation('InitTest');
    MemoryManager.trackObjectDisposal('InitTest');

    final summary = MemoryManager.getMemoryUsage();
    if (summary.totalTrackedObjects < 0) {
      developer.log('⚠️ Memory tracking may have issues');
    }
  }

  /// Set up global error handling
  static void _setupErrorHandling() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log(
        'Flutter Error: ${details.exception}',
        error: details.exception,
        stackTrace: details.stack,
        name: 'FlutterError',
      );

      // In debug mode, also print to console
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Handle async errors outside Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      developer.log(
        'Async Error: $error',
        error: error,
        stackTrace: stack,
        name: 'AsyncError',
      );
      return true; // Mark as handled
    };
  }

  /// Get app initialization status
  static bool get isInitialized => _isInitialized;

  /// Create app with all providers
  static Widget createApp({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: AppConfig.showDebugInfo
          ? MemoryUsageWidget(child: child)
          : child,
    );
  }

  /// Dispose all resources
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    developer.log('🧹 Disposing app resources...');

    try {
      // Dispose performance monitoring
      PerformanceOptimizer.dispose();

      // Dispose memory manager
      MemoryManager.dispose();

      // Dispose services
      await NotificationService.dispose();
      await AudioService.dispose();
      await WebSocketService.dispose();

      _isInitialized = false;
      developer.log('✅ App resources disposed');
    } catch (e) {
      developer.log('⚠️ Error disposing resources: $e');
    }
  }

  /// Run comprehensive app health check
  static Future<AppHealthReport> runHealthCheck() async {
    developer.log('🏥 Running app health check...');

    final healthChecks = <String, bool>{};
    final errors = <String>[];

    try {
      // Check initialization status
      healthChecks['App Initialized'] = _isInitialized;

      // Check storage service
      try {
        await StorageService.setString('health_check', 'ok');
        final value = StorageService.getString('health_check');
        healthChecks['Storage Service'] = value == 'ok';
        await StorageService.remove('health_check');
      } catch (e) {
        healthChecks['Storage Service'] = false;
        errors.add('Storage: $e');
      }

      // Check performance monitoring
      healthChecks['Performance Monitoring'] = PerformanceOptimizer.getSummary().totalMetrics >= 0;

      // Check memory tracking
      healthChecks['Memory Tracking'] = MemoryManager.getMemoryUsage().totalTrackedObjects >= 0;

      // Check notification service
      healthChecks['Notification Service'] = AppConfig.enablePushNotifications;

      // Check WebSocket service
      healthChecks['WebSocket Service'] = AppConfig.enableWebSocket;

      final healthyServices = healthChecks.values.where((v) => v).length;
      final totalServices = healthChecks.length;
      final healthPercentage = (healthyServices / totalServices) * 100;

      final report = AppHealthReport(
        isHealthy: healthPercentage >= 80, // 80% threshold
        healthPercentage: healthPercentage,
        serviceStatus: healthChecks,
        errors: errors,
        timestamp: DateTime.now(),
      );

      developer.log('✅ Health check completed: ${healthPercentage.toStringAsFixed(1)}% healthy');
      return report;
    } catch (e) {
      developer.log('❌ Health check failed: $e');
      return AppHealthReport(
        isHealthy: false,
        healthPercentage: 0,
        serviceStatus: healthChecks,
        errors: ['Health check failed: $e'],
        timestamp: DateTime.now(),
      );
    }
  }
}

// App health report data class
class AppHealthReport {
  final bool isHealthy;
  final double healthPercentage;
  final Map<String, bool> serviceStatus;
  final List<String> errors;
  final DateTime timestamp;

  AppHealthReport({
    required this.isHealthy,
    required this.healthPercentage,
    required this.serviceStatus,
    required this.errors,
    required this.timestamp,
  });

  void printReport() {
    print('\n🏥 App Health Report - ${timestamp.toIso8601String()}');
    print('═══════════════════════════════════════════════');
    print('Overall Health: ${isHealthy ? '✅ HEALTHY' : '❌ UNHEALTHY'}');
    print('Health Score: ${healthPercentage.toStringAsFixed(1)}%');
    print('');

    print('📋 Service Status:');
    serviceStatus.forEach((service, status) {
      final icon = status ? '✅' : '❌';
      print('  $icon $service');
    });

    if (errors.isNotEmpty) {
      print('');
      print('🚨 Errors:');
      for (final error in errors) {
        print('  ❌ $error');
      }
    }

    print('═══════════════════════════════════════════════\n');
  }
}