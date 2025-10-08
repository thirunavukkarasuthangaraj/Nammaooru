import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/maps_service.dart';
import '../../../core/services/api_service.dart';
import '../../../models/order_model.dart';

class CustomerLiveTrackingScreen extends StatefulWidget {
  final OrderModel order;
  final String phase; // 'going_to_shop' or 'delivering_to_customer'

  const CustomerLiveTrackingScreen({
    Key? key,
    required this.order,
    required this.phase,
  }) : super(key: key);

  @override
  State<CustomerLiveTrackingScreen> createState() => _CustomerLiveTrackingScreenState();
}

class _CustomerLiveTrackingScreenState extends State<CustomerLiveTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final MapsService _mapsService = MapsService();
  final ApiService _apiService = ApiService();

  // Animation Controllers
  late AnimationController _markerAnimationController;
  late Animation<LatLng> _markerAnimation;
  Timer? _locationUpdateTimer;

  // Location Data
  LatLng? _currentDriverLocation;
  LatLng? _previousDriverLocation;
  LatLng _destination = LatLng(0, 0);
  String _destinationName = '';
  String _destinationAddress = '';

  // Map Data
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Driver Info
  String _driverName = 'Driver';
  String _driverPhone = '';
  double _distanceToDestination = 0.0;
  String _estimatedArrival = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _initializeAnimationController();
    _initializeDestination();
    _startLiveTracking();
  }

  void _initializeAnimationController() {
    _markerAnimationController = AnimationController(
      duration: Duration(seconds: 15), // 15-second smooth animation
      vsync: this,
    );

    _markerAnimationController.addListener(() {
      if (_markerAnimation.value != null) {
        _updateDriverMarkerPosition(_markerAnimation.value);
      }
    });
  }

  void _initializeDestination() {
    if (widget.phase == 'going_to_shop') {
      _destination = LatLng(
        widget.order.shopLat ?? 0.0,
        widget.order.shopLng ?? 0.0,
      );
      _destinationName = widget.order.shopName ?? 'Shop';
      _destinationAddress = widget.order.shopAddress ?? '';
    } else {
      _destination = LatLng(
        widget.order.customerLat ?? 0.0,
        widget.order.customerLng ?? 0.0,
      );
      _destinationName = widget.order.customerName ?? 'Customer';
      _destinationAddress = widget.order.deliveryAddress ?? '';
    }

    // Set driver info (in real app, get from order data)
    _driverName = 'Delivery Partner';
    _driverPhone = '+91 98765 43210';
  }

  void _startLiveTracking() {
    // Update driver location every 15 seconds
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      _fetchDriverLocation();
    });

    // Initial load
    _fetchDriverLocation();
  }

  Future<void> _fetchDriverLocation() async {
    try {
      // In real implementation, fetch from API
      // For demo, we'll simulate driver movement
      Position? driverPosition = await _simulateDriverMovement();

      if (driverPosition != null) {
        LatLng newLocation = LatLng(driverPosition.latitude, driverPosition.longitude);

        setState(() {
          _previousDriverLocation = _currentDriverLocation;

          // Calculate distance and ETA
          _distanceToDestination = Geolocator.distanceBetween(
            newLocation.latitude,
            newLocation.longitude,
            _destination.latitude,
            _destination.longitude,
          ) / 1000; // Convert to km

          _estimatedArrival = _calculateETA(_distanceToDestination);
        });

        // Animate driver marker from previous to new location
        if (_previousDriverLocation != null) {
          _animateDriverMarker(_previousDriverLocation!, newLocation);
        } else {
          _currentDriverLocation = newLocation;
          _updateMapData();
        }
      }
    } catch (e) {
      print('Error fetching driver location: $e');
    }
  }

  Future<Position?> _simulateDriverMovement() async {
    // Simulate driver moving towards destination
    // In real app, this would be an API call to get actual driver location

    if (_currentDriverLocation == null) {
      // Start from a nearby location
      return Position(
        latitude: _destination.latitude + 0.01, // About 1km away
        longitude: _destination.longitude + 0.01,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    // Move slightly towards destination each time
    double latDiff = _destination.latitude - _currentDriverLocation!.latitude;
    double lngDiff = _destination.longitude - _currentDriverLocation!.longitude;

    // Move 10% closer to destination each update (simulating movement)
    double newLat = _currentDriverLocation!.latitude + (latDiff * 0.1);
    double newLng = _currentDriverLocation!.longitude + (lngDiff * 0.1);

    return Position(
      latitude: newLat,
      longitude: newLng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: _calculateBearing(_currentDriverLocation!, _destination),
      headingAccuracy: 0.0,
      speed: 8.33, // 30 km/h in m/s
      speedAccuracy: 0.0,
    );
  }

  void _animateDriverMarker(LatLng from, LatLng to) {
    _markerAnimation = Tween<LatLng>(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(
      parent: _markerAnimationController,
      curve: Curves.easeInOut,
    ));

    _markerAnimationController.reset();
    _markerAnimationController.forward().then((_) {
      setState(() {
        _currentDriverLocation = to;
      });
      _updateMapData();
    });
  }

  void _updateDriverMarkerPosition(LatLng position) {
    setState(() {
      _currentDriverLocation = position;
    });

    // Update only driver marker during animation
    _markers.removeWhere((marker) => marker.markerId.value == 'driver_location');
    _markers.add(_createDriverMarker(position));

    setState(() {});
  }

  void _updateMapData() {
    _markers.clear();
    _polylines.clear();

    // Add driver marker
    if (_currentDriverLocation != null) {
      _markers.add(_createDriverMarker(_currentDriverLocation!));
    }

    // Add destination marker
    _markers.add(Marker(
      markerId: MarkerId('destination'),
      position: _destination,
      infoWindow: InfoWindow(
        title: _destinationName,
        snippet: widget.phase == 'going_to_shop' ? 'Pickup Location' : 'Delivery Location',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        widget.phase == 'going_to_shop'
          ? BitmapDescriptor.hueOrange
          : BitmapDescriptor.hueRed,
      ),
    ));

    // Add polyline from driver to destination
    if (_currentDriverLocation != null) {
      _polylines.add(Polyline(
        polylineId: PolylineId('route_to_destination'),
        points: [_currentDriverLocation!, _destination],
        color: Colors.blue,
        width: 4,
        patterns: [PatternItem.dash(15), PatternItem.gap(10)],
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ));
    }

    setState(() {});

    // Update camera to show both driver and destination
    _updateCameraView();
  }

  Marker _createDriverMarker(LatLng position) {
    return Marker(
      markerId: MarkerId('driver_location'),
      position: position,
      infoWindow: InfoWindow(
        title: _driverName,
        snippet: 'Distance: ${_distanceToDestination.toStringAsFixed(2)} km',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      rotation: _calculateBearing(position, _destination),
      anchor: Offset(0.5, 0.5),
    );
  }

  void _updateCameraView() {
    if (_mapController != null && _currentDriverLocation != null) {
      List<LatLng> points = [_currentDriverLocation!, _destination];
      CameraPosition cameraPosition = _mapsService.getRouteCameraPosition(points);

      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    }
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1Rad = start.latitude * (3.14159 / 180);
    double lat2Rad = end.latitude * (3.14159 / 180);
    double deltaLonRad = (end.longitude - start.longitude) * (3.14159 / 180);

    double x = math.sin(deltaLonRad) * math.cos(lat2Rad);
    double y = math.cos(lat1Rad) * math.sin(lat2Rad) -
        (math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLonRad));

    double bearing = math.atan2(x, y) * (180 / 3.14159);
    return (bearing + 360) % 360;
  }

  String _calculateETA(double distanceKm) {
    if (distanceKm <= 0) return "Arrived";

    double speedKmh = 25.0; // Assume 25 km/h average speed
    double etaHours = distanceKm / speedKmh;
    int etaMinutes = (etaHours * 60).round();

    if (etaMinutes < 1) {
      return "< 1 min";
    } else if (etaMinutes < 60) {
      return "$etaMinutes min";
    } else {
      int hours = etaMinutes ~/ 60;
      int minutes = etaMinutes % 60;
      return "${hours}h ${minutes}m";
    }
  }

  void _callDriver() {
    // Implement phone call functionality
    print('Calling driver: $_driverPhone');
    // url_launcher can be used to make actual phone calls
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Tracking'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: _callDriver,
            tooltip: 'Call Driver',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _updateMapData();
            },
            initialCameraPosition: CameraPosition(
              target: _destination,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            padding: EdgeInsets.only(bottom: 200),
          ),

          // Driver info card
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Driver avatar
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  SizedBox(width: 15),

                  // Driver info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _driverName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.phase == 'going_to_shop'
                            ? 'Going to pickup your order'
                            : 'On the way to deliver',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Call button
                  IconButton(
                    onPressed: _callDriver,
                    icon: Icon(Icons.phone, color: Colors.green),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Order info
                    Row(
                      children: [
                        Icon(
                          widget.phase == 'going_to_shop'
                            ? Icons.store
                            : Icons.home,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _destinationName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _destinationAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Order #',
                          widget.order.orderNumber,
                          Icons.receipt,
                        ),
                        _buildStatColumn(
                          'Distance',
                          '${_distanceToDestination.toStringAsFixed(1)} km',
                          Icons.social_distance,
                        ),
                        _buildStatColumn(
                          'ETA',
                          _estimatedArrival,
                          Icons.access_time,
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Status indicator
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.phase == 'going_to_shop'
                                ? 'Driver is on the way to pickup your order'
                                : 'Your order is on the way to you',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Live update indicator
          Positioned(
            bottom: 220,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}