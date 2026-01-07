import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/models/simple_order_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_messaging_service.dart';
import '../../../services/firebase_notification_service_mobile.dart';
import '../widgets/order_card.dart';
import '../widgets/order_details_bottom_sheet.dart';
import 'otp_handover_screen.dart';
import 'navigation_screen.dart';
import 'order_details_screen.dart';
import '../../delivery/screens/simple_delivery_completion_screen.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({Key? key}) : super(key: key);

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    FirebaseNotificationService.removeListener(_handleNotification);
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupNotificationListener() {
    FirebaseNotificationService.addListener(_handleNotification);
  }

  void _handleNotification(NotificationModel notification) {
    // Handle order cancellation notification
    // Check both type and status fields since backend may send either
    final type = notification.type.toLowerCase();
    final status = (notification.data?['status'] ?? '').toString().toLowerCase();

    final isCancelled = type == 'order_cancelled' ||
        type == 'delivery_cancelled' ||
        status == 'cancelled' ||
        notification.title.toLowerCase().contains('cancelled');

    if (isCancelled) {
      final orderNumber = notification.data?['orderNumber'] ?? notification.orderId;
      if (orderNumber != null) {
        // Play LOUD urgent sound (like a call ringtone)
        _playUrgentCancellationSound();

        // Show system notification with loud sound
        FirebaseMessagingService.showCancellationNotification(
          title: '🚨 ORDER CANCELLED!',
          body: 'Order #$orderNumber was cancelled. Please return products to shop.',
          orderId: orderNumber.toString(),
        );

        // Show cancellation dialog
        _showOrderCancelledDialog(orderNumber, notification.body);

        // Remove order from list and refresh from API
        final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
        provider.handleOrderCancelled(orderNumber);

        // Also refresh from API to ensure sync with server
        provider.loadCurrentOrders();
      }
    }
  }

  /// Play LOUD urgent sound for order cancellation (like a phone call)
  Future<void> _playUrgentCancellationSound() async {
    try {
      // Set volume to maximum
      await _audioPlayer.setVolume(1.0);
      // Set release mode to loop for urgent attention
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Play the urgent notification sound
      await _audioPlayer.play(AssetSource('sounds/urgent_notification.mp3'));

      // Stop after 10 seconds if user doesn't interact
      Future.delayed(const Duration(seconds: 10), () {
        _audioPlayer.stop();
      });
    } catch (e) {
      print('Error playing cancellation sound: $e');
    }
  }

  /// Stop the urgent sound when user acknowledges
  void _stopUrgentSound() {
    _audioPlayer.stop();
  }

  void _showOrderCancelledDialog(String orderNumber, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text('🚨 ORDER CANCELLED!', style: TextStyle(color: Colors.red, fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Order #$orderNumber has been cancelled by the customer.',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ Please return all products to the shop immediately!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            if (message.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _stopUrgentSound(); // Stop the loud sound
                Navigator.pop(context);
                _loadActiveOrders(); // Refresh the list
              },
              icon: Icon(Icons.check),
              label: Text('I UNDERSTAND'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _loadActiveOrders() {
    final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
    provider.loadCurrentOrders();
  }

  void _showOrderDetails(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(order: order),
      ),
    ).then((_) {
      // Reload orders when returning from details screen
      _loadActiveOrders();
    });
  }

  void _markAsPickedUp(OrderModel order) async {
    final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    try {
      await provider.updateOrderStatus(order.orderNumber ?? order.id.toString(), 'picked_up');

      // Update location tracking context with assignmentId
      locationProvider.updateOrderContext(
        assignmentId: order.assignmentId,
        orderStatus: 'picked_up',
      );

      // Start location tracking if not already active
      if (!locationProvider.isLocationTrackingActive && provider.currentPartner != null) {
        await locationProvider.startLocationTracking(
          partnerId: provider.currentPartner!.partnerId,
          assignmentId: order.assignmentId,
          orderStatus: 'picked_up',
        );
      }

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
    // Navigate to simple delivery completion screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleDeliveryCompletionScreen(order: order),
      ),
    ).then((_) {
      // Reload orders when returning from completion screen
      _loadActiveOrders();
    });
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(order: order),
      ),
    );
  }

  void _startReturnToShop(OrderModel order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.store, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Return to Shop'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.orderNumber} was cancelled by the customer.'),
            SizedBox(height: 12),
            Text(
              'Please return the products to ${order.shopName}.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Start Return'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = ApiService();
      final result = await apiService.startReturnToShop(order.orderNumber ?? order.id.toString());

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Returning to shop. Navigate to ${order.shopName}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        _loadActiveOrders();
      } else {
        throw Exception(result['message'] ?? 'Failed to start return');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmReturnedToShop(OrderModel order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Confirm Return'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Have you returned all products from Order #${order.orderNumber} to ${order.shopName}?'),
            SizedBox(height: 12),
            Text(
              'The shop owner will be notified to collect the items.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm Returned'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = ApiService();
      final result = await apiService.confirmReturnedToShop(order.orderNumber ?? order.id.toString());

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Products returned to shop successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _loadActiveOrders();
      } else {
        throw Exception(result['message'] ?? 'Failed to confirm return');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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
                          color: provider.currentPartner?.isOnline == true
                              ? Colors.green
                              : Colors.red[400],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.currentPartner?.isOnline == true ? 'Online' : 'Offline',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
                    itemCount: activeOrders.length,
                    itemBuilder: (context, index) {
                      final order = activeOrders[index];
                      return _buildActiveOrderCard(order, index);
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

  Widget _buildActiveOrderCard(OrderModel order, int index) {
    final statusInfo = _getStatusInfo(order.status);
    final stepInfo = _getStepInfo(order.status);

    // Use consistent blue color for all cards
    const Color cardColor = Color(0xFF2196F3);

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
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
        child: Column(
          children: [
            // Header with Order Number and Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardColor, cardColor.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // Order number and status row
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: cardColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${order.orderNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              order.shopName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusInfo.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getStatusText(order.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status instruction
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusInfo.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusInfo.subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '₹${order.totalAmount?.toStringAsFixed(0) ?? '0'}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue[50],
                        child: Text(
                          order.customerName.isNotEmpty
                            ? order.customerName[0].toUpperCase()
                            : 'C',
                          style: TextStyle(
                            color: cardColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
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
                      // Call button
                      if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.phone, color: Colors.green[700], size: 20),
                            onPressed: () => _callCustomer(order.customerPhone),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Delivery address
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 18, color: Colors.red[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.deliveryAddress,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action buttons
                  _buildActionButtonsNew(order, statusInfo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool completed, bool active, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: completed ? color : (active ? color.withOpacity(0.2) : Colors.grey[300]),
              shape: BoxShape.circle,
              border: active && !completed ? Border.all(color: color, width: 2) : null,
            ),
            child: Center(
              child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: active ? color : Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: completed || active ? color : Colors.grey[500],
              fontSize: 10,
              fontWeight: completed || active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool completed, Color color) {
    return Container(
      width: 30,
      height: 3,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: completed ? color : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildPickupOTPSection(OrderModel order) {
    final hasOtp = order.pickupOtp != null && order.pickupOtp!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PICKUP OTP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Show this to shop owner',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasOtp
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: order.pickupOtp!.split('').map((digit) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Text(
                      digit,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  )).toList(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for OTP...',
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextActionSection(OrderModel order, _StatusInfo statusInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "NEXT ACTION" label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusInfo.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_forward, size: 14, color: statusInfo.color),
              const SizedBox(width: 4),
              Text(
                'NEXT ACTION',
                style: TextStyle(
                  color: statusInfo.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Action buttons based on status
        _buildActionButtonsNew(order, statusInfo),
      ],
    );
  }

  Widget _buildActionButtonsNew(OrderModel order, _StatusInfo statusInfo) {
    switch (order.status.toLowerCase()) {
      case 'cancelled':
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700], size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order cancelled! Return products to shop',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startNavigation(order),
                    icon: const Icon(Icons.navigation, size: 20),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _startReturnToShop(order),
                    icon: const Icon(Icons.store, size: 20),
                    label: const Text('Start Return to Shop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'returning_to_shop':
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.directions_bike, color: Colors.orange[700], size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Go to ${order.shopName} and return the products',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startNavigation(order),
                    icon: const Icon(Icons.navigation, size: 20),
                    label: const Text('Navigate to Shop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmReturnedToShop(order),
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Returned'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'returned_to_shop':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Products Returned Successfully!',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case 'accepted':
      case 'ready_for_pickup':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startNavigation(order),
                icon: const Icon(Icons.navigation, size: 20),
                label: const Text('Navigate to Shop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showOrderDetails(order),
                icon: const Icon(Icons.inventory_2, size: 20),
                label: const Text('Confirm Pickup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'picked_up':
      case 'in_transit':
      case 'out_for_delivery':
        // Only show Navigate button - delivery completion is done by tapping the card
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startNavigation(order),
            icon: const Icon(Icons.navigation, size: 20),
            label: const Text('Navigate to Customer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'ready_for_pickup':
        return _StatusInfo(
          title: 'GO TO SHOP',
          subtitle: 'Pick up the order from shop',
          icon: Icons.store,
          color: Colors.blue,
        );
      case 'picked_up':
      case 'in_transit':
      case 'out_for_delivery':
        return _StatusInfo(
          title: 'DELIVER ORDER',
          subtitle: 'Go to customer location',
          icon: Icons.delivery_dining,
          color: Colors.purple,
        );
      case 'cancelled':
        return _StatusInfo(
          title: 'ORDER CANCELLED',
          subtitle: 'Return products to shop',
          icon: Icons.cancel,
          color: Colors.red,
        );
      case 'returning_to_shop':
        return _StatusInfo(
          title: 'RETURNING TO SHOP',
          subtitle: 'Take products back to shop',
          icon: Icons.directions_bike,
          color: Colors.orange,
        );
      case 'returned_to_shop':
        return _StatusInfo(
          title: 'RETURNED',
          subtitle: 'Products returned to shop',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      case 'delivered':
        return _StatusInfo(
          title: 'DELIVERED',
          subtitle: 'Order completed',
          icon: Icons.done_all,
          color: Colors.green,
        );
      default:
        return _StatusInfo(
          title: status.toUpperCase(),
          subtitle: 'Order in progress',
          icon: Icons.local_shipping,
          color: Colors.grey,
        );
    }
  }

  _StepInfo _getStepInfo(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'ready_for_pickup':
        return _StepInfo(currentStep: 1, totalSteps: 3);
      case 'picked_up':
      case 'in_transit':
      case 'out_for_delivery':
        return _StepInfo(currentStep: 2, totalSteps: 3);
      case 'delivered':
        return _StepInfo(currentStep: 3, totalSteps: 3);
      case 'cancelled':
      case 'returning_to_shop':
        return _StepInfo(currentStep: 1, totalSteps: 2); // Return flow
      case 'returned_to_shop':
        return _StepInfo(currentStep: 2, totalSteps: 2);
      default:
        return _StepInfo(currentStep: 1, totalSteps: 3);
    }
  }

  Widget _buildCompactOTPDisplay(String otp, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Text(
            'PICKUP OTP:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              otp.split('').join(' '),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
                letterSpacing: 4,
              ),
            ),
          ),
          const Spacer(),
          const Icon(Icons.info_outline, color: Colors.white70, size: 18),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order, Color cardColor) {
    switch (order.status.toLowerCase()) {
      case 'cancelled':
        // Show return to shop button for cancelled orders
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ORDER CANCELLED BY CUSTOMER',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startReturnToShop(order),
                icon: const Icon(Icons.store, size: 20),
                label: const Text('Return to Shop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case 'returning_to_shop':
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'RETURNING TO SHOP',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmReturnedToShop(order),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Confirm Returned to Shop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case 'returned_to_shop':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 24),
              const SizedBox(width: 10),
              Text(
                'RETURNED TO SHOP',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showOrderDetails(order),
            icon: const Icon(Icons.inventory, size: 20),
            label: const Text('Pick Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cardColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        );

      case 'picked_up':
      case 'in_transit':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markAsDelivered(order),
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text('Mark as Delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildOTPDisplay(String otp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFC107).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lock_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'PICKUP OTP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...otp.split('').map((digit) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    digit,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9800),
                      letterSpacing: 2,
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 14),
              SizedBox(width: 6),
              Text(
                'Show this OTP to shop owner for pickup',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

// Helper class for status information
class _StatusInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _StatusInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

// Helper class for step information
class _StepInfo {
  final int currentStep;
  final int totalSteps;

  _StepInfo({
    required this.currentStep,
    required this.totalSteps,
  });
}