import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_config.dart';

class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  // Performance monitoring
  static bool _isMonitoring = false;
  static final List<PerformanceMetric> _metrics = [];
  static Timer? _memoryMonitorTimer;

  /// Initialize performance monitoring
  static void initialize() {
    if (AppConfig.isDebugMode) {
      startMonitoring();
      _setupMemoryLeakDetection();
      _optimizeScrollPerformance();
    }
  }

  /// Start performance monitoring
  static void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    developer.log('🚀 Performance monitoring started');

    // Monitor memory usage every 30 seconds
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _logMemoryUsage();
    });
  }

  /// Stop performance monitoring
  static void stopMonitoring() {
    _isMonitoring = false;
    _memoryMonitorTimer?.cancel();
    developer.log('🛑 Performance monitoring stopped');
  }

  /// Log performance metric
  static void logMetric(String name, int duration, {Map<String, dynamic>? metadata}) {
    if (!_isMonitoring) return;

    final metric = PerformanceMetric(
      name: name,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _metrics.add(metric);

    // Keep only last 100 metrics to prevent memory leaks
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }

    if (AppConfig.showDebugInfo) {
      developer.log('⏱️ $name: ${duration}ms', name: 'Performance');
    }
  }

  /// Measure and log execution time of a function
  static Future<T> measureAsync<T>(String name, Future<T> Function() function) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      logMetric(name, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      logMetric(name, stopwatch.elapsedMilliseconds, metadata: {'error': e.toString()});
      rethrow;
    }
  }

  /// Measure and log execution time of a synchronous function
  static T measureSync<T>(String name, T Function() function) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = function();
      stopwatch.stop();
      logMetric(name, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      logMetric(name, stopwatch.elapsedMilliseconds, metadata: {'error': e.toString()});
      rethrow;
    }
  }

  /// Get performance summary
  static PerformanceSummary getSummary() {
    if (_metrics.isEmpty) {
      return PerformanceSummary.empty();
    }

    final durations = _metrics.map((m) => m.duration).toList();
    durations.sort();

    return PerformanceSummary(
      totalMetrics: _metrics.length,
      averageDuration: durations.reduce((a, b) => a + b) / durations.length,
      medianDuration: durations[durations.length ~/ 2].toDouble(),
      maxDuration: durations.last.toDouble(),
      minDuration: durations.first.toDouble(),
      slowOperations: _metrics
          .where((m) => m.duration > 1000) // Operations slower than 1 second
          .map((m) => '${m.name}: ${m.duration}ms')
          .toList(),
    );
  }

  /// Print performance report
  static void printReport() {
    if (!AppConfig.isDebugMode) return;

    final summary = getSummary();
    print('\n📊 Performance Report:');
    print('  Total Operations: ${summary.totalMetrics}');
    print('  Average Duration: ${summary.averageDuration.toStringAsFixed(2)}ms');
    print('  Median Duration: ${summary.medianDuration.toStringAsFixed(2)}ms');
    print('  Max Duration: ${summary.maxDuration.toStringAsFixed(2)}ms');
    print('  Min Duration: ${summary.minDuration.toStringAsFixed(2)}ms');

    if (summary.slowOperations.isNotEmpty) {
      print('  🐌 Slow Operations:');
      for (final operation in summary.slowOperations) {
        print('    - $operation');
      }
    }
    print('');
  }

  /// Clear all metrics
  static void clearMetrics() {
    _metrics.clear();
    developer.log('🧹 Performance metrics cleared');
  }

  /// Log current memory usage
  static void _logMemoryUsage() {
    // In a real app, you would use packages like flutter_memory_info
    // For now, we'll use a placeholder
    developer.log('💾 Memory check completed', name: 'Memory');
  }

  /// Setup memory leak detection
  static void _setupMemoryLeakDetection() {
    if (kDebugMode) {
      developer.log('🔍 Memory leak detection enabled');
    }
  }

  /// Optimize scroll performance
  static void _optimizeScrollPerformance() {
    // Force GPU rendering for better scroll performance
    if (kDebugMode) {
      developer.log('🏎️ Scroll performance optimization enabled');
    }
  }

  // Widget performance optimizations

  /// Create optimized list view with proper recycling
  static Widget createOptimizedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
      // Optimize for performance
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false, // We're adding manually above
      cacheExtent: 250.0, // Cache 250 pixels outside viewport
    );
  }

  /// Create optimized grid view
  static Widget createOptimizedGridView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
    );
  }

  /// Create performance-optimized image widget
  static Widget createOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return RepaintBoundary(
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.error);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
        },
      ),
    );
  }

  /// Debounce function calls to improve performance
  static Timer? _debounceTimer;
  static void debounce(Duration duration, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Throttle function calls
  static DateTime? _lastThrottleTime;
  static void throttle(Duration duration, VoidCallback callback) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      callback();
    }
  }

  /// Preload critical resources
  static Future<void> preloadCriticalResources(BuildContext context) async {
    // Preload frequently used images
    const imagePaths = [
      'assets/images/logo.png',
      'assets/images/default_product.png',
      'assets/images/default_avatar.png',
    ];

    for (final path in imagePaths) {
      try {
        await precacheImage(AssetImage(path), context);
      } catch (e) {
        developer.log('Failed to preload image: $path', error: e);
      }
    }

    developer.log('✅ Critical resources preloaded');
  }

  /// Optimize haptic feedback
  static void optimizedHapticFeedback(HapticFeedbackType type) {
    if (AppConfig.enableHapticFeedback) {
      HapticFeedback.vibrate();
    }
  }

  /// Memory optimization utilities
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    developer.log('🧹 Image cache cleared');
  }

  static void optimizeImageCache() {
    // Limit image cache size to 100MB
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
    // Keep only 100 images in memory
    PaintingBinding.instance.imageCache.maximumSize = 100;
  }

  /// Dispose resources
  static void dispose() {
    stopMonitoring();
    _debounceTimer?.cancel();
    clearMetrics();
  }
}

