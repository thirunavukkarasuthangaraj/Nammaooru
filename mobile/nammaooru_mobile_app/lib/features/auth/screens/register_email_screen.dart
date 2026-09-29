import '../../../shared/widgets/auth_copy.dart';
import '../../../shared/widgets/customer_auth_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/language_provider.dart';
import '../../../shared/widgets/privacy_policy_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registration step 3 of 3 (final): optional email, then create the account.
/// Phone is already OTP-verified, so this call activates and logs in
/// immediately — no further OTP round.
class RegisterEmailScreen extends StatefulWidget {
  final String phoneNumber;
  final String name;
  const RegisterEmailScreen({super.key, required this.phoneNumber, required this.name});

  @override
  State<RegisterEmailScreen> createState() => _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends State<RegisterEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _generateUsername(String name) {
    final cleanName = name.trim().toLowerCase().replaceAll(' ', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '${cleanName}_$timestamp';
  }

  // Account is verified and logged into by phone OTP, not a password the
  // user chose — generate one server never needs to show them.
  String _generateRandomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%';
    final rand = Random.secure();
    return List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();

    final success = await authProvider.completeRegistration(
      name: widget.name,
      email: email.isEmpty ? null : email,
      phoneNumber: widget.phoneNumber,
      password: _generateRandomPassword(),
      username: _generateUsername(widget.name),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenPolicy = prefs.getBool('privacy_policy_seen') ?? false;
      if (!hasSeenPolicy && mounted) {
        await PrivacyPolicyDialog.show(context);
        await prefs.setBool('privacy_policy_seen', true);
      }
      if (mounted) context.go('/customer/dashboard');
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: VillageTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: AutofillGroup(
              child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomerAuthHeader(
                    title: authCopy(context, 'Almost there!'),
                    subtitle: authCopy(context, 'Add your email if you\'d like (optional)'),
                    languageLabel: lang.showTamil ? 'English' : 'தமிழ்',
                    onLanguageChanged: () => lang.toggleLanguage(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEFF1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            maxLength: 100,
                            autofocus: true,
                            autofillHints: const [AutofillHints.email],
                            onFieldSubmitted: (_) => _handleCreateAccount(),
                            style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
                            decoration: InputDecoration(
                              labelText: authCopy(context, 'Email (optional)'),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54, size: 20),
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              if (!value.contains('@') || !value.contains('.')) {
                                return authCopy(context, 'Please enter a valid email');
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleCreateAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    authCopy(context, 'Create Account'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isSubmitting ? null : _handleCreateAccount,
                          child: Text(
                            authCopy(context, 'Skip for now'),
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
