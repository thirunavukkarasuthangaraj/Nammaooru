import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/models/simple_order_model.dart';
import '../widgets/order_details_bottom_sheet.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  void _loadOrderHistory() {
    final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
    provider.loadOrderHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadOrderHistory(),
        child: Consumer<DeliveryPartnerProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2196F3)),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${provider.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadOrderHistory,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (provider.orderHistory.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Order History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your completed orders will appear here',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.orderHistory.length,
              itemBuilder: (context, index) {
                final order = provider.orderHistory[index];
                return _buildOrderCard(order);
              },
            );
          },
        ),
      ),
    );
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsBottomSheet(
        order: order,
        showActions: false,
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer Info
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(order.customerName),
                ],
              ),
              if (order.customerPhone != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(order.customerPhone!),
                  ],
                ),
              ],
              const SizedBox(height: 8),

              // Shop Info
              Row(
                children: [
                  const Icon(Icons.store, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(order.shopName),
                ],
              ),
              const SizedBox(height: 8),

              // Delivery Address
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(order.deliveryAddress)),
                ],
              ),
              const SizedBox(height: 12),

              // Order Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.totalAmount != null)
                        Text(
                          'Order Value: ₹${order.totalAmount!.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      Text(
                        'Your Earnings: ₹${(order.commission ?? order.deliveryFee ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (order.createdAt != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(order.createdAt!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          DateFormat('hh:mm a').format(order.createdAt!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Distance if available
              if (order.distance != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.directions, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Distance: ${order.distance!.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'picked_up':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}