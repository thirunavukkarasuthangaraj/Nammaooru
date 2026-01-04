import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/models/simple_order_model.dart';
import '../widgets/order_card.dart';
import '../widgets/order_details_bottom_sheet.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  @override
  void initState() {
    super.initState();
    // Load orders after build completes to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableOrders();
    });
  }

  void _loadAvailableOrders() {
    final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
    provider.loadAvailableOrders();
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsBottomSheet(
        order: order,
        onAccept: () => _acceptOrder(order),
        onReject: () => _rejectOrder(order),
      ),
    );
  }

  void _acceptOrder(OrderModel order) async {
    final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    try {
      // Use orderNumber for the API call (backend expects order number, not assignment ID)
      final response = await provider.acceptOrder(order.orderNumber);

      if (response?['success'] == true) {
        final assignmentId = response?['assignmentId'];

        // Start location tracking immediately when order is accepted
        if (provider.currentPartner != null && assignmentId != null) {
          // Update location tracking context with assignmentId from response
          locationProvider.updateOrderContext(
            assignmentId: assignmentId,
            orderStatus: 'accepted',
          );

          // Start location tracking if not already active
          if (!locationProvider.isLocationTrackingActive) {
            await locationProvider.startLocationTracking(
              partnerId: provider.currentPartner!.partnerId,
              assignmentId: assignmentId,
              orderStatus: 'accepted',
            );
          }
        }

        Navigator.pop(context); // Close bottom sheet

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.orderNumber} accepted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to Active Orders screen to show the accepted order
        Navigator.pushReplacementNamed(context, '/active-orders');

        _loadAvailableOrders(); // Refresh the list
      } else {
        // Show actual error message from backend
        final errorMsg = response?['message'] ?? 'Failed to accept order';
        throw Exception(errorMsg);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejectOrder(OrderModel order) async {
    final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);

    try {
      // Use orderNumber for the API call (backend expects order number, not assignment ID)
      final success = await provider.rejectOrder(order.orderNumber, 'Not available');

      if (success) {
        Navigator.pop(context); // Close bottom sheet

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.orderNumber} rejected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        _loadAvailableOrders(); // Refresh the list
      } else {
        // Show actual error from provider
        final errorMsg = provider.error ?? 'Failed to reject order';
        throw Exception(errorMsg);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAvailableOrders,
          ),
        ],
      ),
      body: Consumer<DeliveryPartnerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF2196F3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading available orders...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final availableOrders = provider.availableOrders;

          if (availableOrders.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadAvailableOrders();
            },
            child: Column(
              children: [
                // Summary header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${availableOrders.length} Orders Available',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tap on any order to view details',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Orders list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: availableOrders.length,
                    itemBuilder: (context, index) {
                      final order = availableOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OrderCard(
                          order: order,
                          onTap: () => _showOrderDetails(order),
                          showAcceptReject: true,
                          onAccept: () => _acceptOrder(order),
                          onReject: () => _rejectOrder(order),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Orders Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'New delivery orders will appear here.\nPull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadAvailableOrders,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}