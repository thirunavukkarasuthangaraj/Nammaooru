import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/models/simple_order_model.dart';
import '../widgets/order_card.dart';
import '../widgets/order_details_bottom_sheet.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({Key? key}) : super(key: key);

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  void _loadActiveOrders() {
    final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
    provider.loadCurrentOrders();
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsBottomSheet(
        order: order,
        showActions: true,
        onPickup: order.status == 'accepted' ? () => _markAsPickedUp(order) : null,
        onDeliver: order.status == 'picked_up' || order.status == 'in_transit' ? () => _markAsDelivered(order) : null,
        onCall: () => _callCustomer(order.customerPhone),
      ),
    );
  }

  void _markAsPickedUp(OrderModel order) async {
    final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);

    try {
      await provider.updateOrderStatus(order.id, 'picked_up');
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.id} marked as picked up!'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      _loadActiveOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markAsDelivered(OrderModel order) async {
    final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);

    try {
      await provider.updateOrderStatus(order.id, 'delivered');
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.id} delivered successfully! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _loadActiveOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark as delivered: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _callCustomer(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to make call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startNavigation(OrderModel order) {
    // TODO: Implement navigation to customer location
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Active Orders',
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
            onPressed: _loadActiveOrders,
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
                    'Loading active orders...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final activeOrders = provider.currentOrders;

          if (activeOrders.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadActiveOrders();
            },
            child: Column(
              children: [
                // Summary header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${activeOrders.length} Active Deliveries',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tap to update status or contact customer',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Orders list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeOrders.length,
                    itemBuilder: (context, index) {
                      final order = activeOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildActiveOrderCard(order),
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

  Widget _buildActiveOrderCard(OrderModel order) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order ID and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Customer info
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: Color(0xFF4CAF50), size: 20),
                      onPressed: () => _callCustomer(order.customerPhone),
                      tooltip: 'Call Customer',
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Delivery address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigation, color: Color(0xFF2196F3), size: 20),
                    onPressed: () => _startNavigation(order),
                    tooltip: 'Navigate',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons based on status
              _buildActionButtons(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    switch (order.status.toLowerCase()) {
      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markAsPickedUp(order),
            icon: const Icon(Icons.inventory),
            label: const Text('Mark as Picked Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );

      case 'picked_up':
      case 'in_transit':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markAsDelivered(order),
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Active Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You don\'t have any active deliveries.\nCheck available orders to start earning!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/available-orders'),
            icon: const Icon(Icons.assignment),
            label: const Text('View Available Orders'),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue;
      case 'picked_up':
        return Colors.teal;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green[700]!;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'READY FOR PICKUP';
      case 'picked_up':
        return 'PICKED UP';
      case 'in_transit':
        return 'IN TRANSIT';
      case 'delivered':
        return 'DELIVERED';
      default:
        return status.toUpperCase();
    }
  }
}