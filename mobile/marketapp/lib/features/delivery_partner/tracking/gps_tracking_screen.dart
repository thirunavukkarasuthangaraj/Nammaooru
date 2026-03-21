import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/services/maps_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';

class GpsTrackingScreen extends StatefulWidget {
  final OrderModel order;
  
  const GpsTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _locationUpdateTimer;
  bool _isNavigating = false;
  bool _isTrackingStarted = false;
  double _totalDistance = 0.0;
  double _distanceToDestination = 0.0;
  Duration _estimatedTime = Duration.zero;
  List<LatLng> _routePoints = [];

  late LatLng _pickupLocation;
  late LatLng _deliveryLocation;
  bool _isPickedUp = false;

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeLocations() {
    // Sample coordinates for demo
    _pickupLocation = const LatLng(13.0827, 80.2707); // Chennai
    _deliveryLocation = LatLng(
      widget.order.deliveryAddress.latitude,
      widget.order.deliveryAddress.longitude,
    );
  }

  Future<void> _startLocationTracking() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.requestLocationPermission();

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentPosition != null && mounted) {
        _updateMapCamera();
        _calculateRoute();
        _startRealTimeTracking();
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to get location', isError: true);
      }
    }
  }

  void _startRealTimeTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _updateLocationOnServer(position);
        _updateRoute(position);
      }
    });

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentPosition != null) {
        _updateLocationOnServer(_currentPosition!);
      }
    });
  }

  void _updateLocationOnServer(Position position) {
    // TODO: Send location update to server via API
    print('Updating location: ${position.latitude}, ${position.longitude}');
  }

  void _updateMapCamera() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 16,
          ),
        ),
      );
    }
  }

  void _calculateRoute() {
    if (_currentPosition == null) return;

    final currentLocation = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final destination = _isPickedUp ? _deliveryLocation : _pickupLocation;

    // Calculate distance
    _distanceToDestination = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      destination.latitude,
      destination.longitude,
    );

    // Estimate time (assuming average speed of 30 km/h)
    final timeInHours = _distanceToDestination / 1000 / 30;
    _estimatedTime = Duration(minutes: (timeInHours * 60).round());

    // Generate route points (simplified - in real app, use Google Directions API)
    _routePoints = [currentLocation, destination];

    setState(() {});
    _updateMapMarkers();
  }

  void _updateRoute(Position position) {
    final currentLocation = LatLng(position.latitude, position.longitude);
    final destination = _isPickedUp ? _deliveryLocation : _pickupLocation;

    _distanceToDestination = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      destination.latitude,
      destination.longitude,
    );

    // Check if reached destination (within 50 meters)
    if (_distanceToDestination < 50) {
      if (!_isPickedUp) {
        _showPickupConfirmation();
      } else {
        _showDeliveryConfirmation();
      }
    }

    setState(() {});
  }

  void _updateMapMarkers() {
    if (_mapController == null) return;

    MapsService.clearMarkers();

    // Current location marker
    if (_currentPosition != null) {
      MapsService.addDeliveryPartnerMarker(
        deliveryPartnerId: 'current',
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        partnerName: 'You',
      );
    }

    // Pickup location marker
    if (!_isPickedUp) {
      MapsService.addShopMarker(
        shopId: widget.order.shopId,
        position: _pickupLocation,
        shopName: widget.order.shopName,
      );
    }

    // Delivery location marker
    MapsService.addMarker(
      markerId: 'delivery',
      position: _deliveryLocation,
      infoWindow: 'Delivery Address',
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    // Draw route
    if (_routePoints.isNotEmpty) {
      MapsService.drawDeliveryRoute(_routePoints);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'GPS Tracking',
        backgroundColor: const Color(0xFFF44336),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTrackingInfo(),
          Expanded(
            child: _buildMap(),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTrackingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF44336),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Distance',
                    '${(_distanceToDestination / 1000).toStringAsFixed(1)} km',
                    Icons.place,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'ETA',
                    '${_estimatedTime.inMinutes} min',
                    Icons.access_time,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Status',
                    _isPickedUp ? 'Delivering' : 'Picking up',
                    Icons.local_shipping,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isPickedUp 
                          ? 'Navigate to delivery address'
                          : 'Navigate to pickup location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        MapsService.onMapCreated(controller);
        _updateMapMarkers();
      },
      initialCameraPosition: CameraPosition(
        target: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(13.0827, 80.2707),
        zoom: 14,
      ),
      markers: MapsService.markers,
      polylines: MapsService.polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Call Customer',
                    onPressed: _callCustomer,
                    icon: Icons.call,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Navigate',
                    onPressed: _openExternalNavigation,
                    icon: Icons.navigation,
                    backgroundColor: const Color(0xFFF44336),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: _isPickedUp ? 'Mark as Delivered' : 'Mark as Picked Up',
                onPressed: _isPickedUp ? _markAsDelivered : _markAsPickedUp,
                backgroundColor: Colors.green,
                icon: _isPickedUp ? Icons.check_circle : Icons.shopping_bag,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      _updateMapCamera();
      _calculateRoute();
    } catch (e) {
      Helpers.showSnackBar(context, 'Failed to get location', isError: true);
    }
  }

  void _callCustomer() {
    // TODO: Implement call functionality
    Helpers.showSnackBar(context, 'Calling customer...');
  }

  void _openExternalNavigation() {
    // TODO: Open external navigation app (Google Maps, Waze)
    Helpers.showSnackBar(context, 'Opening navigation...');
  }

  void _markAsPickedUp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Pickup'),
        content: const Text('Have you picked up the order from the shop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isPickedUp = true;
              });
              _calculateRoute();
              Helpers.showSnackBar(context, 'Order marked as picked up');
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _markAsDelivered() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryConfirmationScreen(order: widget.order),
      ),
    );
  }

  void _showPickupConfirmation() {
    if (!_isPickedUp) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Arrived at Pickup'),
          content: const Text('You have reached the pickup location. Confirm pickup?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _markAsPickedUp();
              },
              child: const Text('Confirm Pickup'),
            ),
          ],
        ),
      );
    }
  }

  void _showDeliveryConfirmation() {
    if (_isPickedUp) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Arrived at Destination'),
          content: const Text('You have reached the delivery location. Complete delivery?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _markAsDelivered();
              },
              child: const Text('Complete Delivery'),
            ),
          ],
        ),
      );
    }
  }
}

