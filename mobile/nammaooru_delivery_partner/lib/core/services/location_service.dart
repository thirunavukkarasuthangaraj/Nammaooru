import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';

class LocationService {
  static const int _locationUpdateInterval = 10; // seconds
  static const int _serverUpdateInterval = 30; // seconds for server updates

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _serverUpdateTimer;
  Position? _currentPosition;
  final ApiService _apiService = ApiService();
  final Battery _battery = Battery();

  int? _currentAssignmentId;
  String? _currentOrderStatus;

  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? get currentPosition => _currentPosition;

  /// Set current assignment info for tracking
  void setAssignmentInfo(int? assignmentId, String? orderStatus) {
    _currentAssignmentId = assignmentId;
    _currentOrderStatus = orderStatus;
  }

  /// Start sending location updates to server every 30 seconds
  void startServerSync() {
    _serverUpdateTimer?.cancel();
    _serverUpdateTimer = Timer.periodic(
      const Duration(seconds: _serverUpdateInterval),
      (timer) => _sendLocationToServer(),
    );
  }

  /// Stop sending location updates to server
  void stopServerSync() {
    _serverUpdateTimer?.cancel();
    _serverUpdateTimer = null;
  }

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<void> startLocationTracking({
    Function(Position)? onLocationUpdate,
  }) async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          onLocationUpdate?.call(position);
        },
        onError: (error) {
          print('Location tracking error: $error');
        },
      );
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convert to kilometers
  }

  /// Check if delivery partner is near destination (within 100 meters)
  bool isNearDestination(double destLat, double destLng) {
    if (_currentPosition == null) return false;

    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      destLat,
      destLng,
    );

    return distance <= 100; // 100 meters threshold
  }

  /// Get address from coordinates
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // This would typically use geocoding package
      // For now, return formatted coordinates
      return 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
    } catch (e) {
      return 'Unknown location';
    }
  }

  /// Open Google Maps for navigation
  Future<void> openGoogleMaps(double destinationLat, double destinationLng) async {
    try {
      Position? current = await getCurrentLocation();
      if (current == null) {
        throw Exception('Could not get current location');
      }

      final String googleMapsUrl =
          'https://www.google.com/maps/dir/${current.latitude},${current.longitude}/$destinationLat,$destinationLng';

      // This would typically use url_launcher
      print('Opening Google Maps: $googleMapsUrl');

    } catch (e) {
      print('Error opening Google Maps: $e');
    }
  }

  /// Send current location to server with additional data
  Future<void> _sendLocationToServer() async {
    if (_currentPosition == null) {
      print('No current position available to send to server');
      return;
    }

    try {
      // Get battery level
      int? batteryLevel;
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (e) {
        print('Could not get battery level: $e');
      }

      // Get network type
      String? networkType;
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        networkType = connectivityResult.name.toUpperCase();
      } catch (e) {
        print('Could not get network type: $e');
        networkType = 'UNKNOWN';
      }

      // Send location update to server
      await _apiService.updateLocation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        accuracy: _currentPosition!.accuracy,
        speed: _currentPosition!.speed >= 0 ? _currentPosition!.speed : null,
        heading: _currentPosition!.heading >= 0 ? _currentPosition!.heading : null,
        altitude: _currentPosition!.altitude,
        batteryLevel: batteryLevel,
        networkType: networkType,
        assignmentId: _currentAssignmentId,
        orderStatus: _currentOrderStatus,
      );

      print('✅ Location sent to server successfully');
    } catch (e) {
      print('❌ Failed to send location to server: $e');
    }
  }

  /// Enhanced start location tracking with server sync
  Future<void> startEnhancedLocationTracking({
    Function(Position)? onLocationUpdate,
    int? assignmentId,
    String? orderStatus,
  }) async {
    // Set assignment info
    setAssignmentInfo(assignmentId, orderStatus);

    // Start location tracking
    await startLocationTracking(onLocationUpdate: onLocationUpdate);

    // Start server sync
    startServerSync();

    print('🎯 Enhanced location tracking started for assignment: $assignmentId');
  }

  /// Stop all location tracking and server sync
  void stopEnhancedLocationTracking() {
    stopLocationTracking();
    stopServerSync();
    setAssignmentInfo(null, null);
    print('🛑 Enhanced location tracking stopped');
  }

  /// Dispose resources
  void dispose() {
    stopEnhancedLocationTracking();
  }
}