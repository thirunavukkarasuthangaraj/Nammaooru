import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/simple_order_model.dart';
import 'location_service.dart';

/// Enhanced navigation service for delivery operations
class EnhancedNavigationService {
  final LocationService _locationService = LocationService();

  // Navigation state
  NavigationSession? _currentSession;
  Timer? _distanceCheckTimer;
  Timer? _etaUpdateTimer;

  // Event streams
  final StreamController<NavigationUpdate> _navigationUpdateController =
      StreamController<NavigationUpdate>.broadcast();
  final StreamController<ProximityAlert> _proximityController =
      StreamController<ProximityAlert>.broadcast();

  // Singleton pattern
  static final EnhancedNavigationService _instance = EnhancedNavigationService._internal();
  factory EnhancedNavigationService() => _instance;
  EnhancedNavigationService._internal();

  // Stream getters
  Stream<NavigationUpdate> get navigationUpdateStream => _navigationUpdateController.stream;
  Stream<ProximityAlert> get proximityAlertStream => _proximityController.stream;

  NavigationSession? get currentSession => _currentSession;
  bool get isNavigating => _currentSession != null;

  /// Start navigation to shop for pickup
  Future<NavigationSession> startShopNavigation(OrderModel order) async {
    if (order.shopLatitude == null || order.shopLongitude == null) {
      throw Exception('Shop location not available for order ${order.id}');
    }

    return _startNavigation(
      orderId: order.id.toString(),
      destinationName: order.shopName ?? 'Shop',
      destinationAddress: order.shopAddress ?? 'Shop Address',
      destinationLat: order.shopLatitude!,
      destinationLng: order.shopLongitude!,
      navigationType: NavigationType.toShop,
      order: order,
    );
  }

  /// Start navigation to customer for delivery
  Future<NavigationSession> startCustomerNavigation(OrderModel order) async {
    if (order.customerLatitude == null || order.customerLongitude == null) {
      throw Exception('Customer location not available for order ${order.id}');
    }

    return _startNavigation(
      orderId: order.id.toString(),
      destinationName: order.customerName,
      destinationAddress: order.deliveryAddress,
      destinationLat: order.customerLatitude!,
      destinationLng: order.customerLongitude!,
      navigationType: NavigationType.toCustomer,
      order: order,
    );
  }

  /// Internal navigation start logic
  Future<NavigationSession> _startNavigation({
    required String orderId,
    required String destinationName,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
    required NavigationType navigationType,
    OrderModel? order,
  }) async {
    // Stop any existing navigation
    await stopNavigation();

    // Get current location
    final currentPosition = await _locationService.getCurrentLocation();
    if (currentPosition == null) {
      throw Exception('Could not get current location');
    }

    // Create navigation session
    _currentSession = NavigationSession(
      orderId: orderId,
      destinationName: destinationName,
      destinationAddress: destinationAddress,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      startLat: currentPosition.latitude,
      startLng: currentPosition.longitude,
      navigationType: navigationType,
      startTime: DateTime.now(),
      order: order,
    );

    // Calculate initial distance and ETA
    _updateSessionData();

    // Start monitoring timers
    _startDistanceMonitoring();
    _startETAUpdates();

    // Open Google Maps for navigation
    await _openGoogleMapsNavigation();

    print('🗺️ Navigation started to ${navigationType.name}:');
    print('   Order: $orderId');
    print('   Destination: $destinationName');
    print('   Distance: ${_currentSession!.currentDistance.toStringAsFixed(2)} km');
    print('   ETA: ${_currentSession!.estimatedArrival}');

    // Send initial navigation update
    _sendNavigationUpdate();

    return _currentSession!;
  }

  /// Update session data with current location
  void _updateSessionData() {
    if (_currentSession == null) return;

    final currentPosition = _locationService.currentPosition;
    if (currentPosition == null) return;

    final distance = _calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      _currentSession!.destinationLat,
      _currentSession!.destinationLng,
    );

    // Update session
    _currentSession = _currentSession!.copyWith(
      currentLat: currentPosition.latitude,
      currentLng: currentPosition.longitude,
      currentDistance: distance,
      lastUpdate: DateTime.now(),
    );

    // Calculate ETA (assuming average speed of 30 km/h in city)
    final averageSpeedKmh = 30.0;
    final etaMinutes = (distance / averageSpeedKmh * 60).round();
    final estimatedArrival = DateTime.now().add(Duration(minutes: etaMinutes));

