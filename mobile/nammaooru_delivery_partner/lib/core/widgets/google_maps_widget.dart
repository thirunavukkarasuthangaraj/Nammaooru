import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../models/simple_order_model.dart';

class GoogleMapsWidget extends StatefulWidget {
  final OrderModel? activeOrder;
  final bool showCurrentLocation;
  final bool showRoute;
  final Function(LatLng)? onMapTap;
  final double height;
  final bool enableRealTimeTracking;

  const GoogleMapsWidget({
    Key? key,
    this.activeOrder,
    this.showCurrentLocation = true,
    this.showRoute = false,
    this.onMapTap,
    this.height = 300,
    this.enableRealTimeTracking = true,
  }) : super(key: key);

  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionStreamSubscription;
  PolylinePoints polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();
    _initializeMap();
    if (widget.enableRealTimeTracking) {
      _startRealTimeLocationTracking();
    }
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    _setupMarkersAndRoute();
  }

  void _startRealTimeLocationTracking() {
    // Update location every 5 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _getCurrentLocation();
      await _updateDriverMarker();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position? position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _setupMarkersAndRoute() {
    Set<Marker> markers = {};

    // Add current location marker
    if (_currentLocation != null && widget.showCurrentLocation) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
        ),
      );
    }

    // Add order destination markers
    if (widget.activeOrder != null) {
      final order = widget.activeOrder!;

      // Shop location marker
      if (order.shopLatitude != null && order.shopLongitude != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('shop_location'),
            position: LatLng(order.shopLatitude!, order.shopLongitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: 'Shop: ${order.shopName}',
              snippet: 'Pickup location',
            ),
          ),
        );
      }

      // Customer location marker
      if (order.customerLatitude != null && order.customerLongitude != null) {
        _destinationLocation = LatLng(order.customerLatitude!, order.customerLongitude!);
        markers.add(
          Marker(
            markerId: const MarkerId('customer_location'),
            position: _destinationLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Customer: ${order.customerName}',
              snippet: 'Delivery location',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });

    // Setup route if needed
    if (widget.showRoute && _currentLocation != null && _destinationLocation != null) {
      _setupRoute();
    }
  }

  Future<void> _updateDriverMarker() async {
    if (_currentLocation == null) return;

    Set<Marker> updatedMarkers = Set.from(_markers);
    updatedMarkers.removeWhere((marker) => marker.markerId.value == 'current_location');

    updatedMarkers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Driver position',
        ),
      ),
    );

    setState(() {
      _markers = updatedMarkers;
    });

    // Update route if showing route
    if (widget.showRoute && _destinationLocation != null) {
      await _setupRoute();
    }
  }

  Future<void> _setupRoute() async {
    if (_currentLocation == null || _destinationLocation == null) return;

    // Create a simple polyline connecting current location to destination
    // For production with Google Directions API, you would fetch waypoints here
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [_currentLocation!, _destinationLocation!],
      color: const Color(0xFF2196F3), // Blue color for route
      width: 6,
      patterns: [PatternItem.dot, PatternItem.gap(10)],
      geodesic: true,
    );

    setState(() {
      _polylines = {polyline};
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Zoom to show all markers
    if (_markers.isNotEmpty) {
      _fitMarkersOnMap();
    }
  }

  void _fitMarkersOnMap() {
    if (_markers.isEmpty || _mapController == null) return;

    List<LatLng> positions = _markers.map((marker) => marker.position).toList();

    if (positions.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(positions.first, 16),
      );
    } else {
      LatLngBounds bounds = _getBounds(positions);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  LatLngBounds _getBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (LatLng position in positions) {
      minLat = position.latitude < minLat ? position.latitude : minLat;
      maxLat = position.latitude > maxLat ? position.latitude : maxLat;
      minLng = position.longitude < minLng ? position.longitude : minLng;
      maxLng = position.longitude > maxLng ? position.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  void didUpdateWidget(GoogleMapsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeOrder != widget.activeOrder) {
      _setupMarkersAndRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _currentLocation != null
            ? GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 14,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: widget.showCurrentLocation,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onTap: widget.onMapTap,
                mapType: MapType.normal,
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading map...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}

// Updated extension to work with OrderModel
extension GoogleMapsWidgetExtensions on GoogleMapsWidget {
  /// Navigate to destination using Google Maps
  static Future<void> navigateToDestination({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
  }) async {
    final LocationService locationService = LocationService();
    await locationService.openGoogleMaps(destinationLat, destinationLng);
  }

  /// Calculate ETA to destination
  static Future<String> calculateETA({
    required double currentLat,
    required double currentLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      double distance = LocationService.calculateDistance(
        currentLat,
        currentLng,
        destinationLat,
        destinationLng,
      );

      // Rough ETA calculation (assuming 30 km/h average speed)
      double timeInHours = distance / 30;
      int timeInMinutes = (timeInHours * 60).round();

      if (timeInMinutes < 1) {
        return '< 1 min';
      } else if (timeInMinutes < 60) {
        return '$timeInMinutes min';
      } else {
        int hours = timeInMinutes ~/ 60;
        int minutes = timeInMinutes % 60;
        return '${hours}h ${minutes}m';
      }
    } catch (e) {
      return 'ETA unavailable';
    }
  }
}