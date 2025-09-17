import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../models/delivery_partner.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  Position? _currentPosition;
  bool _isLocationTrackingActive = false;
  bool _isLocationPermissionGranted = false;
  Timer? _locationUpdateTimer;
  String? _lastError;

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isLocationTrackingActive => _isLocationTrackingActive;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  String? get lastError => _lastError;

  // Location update frequency (in seconds)
  static const int _updateIntervalSeconds = 30;

  /// Initialize location services and permissions
  Future<bool> initializeLocation() async {
    try {
      _lastError = null;

      // Check and request permissions
      bool hasPermission = await _locationService.checkLocationPermission();
      _isLocationPermissionGranted = hasPermission;

      if (hasPermission) {
        // Get initial location
        Position? position = await _locationService.getCurrentLocation();
        if (position != null) {
          _currentPosition = position;
          notifyListeners();
          return true;
        }
      }

      _lastError = 'Location permission denied or service unavailable';
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = 'Failed to initialize location: $e';
      notifyListeners();
      return false;
    }
  }

  /// Start continuous location tracking
  Future<void> startLocationTracking({
    required String partnerId,
    String? assignmentId,
    String? orderStatus,
  }) async {
    if (_isLocationTrackingActive) return;

    try {
      _lastError = null;
      _isLocationTrackingActive = true;
      notifyListeners();

      // Start location updates
      await _locationService.startLocationTracking(
        onLocationUpdate: (Position position) {
          _currentPosition = position;
          notifyListeners();

          // Send location update to backend
          _sendLocationUpdate(
            partnerId: partnerId,
            position: position,
            assignmentId: assignmentId,
            orderStatus: orderStatus,
          );
        },
      );

      // Also send periodic updates via timer as backup
      _locationUpdateTimer = Timer.periodic(
        Duration(seconds: _updateIntervalSeconds),
        (timer) async {
          if (_currentPosition != null) {
            await _sendLocationUpdate(
              partnerId: partnerId,
              position: _currentPosition!,
              assignmentId: assignmentId,
              orderStatus: orderStatus,
            );
          }
        },
      );

    } catch (e) {
      _lastError = 'Failed to start location tracking: $e';
      _isLocationTrackingActive = false;
      notifyListeners();
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _isLocationTrackingActive = false;
    _locationService.stopLocationTracking();
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    notifyListeners();
  }

  /// Send location update to backend
  Future<void> _sendLocationUpdate({
    required String partnerId,
    required Position position,
    String? assignmentId,
    String? orderStatus,
  }) async {
    try {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'altitude': position.altitude,
        'timestamp': DateTime.now().toIso8601String(),
        if (assignmentId != null) 'assignmentId': assignmentId,
        if (orderStatus != null) 'orderStatus': orderStatus,
      };

      await _apiService.post(
        '/api/location/partners/$partnerId/update',
        data: locationData,
      );
    } catch (e) {
      print('Failed to send location update: $e');
      // Don't throw error to avoid stopping location tracking
    }
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      _lastError = null;
      Position? position = await _locationService.getCurrentLocation();
      if (position != null) {
        _currentPosition = position;
        notifyListeners();
      }
      return position;
    } catch (e) {
      _lastError = 'Failed to get current location: $e';
      notifyListeners();
      return null;
    }
  }

  /// Calculate distance to destination
  double? calculateDistanceToDestination(double destLat, double destLng) {
    if (_currentPosition == null) return null;

    return LocationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      destLat,
      destLng,
    );
  }

  /// Check if near destination (within 100 meters)
  bool isNearDestination(double destLat, double destLng) {
    return _locationService.isNearDestination(destLat, destLng);
  }

  /// Get ETA to destination
  Future<Map<String, dynamic>?> getETAToDestination({
    required String partnerId,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/location/partners/$partnerId/eta',
        data: {
          'latitude': destLat,
          'longitude': destLng,
        },
      );

      if (response['success'] == true) {
        return response['eta'];
      }
      return null;
    } catch (e) {
      print('Failed to get ETA: $e');
      return null;
    }
  }

  /// Get location history for a partner
  Future<List<Map<String, dynamic>>> getLocationHistory({
    required String partnerId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/location/partners/$partnerId/history',
        queryParams: {
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        },
      );

      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['locations']);
      }
      return [];
    } catch (e) {
      print('Failed to get location history: $e');
      return [];
    }
  }

  /// Get delivery route for an assignment
  Future<List<Map<String, dynamic>>> getDeliveryRoute({
    required String assignmentId,
    required String partnerId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/location/assignments/$assignmentId/route',
        queryParams: {'partnerId': partnerId},
      );

      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['route']);
      }
      return [];
    } catch (e) {
      print('Failed to get delivery route: $e');
      return [];
    }
  }

  /// Check online status
  Future<bool> checkOnlineStatus(String partnerId) async {
    try {
      final response = await _apiService.get(
        '/api/location/partners/$partnerId/online-status',
      );

      if (response['success'] == true) {
        return response['isOnline'] ?? false;
      }
      return false;
    } catch (e) {
      print('Failed to check online status: $e');
      return false;
    }
  }

  /// Open navigation app
  Future<void> openNavigation(double destLat, double destLng) async {
    await _locationService.openGoogleMaps(destLat, destLng);
  }

  /// Update location tracking for specific order
  void updateOrderContext({
    String? assignmentId,
    String? orderStatus,
  }) {
    // This would update the current tracking context
    // Implementation depends on how you want to handle multiple orders
    print('Updated order context: assignment=$assignmentId, status=$orderStatus');
  }

  /// Get formatted address from coordinates
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    return await _locationService.getAddressFromCoordinates(lat, lng);
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}