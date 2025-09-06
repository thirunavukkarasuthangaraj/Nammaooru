import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  
  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  
  Timer? _timer;
  int _remainingTime = 120; // 2 minutes
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _remainingTime = 120;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String get _formattedTime {
    final minutes = (_remainingTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingTime % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _otpValue {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final otp = _otpValue;
    if (otp.length != 6) {
      Helpers.showSnackBar(
        context,
        'Please enter complete OTP',
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.verifyOtp(widget.email, otp);

    if (mounted) {
      if (success) {
        Helpers.showSnackBar(
          context,
          'Account verified successfully! Welcome to NammaOoru!',
        );
        await Future.delayed(const Duration(seconds: 1));
        // User is now authenticated, redirect to appropriate dashboard based on role
        if (authProvider.isCustomer) {
          context.pushReplacement('/customer/dashboard');
        } else if (authProvider.isShopOwner) {
          context.pushReplacement('/shop-owner/dashboard');
        } else if (authProvider.isDeliveryPartner) {
          context.pushReplacement('/delivery-partner/dashboard');
        } else {
          context.pushReplacement('/customer/dashboard'); // Default to customer dashboard
        }
      } else if (authProvider.errorMessage != null) {
        Helpers.showSnackBar(
          context,
          authProvider.errorMessage!,
          isError: true,
        );
        _clearOtp();
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendOtp(widget.email);
    
    if (mounted) {
      if (success) {
        Helpers.showSnackBar(
          context,
          'New OTP sent successfully! Check your email.',
        );
        _clearOtp();
        _startTimer();
      } else if (authProvider.errorMessage != null) {
        Helpers.showSnackBar(
          context,
          authProvider.errorMessage!,
          isError: true,
        );
      }
    }
  }

  void _clearOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _onOtpChanged(String value, int index) {
    setState(() {}); // Trigger rebuild for visual updates
    
    if (value.isNotEmpty) {
      // Move to next field smoothly
      if (index < 5) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _focusNodes[index + 1].requestFocus();
          }
        });
      } else {
        // All fields filled, wait a moment before auto-verification
        _focusNodes[index].unfocus();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _otpValue.length == 6) {
            _handleVerifyOtp();
          }
        });
      }
    } else {
      // Handle backspace - move to previous field
      if (index > 0 && _otpControllers[index].text.isEmpty) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _focusNodes[index - 1].requestFocus();
            _otpControllers[index - 1].selection = TextSelection.fromPosition(
              TextPosition(offset: _otpControllers[index - 1].text.length),
            );
          }
        });
      }
    }
  }

  void _onOtpBackspace(int index) {
    if (index > 0) {
      _otpControllers[index - 1].clear();
      setState(() {}); // Trigger rebuild for visual updates
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Verify Email',
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.authState == AuthState.loading,
            loadingMessage: 'Verifying OTP...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    const Text(
                      'Enter 6-digit code',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _buildOtpFields(),
                    const SizedBox(height: 30),
                    _buildTimer(),
                    const SizedBox(height: 30),
                    _buildVerifyButton(),
                    const SizedBox(height: 20),
                    _buildResendButton(),
                    const SizedBox(height: 30),
                    _buildChangeEmailButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 44,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verify Your Email',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the verification code we sent to',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.email,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpFields() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 48,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focusNodes[index].hasFocus 
                    ? AppColors.primary 
                    : _otpControllers[index].text.isNotEmpty 
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.divider,
                width: _focusNodes[index].hasFocus ? 2.5 : 1.5,
              ),
              color: _focusNodes[index].hasFocus 
                  ? AppColors.primary.withOpacity(0.05)
                  : Colors.grey[50],
              boxShadow: _focusNodes[index].hasFocus 
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: TextFormField(
              controller: _otpControllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _otpControllers[index].text.isNotEmpty 
                    ? AppColors.primary 
                    : AppColors.textSecondary,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) => _onOtpChanged(value, index),
              onTap: () {
                // Clear and focus for smooth experience
                if (_otpControllers[index].text.isNotEmpty) {
                  _otpControllers[index].clear();
                }
              },
              validator: (value) => null, // Remove validation errors
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text(
          'Code expires in',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formattedTime,
          style: TextStyle(
            color: _remainingTime > 30 ? AppColors.primary : AppColors.error,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return PrimaryButton(
      text: 'Verify Email',
      onPressed: _handleVerifyOtp,
      height: 56,
    );
  }

  Widget _buildResendButton() {
    return SecondaryButton(
      text: _canResend ? 'Resend Code' : 'Resend in $_formattedTime',
      onPressed: _canResend ? _handleResendOtp : null,
      height: 56,
      textColor: _canResend ? AppColors.primary : AppColors.textHint,
      borderColor: _canResend ? AppColors.primary : AppColors.textHint,
    );
  }

  Widget _buildChangeEmailButton() {
    return TextButton(
      onPressed: () {
        context.go('/register');
      },
      child: const Text(
        'Change Email Address',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}