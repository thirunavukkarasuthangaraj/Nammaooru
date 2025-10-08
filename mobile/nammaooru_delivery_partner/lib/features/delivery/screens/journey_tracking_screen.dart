import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/api_service.dart';
import '../../../models/order_model.dart';

class JourneyTrackingScreen extends StatefulWidget {
  final OrderModel order;
  final String journeyType; // 'to_shop' or 'to_customer'

  const JourneyTrackingScreen({
    Key? key,
    required this.order,
    required this.journeyType,
  }) : super(key: key);

  @override
  State<JourneyTrackingScreen> createState() => _JourneyTrackingScreenState();
}

class _JourneyTrackingScreenState extends State<JourneyTrackingScreen> {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  Position? _currentPosition;
  double _distanceToDestination = 0.0;
  String _estimatedArrival = 'Calculating...';
  bool _isNearDestination = false;
  bool _hasArrivedAtDestination = false;

  // Destination coordinates
  late double _destinationLat;
  late double _destinationLng;
  late String _destinationName;
  late String _destinationAddress;

  @override
  void initState() {
    super.initState();
    _initializeDestination();
    _startJourneyTracking();
  }

  void _initializeDestination() {
    if (widget.journeyType == 'to_shop') {
      _destinationLat = widget.order.shopLat ?? 0.0;
      _destinationLng = widget.order.shopLng ?? 0.0;
      _destinationName = widget.order.shopName ?? 'Shop';
      _destinationAddress = widget.order.shopAddress ?? '';
    } else {
      _destinationLat = widget.order.customerLat ?? 0.0;
      _destinationLng = widget.order.customerLng ?? 0.0;
      _destinationName = widget.order.customerName ?? 'Customer';
      _destinationAddress = widget.order.deliveryAddress ?? '';
    }
  }

  void _startJourneyTracking() async {
    try {
      // Start journey API call
      await _apiService.startJourney(
        assignmentId: int.parse(widget.order.id),
        journeyType: widget.journeyType,
        destinationLat: _destinationLat,
        destinationLng: _destinationLng,
      );

      // Start location tracking
      if (widget.journeyType == 'to_shop') {
        await _locationService.startJourneyToShop(
          shopLat: _destinationLat,
          shopLng: _destinationLng,
          assignmentId: int.parse(widget.order.id),
          onLocationUpdate: _onLocationUpdate,
        );
      } else {
        await _locationService.startJourneyToCustomer(
          customerLat: _destinationLat,
          customerLng: _destinationLng,
          assignmentId: int.parse(widget.order.id),
          onLocationUpdate: _onLocationUpdate,
        );
      }
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
      _isNearDestination = distance < 0.1; // Within 100 meters
    });

    // Auto-detect arrival
    if (_isNearDestination && !_hasArrivedAtDestination) {
      _showArrivalDialog();
    }
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎯 Arrival Detected'),
        content: Text('You are near $_destinationName. Have you arrived?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: _confirmArrival,
            child: Text('Yes, I\'ve Arrived'),
          ),
        ],
      ),
    );
  }

  void _confirmArrival() async {
    Navigator.of(context).pop(); // Close dialog

    try {
      // Send arrival confirmation to API
      await _apiService.confirmArrival(
        assignmentId: int.parse(widget.order.id),
        journeyType: widget.journeyType,
      );

      setState(() {
        _hasArrivedAtDestination = true;
      });

      // Show next steps
      _showNextStepsDialog();
    } catch (e) {
      _showErrorMessage('Failed to confirm arrival: $e');
    }
  }

  void _showNextStepsDialog() {
    String nextSteps = widget.journeyType == 'to_shop'
        ? 'Collect the order from the shop and verify the items.'
        : 'Deliver the order to the customer and collect payment if needed.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✅ Arrival Confirmed'),
        content: Text(nextSteps),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _openNavigation() async {
    try {
      if (widget.journeyType == 'to_shop') {
        await _locationService.navigateToShop(_destinationLat, _destinationLng);
      } else {
        await _locationService.navigateToCustomer(_destinationLat, _destinationLng);
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
      ),
      body: Column(
        children: [
          // Journey Status Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.journeyType == 'to_shop'
                        ? Icons.store
                        : Icons.person_pin_circle,
                      color: Colors.white,
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
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _destinationAddress,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      icon: Icons.social_distance,
                      label: 'Distance',
                      value: '${_distanceToDestination.toStringAsFixed(2)} km',
                    ),
                    _buildInfoItem(
                      icon: Icons.access_time,
                      label: 'ETA',
                      value: _estimatedArrival,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Order Details Card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${widget.order.orderNumber}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.order.status.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '₹${widget.order.totalAmount}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery Fee',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '₹${widget.order.deliveryFee}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Indicator
          if (_isNearDestination && !_hasArrivedAtDestination)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are near the destination! Tap "I\'ve Arrived" when you reach.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_hasArrivedAtDestination)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Arrival confirmed! You can now proceed with the ${widget.journeyType == 'to_shop' ? 'pickup' : 'delivery'}.',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Spacer(),

          // Action Buttons
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Navigate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openNavigation,
                    icon: Icon(Icons.navigation),
                    label: Text('Open Navigation'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Arrived Button
                if (_isNearDestination && !_hasArrivedAtDestination)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmArrival,
                      icon: Icon(Icons.check),
                      label: Text('I\'ve Arrived'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                // Continue Button (after arrival)
                if (_hasArrivedAtDestination)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.arrow_forward),
                      label: Text('Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.order.status.toLowerCase()) {
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'picked_up':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}