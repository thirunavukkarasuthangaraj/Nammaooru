import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/maps_service.dart';
import '../../../core/services/api_service.dart';
import '../../../models/order_model.dart';
import '../../../core/config/env_config.dart';

class MapJourneyScreen extends StatefulWidget {
  final OrderModel order;
  final String journeyType; // 'to_shop' or 'to_customer'

  const MapJourneyScreen({
    Key? key,
    required this.order,
    required this.journeyType,
  }) : super(key: key);

  @override
  State<MapJourneyScreen> createState() => _MapJourneyScreenState();
}

class _MapJourneyScreenState extends State<MapJourneyScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final MapsService _mapsService = MapsService();
  final ApiService _apiService = ApiService();

  // Current state
  Position? _currentPosition;
  List<LatLng> _traveledPath = []; // Actual path driver has traveled
  List<LatLng> _plannedRoute = []; // Straight line route for reference
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Destination info
  late LatLng _destination;
  late String _destinationName;
  late String _destinationAddress;

  // Journey stats
  double _distanceToDestination = 0.0;
  String _estimatedArrival = 'Calculating...';
  bool _isNearDestination = false;
  bool _hasArrivedAtDestination = false;

  @override
  void initState() {
    super.initState();
    _initializeDestination();
    _startJourneyTracking();
  }

  void _initializeDestination() {
    if (widget.journeyType == 'to_shop') {
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
  }

  void _startJourneyTracking() async {
    try {
      // Get initial current location
      Position? currentPos = await _locationService.getCurrentLocation();
      if (currentPos != null) {
        setState(() {
          _currentPosition = currentPos;
          _traveledPath.add(LatLng(currentPos.latitude, currentPos.longitude));
        });

        // Create initial planned route (straight line for reference)
        _plannedRoute = await _mapsService.getRoutePolyline(
          startLat: currentPos.latitude,
          startLng: currentPos.longitude,
          endLat: _destination.latitude,
          endLng: _destination.longitude,
        );

        _updateMapData();
      }

      // Start real-time location tracking
      if (widget.journeyType == 'to_shop') {
        await _locationService.startJourneyToShop(
          shopLat: _destination.latitude,
          shopLng: _destination.longitude,
          assignmentId: int.parse(widget.order.id),
          onLocationUpdate: _onLocationUpdate,
        );
      } else {
        await _locationService.startJourneyToCustomer(
          customerLat: _destination.latitude,
          customerLng: _destination.longitude,
          assignmentId: int.parse(widget.order.id),
          onLocationUpdate: _onLocationUpdate,
        );
      }

      // Load location history to show previously traveled path
      await _loadLocationHistory();
    } catch (e) {
      print('Error starting journey tracking: $e');
      _showErrorMessage('Failed to start journey tracking: $e');
    }
  }

  void _onLocationUpdate(Position position, double distance, String eta) {
    setState(() {
      _currentPosition = position;
      _distanceToDestination = distance;
      _estimatedArrival = eta;
      _isNearDestination = distance < 0.05; // Within 50 meters

      // Add new location to traveled path (only if moved significantly)
      LatLng newPoint = LatLng(position.latitude, position.longitude);

      if (_traveledPath.isEmpty ||
          Geolocator.distanceBetween(
            _traveledPath.last.latitude,
            _traveledPath.last.longitude,
            newPoint.latitude,
            newPoint.longitude,
          ) > 10) { // Only add if moved more than 10 meters
        _traveledPath.add(newPoint);
      }
    });

    _updateMapData();

    // Auto-detect arrival
    if (_isNearDestination && !_hasArrivedAtDestination) {
      _showArrivalDialog();
    }
  }

  Future<void> _loadLocationHistory() async {
    try {
      final response = await _apiService.getLocationHistory(
        assignmentId: int.parse(widget.order.id),
        hours: 24,
      );

      if (response['success'] && response['locations'] != null) {
        List<Map<String, dynamic>> locations = List<Map<String, dynamic>>.from(response['locations']);

        // Filter locations for this specific assignment and sort by timestamp
        locations = locations
            .where((loc) => loc['assignmentId']?.toString() == widget.order.id)
            .toList();

        locations.sort((a, b) {
          DateTime timeA = DateTime.parse(a['timestamp']);
          DateTime timeB = DateTime.parse(b['timestamp']);
          return timeA.compareTo(timeB);
        });

        // Convert location history to polyline - this shows actual road path
        List<LatLng> historyPath = _mapsService.createLocationHistoryPolyline(locations);

        setState(() {
          // Use history path as the base traveled path (actual road route)
          if (historyPath.isNotEmpty) {
            _traveledPath = historyPath;
            print('📍 Loaded ${historyPath.length} GPS points from driver\'s actual journey');
          }
        });

        _updateMapData();
      }
    } catch (e) {
      print('Error loading location history: $e');
    }
  }

  void _updateMapData() {
    // Create markers
    _markers = _mapsService.createDeliveryMarkers(
      currentLocation: _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null,
      shopLocation: widget.journeyType == 'to_shop' ? _destination : null,
      customerLocation: widget.journeyType == 'to_customer' ? _destination : null,
      shopName: widget.journeyType == 'to_shop' ? _destinationName : '',
      customerName: widget.journeyType == 'to_customer' ? _destinationName : '',
      rotation: _currentPosition?.heading ?? 0.0,
    );

    // Create polylines
    _polylines.clear();

    // 1. Traveled path polyline (GREEN - actual GPS route driver took on roads)
    if (_traveledPath.length > 1) {
      _polylines.add(_mapsService.createTraveledPathPolyline(_traveledPath));
    }

    // 2. Remaining route to destination (BLUE - straight line for reference)
    if (_currentPosition != null) {
      List<LatLng> remainingPath = [
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _destination,
      ];

      _polylines.add(_mapsService.createRemainingRoutePolyline(remainingPath));
    }

    // 3. Show planned route only if no traveled path exists yet (GRAY - reference line)
    if (_traveledPath.length <= 1 && _plannedRoute.isNotEmpty) {
      _polylines.add(_mapsService.createPolyline(
        polylineId: 'planned_route',
        points: _plannedRoute,
        color: Colors.grey.withOpacity(0.6),
        width: 3.0,
        patterns: [PatternItem.dash(15), PatternItem.gap(10)],
      ));
    }

    setState(() {});

    // Update camera to show all relevant points
    _updateCameraView();
  }

  void _updateCameraView() {
    if (_mapController != null && _traveledPath.isNotEmpty) {
      // Include all important points for camera bounds
      List<LatLng> allPoints = [
        ..._traveledPath,
        _destination,
      ];

      if (_currentPosition != null) {
        allPoints.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
      }

      CameraPosition cameraPosition = _mapsService.getRouteCameraPosition(allPoints);

      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    }
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green),
            SizedBox(width: 8),
            Text('Arrived at $_destinationName'),
          ],
        ),
        content: Text('You are near $_destinationName. Have you arrived?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: _confirmArrival,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Yes, I\'ve Arrived'),
          ),
        ],
      ),
    );
  }

  void _confirmArrival() async {
    Navigator.of(context).pop(); // Close dialog

    try {
      await _apiService.confirmArrival(
        assignmentId: int.parse(widget.order.id),
        journeyType: widget.journeyType,
      );

      setState(() {
        _hasArrivedAtDestination = true;
      });

      _showSuccessMessage('Arrival confirmed successfully!');

      // Wait a moment then navigate back
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
    } catch (e) {
      _showErrorMessage('Failed to confirm arrival: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _openNavigation() async {
    try {
      if (widget.journeyType == 'to_shop') {
        await _locationService.navigateToShop(_destination.latitude, _destination.longitude);
      } else {
        await _locationService.navigateToCustomer(_destination.latitude, _destination.longitude);
      }
    } catch (e) {
      _showErrorMessage('Failed to open navigation: $e');
    }
  }

  @override
  void dispose() {
    _locationService.stopEnhancedLocationTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.journeyType == 'to_shop' ? 'Going to Shop' : 'Delivering Order'}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              if (_mapController != null && _currentPosition != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _destination,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            padding: EdgeInsets.only(bottom: 200), // Space for bottom sheet
          ),

          // Legend
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem('Actual GPS Route', Colors.green),
                  _buildLegendItem('Direct to Destination', Colors.blue),
                  if (_traveledPath.length <= 1)
                    _buildLegendItem('Planned Route', Colors.grey),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Destination info
                        Row(
                          children: [
                            Icon(
                              widget.journeyType == 'to_shop'
                                  ? Icons.store
                                  : Icons.person_pin_circle,
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

                        // Journey stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.social_distance,
                              label: 'Distance',
                              value: '${_distanceToDestination.toStringAsFixed(2)} km',
                            ),
                            _buildStatItem(
                              icon: Icons.access_time,
                              label: 'ETA',
                              value: _estimatedArrival,
                            ),
                            _buildStatItem(
                              icon: Icons.route,
                              label: 'Traveled',
                              value: '${(_traveledPath.length * 0.01).toStringAsFixed(1)} km',
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openNavigation,
                                icon: Icon(Icons.navigation),
                                label: Text('Navigate'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (_isNearDestination && !_hasArrivedAtDestination) ...[
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _confirmArrival,
                                  icon: Icon(Icons.check),
                                  label: Text('I\'ve Arrived'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Arrival status banner
          if (_hasArrivedAtDestination)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Arrival Confirmed! You can now proceed with the ${widget.journeyType == 'to_shop' ? 'pickup' : 'delivery'}.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
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