import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/models/simple_order_model.dart';
import '../../../core/services/enhanced_navigation_service.dart';
import '../../../core/constants/app_colors.dart';

/// Comprehensive order completion screen with payment collection
class OrderCompletionScreen extends StatefulWidget {
  final OrderModel order;

  const OrderCompletionScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderCompletionScreen> createState() => _OrderCompletionScreenState();
}

class _OrderCompletionScreenState extends State<OrderCompletionScreen>
    with TickerProviderStateMixin {

  final EnhancedNavigationService _navigationService = EnhancedNavigationService();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customerRatingController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  PaymentStatus _paymentStatus = PaymentStatus.pending;
  bool _isCompleting = false;
  String _errorMessage = '';
  File? _deliveryPhoto;
  int _customerRating = 5;
  bool _customerAvailable = true;
  bool _itemsInGoodCondition = true;

  late AnimationController _completionController;
  late AnimationController _paymentController;
  late Animation<double> _completionAnimation;
  late Animation<double> _paymentAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePaymentMethod();
    _checkArrivalStatus();
  }

  void _initializeAnimations() {
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _paymentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _completionAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: Curves.bounceOut,
    ));

    _paymentAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _paymentController,
      curve: Curves.elasticOut,
    ));
  }

  void _initializePaymentMethod() {
    // Set default payment method based on order
    if (widget.order.paymentMethod != null) {
      switch (widget.order.paymentMethod!.toLowerCase()) {
        case 'cash':
          _selectedPaymentMethod = PaymentMethod.cash;
          break;
        case 'card':
        case 'online':
          _selectedPaymentMethod = PaymentMethod.online;
          _paymentStatus = PaymentStatus.completed; // Online payments are pre-paid
          break;
        case 'cod':
          _selectedPaymentMethod = PaymentMethod.cod;
          break;
      }
    }
  }

  void _checkArrivalStatus() {
    final session = _navigationService.currentSession;
    if (session != null && session.orderId == widget.order.id.toString()) {
      final distance = _navigationService.getRemainingDistance();
      if (distance != null && distance <= 0.1) { // Within 100 meters
        _showArrivalConfirmation();
      }
    }
  }

  void _showArrivalConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'You\'ve arrived at customer location! Complete the delivery.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customerRatingController.dispose();
    _completionController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _takeDeliveryPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _deliveryPhoto = File(photo.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery photo captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _collectPayment() async {
    if (_selectedPaymentMethod == PaymentMethod.online) {
      setState(() {
        _paymentStatus = PaymentStatus.completed;
      });
      _paymentController.forward();
      return;
    }

    // For cash/COD payments, show collection dialog
    final collected = await _showPaymentCollectionDialog();
    if (collected == true) {
      setState(() {
        _paymentStatus = PaymentStatus.completed;
      });
      _paymentController.forward();
    }
  }

  Future<bool?> _showPaymentCollectionDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payments, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Collect Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method: ${_selectedPaymentMethod.displayName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Amount to Collect: ₹${widget.order.totalAmount?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Have you collected the payment from the customer?',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Yet'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Payment Collected'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeOrder() async {
    if (_paymentStatus != PaymentStatus.completed && _selectedPaymentMethod != PaymentMethod.online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please collect payment before completing delivery'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCompleting = true;
      _errorMessage = '';
    });

    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);

      // Create completion data
      final completionData = {
        'orderId': widget.order.id.toString(),
        'paymentMethod': _selectedPaymentMethod.name,
        'paymentStatus': _paymentStatus.name,
        'deliveryNotes': _notesController.text.trim(),
        'customerRating': _customerRating,
        'customerAvailable': _customerAvailable,
        'itemsInGoodCondition': _itemsInGoodCondition,
        'deliveryPhotoPath': _deliveryPhoto?.path,
        'completedAt': DateTime.now().toIso8601String(),
      };

      // Update order status to delivered
      final success = await provider.updateOrderStatus(widget.order.id.toString(), 'DELIVERED');

      if (success) {
        // Stop navigation if active
        await _navigationService.stopNavigation();

        // Show completion animation
        _completionController.forward();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order #${widget.order.orderNumber} delivered successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back after delay
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.of(context).pop(true);
        }

      } else {
        setState(() {
          _errorMessage = 'Failed to complete delivery. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error completing delivery: $e';
      });
    } finally {
      setState(() {
        _isCompleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Complete Delivery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order info card
              _buildOrderInfoCard(),

              const SizedBox(height: 24),

              // Customer info
              _buildCustomerInfoCard(),

              const SizedBox(height: 24),

              // Payment section
              _buildPaymentSection(),

              const SizedBox(height: 24),

              // Delivery confirmation section
              _buildDeliveryConfirmationSection(),

              const SizedBox(height: 24),

              // Photo section
              _buildPhotoSection(),

              const SizedBox(height: 24),

              // Notes section
              _buildNotesSection(),

              const SizedBox(height: 24),

              // Customer rating
              _buildCustomerRatingSection(),

              const SizedBox(height: 32),

              // Error message
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Complete delivery button
              AnimatedBuilder(
                animation: _completionAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_completionAnimation.value * 0.1),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isCompleting ? null : _completeOrder,
                        icon: _isCompleting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          _isCompleting ? 'Completing Delivery...' : 'Complete Delivery',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${widget.order.orderNumber}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'IN TRANSIT',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.store, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text('From: ${widget.order.shopName}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.monetization_on, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Order Value: ₹${widget.order.totalAmount?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(widget.order.customerName),
            ],
          ),
          if (widget.order.customerPhone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(widget.order.customerPhone!),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // Implement call functionality
                  },
                  icon: const Icon(Icons.call, color: Colors.green),
                  tooltip: 'Call Customer',
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.order.deliveryAddress),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Collection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AnimatedBuilder(
                animation: _paymentAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _paymentStatus == PaymentStatus.completed
                        ? 1.0 + (_paymentAnimation.value * 0.2)
                        : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _paymentStatus == PaymentStatus.completed
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _paymentStatus.displayName,
                        style: TextStyle(
                          color: _paymentStatus == PaymentStatus.completed
                              ? Colors.green[800]
                              : Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Method:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ...PaymentMethod.values.map((method) {
            return RadioListTile<PaymentMethod>(
              title: Text(method.displayName),
              subtitle: Text(method.description),
              value: method,
              groupValue: _selectedPaymentMethod,
              onChanged: _paymentStatus == PaymentStatus.completed
                  ? null
                  : (PaymentMethod? value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                        if (value == PaymentMethod.online) {
                          _paymentStatus = PaymentStatus.completed;
                        } else {
                          _paymentStatus = PaymentStatus.pending;
                        }
                      });
                    },
              dense: true,
            );
          }).toList(),
          if (_paymentStatus == PaymentStatus.pending &&
              _selectedPaymentMethod != PaymentMethod.online) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _collectPayment,
                icon: const Icon(Icons.payments),
                label: Text('Collect ₹${widget.order.totalAmount?.toStringAsFixed(0) ?? '0'}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryConfirmationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Confirmation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Customer was available'),
            value: _customerAvailable,
            onChanged: (bool? value) {
              setState(() {
                _customerAvailable = value ?? true;
              });
            },
            dense: true,
          ),
          CheckboxListTile(
            title: const Text('Items delivered in good condition'),
            value: _itemsInGoodCondition,
            onChanged: (bool? value) {
              setState(() {
                _itemsInGoodCondition = value ?? true;
              });
            },
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Photo (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_deliveryPhoto != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(_deliveryPhoto!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _takeDeliveryPhoto,
              icon: Icon(_deliveryPhoto != null ? Icons.refresh : Icons.camera_alt),
              label: Text(_deliveryPhoto != null ? 'Retake Photo' : 'Take Photo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Notes (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any additional notes about the delivery...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRatingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Experience',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Rate your delivery experience (optional):',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _customerRating = index + 1;
                  });
                },
                icon: Icon(
                  index < _customerRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          Text(
            '${_customerRating} star${_customerRating != 1 ? 's' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment methods enum
enum PaymentMethod {
  cash('Cash', 'Cash on delivery'),
  cod('COD', 'Cash on delivery'),
  online('Online', 'Already paid online');

  const PaymentMethod(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Payment status enum
enum PaymentStatus {
  pending('Pending'),
  completed('Completed');

  const PaymentStatus(this.displayName);
  final String displayName;
}