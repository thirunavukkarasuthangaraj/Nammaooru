import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/models/simple_order_model.dart';
import '../services/delivery_confirmation_service.dart';
import '../widgets/photo_capture_widget.dart';
import '../widgets/otp_input_widget.dart';

class DeliveryCompletionScreen extends StatefulWidget {
  final OrderModel order;

  const DeliveryCompletionScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<DeliveryCompletionScreen> createState() => _DeliveryCompletionScreenState();
}

class _DeliveryCompletionScreenState extends State<DeliveryCompletionScreen> {
  final DeliveryConfirmationService _confirmationService = DeliveryConfirmationService();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _deliveryNotesController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _otpGenerated = false;
  bool _otpValidated = false;
  File? _deliveryPhoto;
  File? _signatureFile;
  String? _generatedOtp;
  String? _errorMessage;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _generateDeliveryOTP();
    _customerNameController.text = widget.order.customerName ?? '';
  }

  @override
  void dispose() {
    _otpController.dispose();
    _customerNameController.dispose();
    _deliveryNotesController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _generateDeliveryOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _confirmationService.generateDeliveryOTP(widget.order.id);

      if (response['success'] == true) {
        setState(() {
          _otpGenerated = true;
          _generatedOtp = response['otp']; // For demo purposes
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
        title: const Text('Delivery OTP Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('An OTP has been sent to the customer for delivery confirmation.'),
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
        'delivery',
      );

      if (isValid) {
        setState(() {
          _otpValidated = true;
        });

        _showSnackBar('OTP validated successfully! Complete delivery details.', Colors.green);
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

  Future<void> _captureDeliveryPhoto() async {
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
          _deliveryPhoto = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error capturing photo: $e', Colors.red);
    }
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      _showSnackBar('Please provide a signature', Colors.orange);
      return;
    }

    try {
      final Uint8List? signature = await _signatureController.toPngBytes();
      if (signature != null) {
        // Save signature to temporary file
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(signature);

        setState(() {
          _signatureFile = file;
          _hasSignature = true;
        });

        _showSnackBar('Signature saved successfully!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error saving signature: $e', Colors.red);
    }
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() {
      _signatureFile = null;
      _hasSignature = false;
    });
  }

  Future<void> _completeDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deliveryPhoto == null) {
      _showSnackBar('Please take a delivery photo', Colors.orange);
      return;
    }

    if (!_hasSignature) {
      _showSnackBar('Please provide customer signature', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final position = locationProvider.currentPosition;

      final response = await _confirmationService.confirmDelivery(
        orderId: widget.order.id,
        otp: _otpController.text,
        deliveryPhoto: _deliveryPhoto,
        signatureFile: _signatureFile,
        customerName: _customerNameController.text.trim().isNotEmpty
          ? _customerNameController.text.trim()
          : null,
        deliveryNotes: _deliveryNotesController.text.trim().isNotEmpty
          ? _deliveryNotesController.text.trim()
          : null,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      if (response['success'] == true) {
        _showSnackBar('Delivery completed successfully!', Colors.green);

        // Update order status in provider
        final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
        await provider.updateOrderStatus(widget.order.id, 'DELIVERED');

        // Check if COD payment needs to be collected
        if (widget.order.paymentMethod == 'CASH_ON_DELIVERY' &&
            widget.order.paymentStatus != 'PAID') {
          // Show payment collection confirmation
          _showPaymentCollectionDialog();
        } else {
          // Navigate back to dashboard
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/dashboard',
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to complete delivery';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error completing delivery: $e';
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

  void _showPaymentCollectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payments, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            const Text('Collect Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cash on Delivery',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount to Collect:',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '₹${(widget.order.totalAmount ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
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
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to dashboard without marking as paid
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/dashboard',
                (route) => false,
              );
            },
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _markPaymentAsCollected();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Collected'),
          ),
        ],
      ),
    );
  }

  Future<void> _markPaymentAsCollected() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call backend API to mark payment as collected
      final response = await _confirmationService.markPaymentCollected(widget.order.id);

      if (response['success'] == true) {
        _showSnackBar('Payment marked as collected successfully!', Colors.green);

        // Navigate back to dashboard
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/dashboard',
            (route) => false,
          );
        });
      } else {
        _showSnackBar(
          response['message'] ?? 'Failed to mark payment as collected',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Error marking payment: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Delivery'),
        backgroundColor: Colors.green,
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
                      Text('Delivery: ${widget.order.deliveryAddress}'),
                      Text('Status: ${widget.order.status}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Step 1: OTP Validation
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
                            'Step 1: Validate Delivery OTP',
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

              // Step 2: Customer Details
              if (_otpValidated) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Step 2: Customer Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Received by (Customer Name)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter customer name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _deliveryNotesController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Notes (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Step 3: Delivery Photo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _deliveryPhoto != null ? Icons.check_circle : Icons.camera_alt,
                              color: _deliveryPhoto != null ? Colors.green : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Step 3: Delivery Photo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text('Take a photo of the delivered items:'),
                        const SizedBox(height: 12),

                        if (_deliveryPhoto != null) ...[
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
                                _deliveryPhoto!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _captureDeliveryPhoto,
                                  child: const Text('Retake Photo'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          PhotoCaptureWidget(
                            onPhotoCaptured: (file) {
                              setState(() {
                                _deliveryPhoto = file;
                              });
                            },
                            hint: 'Capture delivery proof photo',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Step 4: Customer Signature
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _hasSignature ? Icons.check_circle : Icons.edit,
                              color: _hasSignature ? Colors.green : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Step 4: Customer Signature',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text('Customer signature for delivery confirmation:'),
                        const SizedBox(height: 12),

                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Signature(
                            controller: _signatureController,
                            backgroundColor: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _clearSignature,
                                child: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveSignature,
                                child: const Text('Save Signature'),
                              ),
                            ),
                          ],
                        ),

                        if (_hasSignature) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '✓ Signature saved successfully',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],

              // Error Message
              if (_errorMessage != null) ...[
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
              ],

              // Complete Delivery Button
              ElevatedButton(
                onPressed: _otpValidated &&
                          _deliveryPhoto != null &&
                          _hasSignature &&
                          !_isLoading
                  ? _completeDelivery
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
                      'Complete Delivery',
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