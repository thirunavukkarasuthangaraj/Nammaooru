import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import 'order_tracking_screen.dart';
import '../dashboard/customer_dashboard.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderNumber;
  final Map<String, dynamic> orderData;

  const OrderConfirmationScreen({
    super.key,
    required this.orderNumber,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Animation
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 60,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Success Message
                    const Text(
                      'Order Placed Successfully! 🎉',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    const Text(
                      'Your order has been confirmed and will be prepared soon.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Order Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Number',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    orderNumber,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Estimated Delivery: ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _getEstimatedDeliveryTime(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              const Icon(
                                Icons.payments,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Payment: ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                orderData['paymentMethod'] ?? 'Cash on Delivery',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              const Icon(
                                Icons.currency_rupee,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Total Amount: ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                Helpers.formatCurrency(orderData['total'] ?? 0),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Delivery Address
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Delivery Address',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (orderData['deliveryAddress'] != null) ...[
                            Text(
                              '${orderData['deliveryAddress']['name']} - ${orderData['deliveryAddress']['phone']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${orderData['deliveryAddress']['addressLine1']}, ${orderData['deliveryAddress']['city']}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              Column(
                children: [
                  PrimaryButton(
                    text: 'Track Your Order',
                    onPressed: () => _trackOrder(context),
                    icon: Icons.location_searching,
                  ),
                  const SizedBox(height: 12),
                  
                  OutlinedButton(
                    onPressed: () => _continueShoppingming(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue Shopping'),
                  ),
                  const SizedBox(height: 8),
                  
                  TextButton(
                    onPressed: () => _shareOrder(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share, size: 18),
                        SizedBox(width: 8),
                        Text('Share Order Details'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEstimatedDeliveryTime() {
    final deliverySlot = orderData['deliverySlot'] ?? 'ASAP';
    
    switch (deliverySlot) {
      case 'ASAP':
        return '30-45 minutes';
      case 'SLOT1':
        return 'Today 6:00-8:00 PM';
      case 'SLOT2':
        return 'Today 8:00-10:00 PM';
      case 'SLOT3':
        return 'Tomorrow 10:00 AM-12:00 PM';
      case 'SLOT4':
        return 'Tomorrow 2:00-4:00 PM';
      default:
        return '30-45 minutes';
    }
  }

  void _trackOrder(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(
          orderNumber: orderNumber,
        ),
      ),
    );
  }

  void _continueShoppingming(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const CustomerDashboard(),
      ),
      (route) => false,
    );
  }

  void _shareOrder(BuildContext context) {
    final message = '''
🎉 Order Placed Successfully!

Order Number: $orderNumber
Total Amount: ${Helpers.formatCurrency(orderData['total'] ?? 0)}
Delivery Time: ${_getEstimatedDeliveryTime()}

Track your order on NammaOoru Delivery app!
    ''';
    
    // TODO: Implement share functionality
    Helpers.showSnackBar(context, 'Share functionality will be added soon');
  }
}