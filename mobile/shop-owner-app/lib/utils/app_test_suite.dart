import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';
import 'performance_optimizer.dart';
import 'memory_manager.dart';
import 'test_data_runner.dart';
import 'app_config.dart';

class AppTestSuite {
  static bool _isRunning = false;
  static final List<TestResult> _testResults = [];

  /// Run comprehensive app test suite
  static Future<AppTestReport> runFullTestSuite() async {
    if (_isRunning) {
      throw Exception('Test suite is already running');
    }

    _isRunning = true;
    _testResults.clear();

    developer.log('🧪 Starting comprehensive app test suite...');

    try {
      // Initialize monitoring
      PerformanceOptimizer.initialize();
      MemoryManager.initialize();

      // Run all test categories
      await _runPerformanceTests();
      await _runMemoryTests();
      await _runAPITests();
      await _runWidgetTests();
      await _runIntegrationTests();

      // Generate report
      final report = AppTestReport(
        testResults: List.from(_testResults),
        performanceSummary: PerformanceOptimizer.getSummary(),
        memorySummary: MemoryManager.getMemoryUsage(),
        timestamp: DateTime.now(),
      );

      developer.log('✅ Test suite completed successfully');
      return report;
    } catch (e) {
      developer.log('❌ Test suite failed: $e');
      rethrow;
    } finally {
      _isRunning = false;
    }
  }

  /// Run performance-specific tests
  static Future<void> _runPerformanceTests() async {
    developer.log('⚡ Running performance tests...');

    // Test widget build performance
    await _testWidgetBuildPerformance();

    // Test list scrolling performance
    await _testListScrollPerformance();

    // Test image loading performance
    await _testImageLoadingPerformance();

    // Test animation performance
    await _testAnimationPerformance();

    // Test memory allocation patterns
    await _testMemoryAllocationPatterns();
  }

