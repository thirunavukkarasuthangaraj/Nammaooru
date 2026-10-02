import '../../../shared/widgets/auth_copy.dart';
import '../../../shared/widgets/privacy_policy_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/language_provider.dart';
import 'otp_verification_screen.dart';

/// Unified phone entry for both login and registration: sends an OTP and
/// lets the backend resolve whether this number already has an account
/// (LOGIN) or not (REGISTRATION) — see AuthProvider.sendAuthOtp(). Hands off
/// to OtpVerificationScreen with whichever purpose was resolved; on success
/// that either logs straight in (LOGIN) or continues to RegisterNameScreen
/// to collect name/email (REGISTRATION, no account exists yet).
class RegisterPhoneScreen extends StatefulWidget {
  const RegisterPhoneScreen({super.key});

  @override
  State<RegisterPhoneScreen> createState() => _RegisterPhoneScreenState();
}

class _RegisterPhoneScreenState extends State<RegisterPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = _phoneController.text.trim();
    final success = await authProvider.sendAuthOtp(phone);
    if (mounted) setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: phone,
            purpose: authProvider.lastAuthPurpose ?? 'REGISTRATION',
          ),
        ),
      );
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: VillageTheme.errorRed,
        ),
      );
    }
  }

  Widget _buildPhoneField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofocus: true,
        autofillHints: const [AutofillHints.telephoneNumber],
        onFieldSubmitted: (_) => _handleSendOtp(),
        onChanged: (value) {
          final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
          if (cleaned.length > 10) {
            _phoneController.text = cleaned.substring(cleaned.length - 10);
            _phoneController.selection = TextSelection.fromPosition(
              TextPosition(offset: _phoneController.text.length),
            );
          } else if (cleaned != value) {
            _phoneController.text = cleaned;
            _phoneController.selection = TextSelection.fromPosition(
              TextPosition(offset: cleaned.length),
            );
          }
          if (cleaned.length == 10) {
            FocusScope.of(context).unfocus();
          }
        },
        style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
        decoration: InputDecoration(
          hintText: authCopy(context, 'Enter mobile number'),
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[500], size: 20),
          border: InputBorder.none,
          counterText: '',
          errorMaxLines: 2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: (value) {
          final digits = (value ?? '').trim().replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.length != 10) {
            return authCopy(context, 'Enter a valid 10-digit phone number');
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
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
                        child: Image.asset('assets/icons/logo-new.png', width: 220),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 56,
                      height: 3,
                      decoration: BoxDecoration(
                        color: VillageTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authCopy(context, 'Everything local, one place'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    authCopy(context, 'Enter your mobile number to continue'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  _buildPhoneField(context),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSendOtp,
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
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  authCopy(context, 'Send OTP'),
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey[600]),
                        children: [
                          TextSpan(text: authCopy(context, 'By continuing, you agree to our ')),
                          TextSpan(
                            text: authCopy(context, 'Terms & Conditions'),
                            style: const TextStyle(
                              color: VillageTheme.primaryGreen,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => PrivacyPolicyDialog.show(context),
                          ),
                          TextSpan(text: authCopy(context, ' and ')),
                          TextSpan(
                            text: authCopy(context, 'Privacy Policy'),
                            style: const TextStyle(
                              color: VillageTheme.primaryGreen,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => PrivacyPolicyDialog.show(context),
                          ),
                        ],
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
}
