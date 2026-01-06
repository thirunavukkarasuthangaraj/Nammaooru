import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/simple_order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final bool showAcceptReject;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool showStatus;

  const OrderCard({
    Key? key,
    required this.order,
    this.onTap,
    this.showAcceptReject = false,
    this.onAccept,
    this.onReject,
    this.showStatus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getStatusGradientColors()[0], _getStatusGradientColors()[1]],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Order number
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${order.orderNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Shop name
                  Expanded(
                    child: Text(
                      order.shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status badge
                  if (showStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          color: _getStatusGradientColors()[0],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person, color: Colors.blue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (order.customerPhone != null)
                              Text(
                                order.customerPhone!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Time
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatTime(order.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Delivery address
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            order.deliveryAddress,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Order stats row
                  Row(
                    children: [
                      // Distance
                      _buildStatChip(
                        icon: Icons.route,
                        value: '${order.distance?.toStringAsFixed(1) ?? 'N/A'} km',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      // Earnings
                      _buildStatChip(
                        icon: Icons.currency_rupee,
                        value: '${order.commission?.toStringAsFixed(0) ?? order.deliveryFee?.toStringAsFixed(0) ?? '30'}',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      // Total amount
                      _buildStatChip(
                        icon: Icons.shopping_bag,
                        value: '₹${order.totalAmount?.toStringAsFixed(0) ?? '0'}',
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  // Accept/Reject buttons
                  if (showAcceptReject) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Reject button
                        SizedBox(
                          width: 100,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: onReject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[600],
                              side: BorderSide(color: Colors.red[400]!, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Accept button
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: onAccept,
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text(
                                'Accept Order',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getStatusGradientColors() {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return [const Color(0xFFFF9800), const Color(0xFFFF5722)];
      case 'assigned':
        return [const Color(0xFF2196F3), const Color(0xFF1976D2)];
      case 'accepted':
        return [const Color(0xFF4CAF50), const Color(0xFF388E3C)];
      case 'picked_up':
        return [const Color(0xFF009688), const Color(0xFF00796B)];
      case 'in_transit':
        return [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)];
      case 'delivered':
        return [const Color(0xFF43A047), const Color(0xFF2E7D32)];
      case 'cancelled':
      case 'returning_to_shop':
      case 'returned_to_shop':
        return [const Color(0xFF2196F3), const Color(0xFF1976D2)]; // Same blue color
      default:
        return [const Color(0xFF757575), const Color(0xFF616161)];
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'NEW';
      case 'accepted':
        return 'ACCEPTED';
      case 'picked_up':
        return 'PICKED UP';
      case 'in_transit':
        return 'IN TRANSIT';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
