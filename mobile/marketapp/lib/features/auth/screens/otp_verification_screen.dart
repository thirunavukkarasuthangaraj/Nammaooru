import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'dart:async';
import 'dart:ui';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/privacy_policy_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String? phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with CodeAutoFill {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  Timer? _timer;
  int _remainingTime = 120; // 2 minutes
  bool _canResend = false;

  @override
  void codeUpdated() {
    // Called by CodeAutoFill when SMS is read via broadcast receiver
    if (code != null && code!.isNotEmpty) {
      final otpMatch = RegExp(r'\d{6}').firstMatch(code!);
      if (otpMatch != null) {
        _otpController.text = otpMatch.group(0)!;
        setState(() {});
        // Auto-verify after filling
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _otpController.text.length == 6) {
            _handleVerifyOtp();
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Start listening for SMS via broadcast receiver
    listenForCode();
  }

  @override
  void dispose() {
    cancel(); // Stop SMS listener
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
        'Please enter a complete 6-digit OTP',
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Prevent multiple verification attempts
    if (authProvider.authState == AuthState.loading) {
      return;
    }

    final success = await authProvider.verifyOtp(widget.email ?? '', otp);

    if (mounted) {
      if (success) {
        Helpers.showSnackBar(
          context,
          'Account verified successfully! Welcome to NammaOoru!',
        );
        await Future.delayed(const Duration(seconds: 1));
        // Show privacy policy on first login (registration)
        final prefs = await SharedPreferences.getInstance();
        final hasSeenPolicy = prefs.getBool('privacy_policy_seen') ?? false;
        if (!hasSeenPolicy && mounted) {
          await PrivacyPolicyDialog.show(context);
          await prefs.setBool('privacy_policy_seen', true);
        }
        // User is now authenticated, redirect to appropriate dashboard based on role
        // Use context.go() so the ShellRoute (bottom nav) is included
        if (authProvider.isCustomer) {
          context.go('/customer/dashboard');
        } else if (authProvider.isShopOwner) {
          context.go('/shop-owner/dashboard');
        } else if (authProvider.isDeliveryPartner) {
          context.go('/delivery-partner/dashboard');
        } else {
          context.go('/customer/dashboard');
        }
      } else {
        // Show detailed error message
        final errorMessage = authProvider.errorMessage ?? 'OTP verification failed. Please try again.';
        Helpers.showSnackBar(
          context,
          errorMessage,
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
        // Re-start listening for SMS
        listenForCode();
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
          widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty
              ? 'We sent a 6-digit code to +91 ${widget.phoneNumber}'
              : 'We sent a 6-digit code to ${widget.email}',
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
          autofillHints: const [AutofillHints.oneTimeCode],
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
            setState(() {}); // Update UI to show input
            if (value.length == 6) {
              // Auto-verify when all 6 digits are entered
              WidgetsBinding.instance.addPostFrameCallback((_) {
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
