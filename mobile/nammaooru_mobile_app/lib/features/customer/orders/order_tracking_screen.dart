import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderNumber;

  const OrderTrackingScreen({
    super.key,
    required this.orderNumber,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  bool _isLoading = true;
  
  // Order Status
  String _currentStatus = 'CONFIRMED';
  Map<String, dynamic>? _orderDetails;
  Map<String, dynamic>? _deliveryPartner;
  
  // Map Data
  final LatLng _shopLocation = const LatLng(13.0827, 80.2707);
  final LatLng _customerLocation = const LatLng(13.0867, 80.2750);
  LatLng _deliveryLocation = const LatLng(13.0827, 80.2707);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final List<Map<String, dynamic>> _orderStatuses = [
    {
      'status': 'PLACED',
      'title': 'Order Placed',
      'subtitle': 'Your order has been confirmed',
      'icon': Icons.receipt_long,
      'time': '2:30 PM',
      'isCompleted': true,
    },
    {
      'status': 'CONFIRMED',
      'title': 'Order Confirmed',
      'subtitle': 'Shop has accepted your order',
      'icon': Icons.check_circle,
      'time': '2:35 PM',
      'isCompleted': true,
    },
    {
      'status': 'PREPARING',
      'title': 'Preparing Order',
      'subtitle': 'Your order is being prepared',
      'icon': Icons.restaurant,
      'time': '2:45 PM',
      'isCompleted': true,
    },
    {
      'status': 'READY_FOR_PICKUP',
      'title': 'Ready for Pickup',
      'subtitle': 'Order is packed and ready',
      'icon': Icons.inventory,
      'time': '3:15 PM',
      'isCompleted': false,
    },
    {
      'status': 'OUT_FOR_DELIVERY',
      'title': 'Out for Delivery',
      'subtitle': 'Delivery partner is on the way',
      'icon': Icons.delivery_dining,
      'time': '',
      'isCompleted': false,
    },
    {
      'status': 'DELIVERED',
      'title': 'Delivered',
      'subtitle': 'Order delivered successfully',
      'icon': Icons.done_all,
      'time': '',
      'isCompleted': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrderDetails();
    _setupMap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement API call to fetch order details
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      _orderDetails = {
        'orderNumber': widget.orderNumber,
        'status': 'PREPARING',
        'total': 245.50,
        'items': [
          {'name': 'Fresh Tomatoes', 'quantity': 2, 'price': 50.0},
          {'name': 'Basmati Rice', 'quantity': 1, 'price': 120.0},
          {'name': 'Milk', 'quantity': 1, 'price': 45.0},
        ],
        'shopName': 'Fresh Mart',
        'shopPhone': '+91 98765 43210',
        'deliveryAddress': 'Home - 123, Main Street, Chennai - 600001',
        'estimatedDeliveryTime': '3:30 PM',
        'paymentMethod': 'Cash on Delivery',
      };

      _deliveryPartner = {
        'name': 'Ravi Kumar',
        'phone': '+91 98765 43211',
        'vehicleNumber': 'TN 01 AB 1234',
        'rating': 4.8,
        'currentLocation': const LatLng(13.0845, 80.2728),
      };
      
      _currentStatus = _orderDetails!['status'];
      
      if (_deliveryPartner != null) {
        _deliveryLocation = _deliveryPartner!['currentLocation'];
      }
      
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load order details', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupMap() {
    _markers.addAll([
      Marker(
        markerId: const MarkerId('shop'),
        position: _shopLocation,
        infoWindow: InfoWindow(
          title: _orderDetails?['shopName'] ?? 'Shop',
          snippet: 'Order pickup location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: _customerLocation,
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Delivery destination',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: _deliveryLocation,
        infoWindow: InfoWindow(
          title: _deliveryPartner?['name'] ?? 'Delivery Partner',
          snippet: 'Current location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    ]);

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_shopLocation, _deliveryLocation, _customerLocation],
        color: AppColors.primary,
        width: 3,
        patterns: [PatternItem.dash(20), PatternItem.gap(20)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Track Order',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: _isLoading 
          ? const LoadingWidget()
          : Column(
              children: [
                _buildOrderStatusHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStatusTab(),
                      _buildMapTab(),
                    ],
                  ),
                ),
                if (_shouldShowDeliveryPartnerInfo()) _buildDeliveryPartnerBar(),
              ],
            ),
    );
  }

  Widget _buildOrderStatusHeader() {
    final currentStatusData = _orderStatuses.firstWhere(
      (status) => status['status'] == _currentStatus,
      orElse: () => _orderStatuses.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withOpacity(0.05),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentStatusData['icon'],
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStatusData['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      currentStatusData['subtitle'],
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_orderDetails != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.orderNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'ETA: ${_orderDetails!['estimatedDeliveryTime']}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _getProgressValue(),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(
            icon: Icon(Icons.list_alt),
            text: 'Order Status',
          ),
          Tab(
            icon: Icon(Icons.map),
            text: 'Live Map',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Timeline
          const Text(
            'Order Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orderStatuses.length,
            itemBuilder: (context, index) {
              return _buildStatusTimelineItem(_orderStatuses[index], index);
            },
          ),
          const SizedBox(height: 24),
          
          // Order Details
          if (_orderDetails != null) ...[
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOrderDetailsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTimelineItem(Map<String, dynamic> statusData, int index) {
    final isActive = statusData['status'] == _currentStatus;
    final isCompleted = statusData['isCompleted'] || 
        _getStatusIndex(_currentStatus) > index;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted || isActive 
                    ? AppColors.primary 
                    : Colors.grey.shade300,
              ),
              child: Icon(
                isCompleted ? Icons.check : statusData['icon'],
                color: isCompleted || isActive ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
            if (index < _orderStatuses.length - 1)
              Container(
                width: 2,
                height: 40,
                color: isCompleted 
                    ? AppColors.primary 
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusData['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  statusData['subtitle'],
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (statusData['time'].isNotEmpty)
                  Text(
                    statusData['time'],
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _orderDetails!['shopName'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {
                    // TODO: Make call to shop
                  },
                ),
              ],
            ),
            const Divider(),
            
            // Order Items
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...(_orderDetails!['items'] as List).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item['quantity']}x ${item['name']}'),
                  ),
                  Text(Helpers.formatCurrency(item['price'])),
                ],
              ),
            )).toList(),
            const Divider(),
            
            Row(
              children: [
                const Text('Total: '),
                const Spacer(),
                Text(
                  Helpers.formatCurrency(_orderDetails!['total']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _orderDetails!['deliveryAddress'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            Row(
              children: [
                const Icon(Icons.payment, size: 16),
                const SizedBox(width: 4),
                Text(
                  _orderDetails!['paymentMethod'],
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _shopLocation,
        zoom: 14.0,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  Widget _buildDeliveryPartnerBar() {
    if (_deliveryPartner == null) return const SizedBox.shrink();
    
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
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _deliveryPartner!['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${_deliveryPartner!['rating']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _deliveryPartner!['vehicleNumber'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                // TODO: Make call to delivery partner
              },
            ),
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                // TODO: Send message to delivery partner
              },
            ),
          ],
        ),
      ),
    );
  }

  double _getProgressValue() {
    final currentIndex = _getStatusIndex(_currentStatus);
    return (currentIndex + 1) / _orderStatuses.length;
  }

  int _getStatusIndex(String status) {
    return _orderStatuses.indexWhere((s) => s['status'] == status);
  }

  bool _shouldShowDeliveryPartnerInfo() {
    return _currentStatus == 'OUT_FOR_DELIVERY' && _deliveryPartner != null;
  }
}