    _currentSession = _currentSession!.copyWith(
      estimatedArrival: estimatedArrival,
    );
  }

  /// Start distance monitoring
  void _startDistanceMonitoring() {
    _distanceCheckTimer?.cancel();
    _distanceCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateSessionData();
      _checkProximity();
      _sendNavigationUpdate();
    });
  }

  /// Start ETA updates
  void _startETAUpdates() {
    _etaUpdateTimer?.cancel();
    _etaUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateSessionData();
      _sendNavigationUpdate();
    });
  }

  /// Check proximity to destination
  void _checkProximity() {
    if (_currentSession == null) return;

    final distance = _currentSession!.currentDistance;
    final proximityThresholds = [2.0, 1.0, 0.5, 0.1]; // km

    for (final threshold in proximityThresholds) {
      if (distance <= threshold && !_currentSession!.alertsSent.contains(threshold)) {
        // Mark alert as sent
        _currentSession!.alertsSent.add(threshold);

        // Send proximity alert
        final alert = ProximityAlert(
          orderId: _currentSession!.orderId,
          destinationName: _currentSession!.destinationName,
          distance: distance,
          navigationType: _currentSession!.navigationType,
          threshold: threshold,
        );

        _proximityController.add(alert);

        if (threshold == 0.1) {
          print('📍 Arrived at ${_currentSession!.destinationName}!');
        } else {
          print('📍 ${(threshold * 1000).round()}m away from ${_currentSession!.destinationName}');
        }
        break;
      }
    }
  }

  /// Send navigation update
  void _sendNavigationUpdate() {
    if (_currentSession == null) return;

    final update = NavigationUpdate(
      session: _currentSession!,
      timestamp: DateTime.now(),
    );

    _navigationUpdateController.add(update);
  }

  /// Open Google Maps for navigation
  Future<void> _openGoogleMapsNavigation() async {
    if (_currentSession == null) return;

    try {
      final destination = '${_currentSession!.destinationLat},${_currentSession!.destinationLng}';
      final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving';

      final uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('🗺️ Google Maps opened for navigation');
      } else {
        throw 'Could not open Google Maps';
      }
    } catch (e) {
      print('❌ Failed to open Google Maps: $e');
    }
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Check if driver has arrived at destination
  bool hasArrivedAtDestination({double toleranceKm = 0.1}) {
    if (_currentSession == null) return false;
    return _currentSession!.currentDistance <= toleranceKm;
  }

  /// Get remaining distance to destination
  double? getRemainingDistance() {
    return _currentSession?.currentDistance;
  }

  /// Get estimated arrival time
  DateTime? getEstimatedArrival() {
    return _currentSession?.estimatedArrival;
  }

  /// Get navigation summary
  NavigationSummary? getNavigationSummary() {
    if (_currentSession == null) return null;

    final elapsed = DateTime.now().difference(_currentSession!.startTime);
    final totalDistance = _calculateDistance(
      _currentSession!.startLat,
      _currentSession!.startLng,
      _currentSession!.destinationLat,
      _currentSession!.destinationLng,
    );

    return NavigationSummary(
      orderId: _currentSession!.orderId,
      navigationType: _currentSession!.navigationType,
      destinationName: _currentSession!.destinationName,
      totalDistance: totalDistance,
      remainingDistance: _currentSession!.currentDistance,
      elapsedTime: elapsed,
      estimatedArrival: _currentSession!.estimatedArrival,
      isArrived: hasArrivedAtDestination(),
    );
  }

  /// Stop current navigation
  Future<void> stopNavigation() async {
    if (_currentSession == null) return;

    print('🛑 Stopping navigation for order ${_currentSession!.orderId}');

    _distanceCheckTimer?.cancel();
    _etaUpdateTimer?.cancel();

    final summary = getNavigationSummary();
    _currentSession = null;

    // Send final navigation update
    if (summary != null) {
      _navigationUpdateController.add(NavigationUpdate(
        session: null,
        navigationEnded: true,
        summary: summary,
        timestamp: DateTime.now(),
      ));
    }

    print('✅ Navigation stopped');
  }

  /// Dispose all resources
  void dispose() {
    stopNavigation();
    _navigationUpdateController.close();
    _proximityController.close();
  }
}

/// Navigation session data
class NavigationSession {
  final String orderId;
  final String destinationName;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final double startLat;
  final double startLng;
  final NavigationType navigationType;
  final DateTime startTime;
  final OrderModel? order;

  double currentLat;
  double currentLng;
  double currentDistance;
  DateTime? estimatedArrival;
  DateTime lastUpdate;
  final Set<double> alertsSent = {};

  NavigationSession({
    required this.orderId,
    required this.destinationName,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.startLat,
    required this.startLng,
    required this.navigationType,
    required this.startTime,
    this.order,
    double? currentLat,
    double? currentLng,
    double? currentDistance,
    this.estimatedArrival,
    DateTime? lastUpdate,
  }) :
    currentLat = currentLat ?? startLat,
    currentLng = currentLng ?? startLng,
    currentDistance = currentDistance ?? 0.0,
    lastUpdate = lastUpdate ?? DateTime.now();

  NavigationSession copyWith({
    double? currentLat,
    double? currentLng,
    double? currentDistance,
    DateTime? estimatedArrival,
    DateTime? lastUpdate,
  }) {
    return NavigationSession(
      orderId: orderId,
      destinationName: destinationName,
      destinationAddress: destinationAddress,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      startLat: startLat,
      startLng: startLng,
      navigationType: navigationType,
      startTime: startTime,
      order: order,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      currentDistance: currentDistance ?? this.currentDistance,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// Navigation types
enum NavigationType {
  toShop('Shop'),
  toCustomer('Customer');

  const NavigationType(this.displayName);
  final String displayName;
}

/// Navigation update event
class NavigationUpdate {
  final NavigationSession? session;
  final bool navigationEnded;
  final NavigationSummary? summary;
  final DateTime timestamp;

  NavigationUpdate({
    this.session,
    this.navigationEnded = false,
    this.summary,
    required this.timestamp,
  });
}

/// Proximity alert event
class ProximityAlert {
  final String orderId;
  final String destinationName;
  final double distance;
  final NavigationType navigationType;
  final double threshold;

  ProximityAlert({
    required this.orderId,
    required this.destinationName,
    required this.distance,
    required this.navigationType,
    required this.threshold,
  });
}

/// Navigation summary
class NavigationSummary {
  final String orderId;
  final NavigationType navigationType;
  final String destinationName;
  final double totalDistance;
  final double remainingDistance;
  final Duration elapsedTime;
  final DateTime? estimatedArrival;
  final bool isArrived;

  NavigationSummary({
    required this.orderId,
    required this.navigationType,
    required this.destinationName,
    required this.totalDistance,
    required this.remainingDistance,
    required this.elapsedTime,
    this.estimatedArrival,
    required this.isArrived,
  });
}