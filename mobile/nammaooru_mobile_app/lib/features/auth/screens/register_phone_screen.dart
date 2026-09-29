import '../../../shared/widgets/auth_copy.dart';
import '../../../shared/widgets/customer_auth_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/language_provider.dart';
import 'otp_verification_screen.dart';

/// Registration step 1 of 3: just the phone number. Sends an OTP and hands
/// off to OtpVerificationScreen(purpose: 'REGISTRATION'), which on success
/// continues to RegisterNameScreen — no account exists yet at this point.
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
    final success = await authProvider.sendRegistrationOtp(phone);
    if (mounted) setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: phone,
            purpose: 'REGISTRATION',
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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomerAuthHeader(
                  title: authCopy(context, 'Create account'),
                  subtitle: authCopy(context, "Let's start with your mobile number"),
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
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          maxLength: 10,
                          autofocus: true,
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
                          },
                          style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
                          decoration: InputDecoration(
                            labelText: authCopy(context, 'Phone Number'),
                            prefixIcon: const Icon(Icons.phone_outlined, color: Colors.black54, size: 20),
                            border: InputBorder.none,
                            counterText: '',
                            errorMaxLines: 2,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            final digits = (value ?? '').trim().replaceAll(RegExp(r'[^0-9]'), '');
                            if (digits.length != 10) {
                              return authCopy(context, 'Enter a valid 10-digit phone number');
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
                          onPressed: _isSubmitting ? null : _handleSendOtp,
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
                                  authCopy(context, 'Send OTP'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
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
    );
  }
}
