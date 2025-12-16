import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/pickup_otp_dialog.dart';
import '../../widgets/verify_pickup_otp_dialog.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic>? orderData;

  const OrderDetailsScreen({super.key, required this.orderId, this.orderData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #$orderId'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: orderData != null
        ? _buildOrderDetails(context, orderData!)
        : Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final order = orderProvider.orders.firstWhere(
            (o) => o.id == orderId,
            orElse: () => Order(
              id: orderId,
              customerId: '',
              customerName: 'Unknown',
              customerPhone: '',
              items: [],
              subtotal: 0,
              tax: 0,
              deliveryFee: 0,
              discount: 0,
              total: 0,
              totalAmount: 0,
              status: 'PENDING',
              paymentStatus: 'PENDING',
              paymentMethod: 'CASH_ON_DELIVERY',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              address: '',
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(order),
                const SizedBox(height: 24),
                _buildCustomerInfo(order),
                const SizedBox(height: 24),
                _buildOrderItems(order),
                const SizedBox(height: 24),
                _buildOrderSummary(order),
                const SizedBox(height: 24),
                _buildOrderActions(context, order, orderProvider),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, Map<String, dynamic> orderData) {
    final items = orderData['items'] as List? ?? [];
    final subtotal = (orderData['subtotal'] ?? orderData['totalAmount'] ?? 0).toDouble();
    final deliveryFee = (orderData['deliveryFee'] ?? 0).toDouble();
    final total = (orderData['totalAmount'] ?? orderData['total'] ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header Card
          Card(
            margin: const EdgeInsets.only(bottom: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${orderData['orderNumber']}',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Placed on ${orderData['createdAt'] ?? ''}', style: AppTextStyles.caption),
                      _buildStatusChipFromString(orderData['status'] ?? 'PENDING'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Customer Info Card
          Card(
            margin: const EdgeInsets.only(bottom: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer Information', style: AppTextStyles.heading3),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.person, 'Name', orderData['customerName'] ?? 'Unknown'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.phone, 'Phone', orderData['customerPhone'] ?? 'Not provided', isPhone: true),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on, 'Address', orderData['address'] ?? 'Not provided'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Order Items Card
          Card(
            margin: const EdgeInsets.only(bottom: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Items', style: AppTextStyles.heading3),
                  const SizedBox(height: 16),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (item['productImageUrl'] ?? '').isNotEmpty
                              ? Image.network(
                                  'http://localhost:8080${item['productImageUrl']}',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 60,
                                    height: 60,
                                    color: AppColors.primary.withOpacity(0.1),
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['productName'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Qty: ${item['quantity']} × ₹${item['unitPrice']}', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        Text('₹${item['totalPrice'] ?? 0}', style: AppTextStyles.heading3),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Order Summary Card
          Card(
            margin: const EdgeInsets.only(bottom: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Summary', style: AppTextStyles.heading3),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  _buildSummaryRow('Total', '₹${total.toStringAsFixed(2)}', isTotal: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24), // Add spacing at the bottom
        ],
      ),
    );
  }

  Widget _buildStatusChipFromString(String status) {
    Color color;
    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'CONFIRMED':
        color = Colors.blue;
        break;
      case 'PREPARING':
        color = Colors.purple;
        break;
      case 'READY':
      case 'READY_FOR_PICKUP':
        color = Colors.green;
        break;
      case 'OUT_FOR_DELIVERY':
        color = Colors.indigo;
        break;
      case 'DELIVERED':
        color = Colors.green;
        break;
      case 'CANCELLED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal ? AppTextStyles.heading3 : AppTextStyles.body,
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.heading3.copyWith(color: AppColors.primary)
              : AppTextStyles.body,
        ),
      ],
    );
  }

  Widget _buildOrderHeader(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Placed on ${_formatDate(order.orderDate ?? order.createdAt)}',
                      style: AppTextStyles.caption,
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
              ],
            ),
            if (order.estimatedDelivery != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Estimated Delivery: ${_formatDate(order.estimatedDelivery!)}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Name', order.customerName),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Phone', order.customerPhone ?? 'Not provided', isPhone: true),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Address', order.address ?? 'Not provided'),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.note, 'Notes', order.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isPhone = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              isPhone
                  ? GestureDetector(
                      onTap: () => _makePhoneCall(value),
                      child: Text(
                        value,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(value, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            ...order.items.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.productImage != null && item.productImage!.isNotEmpty
                ? Image.network(
                    item.productImage!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 60,
                        height: 60,
                        color: AppColors.primary.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag, size: 30, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity} × ₹${item.price.toStringAsFixed(2)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            '₹${(item.quantity * item.price).toStringAsFixed(2)}',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    final subtotal = order.totalAmount;
    final deliveryFee = 30.0;
    final total = subtotal + deliveryFee;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildSummaryRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Total',
              '₹${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActions(BuildContext context, Order order, OrderProvider orderProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            // Debug info - remove after testing
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Debug Info:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('Status: ${order.status}', style: TextStyle(fontSize: 10)),
                  Text('Delivery Type: ${order.deliveryType ?? "null"}', style: TextStyle(fontSize: 10)),
                  Text('Is Self Pickup: ${order.isSelfPickup}', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Debug: Show current order status and delivery type
            if (order.status == 'PENDING') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(context, order, orderProvider),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectOrder(context, order, orderProvider),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (order.status == 'CONFIRMED') ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsPacked(context, order, orderProvider),
                      icon: const Icon(Icons.inventory_2),
                      label: const Text('Mark as Packed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, order, orderProvider),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (order.status == 'PREPARING') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, order, orderProvider),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (order.status == 'READY_FOR_PICKUP') ...[
              if (order.deliveryType == 'SELF_PICKUP') ...[
                // Self-pickup handover button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handoverSelfPickup(context, order, orderProvider),
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('Handover to Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ] else if (order.assignedToDeliveryPartner == true) ...[
                // Delivery pickup OTP verification button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyPickupOTP(context, order, orderProvider),
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Verify Pickup OTP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: order.customerPhone != null ? () => _makePhoneCall(order.customerPhone!) : null,
                icon: const Icon(Icons.phone),
                label: const Text('Call Customer'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toUpperCase()) {
      case 'PENDING':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        label = 'Pending';
        break;
      case 'CONFIRMED':
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        label = 'Confirmed';
        break;
      case 'PREPARING':
        backgroundColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        label = 'Preparing';
        break;
      case 'READY_FOR_PICKUP':
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        label = 'Ready for Pickup';
        break;
      case 'OUTFORDELIVERY':
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        label = 'Out for Delivery';
        break;
      case 'DELIVERED':
        backgroundColor = AppColors.success.withOpacity(0.2);
        textColor = AppColors.success;
        label = 'Delivered';
        break;
      case 'CANCELLED':
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        label = 'Cancelled';
        break;
      case 'SELF_PICKUP_COLLECTED':
        backgroundColor = AppColors.success.withOpacity(0.2);
        textColor = AppColors.success;
        label = 'Collected';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        label = status;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _acceptOrder(BuildContext context, Order order, OrderProvider orderProvider) async {
    final success = await orderProvider.updateOrderStatus(order.id, 'CONFIRMED');
    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showCancelDialog(BuildContext context, Order order, OrderProvider orderProvider) {
    String? selectedReason;
    String? customReason;
    final predefinedReasons = [
      'Item out of stock',
      'Customer request',
      'Damaged items',
      'Wrong items packed',
      'Unable to prepare on time',
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
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text('Why are you cancelling this order?'),
                const SizedBox(height: 12),
                // Predefined reasons with radio buttons
                ...predefinedReasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                        customReason = null;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }).toList(),
                // Custom reason text field (show only if "Other" is selected)
                if (selectedReason == 'Other (please specify)') ...[
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Please specify the reason',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        customReason = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: (selectedReason == null ||
                      (selectedReason == 'Other (please specify)' && (customReason?.isEmpty ?? true)))
                  ? null
                  : () {
                      Navigator.pop(context);
                      _cancelOrder(
                        context,
                        order,
                        orderProvider,
                        selectedReason ?? '',
                        customReason,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text('Confirm Cancellation'),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelOrder(BuildContext context, Order order, OrderProvider orderProvider, String reason, String? customReason) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Prepare the cancellation reason
      final cancellationReason = reason == 'Other (please specify)' ? customReason ?? reason : reason;

      // Call API to cancel order
      final response = await ApiService.cancelOrder(order.id, cancellationReason);

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (response.success && context.mounted) {
        // Refresh the order data
        await orderProvider.loadOrders();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Order cancelled successfully'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back to orders list
        Navigator.pop(context);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: ${response.error ?? "Unknown error"}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _rejectOrder(BuildContext context, Order order, OrderProvider orderProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('Are you sure you want to reject this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await orderProvider.updateOrderStatus(order.id, 'CANCELLED');
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order rejected'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              'Reject',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _markAsPacked(BuildContext context, Order order, OrderProvider orderProvider) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Directly mark the order as ready for pickup (skip PREPARING status)
    final success = await orderProvider.updateOrderStatus(order.id, 'READY_FOR_PICKUP');

    // Close loading dialog
    if (context.mounted) Navigator.pop(context);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Order marked as packed and ready for pickup'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      // For home delivery orders, auto-assign to delivery partner
      if (order.deliveryType != 'SELF_PICKUP') {
        // Show loading dialog for assignment
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          // Get current user ID from storage
          final userJson = await StorageService.getUser();
          final userId = userJson?['userId']?.toString() ?? userJson?['id']?.toString() ?? '1';

          // Auto-assign the order to an available delivery partner
          final assignResponse = await ApiService.autoAssignOrder(order.id, userId);

          // Close loading dialog
          if (context.mounted) Navigator.pop(context);

          if (assignResponse.success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Order assigned to delivery partner'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );

            // Generate pickup OTP for delivery partner
            final otpResponse = await ApiService.generatePickupOTP(order.id);

            if (otpResponse.success && context.mounted) {
              final String otp = otpResponse.data['otp']?.toString() ?? '';

              // Show OTP dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => PickupOTPDialog(
                  otp: otp,
                  orderId: order.id,
                ),
              );
            }

            // Refresh orders to get updated assignment status
            await orderProvider.loadOrders();
          } else if (context.mounted) {
            // Assignment failed, but order is still READY_FOR_PICKUP
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ ${assignResponse.error ?? "Could not assign delivery partner. Please assign manually."}'),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          // Close loading dialog
          if (context.mounted) Navigator.pop(context);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Error assigning delivery partner: ${e.toString()}'),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }
  }

  void _verifyPickupOTP(BuildContext context, Order order, OrderProvider orderProvider) async {
    // Show the verify OTP dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerifyPickupOTPDialog(
        orderId: order.id,
        onVerify: (String otp) async {
          // Call API to verify OTP
          final response = await ApiService.verifyPickupOTP(order.id, otp);

          if (response.success) {
            return; // Success - dialog will close
          } else {
            throw Exception(response.error ?? 'Invalid OTP');
          }
        },
      ),
    );

    // If OTP was verified successfully
    if (result == true && context.mounted) {
      // Refresh the order data
      await orderProvider.loadOrders();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Order handed over to delivery partner successfully'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to orders list
      Navigator.pop(context);
    }
  }

  void _handoverSelfPickup(BuildContext context, Order order, OrderProvider orderProvider) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Handover'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you ready to handover this order to the customer?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Customer: ${order.customerName}'),
                  const SizedBox(height: 4),
                  Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
                  if (order.paymentMethod == 'CASH_ON_DELIVERY') ...[
                    const SizedBox(height: 8),
                    const Text(
                      '💰 Collect payment from customer',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Handover'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Call API to mark order as handed over
        final response = await ApiService.handoverSelfPickup(order.id);

        // Close loading dialog
        if (context.mounted) Navigator.pop(context);

        if (response.success && context.mounted) {
          // Refresh the order data
          await orderProvider.loadOrders();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Order handed over successfully!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate back to orders list
          Navigator.pop(context);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to handover order: ${response.error ?? "Unknown error"}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (context.mounted) Navigator.pop(context);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}