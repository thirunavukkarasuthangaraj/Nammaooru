import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, Duration> _operationTimes = {};
  final List<FrameMetrics> _frameMetrics = [];
  bool _isMonitoring = false;

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    if (kDebugMode) {
      // Monitor frame rendering performance
      SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);

      // Monitor timeline events
      developer.Timeline.startSync('PerformanceMonitoring');

      debugPrint('🚀 Performance monitoring started');
    }
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;

    if (kDebugMode) {
      SchedulerBinding.instance.removePersistentFrameCallback(_onFrame);
      developer.Timeline.finishSync();

      _printPerformanceReport();
      debugPrint('⏹️ Performance monitoring stopped');
    }
  }

  /// Start timing an operation
  void startOperation(String operationName) {
    if (kDebugMode) {
      _startTimes[operationName] = DateTime.now();
      developer.Timeline.startSync(operationName);
    }
  }

  /// End timing an operation
  void endOperation(String operationName) {
    if (kDebugMode) {
      final endTime = DateTime.now();
      final startTime = _startTimes.remove(operationName);

      if (startTime != null) {
        final duration = endTime.difference(startTime);
        _operationTimes[operationName] = duration;

        developer.Timeline.finishSync();

        // Log slow operations
        if (duration.inMilliseconds > 100) {
          debugPrint('⚠️ Slow operation: $operationName took ${duration.inMilliseconds}ms');
        }
      }
    }
  }

  /// Time a specific operation
  Future<T> timeOperation<T>(String operationName, Future<T> Function() operation) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }

  /// Time a synchronous operation
  T timeSync<T>(String operationName, T Function() operation) {
    startOperation(operationName);
    try {
      final result = operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }

  /// Monitor frame rendering
  void _onFrame(Duration timestamp) {
    final frameMetrics = SchedulerBinding.instance.currentFrameTimeStamp;

    // Store frame metrics for analysis
    if (_frameMetrics.length > 100) {
      _frameMetrics.removeAt(0);
    }

    // Check for janky frames (> 16.67ms for 60fps)
    final frameDuration = timestamp;
    if (frameDuration.inMilliseconds > 16) {
      debugPrint('🐌 Janky frame detected: ${frameDuration.inMilliseconds}ms');
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getMetrics() {
    return {
      'operationTimes': Map<String, int>.from(
        _operationTimes.map((key, value) => MapEntry(key, value.inMilliseconds))
      ),
      'averageFrameTime': _getAverageFrameTime(),
      'slowOperations': _getSlowOperations(),
      'frameDrops': _getFrameDropCount(),
    };
  }

  /// Get average frame time
  double _getAverageFrameTime() {
    if (_frameMetrics.isEmpty) return 0.0;

    final totalTime = _frameMetrics.fold<int>(
      0,
      (sum, metrics) => sum + metrics.totalSpan.inMicroseconds
    );

    return totalTime / _frameMetrics.length / 1000.0; // Convert to milliseconds
  }

  /// Get operations that took longer than threshold
  List<Map<String, dynamic>> _getSlowOperations({int thresholdMs = 100}) {
    return _operationTimes.entries
        .where((entry) => entry.value.inMilliseconds > thresholdMs)
        .map((entry) => {
              'operation': entry.key,
              'duration': entry.value.inMilliseconds,
            })
        .toList();
  }

  /// Get frame drop count
  int _getFrameDropCount() {
    return _frameMetrics.where((metrics) =>
      metrics.totalSpan.inMilliseconds > 16
    ).length;
  }

  /// Print performance report
  void _printPerformanceReport() {
    debugPrint('\n📊 Performance Report:');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Operation times
    if (_operationTimes.isNotEmpty) {
      debugPrint('📈 Operation Times:');
      final sortedOperations = _operationTimes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedOperations.take(10)) {
        debugPrint('  • ${entry.key}: ${entry.value.inMilliseconds}ms');
      }
    }

    // Frame performance
    if (_frameMetrics.isNotEmpty) {
      debugPrint('🎬 Frame Performance:');
      debugPrint('  • Average frame time: ${_getAverageFrameTime().toStringAsFixed(2)}ms');
      debugPrint('  • Frame drops: ${_getFrameDropCount()}');
      debugPrint('  • Total frames analyzed: ${_frameMetrics.length}');
    }

    // Slow operations
    final slowOps = _getSlowOperations();
    if (slowOps.isNotEmpty) {
      debugPrint('⚠️ Slow Operations (>100ms):');
      for (final op in slowOps) {
        debugPrint('  • ${op['operation']}: ${op['duration']}ms');
      }
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  /// Clear all metrics
  void clearMetrics() {
    _startTimes.clear();
    _operationTimes.clear();
    _frameMetrics.clear();
    debugPrint('📊 Performance metrics cleared');
  }

  /// Log memory usage
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      final info = ProcessInfo.currentRss;
      final mb = (info / 1024 / 1024).toStringAsFixed(2);
      debugPrint('🧠 Memory usage in $context: ${mb}MB');
    }
  }

  /// Profile widget build time
  static Widget profileWidget({
    required Widget child,
    required String name,
  }) {
    if (!kDebugMode) return child;

    return Builder(
      builder: (context) {
        final monitor = PerformanceMonitor();

        return StatefulWidget(
          child: StatefulBuilder(
            builder: (context, setState) {
              monitor.startOperation('Widget Build: $name');

              WidgetsBinding.instance.addPostFrameCallback((_) {
                monitor.endOperation('Widget Build: $name');
              });

              return child;
            },
          ),
        ).child!;
      },
    );
  }

  /// Auto-optimize based on device performance
  static Map<String, dynamic> getOptimizationSettings() {
    // Simple heuristic based on device capabilities
    // In production, this could be more sophisticated

    final isLowEndDevice = _isLowEndDevice();

    return {
      'enableAnimations': !isLowEndDevice,
      'imageQuality': isLowEndDevice ? 60 : 80,
      'cacheSize': isLowEndDevice ? 50 : 200,
      'maxConcurrentRequests': isLowEndDevice ? 2 : 6,
      'enableBlur': !isLowEndDevice,
      'enableShadows': !isLowEndDevice,
      'listItemHeight': isLowEndDevice ? 60.0 : 80.0,
    };
  }

  /// Simple heuristic to detect low-end devices
  static bool _isLowEndDevice() {
    // This is a simplified check
    // In production, you might want to use device_info_plus
    // to get more detailed device specifications

    try {
      final info = ProcessInfo.currentRss;
      return info < 1024 * 1024 * 512; // Less than 512MB RAM
    } catch (e) {
      return false;
    }
  }
}

/// Extension to easily add performance monitoring to any widget
extension PerformanceWidgetExtension on Widget {
  Widget withPerformanceMonitoring(String name) {
    return PerformanceMonitor.profileWidget(
      child: this,
      name: name,
    );
  }
}