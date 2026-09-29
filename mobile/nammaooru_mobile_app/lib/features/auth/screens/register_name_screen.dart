import '../../../shared/widgets/auth_copy.dart';
import '../../../shared/widgets/customer_auth_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_provider.dart';
import 'register_email_screen.dart';

/// Registration step 2 of 3: just the name. Phone is already verified at
/// this point (OtpVerificationScreen completed) — nothing to send yet.
class RegisterNameScreen extends StatefulWidget {
  final String phoneNumber;
  const RegisterNameScreen({super.key, required this.phoneNumber});

  @override
  State<RegisterNameScreen> createState() => _RegisterNameScreenState();
}

class _RegisterNameScreenState extends State<RegisterNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterEmailScreen(
          phoneNumber: widget.phoneNumber,
          name: _nameController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
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
                  title: authCopy(context, "What's your name?"),
                  subtitle: authCopy(context, 'Mobile number verified'),
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
                          controller: _nameController,
                          textInputAction: TextInputAction.done,
                          maxLength: 50,
                          autofocus: true,
                          autofillHints: const [AutofillHints.name],
                          onFieldSubmitted: (_) => _handleNext(),
                          style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
                          decoration: InputDecoration(
                            labelText: authCopy(context, 'Full Name'),
                            prefixIcon: const Icon(Icons.person_outlined, color: Colors.black54, size: 20),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return authCopy(context, 'Please enter your name');
                            }
                            if (value.trim().length < 2) {
                              return authCopy(context, 'Name must be at least 2 characters');
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
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            authCopy(context, 'Next'),
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
      ),
    );
  }
}
