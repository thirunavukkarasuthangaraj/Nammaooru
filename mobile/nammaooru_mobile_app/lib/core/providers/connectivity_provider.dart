import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
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

  ConnectivityProvider() {
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

  void _updateConnectionQuality(ConnectionQuality quality) {
    if (_connectionQuality != quality) {
      _connectionQuality = quality;
      _checkAndShowAlert(quality);
      notifyListeners();
    }
  }

  void _checkAndShowAlert(ConnectionQuality quality) {
    // Only show alert for very slow or offline connections
    // "Slow" is acceptable for most operations and shouldn't interrupt the user
    if (quality == ConnectionQuality.verySlow ||
        quality == ConnectionQuality.offline) {
      _showAlert = true;
      _alertMessage = _connectivityService.getConnectionStatusMessage();
      _alertMessageTamil = _connectivityService.getConnectionStatusMessageTamil();
    } else {
      _showAlert = false;
    }
  }

  /// Manually dismiss alert
  void dismissAlert() {
    _showAlert = false;
    notifyListeners();
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
    _connectivityService.dispose();
    super.dispose();
  }
}
