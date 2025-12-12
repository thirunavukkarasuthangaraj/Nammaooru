import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/modern_button.dart';
import '../dashboard/main_navigation.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String identifier;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.identifier,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  static String get baseUrl => AppConfig.apiBaseUrl;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': widget.identifier,
          'otp': widget.otp,
          'newPassword': _newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      print('Reset password response: $data');

      if (!mounted) return;

      if (response.statusCode == 200 && data['statusCode'] == '0000') {
        // Password reset successfully
        _showSuccess(data['message'] ?? 'Password reset successfully!');

        // Wait a moment to show success message
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        // Auto login with new credentials
        await _autoLogin();
      } else {
        _showError(data['message'] ?? 'Failed to reset password. Please try again.');
      }
    } catch (e) {
      print('Error resetting password: $e');
      _showError('Network error: Please check your connection');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _autoLogin() async {
    try {
      debugPrint('Auto-login with identifier: ${widget.identifier}');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': widget.identifier,
          'password': _newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('Auto-login response: $data');

      if (!mounted) return;

      if (response.statusCode == 200 && data['statusCode'] == '0000') {
        // Login successful
        final token = data['data']?['accessToken']?.toString() ??
            data['data']?['token']?.toString() ??
            '';

        // Check user role - only SHOP_OWNER allowed
        final String? userRole = data['data']?['role']?.toString();
        debugPrint('User role: $userRole');

        if (userRole != 'SHOP_OWNER') {
          debugPrint('Access denied: User role is not SHOP_OWNER');
          if (!mounted) return;
          _showError('Access Denied: This app is only for shop owners.');

          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;

          int count = 0;
          Navigator.of(context).popUntil((route) {
            count++;
            return count == 3;
          });
          return;
        }

        // Save token and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_data', jsonEncode(data['data']));

        debugPrint('Token saved, navigating to dashboard...');

        // Small delay to ensure state is saved
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        // Navigate to dashboard and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainNavigation(
              userName: data['data']['username'] ?? 'Shop Owner',
              token: token,
            ),
          ),
          (route) => false,
        );
      } else {
        debugPrint('Auto-login failed: ${data['message']}');
        if (!mounted) return;
        _showError('Password reset successful. Please login manually.');

        // Navigate back to login screen
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        int count = 0;
        Navigator.of(context).popUntil((route) {
          count++;
          return count == 3;
        });
      }
    } catch (e) {
      debugPrint('Error during auto-login: $e');
      if (!mounted) return;
      _showError('Password reset successful. Please login manually.');

      // Navigate back to login screen
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      int count = 0;
      Navigator.of(context).popUntil((route) {
        count++;
        return count == 3;
      });
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
        title: const Text('Reset Password'),
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
                      Icons.lock_open,
                      size: 48,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Text('Create New Password', style: AppTheme.h2),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Enter your new password below',
                    style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.space48),

                  // New Password field
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter new password',
                      prefixIcon: const Icon(Icons.lock, color: AppTheme.primary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Confirm Password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter new password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Reset Password button
                  ModernButton(
                    text: 'Reset Password',
                    icon: Icons.check_circle,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    fullWidth: true,
                    useGradient: true,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _resetPassword,
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Back button
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
