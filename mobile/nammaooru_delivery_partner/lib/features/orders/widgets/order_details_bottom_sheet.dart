import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/simple_order_model.dart';

class OrderDetailsBottomSheet extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onPickup;
  final VoidCallback? onDeliver;
  final VoidCallback? onCall;
  final bool showActions;

  const OrderDetailsBottomSheet({
    Key? key,
    required this.order,
    this.onAccept,
    this.onReject,
    this.onPickup,
    this.onDeliver,
    this.onCall,
    this.showActions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Order Details',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
                    order.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Order info
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID and time
                  _buildInfoRow(
                    'Order ID',
                    '#${order.id}',
                    Icons.receipt_long,
                  ),

                  _buildInfoRow(
                    'Order Time',
                    _formatDateTime(order.createdAt),
                    Icons.access_time,
                  ),

                  const Divider(height: 32),

                  // Customer details
                  Text(
                    'Customer Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    'Name',
                    order.customerName,
                    Icons.person,
                  ),

                  if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                    _buildInfoRow(
                      'Phone',
                      order.customerPhone!,
                      Icons.phone,
                      trailing: onCall != null
                          ? IconButton(
                              icon: const Icon(Icons.call, color: Color(0xFF4CAF50)),
                              onPressed: onCall,
                            )
                          : null,
                    ),

                  const Divider(height: 32),

                  // Shop details
                  Text(
                    'Shop Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    'Shop Name',
                    order.shopName,
                    Icons.store,
                  ),

                  const Divider(height: 32),

                  // Delivery details
                  Text(
                    'Delivery Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    'Delivery Address',
                    order.deliveryAddress,
                    Icons.location_on,
                    maxLines: 3,
                  ),

                  if (order.distance != null)
                    _buildInfoRow(
                      'Distance',
                      '${order.distance!.toStringAsFixed(1)} km',
                      Icons.directions,
                    ),

                  const Divider(height: 32),

                  // Earnings details
                  Text(
                    'Earnings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.currency_rupee, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${order.commission?.toStringAsFixed(0) ?? order.deliveryFee?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Your Earnings',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action buttons
          if (showActions || onAccept != null || onReject != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: _buildActionButtons(context),
            ),
          ] else ...[
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Widget? trailing,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (onAccept != null && onReject != null) {
      // Available order actions
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Accept Order'),
            ),
          ),
        ],
      );
    } else if (showActions) {
      // Active order actions
      return Column(
        children: [
          if (onCall != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone),
                label: const Text('Call Customer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          if (onCall != null && (onPickup != null || onDeliver != null))
            const SizedBox(height: 12),

          if (onPickup != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPickup,
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
            ),

          if (onDeliver != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDeliver,
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
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'picked_up':
        return Colors.teal;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM dd, yyyy \'at\' HH:mm').format(dateTime);
  }
}