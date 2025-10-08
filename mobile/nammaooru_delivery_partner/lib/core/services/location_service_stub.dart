// Simplified location service stub for build
import 'dart:async';

class Position {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double heading;
  final double speed;
  final DateTime timestamp;

  Position({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.timestamp,
  });
}

class LocationService {
  Position? _currentPosition;

  Future<bool> requestPermission() async {
    // Stub implementation
    return true;
  }

  Future<Position?> getCurrentLocation() async {
    // Return mock location for testing
    _currentPosition = Position(
      latitude: 12.9716,
      longitude: 77.5946,
      accuracy: 10.0,
      altitude: 920.0,
      heading: 0.0,
      speed: 0.0,
      timestamp: DateTime.now(),
    );
    return _currentPosition;
  }

  void startLocationTracking({required Function(Position) onLocationUpdate}) {
    // Mock location updates
    Timer.periodic(Duration(seconds: 30), (timer) {
      final mockPosition = Position(
        latitude: 12.9716 + (DateTime.now().millisecondsSinceEpoch % 100) * 0.00001,
        longitude: 77.5946 + (DateTime.now().millisecondsSinceEpoch % 100) * 0.00001,
        accuracy: 10.0,
        altitude: 920.0,
        heading: 0.0,
        speed: 5.0,
        timestamp: DateTime.now(),
      );
      onLocationUpdate(mockPosition);
    });
  }

  void stopLocationTracking() {
    // Stub implementation
  }

  Position? get currentPosition => _currentPosition;
}