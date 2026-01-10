import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum ConnectionQuality {
  excellent, // < 500ms
  good,      // 500-1200ms
  slow,      // 1200-3000ms
  verySlow,  // > 3000ms
  offline,   // No connection
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectionQuality> _connectionQualityController =
      StreamController<ConnectionQuality>.broadcast();

  Stream<ConnectionQuality> get connectionQualityStream =>
      _connectionQualityController.stream;

  ConnectionQuality _currentQuality = ConnectionQuality.excellent;
  ConnectionQuality get currentQuality => _currentQuality;

  bool _isMonitoring = false;
  Timer? _qualityCheckTimer;
  StreamSubscription? _connectivitySubscription;

  // Debouncing: require consecutive poor readings before alerting
  int _consecutivePoorReadings = 0;
  static const int _requiredPoorReadingsForAlert = 2; // Need 2 consecutive poor readings
  ConnectionQuality? _lastMeasuredQuality;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Initial connectivity check
    await _checkConnectivityAndQuality();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        // Use first result or none if empty
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        _onConnectivityChanged(result);
      },
      onError: (error) {
        debugPrint('❌ Connectivity error: $error');
      },
    );

    // Periodic quality check (every 15 seconds when app is active)
    _startPeriodicQualityCheck();

    debugPrint('✅ Connectivity service initialized');
  }

  /// Start periodic quality checks
  void _startPeriodicQualityCheck() {
    _qualityCheckTimer?.cancel();
    _qualityCheckTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkInternetQuality(),
    );
  }

  /// Stop periodic quality checks
  void stopMonitoring() {
    _qualityCheckTimer?.cancel();
    _connectivitySubscription?.cancel();
    _isMonitoring = false;
    debugPrint('🛑 Connectivity monitoring stopped');
  }

  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      _updateConnectionQuality(ConnectionQuality.offline);
      debugPrint('📡 Network: OFFLINE');
      return;
    }

    // When connectivity returns, immediately check quality
    debugPrint('📡 Network change detected: $result');
    await _checkInternetQuality();
  }

  /// Check both connectivity and internet quality
  Future<void> _checkConnectivityAndQuality() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final connectivityResult = connectivityResults.isNotEmpty
        ? connectivityResults.first
        : ConnectivityResult.none;

    if (connectivityResult == ConnectivityResult.none) {
      _updateConnectionQuality(ConnectionQuality.offline);
      return;
    }

    await _checkInternetQuality();
  }

  /// Check internet quality by measuring response time
  Future<void> _checkInternetQuality() async {
    try {
      // Use a lightweight endpoint for speed test
      // Try Google DNS or a known fast endpoint
      final stopwatch = Stopwatch()..start();

      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              // If timeout, consider it very slow
              return http.Response('', 408);
            },
          );

      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      ConnectionQuality measuredQuality;
      if (response.statusCode == 408) {
        // Timeout occurred
        measuredQuality = ConnectionQuality.verySlow;
        debugPrint('📡 Network: VERY SLOW (timeout)');
      } else {
        // Categorize connection quality based on latency
        measuredQuality = _categorizeLatency(latency);
        debugPrint('📡 Network latency: ${latency}ms - Quality: ${measuredQuality.name}');
      }

      _applyDebouncedQualityUpdate(measuredQuality);

    } on SocketException catch (e) {
      _applyDebouncedQualityUpdate(ConnectionQuality.offline);
      debugPrint('📡 Network: OFFLINE (${e.message})');
    } catch (e) {
      // On any error, assume slow connection but debounce it
      _applyDebouncedQualityUpdate(ConnectionQuality.slow);
      debugPrint('📡 Network check error: $e');
    }
  }

  /// Apply debouncing to prevent false alerts from transient network hiccups
  void _applyDebouncedQualityUpdate(ConnectionQuality measuredQuality) {
    final isPoorQuality = measuredQuality == ConnectionQuality.slow ||
        measuredQuality == ConnectionQuality.verySlow ||
        measuredQuality == ConnectionQuality.offline;

    if (isPoorQuality) {
      // For poor quality, require consecutive readings before alerting
      if (_lastMeasuredQuality == measuredQuality ||
          (_lastMeasuredQuality != null && _isPoorQuality(_lastMeasuredQuality!))) {
        _consecutivePoorReadings++;
      } else {
        _consecutivePoorReadings = 1;
      }

      _lastMeasuredQuality = measuredQuality;

      // Only update if we've had enough consecutive poor readings
      if (_consecutivePoorReadings >= _requiredPoorReadingsForAlert) {
        _updateConnectionQuality(measuredQuality);
        debugPrint('📡 Debounce: Poor connection confirmed after $_consecutivePoorReadings readings');
      } else {
        debugPrint('📡 Debounce: Ignoring transient poor reading ($_consecutivePoorReadings/$_requiredPoorReadingsForAlert)');
      }
    } else {
      // Good quality - immediately update and reset counter
      _consecutivePoorReadings = 0;
      _lastMeasuredQuality = measuredQuality;
      _updateConnectionQuality(measuredQuality);
    }
  }

  /// Check if a quality level is considered poor
  bool _isPoorQuality(ConnectionQuality quality) {
    return quality == ConnectionQuality.slow ||
        quality == ConnectionQuality.verySlow ||
        quality == ConnectionQuality.offline;
  }

  /// Categorize latency into quality levels
  /// Thresholds are lenient to account for mobile network variability
  ConnectionQuality _categorizeLatency(int latencyMs) {
    if (latencyMs < 500) {
      return ConnectionQuality.excellent;
    } else if (latencyMs < 1200) {
      return ConnectionQuality.good;
    } else if (latencyMs < 3000) {
      return ConnectionQuality.slow;
    } else {
      return ConnectionQuality.verySlow;
    }
  }

  /// Update connection quality and notify listeners
  void _updateConnectionQuality(ConnectionQuality quality) {
    if (_currentQuality != quality) {
      _currentQuality = quality;
      _connectionQualityController.add(quality);
    }
  }

  /// Check if internet is available (quick check)
  Future<bool> hasInternetConnection() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final connectivityResult = connectivityResults.isNotEmpty
        ? connectivityResults.first
        : ConnectivityResult.none;

    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    return _currentQuality != ConnectionQuality.offline;
  }

  /// Check if connection is too slow for operations
  bool isConnectionSlow() {
    return _currentQuality == ConnectionQuality.slow ||
           _currentQuality == ConnectionQuality.verySlow;
  }

  /// Check if offline
  bool isOffline() {
    return _currentQuality == ConnectionQuality.offline;
  }

  /// Get user-friendly connection status message
  String getConnectionStatusMessage() {
    switch (_currentQuality) {
      case ConnectionQuality.excellent:
        return 'Connection is excellent';
      case ConnectionQuality.good:
        return 'Connection is good';
      case ConnectionQuality.slow:
        return 'Connection is slow';
      case ConnectionQuality.verySlow:
        return 'Connection is very slow';
      case ConnectionQuality.offline:
        return 'No internet connection';
    }
  }

  /// Get user-friendly connection status message in Tamil
  String getConnectionStatusMessageTamil() {
    switch (_currentQuality) {
      case ConnectionQuality.excellent:
        return 'இணைப்பு சிறப்பாக உள்ளது';
      case ConnectionQuality.good:
        return 'இணைப்பு நன்றாக உள்ளது';
      case ConnectionQuality.slow:
        return 'இணைப்பு மெதுவாக உள்ளது';
      case ConnectionQuality.verySlow:
        return 'இணைப்பு மிகவும் மெதுவாக உள்ளது';
      case ConnectionQuality.offline:
        return 'இணைய இணைப்பு இல்லை';
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _connectionQualityController.close();
  }
}
