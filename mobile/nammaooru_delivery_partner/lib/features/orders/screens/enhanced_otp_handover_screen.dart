import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/models/simple_order_model.dart';
import '../../../core/services/enhanced_navigation_service.dart';
import '../../../core/constants/app_colors.dart';

/// Enhanced OTP handover screen with improved UX and navigation integration
class EnhancedOTPHandoverScreen extends StatefulWidget {
  final OrderModel order;

  const EnhancedOTPHandoverScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<EnhancedOTPHandoverScreen> createState() => _EnhancedOTPHandoverScreenState();
}

class _EnhancedOTPHandoverScreenState extends State<EnhancedOTPHandoverScreen>
    with TickerProviderStateMixin {

  final List<TextEditingController> _otpControllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final EnhancedNavigationService _navigationService = EnhancedNavigationService();

  bool _isVerifying = false;
  bool _isResendingOTP = false;
  String _errorMessage = '';
  String _successMessage = '';
  int _resendCooldown = 0;

  late AnimationController _shakeController;
  late AnimationController _successController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startResendTimer();

    // Show arrival notification if driver is near shop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkArrivalStatus();
    });
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _successAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.bounceOut,
    ));
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
            Expanded(
              child: Text(
                'You\'ve arrived at ${widget.order.shopName}! Please get the OTP from shop owner.',
                style: const TextStyle(fontWeight: FontWeight.w500),
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
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  String get _enteredOTP {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool get _isOTPComplete {
    return _enteredOTP.length == 4 && _enteredOTP.isNotEmpty;
  }

  void _onOTPChanged(String value, int index) {
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_isOTPComplete) {
      _verifyOTP();
    }
  }

  void _onBackspace(int index) {
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOTP() async {
    if (!_isOTPComplete) {
      setState(() {
        _errorMessage = 'Please enter complete OTP';
      });
      _shakeController.forward().then((_) => _shakeController.reset());
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final success = await provider.verifyPickupOTP(widget.order.id.toString(), _enteredOTP);

      if (success) {
        setState(() {
          _successMessage = 'OTP verified successfully!';
        });

        _successController.forward();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Order picked up successfully! Navigate to customer now.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Stop shop navigation if active
        await _navigationService.stopNavigation();

        // Delay for animation and user feedback
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // Ask user if they want to navigate to customer
          _showCustomerNavigationDialog();
        }

      } else {
        setState(() {
          _errorMessage = 'Invalid OTP. Please check with the shop owner.';
          _clearOTP();
        });
        _shakeController.forward().then((_) => _shakeController.reset());
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
        _clearOTP();
      });
      _shakeController.forward().then((_) => _shakeController.reset());
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _showCustomerNavigationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.navigation, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Start Customer Navigation?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order picked up from ${widget.order.shopName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Deliver to: ${widget.order.customerName}'),
              Text('Address: ${widget.order.deliveryAddress}'),
              if (widget.order.customerPhone != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${widget.order.customerPhone}'),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Return to dashboard
              },
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _startCustomerNavigation();
                Navigator.of(context).pop(true); // Return to dashboard
              },
              icon: const Icon(Icons.navigation),
              label: const Text('Navigate Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startCustomerNavigation() async {
    if (!widget.order.canNavigateToCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer location not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _navigationService.startCustomerNavigation(widget.order);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigation to customer started'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start navigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOTP() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isResendingOTP = true;
      _errorMessage = '';
    });

    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final success = await provider.requestNewPickupOTP(widget.order.id.toString());

      if (success) {
        setState(() {
          _successMessage = 'New OTP sent to shop owner';
        });
        _startResendTimer();
        _clearOTP();
      } else {
        setState(() {
          _errorMessage = 'Failed to resend OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
    } finally {
      setState(() {
        _isResendingOTP = false;
      });
    }
  }

  void _startResendTimer() {
    setState(() {
      _resendCooldown = 30; // 30 seconds cooldown
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
        });

        if (_resendCooldown <= 0) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'OTP Verification',
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Shop info card
              _buildShopInfoCard(),

              const SizedBox(height: 40),

              // Title
              const Text(
                'Enter Pickup OTP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Get the 4-digit OTP from ${widget.order.shopName}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // OTP input fields
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value * 10 *
                        ((_shakeAnimation.value * 10).round() % 2 == 0 ? 1 : -1), 0),
                    child: _buildOTPInputFields(),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Error/Success messages
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

              if (_successMessage.isNotEmpty) ...[
                AnimatedBuilder(
                  animation: _successAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _successAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage,
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Verify button
              if (!_isOTPComplete) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isOTPComplete ? _verifyOTP : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Resend OTP
              TextButton.icon(
                onPressed: _resendCooldown > 0 || _isResendingOTP ? null : _resendOTP,
                icon: _isResendingOTP
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  _resendCooldown > 0
                      ? 'Resend OTP in ${_resendCooldown}s'
                      : 'Resend OTP',
                ),
              ),

              const SizedBox(height: 40),

              // Help section
              _buildHelpSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.shopName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.order.shopAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.order.shopAddress!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${widget.order.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.order.displayStatus,
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOTPInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _otpControllers[index].text.isNotEmpty
                  ? AppColors.primary
                  : Colors.grey[300]!,
              width: 2,
            ),
            color: _otpControllers[index].text.isNotEmpty
                ? AppColors.primary.withOpacity(0.1)
                : Colors.grey[50],
          ),
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (value) => _onOTPChanged(value, index),
            onTap: () {
              _otpControllers[index].selection = TextSelection.fromPosition(
                TextPosition(offset: _otpControllers[index].text.length),
              );
            },
            onSubmitted: (value) {
              if (index < 3 && value.isNotEmpty) {
                _focusNodes[index + 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildHelpSection() {
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
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Need Help?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Ask the shop owner for the 4-digit pickup OTP\n'
            '• Make sure you\'re at the correct shop location\n'
            '• If OTP doesn\'t work, tap "Resend OTP"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Import Timer
import 'dart:async';