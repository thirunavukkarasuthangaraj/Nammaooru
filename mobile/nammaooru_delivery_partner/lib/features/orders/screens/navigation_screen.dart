import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/simple_order_model.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/widgets/google_maps_widget.dart';

class NavigationScreen extends StatefulWidget {
  final OrderModel order;

  const NavigationScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  bool _isTrackingLocation = false;
  String? _estimatedTime;
  double? _distanceToDestination;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  Future<void> _initializeNavigation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final deliveryProvider = Provider.of<DeliveryPartnerProvider>(context, listen: false);

    // Initialize location services
    await locationProvider.initializeLocation();

    // Start location tracking for this order
    if (deliveryProvider.currentPartner?.partnerId != null) {
      await locationProvider.startLocationTracking(
        partnerId: deliveryProvider.currentPartner!.partnerId,
        assignmentId: widget.order.assignmentId?.toString(),
        orderStatus: widget.order.status,
      );

      setState(() {
        _isTrackingLocation = true;
      });

      _updateNavigationInfo();
    }
  }

  void _updateNavigationInfo() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    if (locationProvider.currentPosition != null) {
      // Calculate distance to destination
      double? destLat, destLng;

      if (widget.order.status == 'accepted') {
        // Navigate to shop for pickup
        destLat = widget.order.shopLatitude;
        destLng = widget.order.shopLongitude;
      } else if (widget.order.status == 'picked_up' || widget.order.status == 'in_transit') {
        // Navigate to customer for delivery
        destLat = widget.order.customerLatitude;
        destLng = widget.order.customerLongitude;
      }

      if (destLat != null && destLng != null && destLat != 0 && destLng != 0) {
        setState(() {
          _distanceToDestination = locationProvider.calculateDistanceToDestination(destLat!, destLng!);
        });

        // Get ETA
        _getETA(destLat, destLng);
      }
    }
  }

  Future<void> _getETA(double destLat, double destLng) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final deliveryProvider = Provider.of<DeliveryPartnerProvider>(context, listen: false);

    if (deliveryProvider.currentPartner?.partnerId != null) {
      final eta = await locationProvider.getETAToDestination(
        partnerId: deliveryProvider.currentPartner!.partnerId,
        destLat: destLat,
        destLng: destLng,
      );

      if (eta != null && mounted) {
        setState(() {
          _estimatedTime = eta['estimatedMinutes'] != null
              ? '${eta['estimatedMinutes']} min'
              : 'N/A';
        });
      }
    }
  }

  String _getDestinationTitle() {
    if (widget.order.status == 'accepted') {
      return 'Navigate to Shop';
    } else if (widget.order.status == 'picked_up' || widget.order.status == 'in_transit') {
      return 'Navigate to Customer';
    }
    return 'Navigation';
  }

  String _getDestinationSubtitle() {
    if (widget.order.status == 'accepted') {
      return 'Pickup: ${widget.order.shopName}';
    } else if (widget.order.status == 'picked_up' || widget.order.status == 'in_transit') {
      return 'Delivery: ${widget.order.customerName}';
    }
    return '';
  }

  Widget _buildNavigationInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.order.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order #${widget.order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Destination Info
          Row(
            children: [
              Icon(
                widget.order.status == 'accepted' ? Icons.store : Icons.home,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDestinationTitle(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getDestinationSubtitle(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Distance and ETA
          Row(
            children: [
              if (_distanceToDestination != null) ...[
                Icon(Icons.straighten, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_distanceToDestination!.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (_estimatedTime != null) ...[
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  'ETA: $_estimatedTime',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Navigation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openNavigation,
              icon: const Icon(Icons.navigation),
              label: const Text('Open in Maps'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.order.status) {
      case 'accepted':
        return Colors.orange;
      case 'picked_up':
        return Colors.blue;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _openNavigation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    double? destLat, destLng;

    if (widget.order.status == 'accepted') {
      // Navigate to shop for pickup
      destLat = widget.order.shopLatitude;
      destLng = widget.order.shopLongitude;
    } else if (widget.order.status == 'picked_up' || widget.order.status == 'in_transit') {
      // Navigate to customer for delivery
      destLat = widget.order.customerLatitude;
      destLng = widget.order.customerLongitude;
    }

    if (destLat != null && destLng != null && destLat != 0 && destLng != 0) {
      await locationProvider.openNavigation(destLat, destLng);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Destination coordinates not available. Shop: ${widget.order.shopName}'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getDestinationTitle()),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              return IconButton(
                onPressed: () {
                  _updateNavigationInfo();
                },
                icon: Icon(
                  _isTrackingLocation ? Icons.gps_fixed : Icons.gps_off,
                  color: _isTrackingLocation ? Colors.green : Colors.grey,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation Info Card
          _buildNavigationInfo(),

          // Google Maps Widget
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<LocationProvider>(
                builder: (context, locationProvider, child) {
                  // Convert OrderModel to Order for GoogleMapsWidget
                  final order = widget.order;

                  return GoogleMapsWidget(
                    activeOrder: order,
                    showCurrentLocation: true,
                    showRoute: true,
                    height: double.infinity,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Don't stop location tracking here as it might be used by other screens
    super.dispose();
  }
}