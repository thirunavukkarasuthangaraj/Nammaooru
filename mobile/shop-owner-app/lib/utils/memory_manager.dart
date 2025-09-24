import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'app_config.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  // Memory tracking
  static final Map<String, int> _objectCounts = {};
  static final Map<String, List<String>> _stackTraces = {};
  static Timer? _monitoringTimer;
  static bool _isMonitoring = false;

  /// Initialize memory monitoring
  static void initialize() {
    if (AppConfig.isDebugMode) {
      startMonitoring();
      _setupLeakDetection();
    }
  }

  /// Start memory monitoring
  static void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    developer.log('🔍 Memory monitoring started');

    // Monitor memory every 60 seconds
    _monitoringTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkMemoryUsage();
      _detectPotentialLeaks();
    });
  }

  /// Stop memory monitoring
  static void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    developer.log('🛑 Memory monitoring stopped');
  }

  /// Track object creation
  static void trackObjectCreation(String objectType, [String? identifier]) {
    if (!AppConfig.isDebugMode) return;

    final key = identifier != null ? '$objectType:$identifier' : objectType;
    _objectCounts[key] = (_objectCounts[key] ?? 0) + 1;

    if (kDebugMode && AppConfig.showDebugInfo) {
      final stackTrace = StackTrace.current.toString();
      _stackTraces[key] = (_stackTraces[key] ?? [])..add(stackTrace);
    }
  }

  /// Track object disposal
  static void trackObjectDisposal(String objectType, [String? identifier]) {
    if (!AppConfig.isDebugMode) return;

    final key = identifier != null ? '$objectType:$identifier' : objectType;
    if (_objectCounts.containsKey(key)) {
      _objectCounts[key] = (_objectCounts[key]! - 1).clamp(0, double.infinity).toInt();

      if (_objectCounts[key] == 0) {
        _objectCounts.remove(key);
        _stackTraces.remove(key);
      }
    }
  }

  /// Get memory usage summary
  static MemoryUsageSummary getMemoryUsage() {
    final totalObjects = _objectCounts.values.fold<int>(0, (sum, count) => sum + count);
    final leakyObjects = _objectCounts.entries
        .where((entry) => entry.value > 10) // Objects with more than 10 instances
        .map((entry) => '${entry.key}: ${entry.value} instances')
        .toList();

    return MemoryUsageSummary(
      totalTrackedObjects: totalObjects,
      uniqueObjectTypes: _objectCounts.length,
      potentialLeaks: leakyObjects,
      objectCounts: Map.from(_objectCounts),
    );
  }

  /// Print memory report
  static void printMemoryReport() {
    if (!AppConfig.isDebugMode) return;

    final summary = getMemoryUsage();
    print('\n💾 Memory Usage Report:');
    print('  Total Tracked Objects: ${summary.totalTrackedObjects}');
    print('  Unique Object Types: ${summary.uniqueObjectTypes}');

    if (summary.potentialLeaks.isNotEmpty) {
      print('  🚨 Potential Memory Leaks:');
      for (final leak in summary.potentialLeaks) {
        print('    - $leak');
      }
    }

    if (summary.objectCounts.isNotEmpty) {
      print('  📊 Object Counts:');
      final sortedCounts = summary.objectCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedCounts.take(10)) {
        print('    ${entry.key}: ${entry.value}');
      }
    }
    print('');
  }

  /// Check current memory usage
  static void _checkMemoryUsage() {
    final summary = getMemoryUsage();

    if (summary.totalTrackedObjects > 1000) {
      developer.log(
        '⚠️ High object count: ${summary.totalTrackedObjects}',
        name: 'Memory',
      );
    }

    if (summary.potentialLeaks.isNotEmpty) {
      developer.log(
        '🚨 Potential leaks detected: ${summary.potentialLeaks.length}',
        name: 'Memory',
      );
    }
  }

  /// Detect potential memory leaks
  static void _detectPotentialLeaks() {
    final leaks = _objectCounts.entries
        .where((entry) => entry.value > 20) // More aggressive threshold
        .toList();

    for (final leak in leaks) {
      developer.log(
        '🚨 Memory leak detected: ${leak.key} has ${leak.value} instances',
        name: 'MemoryLeak',
      );

      // Print stack traces for leaked objects
      if (_stackTraces.containsKey(leak.key)) {
        final traces = _stackTraces[leak.key]!;
        if (traces.isNotEmpty) {
          developer.log(
            'Stack trace for ${leak.key}:\n${traces.last}',
            name: 'MemoryLeak',
          );
        }
      }
    }
  }

  /// Setup leak detection
  static void _setupLeakDetection() {
    developer.log('🔍 Memory leak detection enabled');

    // Set up global error handler for uncaught exceptions
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
  }

  /// Clear all tracking data
  static void clearTracking() {
    _objectCounts.clear();
    _stackTraces.clear();
    developer.log('🧹 Memory tracking data cleared');
  }

  /// Force garbage collection (for testing)
  static void forceGarbageCollection() {
    if (kDebugMode) {
      // Note: Dart doesn't expose GC directly, but we can trigger it indirectly
      final list = List.filled(1000000, 0);
      list.clear();
      developer.log('🗑️ Garbage collection triggered');
    }
  }

  /// Dispose resources
  static void dispose() {
    stopMonitoring();
    clearTracking();
  }
}

