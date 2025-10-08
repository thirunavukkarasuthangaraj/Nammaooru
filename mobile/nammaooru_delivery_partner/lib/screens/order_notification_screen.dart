import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/order_provider.dart';
import '../core/services/api_service.dart';

class OrderNotificationScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderNotificationScreen({
    Key? key,
    required this.orderData,
  }) : super(key: key);

  @override
  State<OrderNotificationScreen> createState() => _OrderNotificationScreenState();
}

class _OrderNotificationScreenState extends State<OrderNotificationScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final orderNumber = widget.orderData['orderNumber'] ?? 'N/A';
    final shopName = widget.orderData['shopName'] ?? 'Unknown Shop';
    final deliveryAddress = widget.orderData['deliveryAddress'] ?? 'No address';
    final totalAmount = widget.orderData['totalAmount'] ?? '0';

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button - force user to accept or reject
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Notification Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                // Title
                const Text(
                  'New Order Available!',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Order Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Number
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Order #$orderNumber',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Shop Name
                      Row(
                        children: [
                          const Icon(Icons.store, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Delivery Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deliveryAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Total Amount
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '₹$totalAmount',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Action Buttons
                if (_isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  )
                else
                  Row(
                    children: [
                      // Reject Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleReject(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'REJECT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Accept Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleAccept(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'ACCEPT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Auto reject timer (optional)
                Text(
                  'This order will be auto-rejected in 30 seconds if no action is taken',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orderNumber = widget.orderData['orderNumber'];
      final apiService = ApiService();

      final response = await apiService.acceptOrder(orderNumber);

      if (response['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order accepted successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to order details or back to dashboard
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        throw Exception(response['message'] ?? 'Failed to accept order');
      }
    } catch (e) {
      print('Error accepting order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept order: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orderNumber = widget.orderData['orderNumber'];
      final apiService = ApiService();

      final response = await apiService.rejectOrder(orderNumber, reason: 'Driver not available');

      if (response['success'] == true) {
        // Show message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        // Go back to dashboard
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        throw Exception(response['message'] ?? 'Failed to reject order');
      }
    } catch (e) {
      print('Error rejecting order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject order: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}