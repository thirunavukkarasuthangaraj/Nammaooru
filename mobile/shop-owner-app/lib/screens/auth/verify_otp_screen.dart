import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/modern_button.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String identifier;

  const VerifyOtpScreen({
    super.key,
    required this.identifier,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  static String get baseUrl => AppConfig.apiBaseUrl;

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': widget.identifier,
          'otp': _otpController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      print('Verify OTP response: $data');

      if (!mounted) return;

      if (response.statusCode == 200 && data['statusCode'] == '0000') {
        // OTP verified successfully
        _showSuccess(data['message'] ?? 'OTP verified successfully!');

        // Navigate to reset password screen
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              identifier: widget.identifier,
              otp: _otpController.text.trim(),
            ),
          ),
        );
      } else {
        _showError(data['message'] ?? 'Invalid OTP. Please try again.');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      _showError('Network error: Please check your connection');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': widget.identifier,
        }),
      );

      final data = jsonDecode(response.body);
      print('Resend OTP response: $data');

      if (!mounted) return;

      if (response.statusCode == 200 && data['statusCode'] == '0000') {
        _showSuccess(data['message'] ?? 'OTP resent successfully!');
      } else {
        _showError(data['message'] ?? 'Failed to resend OTP. Please try again.');
      }
    } catch (e) {
      print('Error resending OTP: $e');
      _showError('Network error: Please check your connection');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                      boxShadow: AppTheme.shadowLarge,
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      size: 48,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Text('Enter OTP', style: AppTheme.h2),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Enter the 6-digit OTP sent to\n${widget.identifier}',
                    style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.space48),

                  // OTP field
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: 'OTP',
                      hintText: '000000',
                      prefixIcon: const Icon(Icons.pin, color: AppTheme.primary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the OTP';
                      }
                      if (value.length != 6) {
                        return 'OTP must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Verify OTP button
                  ModernButton(
                    text: 'Verify OTP',
                    icon: Icons.check_circle,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    fullWidth: true,
                    useGradient: true,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _verifyOtp,
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Resend OTP button
                  TextButton.icon(
                    onPressed: _isResending ? null : _resendOtp,
                    icon: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          )
                        : const Icon(Icons.refresh, color: AppTheme.primary),
                    label: Text(
                      _isResending ? 'Resending...' : 'Resend OTP',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),

                  // Back to forgot password
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
