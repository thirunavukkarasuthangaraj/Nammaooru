import '../../../shared/widgets/auth_copy.dart';
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
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: () => lang.toggleLanguage(),
                        style: TextButton.styleFrom(
                          foregroundColor: VillageTheme.primaryGreen,
                          backgroundColor: VillageTheme.primaryGreen.withOpacity(0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(lang.showTamil ? 'English' : 'தமிழ்'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 0.63,
                          child: Image.asset('assets/icons/logo-new.png', width: 150),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: lang.showTamil ? 'நம்ம ஊரு' : 'Namma Ooru',
                            style: const TextStyle(color: Color(0xFF4CAF50)),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: lang.showTamil ? 'கனெக்ட்' : 'Connect',
                            style: const TextStyle(color: Color(0xFF2196F3)),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: VillageTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      authCopy(context, 'Almost there!'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      authCopy(context, 'Add your email if you\'d like (optional)'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFFDDE3E8)),
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
                          hintText: authCopy(context, 'Email (optional)'),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500], size: 20),
                          border: InputBorder.none,
                          counterText: '',
                          errorMaxLines: 2,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleCreateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                authCopy(context, 'Create Account'),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
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
