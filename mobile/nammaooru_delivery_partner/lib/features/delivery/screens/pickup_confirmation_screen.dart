import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/models/simple_order_model.dart';
import '../services/delivery_confirmation_service.dart';
import '../widgets/photo_capture_widget.dart';
import '../widgets/otp_input_widget.dart';

class PickupConfirmationScreen extends StatefulWidget {
  final OrderModel order;

  const PickupConfirmationScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<PickupConfirmationScreen> createState() => _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  final DeliveryConfirmationService _confirmationService = DeliveryConfirmationService();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _otpGenerated = false;
  bool _otpValidated = false;
  File? _pickupPhoto;
  String? _generatedOtp;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generatePickupOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _generatePickupOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _confirmationService.generatePickupOTP(widget.order.id);

      if (response['success'] == true) {
        setState(() {
          _otpGenerated = true;
          _generatedOtp = response['otp']; // For demo purposes - in production, OTP is sent via SMS
        });

        _showOTPDialog();
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to generate OTP';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating OTP: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showOTPDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pickup OTP Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('An OTP has been sent to the customer for pickup confirmation.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Demo OTP (Customer receives this):',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generatedOtp ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _validateOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _confirmationService.validateOTP(
        widget.order.id,
        _otpController.text,
        'pickup',
      );

      if (isValid) {
        setState(() {
          _otpValidated = true;
        });

        _showSnackBar('OTP validated successfully! Now take a pickup photo.', Colors.green);
      } else {
        setState(() {
          _errorMessage = 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error validating OTP: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _capturePickupPhoto() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _pickupPhoto = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error capturing photo: $e', Colors.red);
    }
  }

  Future<void> _confirmPickup() async {
    if (_pickupPhoto == null) {
      _showSnackBar('Please take a pickup photo', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _confirmationService.confirmPickup(
        orderId: widget.order.id,
        otp: _otpController.text,
        photoFile: _pickupPhoto!,
      );

      if (response['success'] == true) {
        _showSnackBar('Pickup confirmed successfully!', Colors.green);

        // Update order status in provider
        final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
        await provider.updateOrderStatus(widget.order.orderNumber ?? widget.order.id.toString(), 'PICKED_UP');

        // Navigate back to dashboard
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to confirm pickup';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error confirming pickup: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Confirmation'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${widget.order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Customer: ${widget.order.customerName}'),
                      Text('Phone: ${widget.order.customerPhone}'),
                      Text('Pickup: ${widget.order.shopName}'),
                      Text('Delivery: ${widget.order.deliveryAddress}'),
                      Text('Status: ${widget.order.status}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Step 1: OTP Generation
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _otpGenerated ? Icons.check_circle : Icons.phone,
                            color: _otpGenerated ? Colors.green : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Step 1: OTP Generated',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _otpGenerated
                          ? 'OTP has been sent to customer for pickup confirmation'
                          : 'Generating OTP for customer...',
                      ),
                      if (!_otpGenerated && !_isLoading)
                        ElevatedButton(
                          onPressed: _generatePickupOTP,
                          child: const Text('Regenerate OTP'),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Step 2: OTP Validation
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _otpValidated ? Icons.check_circle : Icons.lock,
                            color: _otpValidated ? Colors.green : (_otpGenerated ? Colors.blue : Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Step 2: Validate OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_otpGenerated && !_otpValidated) ...[
                        const Text('Enter the OTP provided by the customer:'),
                        const SizedBox(height: 12),
                        OTPInputWidget(
                          controller: _otpController,
                          onChanged: (value) {
                            if (value.length == 6) {
                              _validateOTP();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _otpGenerated && !_isLoading ? _validateOTP : null,
                          child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Validate OTP'),
                        ),
                      ],

                      if (_otpValidated)
                        const Text(
                          '✓ OTP validated successfully',
                          style: TextStyle(color: Colors.green),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Step 3: Pickup Photo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _pickupPhoto != null ? Icons.check_circle : Icons.camera_alt,
                            color: _pickupPhoto != null ? Colors.green : (_otpValidated ? Colors.blue : Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Step 3: Pickup Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_otpValidated) ...[
                        const Text('Take a photo of the items being picked up:'),
                        const SizedBox(height: 12),

                        if (_pickupPhoto != null) ...[
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _pickupPhoto!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _capturePickupPhoto,
                                  child: const Text('Retake Photo'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          PhotoCaptureWidget(
                            onPhotoCaptured: (file) {
                              setState(() {
                                _pickupPhoto = file;
                              });
                            },
                            isEnabled: _otpValidated,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 16),

              // Confirm Pickup Button
              ElevatedButton(
                onPressed: _otpValidated && _pickupPhoto != null && !_isLoading
                  ? _confirmPickup
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Confirm Pickup',
                      style: TextStyle(fontSize: 16),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}