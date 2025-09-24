import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderNumber;
  final String? assignmentId;

  const OrderTrackingScreen({
    super.key,
    required this.orderNumber,
    this.assignmentId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Timer? _locationUpdateTimer;

  // Map state
  LatLng? _driverLocation;
  LatLng? _customerLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Tracking data
  Map<String, dynamic>? _trackingData;
  bool _isLoading = true;
  String? _errorMessage;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _routeController;
  late Animation<double> _routeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTrackingData();
    _startLocationUpdates();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _routeController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _routeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _routeController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadTrackingData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/delivery-partner/track/order/${widget.orderNumber}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _trackingData = data['tracking'];
            _updateMapData();
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load tracking data');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateMapData() {
    if (_trackingData == null) return;

    final currentLocation = _trackingData!['currentLocation'];
    if (currentLocation != null) {
      _driverLocation = LatLng(
        currentLocation['latitude'].toDouble(),
        currentLocation['longitude'].toDouble(),
      );
    }

    // Update markers
    _updateMarkers();

    // Update polyline (route between driver and customer)
    if (_driverLocation != null && _customerLocation != null) {
      _updatePolyline();
    }

    // Move camera to show both locations
    if (_driverLocation != null) {
      _moveCameraToShowBothLocations();
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Driver marker with animation
    if (_driverLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _driverLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Delivery Partner',
          snippet: _trackingData?['partnerName'] ?? 'On the way',
        ),
      ));
    }

    // Customer location marker
    if (_customerLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('customer'),
        position: _customerLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: 'Delivery Location',
          snippet: 'Your order will be delivered here',
        ),
      ));
    }
  }

  void _updatePolyline() {
    if (_driverLocation == null || _customerLocation == null) return;

    _polylines.clear();

    // Create animated polyline with gradient effect
    _polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: [_driverLocation!, _customerLocation!],
      color: AppColors.primary,
      width: 6,
      patterns: [PatternItem.dash(30), PatternItem.gap(15)],
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    ));

    // Add a glowing effect with a thicker background polyline
    _polylines.add(Polyline(
      polylineId: const PolylineId('route_glow'),
      points: [_driverLocation!, _customerLocation!],
      color: AppColors.primary.withOpacity(0.3),
      width: 12,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    ));

    // Animate route
    _routeController.forward(from: 0.0);
  }

  void _moveCameraToShowBothLocations() {
    if (_mapController == null || _driverLocation == null) return;

    if (_customerLocation != null) {
      // Show both locations
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _driverLocation!.latitude < _customerLocation!.latitude
              ? _driverLocation!.latitude
              : _customerLocation!.latitude,
          _driverLocation!.longitude < _customerLocation!.longitude
              ? _driverLocation!.longitude
              : _customerLocation!.longitude,
        ),
        northeast: LatLng(
          _driverLocation!.latitude > _customerLocation!.latitude
              ? _driverLocation!.latitude
              : _customerLocation!.latitude,
          _driverLocation!.longitude > _customerLocation!.longitude
              ? _driverLocation!.longitude
              : _customerLocation!.longitude,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } else {
      // Show only driver location
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_driverLocation!, 16.0),
      );
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _loadTrackingData(),
    );
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _pulseController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order ${widget.orderNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status header
          if (_trackingData != null) _buildStatusHeader(),

          // Map
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _buildMap(),
          ),

          // Bottom sheet with details
          if (_trackingData != null) _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    final status = _trackingData!['deliveryStatus'] ?? 'UNKNOWN';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: statusColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Icon(
                  _getStatusIcon(status),
                  color: statusColor,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  'Order ${widget.orderNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _driverLocation ?? const LatLng(12.2958, 76.6394), // Default to Mysore
        zoom: 14.0,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (_driverLocation != null) {
          _moveCameraToShowBothLocations();
        }
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildBottomSheet() {
    final currentLocation = _trackingData!['currentLocation'];
    final partnerName = _trackingData!['partnerName'] ?? 'Delivery Partner';
    final partnerPhone = _trackingData!['partnerPhone'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.delivery_dining, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (partnerPhone != null)
                        Text(
                          partnerPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (partnerPhone != null)
                  IconButton(
                    onPressed: () {
                      // TODO: Implement phone call functionality
                      print('Call: $partnerPhone');
                    },
                    icon: const Icon(Icons.phone, color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (currentLocation != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on,
                       color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last updated: ${_formatTimestamp(currentLocation['lastUpdated'])}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              if (currentLocation['speed'] != null &&
                  currentLocation['speed'] > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.speed,
                         color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Speed: ${(currentLocation['speed'] * 3.6).toStringAsFixed(1)} km/h',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load tracking data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again later',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTrackingData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return Colors.blue;
      case 'PICKED_UP':
        return Colors.orange;
      case 'IN_TRANSIT':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return 'Order Accepted';
      case 'PICKED_UP':
        return 'Picked Up';
      case 'IN_TRANSIT':
        return 'On the Way';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'PICKED_UP':
        return Icons.local_shipping;
      case 'IN_TRANSIT':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.done_all;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds} seconds ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return '${difference.inHours} hours ago';
      }
    } catch (e) {
      return timestamp.toString();
    }
  }
}