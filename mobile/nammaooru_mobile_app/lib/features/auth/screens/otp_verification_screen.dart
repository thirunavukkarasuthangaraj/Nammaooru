import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'dart:async';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/auth_copy.dart';
import '../../../shared/widgets/customer_auth_header.dart';
import '../../../shared/widgets/privacy_policy_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_name_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  // 'REGISTRATION' — no account exists yet; on success, continue to the
  //   name/email steps rather than logging in.
  // 'LOGIN' — an account already exists; on success, log straight in.
  final String purpose;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.purpose = 'REGISTRATION',
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

    final isRegistration = widget.purpose == 'REGISTRATION';
    final success = isRegistration
        ? await authProvider.verifyRegistrationOtp(widget.phoneNumber, otp)
        : await authProvider.verifyOtp(widget.phoneNumber, otp, purpose: widget.purpose);

    if (mounted) {
      if (success) {
        if (isRegistration) {
          // No account yet — continue to the name step, nothing to route to.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RegisterNameScreen(phoneNumber: widget.phoneNumber),
            ),
          );
          return;
        }

        Helpers.showSnackBar(
          context,
          'Welcome back!',
        );
        await Future.delayed(const Duration(seconds: 1));
        final prefs = await SharedPreferences.getInstance();
        final hasSeenPolicy = prefs.getBool('privacy_policy_seen') ?? false;
        if (!hasSeenPolicy && mounted) {
          await PrivacyPolicyDialog.show(context);
          await prefs.setBool('privacy_policy_seen', true);
        }
        // User is now authenticated, redirect to appropriate dashboard based on role
        // Use context.go() so the ShellRoute (bottom nav) is included
        if (!mounted) return;
        if (authProvider.isCustomer || authProvider.isShopOwner) {
          context.go('/customer/dashboard');
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
    final success = widget.purpose == 'REGISTRATION'
        ? await authProvider.sendRegistrationOtp(widget.phoneNumber)
        : await authProvider.resendOtp(widget.phoneNumber, purpose: widget.purpose);

    if (mounted) {
      if (success) {
        Helpers.showSnackBar(
          context,
          'New OTP sent successfully! Check your phone.',
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
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return LoadingOverlay(
              isLoading: authProvider.authState == AuthState.loading,
              loadingMessage: authCopy(context, 'Verifying OTP...'),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomerAuthHeader(
                        title: authCopy(context, 'Verify your number'),
                        subtitle: authCopy(context, 'We sent a 6-digit code to') +
                            ' +91 ${widget.phoneNumber}',
                        languageLabel: lang.showTamil ? 'English' : 'தமிழ்',
                        onLanguageChanged: () => lang.toggleLanguage(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildOtpFields(),
                                  const SizedBox(height: 20),
                                  Center(child: _buildTimer()),
                                  const SizedBox(height: 24),
                                  _buildVerifyButton(authProvider.authState == AuthState.loading),
                                  const SizedBox(height: 12),
                                  _buildResendButton(),
                                  const SizedBox(height: 16),
                                  _buildChangeNumberButton(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        autofocus: true,
        autofillHints: const [AutofillHints.oneTimeCode],
        style: const TextStyle(
          fontSize: 22,
          letterSpacing: 10,
          fontWeight: FontWeight.bold,
          color: VillageTheme.primaryGreen,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          hintText: '• • • • • •',
          hintStyle: const TextStyle(letterSpacing: 10, color: Color(0xFFB0BEC5)),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return authCopy(context, 'Please enter OTP');
          }
          if (value.length != 6) {
            return authCopy(context, 'OTP must be 6 digits');
          }
          return null;
        },
        onChanged: (value) {
          setState(() {});
          if (value.length == 6) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _otpValue.length == 6) {
                _handleVerifyOtp();
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text(
          authCopy(context, 'Code expires in'),
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          _formattedTime,
          style: TextStyle(
            color: _remainingTime > 30 ? VillageTheme.primaryGreen : VillageTheme.errorRed,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleVerifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                authCopy(context, 'Verify OTP'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildResendButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _canResend ? _handleResendOtp : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _canResend ? VillageTheme.primaryGreen : Colors.grey[300]!,
            width: 2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          _canResend
              ? authCopy(context, 'Resend Code')
              : '${authCopy(context, 'Resend in')} $_formattedTime',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _canResend ? VillageTheme.primaryGreen : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeNumberButton() {
    return Center(
      child: TextButton(
        onPressed: () => context.go('/register'),
        child: Text(
          authCopy(context, 'Change Mobile number'),
          style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
