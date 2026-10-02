import '../../../shared/widgets/auth_copy.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/village_theme.dart';
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
                    authCopy(context, "What's your name?"),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    authCopy(context, 'Mobile number verified'),
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
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      maxLength: 50,
                      autofocus: true,
                      autofillHints: const [AutofillHints.name],
                      onFieldSubmitted: (_) => _handleNext(),
                      style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
                      decoration: InputDecoration(
                        hintText: authCopy(context, 'Full Name'),
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.person_outlined, color: Colors.grey[500], size: 20),
                        border: InputBorder.none,
                        counterText: '',
                        errorMaxLines: 2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            authCopy(context, 'Next'),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
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