class DeliveryConfirmationScreen extends StatefulWidget {
  final OrderModel order;
  
  const DeliveryConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> {
  final TextEditingController _notesController = TextEditingController();
  String? _proofImagePath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Delivery Confirmation',
        backgroundColor: Color(0xFFF44336),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 20),
            _buildProofOfDelivery(),
            const SizedBox(height: 20),
            _buildDeliveryNotes(),
            const SizedBox(height: 20),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${widget.order.id}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Customer: ${widget.order.customerName}'),
          Text('Phone: ${widget.order.customerPhone}'),
          Text('Total: ${Helpers.formatCurrency(widget.order.totalAmount)}'),
          const SizedBox(height: 8),
          Text(
            'Delivery Address:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(widget.order.deliveryAddress.fullAddress),
        ],
      ),
    );
  }

  Widget _buildProofOfDelivery() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proof of Delivery',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_proofImagePath != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(_proofImagePath!), // In real app, use File
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Retake Photo',
                    onPressed: _takeProofPhoto,
                    icon: Icons.camera_alt,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: InkWell(
                onTap: _takeProofPhoto,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Take Photo',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Notes (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add any notes about the delivery...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        text: 'Complete Delivery',
        onPressed: _proofImagePath != null && !_isSubmitting 
            ? _completeDelivery 
            : null,
        isLoading: _isSubmitting,
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      ),
    );
  }

  void _takeProofPhoto() {
    // TODO: Implement camera functionality
    setState(() {
      _proofImagePath = 'https://via.placeholder.com/400x300'; // Sample image
    });
  }

  Future<void> _completeDelivery() async {
    setState(() => _isSubmitting = true);

    try {
      // TODO: Submit delivery confirmation to server
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/delivery-partner/dashboard',
          (route) => false,
        );
        Helpers.showSnackBar(context, 'Delivery completed successfully!');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to complete delivery', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}