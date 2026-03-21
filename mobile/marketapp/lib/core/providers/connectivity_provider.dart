import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier with WidgetsBindingObserver {
  final ConnectivityService _connectivityService = ConnectivityService();

  ConnectionQuality _connectionQuality = ConnectionQuality.excellent;
  ConnectionQuality get connectionQuality => _connectionQuality;

  bool _showAlert = false;
  bool get showAlert => _showAlert;

  String _alertMessage = '';
  String get alertMessage => _alertMessage;

  String _alertMessageTamil = '';
  String get alertMessageTamil => _alertMessageTamil;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Cooldown management - don't show alert again for 60 seconds after dismissal
  DateTime? _lastDismissedAt;
  static const Duration _cooldownDuration = Duration(seconds: 60);

  // Auto-dismiss timer
  Timer? _autoDismissTimer;

  ConnectivityProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    // Skip connectivity monitoring on web platform (CORS issues)
    if (kIsWeb) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    await _connectivityService.initialize();

    // Listen to connection quality changes
    _connectivityService.connectionQualityStream.listen((quality) {
      _updateConnectionQuality(quality);
    });

    // Get initial quality
    _connectionQuality = _connectivityService.currentQuality;
    _checkAndShowAlert(_connectionQuality);

    _isInitialized = true;
    notifyListeners();

    debugPrint('✅ ConnectivityProvider initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App going to background - stop periodic checks to avoid false "offline"
      _connectivityService.stopMonitoring();
      debugPrint('📡 App paused - stopped connectivity monitoring');
    } else if (state == AppLifecycleState.resumed) {
      // App coming back - dismiss any stale alert and recheck fresh
      _showAlert = false;
      _connectionQuality = ConnectionQuality.excellent;
      notifyListeners();

      // Re-initialize monitoring and force a fresh check
      _connectivityService.initialize();
      debugPrint('📡 App resumed - restarted connectivity monitoring');
    }
  }

  void _updateConnectionQuality(ConnectionQuality quality) {
    if (_connectionQuality != quality) {
      _connectionQuality = quality;
      _checkAndShowAlert(quality);
      notifyListeners();
    }
  }

  void _checkAndShowAlert(ConnectionQuality quality) {
    // Cancel any pending auto-dismiss
    _autoDismissTimer?.cancel();

    // Only show alert for very slow or offline connections
    // "Slow" is acceptable for most operations and shouldn't interrupt the user
    if (quality == ConnectionQuality.verySlow ||
        quality == ConnectionQuality.offline) {
      // Check if we're in cooldown period (user dismissed recently)
      if (_lastDismissedAt != null) {
        final timeSinceDismiss = DateTime.now().difference(_lastDismissedAt!);
        if (timeSinceDismiss < _cooldownDuration) {
          // Still in cooldown, don't show alert
          debugPrint('📡 Alert suppressed - in cooldown (${_cooldownDuration.inSeconds - timeSinceDismiss.inSeconds}s remaining)');
          return;
        }
      }

      _showAlert = true;
      _alertMessage = _connectivityService.getConnectionStatusMessage();
      _alertMessageTamil = _connectivityService.getConnectionStatusMessageTamil();
    } else {
      // Connection is good now - auto-dismiss with small delay
      if (_showAlert) {
        _autoDismissTimer = Timer(const Duration(milliseconds: 500), () {
          _showAlert = false;
          notifyListeners();
          debugPrint('📡 Alert auto-dismissed - connection restored');
        });
      }
    }
  }

  /// Manually dismiss alert - starts cooldown period
  void dismissAlert() {
    _showAlert = false;
    _lastDismissedAt = DateTime.now();
    _autoDismissTimer?.cancel();
    notifyListeners();
    debugPrint('📡 Alert dismissed - cooldown started for ${_cooldownDuration.inSeconds}s');
  }

  /// Check if internet is available
  Future<bool> hasInternetConnection() {
    return _connectivityService.hasInternetConnection();
  }

  /// Check if connection is slow
  bool isConnectionSlow() {
    return _connectivityService.isConnectionSlow();
  }

  /// Check if offline
  bool isOffline() {
    return _connectivityService.isOffline();
  }

  /// Get connection status message
  String getConnectionStatusMessage() {
    return _connectivityService.getConnectionStatusMessage();
  }

  /// Get connection status message in Tamil
  String getConnectionStatusMessageTamil() {
    return _connectivityService.getConnectionStatusMessageTamil();
  }

  /// Get icon for connection quality
  IconData getConnectionIcon() {
    switch (_connectionQuality) {
      case ConnectionQuality.excellent:
      case ConnectionQuality.good:
        return Icons.signal_wifi_4_bar;
      case ConnectionQuality.slow:
        return Icons.signal_wifi_statusbar_connected_no_internet_4;
      case ConnectionQuality.verySlow:
        return Icons.signal_wifi_bad;
      case ConnectionQuality.offline:
        return Icons.signal_wifi_off;
    }
  }

  /// Get color for connection quality
  Color getConnectionColor() {
    switch (_connectionQuality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.slow:
        return Colors.orange;
      case ConnectionQuality.verySlow:
        return Colors.deepOrange;
      case ConnectionQuality.offline:
        return Colors.red;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoDismissTimer?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }
}