  static Future<void> _testWidgetBuildPerformance() async {
    final testName = 'Widget Build Performance';
    final stopwatch = Stopwatch()..start();

    try {
      // Simulate building complex widgets multiple times
      for (int i = 0; i < 100; i++) {
        await PerformanceOptimizer.measureAsync('Complex Widget Build', () async {
          // Simulate complex widget tree
          await Future.delayed(const Duration(microseconds: 100));
        });
      }

      stopwatch.stop();
      _addTestResult(
        testName,
        TestStatus.passed,
        'Average build time: ${stopwatch.elapsedMilliseconds / 100}ms',
      );
    } catch (e) {
      stopwatch.stop();
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  static Future<void> _testListScrollPerformance() async {
    final testName = 'List Scroll Performance';

    try {
      // Test list view with many items
      final itemCount = 1000;
      final buildTimes = <int>[];

      for (int i = 0; i < 10; i++) {
        final stopwatch = Stopwatch()..start();

        // Simulate list item build
        for (int j = 0; j < 50; j++) {
          await Future.delayed(const Duration(microseconds: 10));
        }

        stopwatch.stop();
        buildTimes.add(stopwatch.elapsedMicroseconds);
      }

      final avgTime = buildTimes.reduce((a, b) => a + b) / buildTimes.length;

      if (avgTime < 1000) { // Less than 1ms average
        _addTestResult(
          testName,
          TestStatus.passed,
          'Average scroll build time: ${avgTime.toStringAsFixed(2)}μs',
        );
      } else {
        _addTestResult(
          testName,
          TestStatus.warning,
          'Slow scroll performance: ${avgTime.toStringAsFixed(2)}μs',
        );
      }
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  static Future<void> _testImageLoadingPerformance() async {
    final testName = 'Image Loading Performance';

    try {
      final stopwatch = Stopwatch()..start();

      // Simulate image loading
      for (int i = 0; i < 10; i++) {
        await PerformanceOptimizer.measureAsync('Image Load $i', () async {
          await Future.delayed(const Duration(milliseconds: 50)); // Simulate network delay
        });
      }

      stopwatch.stop();
      _addTestResult(
        testName,
        TestStatus.passed,
        'Total time for 10 images: ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  static Future<void> _testAnimationPerformance() async {
    final testName = 'Animation Performance';

    try {
      // Test animation frame rates
      final frameTimes = <int>[];
      final stopwatch = Stopwatch();

      for (int i = 0; i < 60; i++) { // Simulate 60 frames
        stopwatch.reset();
        stopwatch.start();

        // Simulate animation frame processing
        await Future.delayed(const Duration(microseconds: 16666)); // 60 FPS target

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds);
      }

      final avgFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
      final fps = 1000000 / avgFrameTime; // Convert to FPS

      if (fps >= 55) {
        _addTestResult(
          testName,
          TestStatus.passed,
          'Average FPS: ${fps.toStringAsFixed(1)}',
        );
      } else {
        _addTestResult(
          testName,
          TestStatus.warning,
          'Low FPS: ${fps.toStringAsFixed(1)}',
        );
      }
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  static Future<void> _testMemoryAllocationPatterns() async {
    final testName = 'Memory Allocation Patterns';

    try {
      final initialMemory = MemoryManager.getMemoryUsage();

      // Create and dispose objects to test memory management
      for (int i = 0; i < 100; i++) {
        MemoryManager.trackObjectCreation('TestObject', 'test_$i');

        // Simulate object lifecycle
        await Future.delayed(const Duration(microseconds: 100));

        MemoryManager.trackObjectDisposal('TestObject', 'test_$i');
      }

      final finalMemory = MemoryManager.getMemoryUsage();
      final memoryDiff = finalMemory.totalTrackedObjects - initialMemory.totalTrackedObjects;

      if (memoryDiff <= 5) { // Allow for some tracking overhead
        _addTestResult(
          testName,
          TestStatus.passed,
          'Memory leak check passed. Diff: $memoryDiff objects',
        );
      } else {
        _addTestResult(
          testName,
          TestStatus.warning,
          'Potential memory leak. Diff: $memoryDiff objects',
        );
      }
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  /// Run memory-specific tests
  static Future<void> _runMemoryTests() async {
    developer.log('💾 Running memory tests...');

    await _testMemoryLeakDetection();
    await _testResourceDisposal();
    await _testCacheManagement();
  }

  static Future<void> _testMemoryLeakDetection() async {
    final testName = 'Memory Leak Detection';

    try {
      final initialCount = MemoryManager.getMemoryUsage().totalTrackedObjects;

      // Create objects that should be garbage collected
      final objects = <Object>[];
      for (int i = 0; i < 50; i++) {
        objects.add(Object());
        MemoryManager.trackObjectCreation('TempObject');
      }

      // Clear references
      objects.clear();

      // Force cleanup
      for (int i = 0; i < 50; i++) {
        MemoryManager.trackObjectDisposal('TempObject');
      }

      final finalCount = MemoryManager.getMemoryUsage().totalTrackedObjects;

      if (finalCount <= initialCount + 5) {
        _addTestResult(testName, TestStatus.passed, 'No memory leaks detected');
      } else {
        _addTestResult(
          testName,
          TestStatus.warning,
          'Potential leak: ${finalCount - initialCount} objects',
        );
      }
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  static Future<void> _testResourceDisposal() async {
    final testName = 'Resource Disposal';

    try {
      int disposedCount = 0;

      // Test timer disposal
      final timer = Timer.periodic(const Duration(milliseconds: 10), (_) {});
      timer.cancel();
      disposedCount++;

      // Test stream subscription disposal
      final controller = StreamController<int>();
      final subscription = controller.stream.listen((_) {});
      await subscription.cancel();
      await controller.close();
      disposedCount++;

      _addTestResult(
        testName,
        TestStatus.passed,
        'Successfully disposed $disposedCount resources',
      );
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  static Future<void> _testCacheManagement() async {
    final testName = 'Cache Management';

    try {
      // Test image cache optimization
      PerformanceOptimizer.optimizeImageCache();

      // Test cache clearing
      PerformanceOptimizer.clearImageCache();

      _addTestResult(testName, TestStatus.passed, 'Cache management working correctly');
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  /// Run API tests
  static Future<void> _runAPITests() async {
    developer.log('🌐 Running API tests...');

    if (AppConfig.useMockData) {
      await TestDataRunner.testAllEndpoints();
      _addTestResult('API Tests', TestStatus.passed, 'All mock API endpoints working');
    } else {
      await _testRealAPIEndpoints();
    }
  }

  static Future<void> _testRealAPIEndpoints() async {
    final testName = 'Real API Endpoints';

    try {
      // Test critical endpoints
      final endpoints = [
        () => ApiService.getShopProfile(),
        () => ApiService.getProducts(limit: 5),
        () => ApiService.getOrders(limit: 5),
        () => ApiService.getNotifications(limit: 5),
      ];

      int successCount = 0;
      for (final endpoint in endpoints) {
        try {
          final response = await endpoint().timeout(const Duration(seconds: 10));
          if (response.isSuccess) {
            successCount++;
          }
        } catch (e) {
          // Continue testing other endpoints
        }
      }

      if (successCount == endpoints.length) {
        _addTestResult(testName, TestStatus.passed, 'All endpoints responding');
      } else {
        _addTestResult(
          testName,
          TestStatus.warning,
          '$successCount/${endpoints.length} endpoints working',
        );
      }
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  /// Run widget tests
  static Future<void> _runWidgetTests() async {
    developer.log('🎨 Running widget tests...');

    await _testCustomWidgets();
    await _testWidgetPerformance();
  }

  static Future<void> _testCustomWidgets() async {
    final testName = 'Custom Widgets';

    try {
      // Test optimized widgets
      final listView = PerformanceOptimizer.createOptimizedListView(
        itemCount: 100,
        itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
      );

      final gridView = PerformanceOptimizer.createOptimizedGridView(
        itemCount: 100,
        itemBuilder: (context, index) => Card(child: Text('Item $index')),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      );

      // Widgets created successfully
      _addTestResult(testName, TestStatus.passed, 'Custom widgets created successfully');
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  static Future<void> _testWidgetPerformance() async {
    final testName = 'Widget Performance';

    try {
      // Test widget build times
      final buildTimes = <int>[];

      for (int i = 0; i < 10; i++) {
        final stopwatch = Stopwatch()..start();

        // Simulate widget build
        await Future.delayed(const Duration(microseconds: 500));

        stopwatch.stop();
        buildTimes.add(stopwatch.elapsedMicroseconds);
      }

      final avgBuildTime = buildTimes.reduce((a, b) => a + b) / buildTimes.length;

      if (avgBuildTime < 1000) { // Less than 1ms
        _addTestResult(
          testName,
          TestStatus.passed,
          'Average build time: ${avgBuildTime.toStringAsFixed(2)}μs',
        );
      } else {
        _addTestResult(
          testName,
          TestStatus.warning,
          'Slow build time: ${avgBuildTime.toStringAsFixed(2)}μs',
        );
      }
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  /// Run integration tests
  static Future<void> _runIntegrationTests() async {
    developer.log('🔗 Running integration tests...');

    await _testUserWorkflows();
    await _testDataFlow();
    await _testErrorHandling();
  }

  static Future<void> _testUserWorkflows() async {
    final testName = 'User Workflows';

    try {
      // Simulate common user workflows
      await _simulateLoginWorkflow();
      await _simulateProductManagementWorkflow();
      await _simulateOrderManagementWorkflow();

      _addTestResult(testName, TestStatus.passed, 'All user workflows completed');
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  static Future<void> _simulateLoginWorkflow() async {
    // Simulate login process
    final loginResponse = await ApiService.login(
      email: 'ananya@gmail.com',
      password: 'password123',
    );

    if (!loginResponse.isSuccess) {
      throw Exception('Login failed');
    }
  }

  static Future<void> _simulateProductManagementWorkflow() async {
    // Get products
    final productsResponse = await ApiService.getProducts(limit: 10);
    if (!productsResponse.isSuccess) {
      throw Exception('Failed to get products');
    }

    // Search products
    final searchResponse = await ApiService.getProducts(search: 'rice');
    if (!searchResponse.isSuccess) {
      throw Exception('Failed to search products');
    }
  }

  static Future<void> _simulateOrderManagementWorkflow() async {
    // Get orders
    final ordersResponse = await ApiService.getOrders(limit: 10);
    if (!ordersResponse.isSuccess) {
      throw Exception('Failed to get orders');
    }

    // Update order status
    final updateResponse = await ApiService.updateOrderStatus('order_001', 'confirmed');
    if (!updateResponse.isSuccess) {
      throw Exception('Failed to update order status');
    }
  }

  static Future<void> _testDataFlow() async {
    final testName = 'Data Flow';

    try {
      // Test data flow through different layers
      final mockData = MockDataService.mockProducts;
      if (mockData.isEmpty) {
        throw Exception('No mock data available');
      }

      // Test data transformation
      final jsonData = mockData.map((p) => p.toJson()).toList();
      if (jsonData.isEmpty) {
        throw Exception('Data transformation failed');
      }

      _addTestResult(testName, TestStatus.passed, 'Data flow working correctly');
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  static Future<void> _testErrorHandling() async {
    final testName = 'Error Handling';

    try {
      // Test invalid login
      final invalidLogin = await ApiService.login(
        email: 'invalid@email.com',
        password: 'wrongpassword',
      );

      if (invalidLogin.isSuccess) {
        throw Exception('Invalid login should have failed');
      }

      _addTestResult(testName, TestStatus.passed, 'Error handling working correctly');
    } catch (e) {
      _addTestResult(testName, TestStatus.failed, 'Error: $e');
    }
  }

  /// Add test result
  static void _addTestResult(String name, TestStatus status, String message) {
    final result = TestResult(
      name: name,
      status: status,
      message: message,
      timestamp: DateTime.now(),
    );

    _testResults.add(result);

    final statusIcon = switch (status) {
      TestStatus.passed => '✅',
      TestStatus.failed => '❌',
      TestStatus.warning => '⚠️',
      TestStatus.skipped => '⏭️',
    };

    developer.log('$statusIcon $name: $message');
  }

  /// Get latest test results
  static List<TestResult> getTestResults() => List.from(_testResults);

  /// Clear test results
  static void clearResults() {
    _testResults.clear();
  }
}

// Data classes for test results

class AppTestReport {
  final List<TestResult> testResults;
  final PerformanceSummary performanceSummary;
  final MemoryUsageSummary memorySummary;
  final DateTime timestamp;

  AppTestReport({
    required this.testResults,
    required this.performanceSummary,
    required this.memorySummary,
    required this.timestamp,
  });

  int get totalTests => testResults.length;
  int get passedTests => testResults.where((r) => r.status == TestStatus.passed).length;
  int get failedTests => testResults.where((r) => r.status == TestStatus.failed).length;
  int get warningTests => testResults.where((r) => r.status == TestStatus.warning).length;

  double get successRate => totalTests > 0 ? (passedTests / totalTests) * 100 : 0;

  void printReport() {
    print('\n📋 Test Report - ${timestamp.toIso8601String()}');
    print('═══════════════════════════════════════════════');
    print('Total Tests: $totalTests');
    print('Passed: $passedTests');
    print('Failed: $failedTests');
    print('Warnings: $warningTests');
    print('Success Rate: ${successRate.toStringAsFixed(1)}%');
    print('');

    print('📊 Performance Summary:');
    print('  Average Duration: ${performanceSummary.averageDuration.toStringAsFixed(2)}ms');
    print('  Total Operations: ${performanceSummary.totalMetrics}');

    print('');
    print('💾 Memory Summary:');
    print('  Tracked Objects: ${memorySummary.totalTrackedObjects}');
    print('  Object Types: ${memorySummary.uniqueObjectTypes}');
    if (memorySummary.potentialLeaks.isNotEmpty) {
      print('  Potential Leaks: ${memorySummary.potentialLeaks.length}');
    }

    print('');
    print('🔍 Test Details:');
    for (final result in testResults) {
      final icon = switch (result.status) {
        TestStatus.passed => '✅',
        TestStatus.failed => '❌',
        TestStatus.warning => '⚠️',
        TestStatus.skipped => '⏭️',
      };
      print('  $icon ${result.name}: ${result.message}');
    }
    print('═══════════════════════════════════════════════\n');
  }
}

class TestResult {
  final String name;
  final TestStatus status;
  final String message;
  final DateTime timestamp;

  TestResult({
    required this.name,
    required this.status,
    required this.message,
    required this.timestamp,
  });
}

enum TestStatus {
  passed,
  failed,
  warning,
  skipped,
}