class MemoryUsageSummary {
  final int totalTrackedObjects;
  final int uniqueObjectTypes;
  final List<String> potentialLeaks;
  final Map<String, int> objectCounts;

  MemoryUsageSummary({
    required this.totalTrackedObjects,
    required this.uniqueObjectTypes,
    required this.potentialLeaks,
    required this.objectCounts,
  });
}

// Mixin for automatic memory tracking of StatefulWidgets
mixin MemoryTrackingMixin<T extends StatefulWidget> on State<T> {
  late final String _widgetId;

  @override
  void initState() {
    super.initState();
    _widgetId = '${widget.runtimeType}_${hashCode}';
    MemoryManager.trackObjectCreation('Widget', _widgetId);
  }

  @override
  void dispose() {
    MemoryManager.trackObjectDisposal('Widget', _widgetId);
    super.dispose();
  }
}

// Mixin for tracking disposable resources
mixin DisposableResourceMixin {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<AnimationController> _animationControllers = [];

  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
    MemoryManager.trackObjectCreation('StreamSubscription');
  }

  void addTimer(Timer timer) {
    _timers.add(timer);
    MemoryManager.trackObjectCreation('Timer');
  }

  void addAnimationController(AnimationController controller) {
    _animationControllers.add(controller);
    MemoryManager.trackObjectCreation('AnimationController');
  }

  void disposeResources() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
      MemoryManager.trackObjectDisposal('StreamSubscription');
    }
    _subscriptions.clear();

    // Cancel all timers
    for (final timer in _timers) {
      timer.cancel();
      MemoryManager.trackObjectDisposal('Timer');
    }
    _timers.clear();

    // Dispose animation controllers
    for (final controller in _animationControllers) {
      controller.dispose();
      MemoryManager.trackObjectDisposal('AnimationController');
    }
    _animationControllers.clear();
  }
}

// Memory-aware StreamSubscription wrapper
class ManagedStreamSubscription<T> {
  final StreamSubscription<T> _subscription;
  final String _identifier;

  ManagedStreamSubscription._(this._subscription, this._identifier) {
    MemoryManager.trackObjectCreation('ManagedStreamSubscription', _identifier);
  }

  factory ManagedStreamSubscription.from(
    Stream<T> stream,
    void Function(T) onData, {
    String? identifier,
  }) {
    final id = identifier ?? 'subscription_${DateTime.now().millisecondsSinceEpoch}';
    final subscription = stream.listen(onData);
    return ManagedStreamSubscription._(subscription, id);
  }

  void cancel() {
    _subscription.cancel();
    MemoryManager.trackObjectDisposal('ManagedStreamSubscription', _identifier);
  }

  void pause() => _subscription.pause();
  void resume() => _subscription.resume();
  bool get isPaused => _subscription.isPaused;

  Future<void> asFuture([T? futureValue]) => _subscription.asFuture(futureValue);
}

// Memory-aware Timer wrapper
class ManagedTimer {
  final Timer _timer;
  final String _identifier;

  ManagedTimer._(this._timer, this._identifier) {
    MemoryManager.trackObjectCreation('ManagedTimer', _identifier);
  }

  factory ManagedTimer.periodic(
    Duration duration,
    void Function(Timer) callback, {
    String? identifier,
  }) {
    final id = identifier ?? 'timer_${DateTime.now().millisecondsSinceEpoch}';
    final timer = Timer.periodic(duration, callback);
    return ManagedTimer._(timer, id);
  }

  factory ManagedTimer(
    Duration duration,
    void Function() callback, {
    String? identifier,
  }) {
    final id = identifier ?? 'timer_${DateTime.now().millisecondsSinceEpoch}';
    final timer = Timer(duration, callback);
    return ManagedTimer._(timer, id);
  }

  void cancel() {
    _timer.cancel();
    MemoryManager.trackObjectDisposal('ManagedTimer', _identifier);
  }

  bool get isActive => _timer.isActive;
  int get tick => _timer.tick;
}

// Widget for displaying memory usage in debug mode
class MemoryUsageWidget extends StatefulWidget {
  final Widget child;

  const MemoryUsageWidget({super.key, required this.child});

  @override
  State<MemoryUsageWidget> createState() => _MemoryUsageWidgetState();
}

class _MemoryUsageWidgetState extends State<MemoryUsageWidget> {
  Timer? _updateTimer;
  MemoryUsageSummary _summary = MemoryUsageSummary(
    totalTrackedObjects: 0,
    uniqueObjectTypes: 0,
    potentialLeaks: [],
    objectCounts: {},
  );

  @override
  void initState() {
    super.initState();
    if (AppConfig.showDebugInfo) {
      _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        setState(() {
          _summary = MemoryManager.getMemoryUsage();
        });
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.showDebugInfo) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 100,
          right: 10,
          child: Material(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Memory Debug',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Objects: ${_summary.totalTrackedObjects}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Types: ${_summary.uniqueObjectTypes}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  if (_summary.potentialLeaks.isNotEmpty)
                    Text(
                      'Leaks: ${_summary.potentialLeaks.length}',
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}