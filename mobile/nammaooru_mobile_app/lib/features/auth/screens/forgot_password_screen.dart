import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../providers/forgot_password_provider.dart';
import '../../../core/auth/auth_provider.dart';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Timer? _timer;
  int _resendTimer = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendTimer--;
      });

      if (_resendTimer <= 0) {
        timer.cancel();
      }
    });
  }

  void _cleanPhone(String value) {
    String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length > 10) {
      cleaned = cleaned.substring(cleaned.length - 10);
    }
    if (cleaned != value) {
      _emailController.text = cleaned;
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: cleaned.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          final provider = Provider.of<ForgotPasswordProvider>(context, listen: false);
          if (provider.currentStep != ForgotPasswordStep.email) {
            provider.goBack();
          } else {
            context.go('/login');
          }
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
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
                child: Consumer<ForgotPasswordProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getLoadingMessage(provider.currentStep),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return Center(
                      child: SingleChildScrollView(
                        child: Container(
                          margin: const EdgeInsets.all(24.0),
                          padding: const EdgeInsets.all(28.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _buildCurrentStep(provider),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLoadingMessage(ForgotPasswordStep step) {
    switch (step) {
      case ForgotPasswordStep.email:
        return 'Sending OTP...';
      case ForgotPasswordStep.otp:
        return 'Verifying OTP...';
      case ForgotPasswordStep.password:
        return 'Resetting password...';
    }
  }

  Widget _buildCurrentStep(ForgotPasswordProvider provider) {
    switch (provider.currentStep) {
      case ForgotPasswordStep.email:
        return _buildEmailStep(provider);
      case ForgotPasswordStep.otp:
        return _buildOtpStep(provider);
      case ForgotPasswordStep.password:
        return _buildPasswordStep(provider);
    }
  }

  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E93),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53E3E), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 16),
      prefixIcon: Icon(icon, color: Colors.black54, size: 20),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      counterText: '',
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  // ---- Step 1: Phone number ----
  Widget _buildEmailStep(ForgotPasswordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          'Forgot Password',
          'Enter your mobile number to receive a verification code.',
          Icons.phone_outlined,
        ),
        const SizedBox(height: 32),
        Form(
          key: _emailFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                onChanged: _cleanPhone,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter your mobile number';
                  final digits = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length != 10) return 'Mobile number must be 10 digits';
                  return null;
                },
                decoration: _inputDecoration(hint: 'Mobile Number', icon: Icons.phone),
              ),
              const SizedBox(height: 24),
              _buildButton('Send Verification Code', () => _sendOtp(provider)),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBox(provider.errorMessage!),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Login', style: TextStyle(color: Color(0xFF666666))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Step 2: OTP → verify + set dummy password + auto-login → dashboard ----
  Widget _buildOtpStep(ForgotPasswordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          'Verify Code',
          'We sent a 6-digit code to\n+91 ${provider.email}',
          Icons.verified_user_outlined,
        ),
        const SizedBox(height: 32),
        Form(
          key: _otpFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter the code';
                  if (value.length != 6) return 'Code must be 6 digits';
                  return null;
                },
                decoration: _inputDecoration(hint: '------', icon: Icons.pin_outlined),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => provider.goBack(),
                    child: const Text('Change Number', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: _resendTimer > 0 ? null : () => _resendOtp(provider),
                    child: Text(
                      _resendTimer > 0 ? 'Resend in ${_resendTimer}s' : 'Resend Code',
                      style: TextStyle(
                        color: _resendTimer > 0 ? const Color(0xFF999999) : const Color(0xFF2196F3),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildButton('Verify & Login', () => _verifyAndLogin(provider)),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBox(provider.errorMessage!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ---- Step 3: New Password ----
  Widget _buildPasswordStep(ForgotPasswordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          'New Password',
          'Enter your new password.',
          Icons.lock_reset_outlined,
        ),
        const SizedBox(height: 32),
        Form(
          key: _passwordFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _resetPassword(provider),
                style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a password';
                  if (value.length < 4) return 'Password must be at least 4 characters';
                  return null;
                },
                decoration: _inputDecoration(
                  hint: 'New Password (min 4 chars)',
                  icon: Icons.lock_outlined,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF666666), size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildButton('Update Password', () => _resetPassword(provider)),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBox(provider.errorMessage!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _verifyAndLogin(ForgotPasswordProvider provider) async {
    if (_otpFormKey.currentState!.validate()) {
      final success = await provider.verifyAndResetWithDummyPassword(_otpController.text.trim());

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verified! Logging you in...'), backgroundColor: Color(0xFF4CAF50)),
        );

        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        // Auto-login with dummy password (mobile number)
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        try {
          final loginSuccess = await authProvider.login(
            provider.email, // mobile number
            provider.dummyPassword, // mobile number as password
          );

          if (!mounted) return;

          if (loginSuccess) {
            context.go(authProvider.getHomeRoute());
          } else {
            context.go('/login');
          }
        } catch (_) {
          if (!mounted) return;
          context.go('/login');
        }
      }
    }
  }

  void _sendOtp(ForgotPasswordProvider provider) async {
    if (_emailFormKey.currentState!.validate()) {
      final success = await provider.sendOtp(_emailController.text.trim());
      if (mounted && success) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent!'), backgroundColor: Color(0xFF4CAF50)),
        );
      }
    }
  }

  void _verifyOtp(ForgotPasswordProvider provider) async {
    if (_otpFormKey.currentState!.validate()) {
      final success = await provider.verifyOtp(_otpController.text.trim());
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code verified!'), backgroundColor: Color(0xFF4CAF50)),
        );
      }
    }
  }

  void _resetPassword(ForgotPasswordProvider provider) async {
    if (_passwordFormKey.currentState!.validate()) {
      final success = await provider.resetPassword(
        _otpController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated! Logging you in...'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 1),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        try {
          final loginSuccess = await authProvider.login(
            provider.email,
            _passwordController.text,
          );

          if (!mounted) return;

          if (loginSuccess) {
            await Future.delayed(const Duration(milliseconds: 300));
            if (!mounted) return;
            context.go(authProvider.getHomeRoute());
          } else {
            context.go('/login');
          }
        } catch (_) {
          if (!mounted) return;
          context.go('/login');
        }
      }
    }
  }

  void _resendOtp(ForgotPasswordProvider provider) async {
    final success = await provider.resendOtp();
    if (mounted && success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code sent again!'), backgroundColor: Color(0xFF4CAF50)),
      );
    }
  }
}
