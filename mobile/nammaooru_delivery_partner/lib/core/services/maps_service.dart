import 'dart:async';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../config/env_config.dart';

class MapsService {
  // Singleton pattern
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  /// Get route polyline between two points using straight line (no API cost)
  Future<List<LatLng>> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String travelMode = 'driving',
  }) async {
    // Create a smooth curved line between two points to simulate road routing
    return _createSmoothRoute(startLat, startLng, endLat, endLng);
  }

  /// Get route information using distance calculation (no API cost)
  Future<Map<String, dynamic>> getRouteInfo({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String travelMode = 'driving',
  }) async {
    // Calculate distance using Haversine formula
    double distance = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);

    // Add 20% extra distance to simulate actual road routing
    double roadDistance = distance * 1.2;

    // Calculate duration based on travel mode
    double speedKmh = travelMode == 'walking' ? 5.0 : 30.0; // 5 km/h walking, 30 km/h driving
    double durationHours = (roadDistance / 1000) / speedKmh;
    int durationMinutes = (durationHours * 60).round();

    return {
      'distance': '${(roadDistance / 1000).toStringAsFixed(1)} km',
      'distanceValue': roadDistance.toInt(),
      'duration': '${durationMinutes} mins',
      'durationValue': durationMinutes * 60,
      'polyline': '',
      'startAddress': 'Current Location',
      'endAddress': 'Destination',
      'steps': [],
    };
  }

  /// Create polyline from list of LatLng points
  Polyline createPolyline({
    required String polylineId,
    required List<LatLng> points,
    Color color = const Color(0xFF2196F3),
    double width = 5.0,
    List<PatternItem> patterns = const [],
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color,
      width: width,
      patterns: patterns,
      geodesic: true,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );
  }

  /// Create markers for start and end points
  Set<Marker> createRouteMarkers({
    required LatLng startPoint,
    required LatLng endPoint,
    String startTitle = 'Start',
    String endTitle = 'Destination',
    BitmapDescriptor? startIcon,
    BitmapDescriptor? endIcon,
  }) {
    return {
      Marker(
        markerId: MarkerId('start'),
        position: startPoint,
        infoWindow: InfoWindow(title: startTitle),
        icon: startIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: MarkerId('end'),
        position: endPoint,
        infoWindow: InfoWindow(title: endTitle),
        icon: endIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  /// Get camera position that shows entire route
  CameraPosition getRouteCameraPosition(List<LatLng> routePoints, {double padding = 100.0}) {
    if (routePoints.isEmpty) {
      return CameraPosition(target: LatLng(0, 0), zoom: 10);
    }

    if (routePoints.length == 1) {
      return CameraPosition(target: routePoints.first, zoom: 15);
    }

    // Calculate bounds
    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (LatLng point in routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // Calculate center and zoom level
    LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    return CameraPosition(
      target: center,
      zoom: _calculateZoomLevel(minLat, maxLat, minLng, maxLng),
    );
  }

  /// Add current location marker that updates in real-time
  Marker createCurrentLocationMarker(
    LatLng currentLocation, {
    String title = 'Current Location',
    double rotation = 0.0,
  }) {
    return Marker(
      markerId: MarkerId('current_location'),
      position: currentLocation,
      infoWindow: InfoWindow(title: title),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      rotation: rotation,
      anchor: Offset(0.5, 0.5),
    );
  }

  /// Create animated polyline showing traveled path
  Polyline createTraveledPathPolyline(List<LatLng> traveledPoints) {
    return Polyline(
      polylineId: PolylineId('traveled_path'),
      points: traveledPoints,
      color: Color(0xFF4CAF50), // Green for completed path
      width: 4.0,
      patterns: [PatternItem.dash(10), PatternItem.gap(5)],
      geodesic: true,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  /// Create remaining route polyline
  Polyline createRemainingRoutePolyline(List<LatLng> remainingPoints) {
    return Polyline(
      polylineId: PolylineId('remaining_route'),
      points: remainingPoints,
      color: Color(0xFF2196F3), // Blue for remaining path
      width: 5.0,
      geodesic: true,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  /// Calculate zoom level based on bounds
  double _calculateZoomLevel(double minLat, double maxLat, double minLng, double maxLng) {
    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    double maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff < 0.01) return 15.0;
    if (maxDiff < 0.02) return 14.0;
    if (maxDiff < 0.05) return 13.0;
    if (maxDiff < 0.1) return 12.0;
    if (maxDiff < 0.2) return 11.0;
    if (maxDiff < 0.5) return 10.0;
    if (maxDiff < 1.0) return 9.0;
    if (maxDiff < 2.0) return 8.0;
    return 7.0;
  }

  /// Create a road-like route polyline without API calls (cost-free but looks like roads)
  List<LatLng> _createSmoothRoute(double startLat, double startLng, double endLat, double endLng) {
    List<LatLng> points = [];

    // Add starting point
    points.add(LatLng(startLat, startLng));

    // Calculate distance and direction
    double distance = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);

    // If distance is very short, just draw straight line
    if (distance < 500) { // Less than 500m
      points.add(LatLng(endLat, endLng));
      return points;
    }

    // Create road-like waypoints that simulate following streets
    int numberOfSegments = math.min((distance / 300).round(), EnvConfig.maxPolylinePoints - 2);

    // Calculate bearing from start to end
    double bearing = _calculateBearing(LatLng(startLat, startLng), LatLng(endLat, endLng));

    for (int i = 1; i < numberOfSegments + 1; i++) {
      double ratio = i / (numberOfSegments + 1);

      // Basic interpolation
      double lat = startLat + (endLat - startLat) * ratio;
      double lng = startLng + (endLng - startLng) * ratio;

      // Add road-like variations to simulate following streets
      // Create turns and curves that resemble actual road patterns
      double roadCurve = _createRoadLikeVariation(ratio, bearing, distance);

      // Apply the road variation perpendicular to the main direction
      double perpBearing = (bearing + 90) * (math.pi / 180); // 90 degrees perpendicular

      // Small offsets to simulate following roads instead of straight line
      lat += roadCurve * math.cos(perpBearing) * 0.0008; // ~88m per 0.001 degree
      lng += roadCurve * math.sin(perpBearing) * 0.0008;

      points.add(LatLng(lat, lng));
    }

    // Add ending point
    points.add(LatLng(endLat, endLng));

    return points;
  }

  /// Create road-like variation pattern
  double _createRoadLikeVariation(double ratio, double bearing, double distance) {
    // Create a pattern that simulates road curves and turns
    double curve = 0;

    // Add gentle S-curves
    curve += math.sin(ratio * math.pi * 2) * 0.3;

    // Add random-looking variations for different road segments
    curve += math.sin(ratio * math.pi * 4) * 0.15;
    curve += math.cos(ratio * math.pi * 3) * 0.1;

    // Adjust curve intensity based on distance (longer routes have more variation)
    double intensity = math.min(distance / 5000, 1.0); // Scale with distance up to 5km

    return curve * intensity;
  }

  /// Calculate bearing between two points
  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * math.pi / 180;
    double lat2 = end.latitude * math.pi / 180;
    double deltaLng = (end.longitude - start.longitude) * math.pi / 180;

    double y = math.sin(deltaLng) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
               math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);

    double bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  /// Create polyline from location history points (driver's actual path)
  List<LatLng> createLocationHistoryPolyline(List<Map<String, dynamic>> locationHistory) {
    List<LatLng> points = [];

    for (var location in locationHistory) {
      if (location['latitude'] != null && location['longitude'] != null) {
        points.add(LatLng(
          location['latitude'].toDouble(),
          location['longitude'].toDouble(),
        ));
      }
    }

    // Simplify polyline to reduce points and improve performance
    return _simplifyPolyline(points, EnvConfig.polylineSimplificationTolerance);
  }

  /// Simplify polyline using Douglas-Peucker algorithm
  List<LatLng> _simplifyPolyline(List<LatLng> points, double tolerance) {
    if (points.length <= 2) return points;

    // Find the point with maximum distance from the line between start and end
    double maxDistance = 0;
    int maxIndex = 0;

    LatLng start = points.first;
    LatLng end = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      double distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      List<LatLng> leftPoints = _simplifyPolyline(points.sublist(0, maxIndex + 1), tolerance);
      List<LatLng> rightPoints = _simplifyPolyline(points.sublist(maxIndex), tolerance);

      // Remove duplicate point at the junction
      leftPoints.removeLast();
      return [...leftPoints, ...rightPoints];
    } else {
      return [start, end];
    }
  }

  /// Calculate perpendicular distance from point to line
  double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    double x0 = point.latitude;
    double y0 = point.longitude;
    double x1 = lineStart.latitude;
    double y1 = lineStart.longitude;
    double x2 = lineEnd.latitude;
    double y2 = lineEnd.longitude;

    double numerator = ((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1).abs();
    double denominator = math.sqrt(math.pow(y2 - y1, 2) + math.pow(x2 - x1, 2));

    return numerator / denominator;
  }

  /// Create driver tracking markers (current location, shop, customer)
  Set<Marker> createDeliveryMarkers({
    LatLng? currentLocation,
    LatLng? shopLocation,
    LatLng? customerLocation,
    String shopName = 'Shop',
    String customerName = 'Customer',
    double rotation = 0.0,
  }) {
    Set<Marker> markers = {};

    // Current location marker (moving)
    if (currentLocation != null) {
      markers.add(Marker(
        markerId: MarkerId('driver_location'),
        position: currentLocation,
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        rotation: rotation,
        anchor: Offset(0.5, 0.5),
      ));
    }

    // Shop location marker
    if (shopLocation != null) {
      markers.add(Marker(
        markerId: MarkerId('shop_location'),
        position: shopLocation,
        infoWindow: InfoWindow(title: shopName, snippet: 'Pickup Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }

    // Customer location marker
    if (customerLocation != null) {
      markers.add(Marker(
        markerId: MarkerId('customer_location'),
        position: customerLocation,
        infoWindow: InfoWindow(title: customerName, snippet: 'Delivery Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    return markers;
  }

  /// Calculate the closest point on route to current location
  int findClosestPointIndex(List<LatLng> routePoints, LatLng currentLocation) {
    if (routePoints.isEmpty) return 0;

    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < routePoints.length; i++) {
      double distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        routePoints[i].latitude,
        routePoints[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  /// Split route into traveled and remaining parts
  Map<String, List<LatLng>> splitRouteByCurrentLocation(
    List<LatLng> fullRoute,
    LatLng currentLocation,
  ) {
    if (fullRoute.isEmpty) {
      return {'traveled': [], 'remaining': []};
    }

    int closestIndex = findClosestPointIndex(fullRoute, currentLocation);

    return {
      'traveled': fullRoute.sublist(0, closestIndex + 1),
      'remaining': fullRoute.sublist(closestIndex),
    };
  }
}