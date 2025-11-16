import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/modern_button.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isLoading = false;

  static String get baseUrl => AppConfig.apiBaseUrl;

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': _identifierController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      print('Send OTP response: $data');

      if (!mounted) return;

      if (response.statusCode == 200 && data['statusCode'] == '0000') {
        // OTP sent successfully
        _showSuccess(data['message'] ?? 'OTP sent successfully!');

        // Navigate to OTP verification screen
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(
              identifier: _identifierController.text.trim(),
            ),
          ),
        );
      } else {
        _showError(data['message'] ?? 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      print('Error sending OTP: $e');
      _showError('Network error: Please check your connection');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        title: const Text('Forgot Password'),
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
                      Icons.lock_reset,
                      size: 48,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Text('Reset Password', style: AppTheme.h2),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Enter your mobile number or email to receive an OTP',
                    style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.space48),

                  // Mobile Number or Email field
                  TextFormField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number or Email',
                      hintText: 'Enter mobile number or email',
                      prefixIcon: const Icon(Icons.person, color: AppTheme.primary),
                      filled: true,
                      fillColor: AppTheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number or email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Send OTP button
                  ModernButton(
                    text: 'Send OTP',
                    icon: Icons.send,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    fullWidth: true,
                    useGradient: true,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _sendOtp,
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Back to login
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Login',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primary,
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
    _identifierController.dispose();
    super.dispose();
  }
}
