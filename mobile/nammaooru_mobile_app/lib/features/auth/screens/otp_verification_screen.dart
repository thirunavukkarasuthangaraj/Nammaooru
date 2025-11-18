import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:ui';
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
  final _otpController = TextEditingController();

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
    _otpController.dispose();
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
    return _otpController.text;
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

    final success = await authProvider.verifyOtp(widget.email ?? '', otp);

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
          context.pushReplacement(
              '/customer/dashboard'); // Default to customer dashboard
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
    final success = await authProvider.resendOtp(widget.email ?? '');

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
    _otpController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
            SafeArea(
              child: Consumer<AuthProvider>(
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
                            const SizedBox(height: 40),
                            _buildHeader(),
                            const SizedBox(height: 40),
                            const Text(
                              'Enter 6-digit code',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verify Your Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'We sent a 6-digit code to ${widget.email}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtpFields() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: '• • • • • •',
            hintStyle: TextStyle(
              letterSpacing: 8,
              color: Color(0xFFE0E0E0),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter OTP';
            }
            if (value.length != 6) {
              return 'OTP must be 6 digits';
            }
            return null;
          },
          onChanged: (value) {
            if (value.length == 6) {
              // Auto-verify when all 6 digits are entered
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && _otpValue.length == 6) {
                  _handleVerifyOtp();
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text(
          'Code expires in',
          style: TextStyle(
            color: Colors.black,
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
      text: 'Verify OTP',
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
        'Change Mobile number',
        style: TextStyle(
          color: Colors.black,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
