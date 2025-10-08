import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/models/simple_order_model.dart';
import '../../../core/services/api_service.dart';

class SimpleDeliveryCompletionScreen extends StatefulWidget {
  final OrderModel order;

  const SimpleDeliveryCompletionScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<SimpleDeliveryCompletionScreen> createState() => _SimpleDeliveryCompletionScreenState();
}

class _SimpleDeliveryCompletionScreenState extends State<SimpleDeliveryCompletionScreen> {
  bool _isLoading = false;
  bool _paymentCollected = false;

  Future<void> _completeDelivery() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Complete Delivery'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${widget.order.orderNumber}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text('Customer: ${widget.order.customerName}'),
            SizedBox(height: 8),

            // Show payment details if COD
            if (widget.order.paymentMethod == 'CASH_ON_DELIVERY') ...[
              Divider(),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payments, color: Colors.orange[700], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Cash on Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount to Collect:'),
                        Text(
                          '₹${(widget.order.totalAmount ?? 0).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              CheckboxListTile(
                value: _paymentCollected,
                onChanged: (value) {
                  setState(() {
                    _paymentCollected = value ?? false;
                  });
                },
                title: Text('I have collected the payment'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],

            SizedBox(height: 12),
            Text(
              'Confirm that you have handed over the product to the customer?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: (widget.order.paymentMethod == 'CASH_ON_DELIVERY' && !_paymentCollected)
                ? null
                : () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm Delivery'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);

      // Update order status to DELIVERED
      await provider.updateOrderStatus(widget.order.id, 'DELIVERED');

      // If COD and payment collected, mark payment as collected
      if (widget.order.paymentMethod == 'CASH_ON_DELIVERY' && _paymentCollected) {
        try {
          final apiService = ApiService();
          await apiService.post(
            '/mobile/delivery-partner/orders/${widget.order.id}/collect-payment',
            {},
          );
        } catch (e) {
          print('Warning: Failed to mark payment as collected: $e');
          // Continue even if payment marking fails
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Delivery completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to dashboard
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Delivery'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Completing delivery...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Order Details Card
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt, color: Colors.blue, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Order Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 24),

                          _buildInfoRow('Order Number', widget.order.orderNumber ?? 'N/A'),
                          SizedBox(height: 8),
                          _buildInfoRow('Customer', widget.order.customerName),
                          SizedBox(height: 8),
                          _buildInfoRow('Phone', widget.order.customerPhone ?? 'N/A'),
                          SizedBox(height: 8),
                          _buildInfoRow('Address', widget.order.deliveryAddress),
                          SizedBox(height: 8),
                          _buildInfoRow(
                            'Total Amount',
                            '₹${(widget.order.totalAmount ?? 0).toStringAsFixed(0)}',
                            valueColor: Colors.green[700],
                          ),
                          SizedBox(height: 8),
                          _buildInfoRow(
                            'Payment Method',
                            widget.order.paymentMethod == 'CASH_ON_DELIVERY'
                                ? 'Cash on Delivery'
                                : widget.order.paymentMethod ?? 'N/A',
                            valueColor: widget.order.paymentMethod == 'CASH_ON_DELIVERY'
                                ? Colors.orange[700]
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Payment Collection Card (if COD)
                  if (widget.order.paymentMethod == 'CASH_ON_DELIVERY') ...[
                    Card(
                      elevation: 3,
                      color: Colors.orange[50],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payments, color: Colors.orange[700], size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Collect Cash Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[300]!, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Amount to Collect:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '₹${(widget.order.totalAmount ?? 0).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.account_balance_wallet,
                                    size: 48,
                                    color: Colors.orange[300],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16),

                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange[900], size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Please collect this amount from the customer before completing delivery',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Instructions Card
                  Card(
                    elevation: 3,
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.checklist, color: Colors.blue[700], size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Delivery Checklist',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          _buildChecklistItem('✓ Reached customer location'),
                          _buildChecklistItem('✓ Product handed over to customer'),
                          if (widget.order.paymentMethod == 'CASH_ON_DELIVERY')
                            _buildChecklistItem('✓ Cash payment collected'),
                          _buildChecklistItem('✓ Customer satisfied with delivery'),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Complete Delivery Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _completeDelivery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Complete Delivery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue[900],
        ),
      ),
    );
  }
}
