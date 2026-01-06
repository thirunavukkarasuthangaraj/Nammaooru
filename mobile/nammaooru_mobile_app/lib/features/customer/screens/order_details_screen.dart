import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/order_service.dart';
import '../../../core/utils/image_url_helper.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService();
  Order? _order;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _orderService.getOrderById(widget.orderId);
      
      if (mounted) {
        setState(() {
          if (result['success']) {
            _order = result['data'] as Order;
          } else {
            _error = result['message'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load order details';
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null ? 'Order #${_order!.orderNumber}' : 'Order Details'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : _buildOrderDetails(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load order details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Please try again',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrderDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummaryCard(),
          const SizedBox(height: 16),
          if (_order!.canBeTracked) ...[
            _buildTrackingCard(),
            const SizedBox(height: 16),
          ],
          _buildOrderItemsCard(),
          const SizedBox(height: 16),
          _buildDeliveryAddressCard(),
          const SizedBox(height: 16),
          _buildPaymentDetailsCard(),
          const SizedBox(height: 16),
          _buildStatusHistoryCard(),
          if (_order!.canBeCancelled) ...[
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Date:'),
                Text(_formatDate(_order!.orderDate)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:'),
                Text(
                  '₹${_order!.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (_order!.estimatedDeliveryTime != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Delivery:'),
                  Text(_formatDate(_order!.estimatedDeliveryTime!)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (_order!.statusColor) {
      case 'orange':
        backgroundColor = Colors.orange;
        break;
      case 'blue':
        backgroundColor = Colors.blue;
        break;
      case 'purple':
        backgroundColor = Colors.purple;
        break;
      case 'green':
        backgroundColor = Colors.green;
        break;
      case 'red':
        backgroundColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _order!.statusDisplayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTrackingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Tracking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_order!.statusHistory.isNotEmpty) ...[
              ..._order!.statusHistory.asMap().entries.map((entry) {
                final index = entry.key;
                final history = entry.value;
                final isLast = index == _order!.statusHistory.length - 1;
                
                return _buildTrackingStep(
                  history.description,
                  _formatDateTime(history.timestamp),
                  isCompleted: true,
                  isLast: isLast,
                  location: history.location,
                );
              }).toList(),
            ] else ...[
              _buildTrackingStep(
                'Order placed successfully',
                _formatDateTime(_order!.orderDate),
                isCompleted: true,
                isLast: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStep(
    String title,
    String time, {
    required bool isCompleted,
    required bool isLast,
    String? location,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              if (location != null) ...[
                const SizedBox(height: 2),
                Text(
                  location,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_order!.items.map((item) => _buildOrderItem(item)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
              ),
              child: item.productImage.isNotEmpty
                  ? Image.network(
                      ImageUrlHelper.getFullImageUrl(item.productImage),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image, color: Colors.grey.shade400),
                    )
                  : Icon(Icons.shopping_bag, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.shopName.isNotEmpty)
                  Text(
                    'From ${item.shopName}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.unit.isNotEmpty && item.unit != 'piece') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          item.unit,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Qty: ${item.quantity} × ₹${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_order!.deliveryAddress.name} - ${_order!.deliveryAddress.phone}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(_order!.deliveryAddress.fullAddress),
            if (_order!.deliveryInstructions?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Instructions: ${_order!.deliveryInstructions}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Method:'),
                Text(_order!.paymentMethod.replaceAll('_', ' ')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Status:'),
                Text(
                  _order!.paymentStatus,
                  style: TextStyle(
                    color: _order!.paymentStatus == 'PAID' 
                        ? Colors.green 
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text('₹${_order!.totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee:'),
                Text('₹0.00'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${_order!.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistoryCard() {
    if (_order!.statusHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_order!.statusHistory.reversed.map((history) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      history.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    _formatDateTime(history.timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCancelDialog(),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _reorderItems(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reorder Items'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    // Server sends UTC time, convert to IST (UTC+5:30)
    final istDate = date.add(const Duration(hours: 5, minutes: 30));
    return '${istDate.day}/${istDate.month}/${istDate.year}';
  }

  String _formatDateTime(DateTime date) {
    // Server sends UTC time, convert to IST (UTC+5:30)
    final istDate = date.add(const Duration(hours: 5, minutes: 30));
    final hour = istDate.hour > 12 ? istDate.hour - 12 : istDate.hour;
    final period = istDate.hour >= 12 ? 'PM' : 'AM';
    return '${istDate.day}/${istDate.month}/${istDate.year} ${hour == 0 ? 12 : hour}:${istDate.minute.toString().padLeft(2, '0')} $period';
  }

  void _showCancelDialog() {
    String? selectedReason;
    String? customReason;

    final predefinedReasons = [
      'Changed my mind',
      'Found better price elsewhere',
      'Product no longer needed',
      'Delivery time too long',
      'Wrong product selected',
      'Other (please specify)',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cancel Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to cancel order #${_order!.orderNumber}?'),
                const SizedBox(height: 16),
                const Text(
                  'Reason for cancellation:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...predefinedReasons.map((reason) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(reason),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                          if (value != 'Other (please specify)') {
                            customReason = null;
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
                if (selectedReason == 'Other (please specify)') ...[
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Please specify reason',
                      hintText: 'Why are you cancelling this order?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => customReason = value,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Order'),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      final reason = selectedReason == 'Other (please specify)'
                          ? customReason ?? ''
                          : selectedReason ?? '';
                      Navigator.pop(context);
                      _cancelOrder(reason);
                    },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder(String reason) async {
    try {
      final result = await _orderService.cancelOrder(_order!.id, reason);
      
      if (result['success']) {
        _showSnackBar('Order cancelled successfully', Colors.orange);
        _loadOrderDetails(); // Reload to get updated status
      } else {
        _showSnackBar(result['message'] ?? 'Failed to cancel order', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to cancel order', Colors.red);
    }
  }

  Future<void> _reorderItems() async {
    try {
      final result = await _orderService.reorderItems(_order!.id);

      if (result['success']) {
        _showSnackBar('Items added to cart', Colors.green);
        // Navigate to cart after adding items
        if (mounted) {
          context.push('/customer/cart');
        }
      } else {
        _showSnackBar(result['message'] ?? 'Failed to add items to cart', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to add items to cart', Colors.red);
    }
  }
}