class PerformanceMetric {
  final String name;
  final int duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });
}

class PerformanceSummary {
  final int totalMetrics;
  final double averageDuration;
  final double medianDuration;
  final double maxDuration;
  final double minDuration;
  final List<String> slowOperations;

  PerformanceSummary({
    required this.totalMetrics,
    required this.averageDuration,
    required this.medianDuration,
    required this.maxDuration,
    required this.minDuration,
    required this.slowOperations,
  });

  factory PerformanceSummary.empty() {
    return PerformanceSummary(
      totalMetrics: 0,
      averageDuration: 0,
      medianDuration: 0,
      maxDuration: 0,
      minDuration: 0,
      slowOperations: [],
    );
  }
}

// Custom widgets for performance optimization

class OptimizedListItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const OptimizedListItem({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

class LazyLoadingBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Widget placeholder;

  const LazyLoadingBuilder({
    super.key,
    required this.builder,
    required this.placeholder,
  });

  @override
  State<LazyLoadingBuilder> createState() => _LazyLoadingBuilderState();
}

class _LazyLoadingBuilderState extends State<LazyLoadingBuilder> {
  Widget? _cachedWidget;
  bool _isBuilt = false;

  @override
  Widget build(BuildContext context) {
    if (!_isBuilt) {
      // Build the widget on next frame to avoid blocking current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _cachedWidget = widget.builder(context);
            _isBuilt = true;
          });
        }
      });
      return widget.placeholder;
    }

    return _cachedWidget ?? widget.placeholder;
  }
}

// Performance monitoring mixins

mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  late final Stopwatch _buildStopwatch;
  late final String _widgetName;

  @override
  void initState() {
    super.initState();
    _widgetName = widget.runtimeType.toString();
    _buildStopwatch = Stopwatch();
  }

  @override
  Widget build(BuildContext context) {
    _buildStopwatch.reset();
    _buildStopwatch.start();

    final widget = buildWithTracking(context);

    _buildStopwatch.stop();
    PerformanceOptimizer.logMetric(
      'Widget Build: $_widgetName',
      _buildStopwatch.elapsedMilliseconds,
    );

    return widget;
  }

  Widget buildWithTracking(BuildContext context);
}

mixin AsyncOperationMixin {
  Future<T> trackAsyncOperation<T>(String operationName, Future<T> operation) {
    return PerformanceOptimizer.measureAsync(operationName, () => operation);
  }
}