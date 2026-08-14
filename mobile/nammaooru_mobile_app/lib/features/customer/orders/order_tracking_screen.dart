import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/order_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderNumber;
  final String? assignmentId;
  // Order data drives the status timeline; live partner tracking (and the
  // map, later) only enrich it when available.
  final Order? order;

  const OrderTrackingScreen({
    super.key,
    required this.orderNumber,
    this.assignmentId,
    this.order,
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

  // Live order status: starts from the snapshot passed in, then refreshed
  // from the server so shop-owner status changes appear on re-open/poll
  final OrderService _orderService = OrderService();
  Order? _order;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _routeController;
  late Animation<double> _routeAnimation;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _initializeAnimations();
    _loadOrderStatus();
    _loadTrackingData();
    _startLocationUpdates();
  }

  /// Refresh the order itself so the timeline follows the shop owner's
  /// status changes (the tracking API below only knows the delivery partner)
  Future<void> _loadOrderStatus() async {
    final orderId = widget.order?.id;
    if (orderId == null) return;
    try {
      final result = await _orderService.getOrderById(orderId);
      if (result['success'] == true && result['data'] is Order && mounted) {
        final fresh = result['data'] as Order;
        final statusChanged = fresh.status != _order?.status;
        setState(() => _order = fresh);
        // Re-run the fill animation only when progress actually moved,
        // not on every 30s poll
        if (statusChanged) _routeController.forward(from: 0.0);
      }
    } catch (_) {
      // Keep showing the snapshot we already have
    }
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

    // Fill the timeline + journey line as soon as the screen opens
    _routeController.forward(from: 0.0);
  }

  Future<void> _loadTrackingData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/mobile/delivery-partner/track/order/${widget.orderNumber}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.requestTimeout);

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
        throw Exception('Unable to connect to server. Please check your internet connection.');
      }
    } catch (e) {
      setState(() {
        // Clean error message - don't expose technical details
        String cleanError = e.toString();
        if (cleanError.contains('TimeoutException')) {
          _errorMessage = 'Connection timeout. Please check your internet connection and try again.';
        } else if (cleanError.contains('SocketException') || cleanError.contains('Failed host lookup')) {
          _errorMessage = 'Cannot connect to server. Please check your internet connection.';
        } else if (cleanError.contains('http://') || cleanError.contains('https://')) {
          // Remove URL from error message
          _errorMessage = 'Unable to load tracking information. Please try again.';
        } else {
          _errorMessage = cleanError.replaceAll('Exception: ', '');
        }
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
      (timer) {
        _loadOrderStatus();
        _loadTrackingData();
      },
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
          // Status header (order status; live partner status when available)
          _buildStatusHeader(),

          // Journey line + status timeline. The map returns here later —
          // for now tracking works for every order with no location needed.
          Expanded(
            child: _isLoading && _order == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildJourneyLine(),
                        const SizedBox(height: 28),
                        _buildTimeline(),
                      ],
                    ),
                  ),
          ),

          // Bottom sheet with details
          if (_trackingData != null) _buildBottomSheet(),
        ],
      ),
    );
  }

  // ===== Status timeline =====

  String get _currentStatus {
    var s = (_order?.status ?? _trackingData?['deliveryStatus'] ?? 'PENDING')
        .toString()
        .toUpperCase();
    if (s == 'COMPLETED') s = 'DELIVERED';
    return s;
  }

  bool get _isCancelled =>
      _currentStatus == 'CANCELLED' || _currentStatus == 'REFUNDED';

  bool get _isPickupFlow {
    if (_currentStatus == 'SELF_PICKUP_COLLECTED') return true;
    return _order?.statusHistory
            .any((h) => h.status.toUpperCase() == 'SELF_PICKUP_COLLECTED') ??
        false;
  }

  List<_TimelineStep> get _steps {
    final steps = <_TimelineStep>[
      const _TimelineStep('PENDING', 'Order Placed', 'ஆர்டர் செய்யப்பட்டது', Icons.receipt_long),
      const _TimelineStep('CONFIRMED', 'Confirmed', 'உறுதி செய்யப்பட்டது', Icons.check_circle_outline),
      const _TimelineStep('PREPARING', 'Preparing', 'தயாராகிறது', Icons.soup_kitchen_outlined),
      const _TimelineStep('READY_FOR_PICKUP', 'Ready', 'தயார்', Icons.inventory_2_outlined),
    ];
    if (_isPickupFlow) {
      steps.add(const _TimelineStep('SELF_PICKUP_COLLECTED', 'Collected', 'பெறப்பட்டது', Icons.storefront));
    } else {
      steps.add(const _TimelineStep('OUT_FOR_DELIVERY', 'Out for Delivery', 'டெலிவரிக்கு புறப்பட்டது', Icons.delivery_dining));
      steps.add(const _TimelineStep('DELIVERED', 'Delivered', 'வழங்கப்பட்டது', Icons.home));
    }
    return steps;
  }

  int _currentStepIndex(List<_TimelineStep> steps) {
    if (_isCancelled) {
      // Highest step actually reached before cancelling (from history)
      var reached = 0;
      for (var i = 0; i < steps.length; i++) {
        final hit = _order?.statusHistory
                .any((h) => h.status.toUpperCase() == steps[i].key) ??
            false;
        if (hit) reached = i;
      }
      return reached;
    }
    final idx = steps.indexWhere((s) => s.key == _currentStatus);
    return idx < 0 ? 0 : idx;
  }

  DateTime? _timeFor(String key) {
    if (_order == null) return null;
    for (final h in _order!.statusHistory) {
      if (h.status.toUpperCase() == key) return h.timestamp;
    }
    if (key == 'PENDING') return _order!.orderDate;
    return null;
  }

  String _fmtTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.hour >= 12 ? 'PM' : 'AM';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '$h:$m $ap, ${t.day} ${months[t.month - 1]}';
  }

  /// Straight source→destination line: shop on the left, home (or customer
  /// hand for self-pickup) on the right, green progress fills between them
  /// and the vehicle icon rides the line to the current position.
  Widget _buildJourneyLine() {
    final steps = _steps;
    final current = _currentStepIndex(steps);
    final progress = steps.length <= 1 ? 0.0 : current / (steps.length - 1);
    final lineColor = _isCancelled ? Colors.red : AppColors.primary;
    // The scooter means "a driver is on the road" — showing it earlier
    // (e.g. while the order is just Ready) confuses customers. Before
    // dispatch the progress tip is a plain dot instead.
    final showVehicle = !_isCancelled && _currentStatus == 'OUT_FOR_DELIVERY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_routeAnimation, _pulseAnimation]),
        builder: (context, _) {
          final fill = (progress * _routeAnimation.value).clamp(0.0, 1.0);
          return LayoutBuilder(
            builder: (context, constraints) {
              // Width available for the line between the two end icons
              const iconSpace = 34.0;
              final lineWidth = constraints.maxWidth - (iconSpace * 2);
              return SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // End icons
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.storefront, size: 30, color: AppColors.primary),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        _isPickupFlow ? Icons.emoji_people : Icons.home,
                        size: 30,
                        color: fill >= 1.0 ? AppColors.primary : Colors.grey,
                      ),
                    ),
                    // Base line
                    Positioned(
                      left: iconSpace,
                      right: iconSpace,
                      child: Container(height: 4, color: Colors.grey.shade300),
                    ),
                    // Progress line
                    Positioned(
                      left: iconSpace,
                      child: Container(
                        height: 4,
                        width: lineWidth * fill,
                        color: lineColor,
                      ),
                    ),
                    // Scooter rides the line ONLY while a driver is really
                    // on the road; before that a plain pulsing dot marks
                    // how far the order has progressed.
                    if (showVehicle && fill < 1.0)
                      Positioned(
                        left: iconSpace + (lineWidth * fill) - 14,
                        top: 0,
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Icon(Icons.delivery_dining, size: 26, color: lineColor),
                        ),
                      ),
                    if (!showVehicle && !_isCancelled && fill > 0 && fill < 1.0)
                      Positioned(
                        left: iconSpace + (lineWidth * fill) - 7,
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: lineColor,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                    if (_isCancelled)
                      Positioned(
                        left: iconSpace + (lineWidth * fill) - 12,
                        top: 2,
                        child: const Icon(Icons.cancel, size: 24, color: Colors.red),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = _steps;
    final current = _currentStepIndex(steps);

    return AnimatedBuilder(
      animation: Listenable.merge([_routeAnimation, _pulseAnimation]),
      builder: (context, _) {
        // How far the green fill has progressed, in step units
        final fill = _routeAnimation.value * current;
        final rows = <Widget>[];
        for (var i = 0; i < steps.length; i++) {
          rows.add(_buildStepRow(
            steps[i],
            reached: fill >= i - 0.01 && (i <= current),
            isCurrent: i == current && !_isCancelled,
            isLast: i == steps.length - 1 && !_isCancelled,
            segmentFill: (fill - i).clamp(0.0, 1.0),
          ));
        }
        if (_isCancelled) {
          rows.add(_buildStepRow(
            const _TimelineStep('CANCELLED', 'Cancelled', 'ரத்து செய்யப்பட்டது', Icons.cancel_outlined),
            reached: true,
            isCurrent: false,
            isLast: true,
            segmentFill: 0,
            isCancelledStep: true,
          ));
        }
        return Column(children: rows);
      },
    );
  }

  Widget _buildStepRow(
    _TimelineStep step, {
    required bool reached,
    required bool isCurrent,
    required bool isLast,
    required double segmentFill,
    bool isCancelledStep = false,
  }) {
    final color = isCancelledStep
        ? Colors.red
        : reached
            ? AppColors.primary
            : Colors.grey.shade400;
    final time = _timeFor(step.key);
    final isDone = reached && !isCurrent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Step circle (current step pulses)
                Transform.scale(
                  scale: isCurrent ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached ? color : Colors.white,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(
                      isDone && !isCancelledStep ? Icons.check : step.icon,
                      size: 18,
                      color: reached ? Colors.white : color,
                    ),
                  ),
                ),
                // Connector to the next step (fills with the animation)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: Colors.grey.shade300,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: FractionallySizedBox(
                          heightFactor: segmentFill,
                          child: Container(width: 3, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: reached ? FontWeight.bold : FontWeight.w500,
                      color: isCancelledStep
                          ? Colors.red
                          : reached
                              ? const Color(0xFF1A1A1A)
                              : Colors.grey,
                    ),
                  ),
                  Text(
                    step.labelTamil,
                    style: TextStyle(
                      fontSize: 12,
                      color: reached ? Colors.grey.shade700 : Colors.grey.shade400,
                    ),
                  ),
                  if (time != null && reached)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _fmtTime(time),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  Widget _buildStatusHeader() {
    final status = _currentStatus;
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

  // Map view is parked until the Maps key/billing is sorted; the timeline
  // above replaces it. Kept (with its helpers) to re-enable later.
  // ignore: unused_element
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

  // ignore: unused_element
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
      case 'CONFIRMED':
        return Colors.blue;
      case 'PICKED_UP':
      case 'PREPARING':
        return Colors.orange;
      case 'IN_TRANSIT':
      case 'OUT_FOR_DELIVERY':
      case 'READY_FOR_PICKUP':
        return Colors.purple;
      case 'DELIVERED':
      case 'SELF_PICKUP_COLLECTED':
        return Colors.green;
      case 'CANCELLED':
      case 'REFUNDED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Order Placed';
      case 'ACCEPTED':
      case 'CONFIRMED':
        return 'Order Confirmed';
      case 'PREPARING':
        return 'Preparing Your Order';
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'PICKED_UP':
        return 'Picked Up';
      case 'IN_TRANSIT':
      case 'OUT_FOR_DELIVERY':
        return 'On the Way';
      case 'DELIVERED':
        return 'Delivered';
      case 'SELF_PICKUP_COLLECTED':
        return 'Collected';
      case 'CANCELLED':
        return 'Cancelled';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.receipt_long;
      case 'ACCEPTED':
      case 'CONFIRMED':
        return Icons.check_circle;
      case 'PREPARING':
        return Icons.soup_kitchen_outlined;
      case 'READY_FOR_PICKUP':
        return Icons.inventory_2_outlined;
      case 'PICKED_UP':
        return Icons.local_shipping;
      case 'IN_TRANSIT':
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.done_all;
      case 'SELF_PICKUP_COLLECTED':
        return Icons.storefront;
      case 'CANCELLED':
      case 'REFUNDED':
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

class _TimelineStep {
  final String key;
  final String label;
  final String labelTamil;
  final IconData icon;
  const _TimelineStep(this.key, this.label, this.labelTamil, this.icon);
}