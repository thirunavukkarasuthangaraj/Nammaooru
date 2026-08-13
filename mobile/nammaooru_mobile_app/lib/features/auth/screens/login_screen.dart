import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/services/post_login_service.dart';
import '../../../shared/widgets/privacy_policy_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _isLoggingIn) return;

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (success) {
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Initialize post-login essentials (non-blocking)
          PostLoginService().initializePostLogin().then((_) {
            print('Post-login initialization completed');
          }).catchError((error) {
            print('Post-login initialization failed: $error');
          });
          
          await authProvider.refreshAuthState();
          final isNowLoggedIn = authProvider.isAuthenticated;

          if (isNowLoggedIn) {
            // Show privacy policy on first login
            final prefs = await SharedPreferences.getInstance();
            final hasSeenPolicy = prefs.getBool('privacy_policy_seen') ?? false;
            if (!hasSeenPolicy && mounted) {
              await PrivacyPolicyDialog.show(context);
              await prefs.setBool('privacy_policy_seen', true);
            }

            // Check if we can go back (user came from another page)
            if (Navigator.of(context).canPop()) {
              // Return to previous page with success result
              Navigator.of(context).pop(true);
            } else {
              // No previous page, go to dashboard
              context.go('/customer/dashboard');
            }
          } else {
            Helpers.showSnackBar(
              context,
              'Login error: Please try again',
              isError: true,
            );
          }
          
        } else if (authProvider.errorMessage != null) {
          Helpers.showSnackBar(
            context,
            authProvider.errorMessage!,
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/customer/dashboard');
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
              child: Consumer2<AuthProvider, LanguageProvider>(
                builder: (context, authProvider, languageProvider, child) {
                  return LoadingOverlay(
                    isLoading: authProvider.authState == AuthState.loading,
                    loadingMessage: 'Logging in...',
                    child: SingleChildScrollView(
                      child: AutofillGroup(
                        child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildEmailField(),
                                  const SizedBox(height: 12),
                                  _buildPasswordField(),
                                  const SizedBox(height: 8),
                                  _buildRememberMeAndForgotPassword(),
                                  const SizedBox(height: 16),
                                  _buildLoginButton(),
                                  const SizedBox(height: 12),
                                  _buildSignUpLink(),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  );
                },
              ),
    ),
    ),
    );
  }

  Widget _buildHeader() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    // Signature curved green header, matching the dashboard.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 12, 24, 36),
      decoration: const BoxDecoration(
        color: VillageTheme.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.elliptical(200, 40),
          bottomRight: Radius.elliptical(200, 40),
        ),
      ),
      child: Column(
      children: [
        // Language toggle at top-right
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'En',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: languageProvider.showTamil ? FontWeight.w400 : FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => languageProvider.toggleLanguage(),
                  child: Container(
                    width: 36,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnimatedAlign(
                      alignment: languageProvider.showTamil
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'த',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: languageProvider.showTamil ? FontWeight.bold : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 110,
          height: 110,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Image.asset(
            'assets/icons/logo-new.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          languageProvider.getText('Welcome!', 'வரவேற்கிறோம்!'),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          languageProvider.getText('Login to continue', 'தொடர உள்நுழையுங்கள்'),
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          languageProvider.getText('Serving Thirupattur zone', 'திருப்பத்தூர் பகுதிக்கு சேவை'),
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.telephoneNumber],
        onChanged: (value) {
          // Strip country code (+91, 91, 0) and spaces from autofill
          String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
          if (cleaned.length > 10) {
            // Remove leading country code (91)
            if (cleaned.startsWith('91') && cleaned.length >= 12) {
              cleaned = cleaned.substring(cleaned.length - 10);
            } else {
              cleaned = cleaned.substring(cleaned.length - 10);
            }
          }
          if (cleaned != value) {
            _emailController.text = cleaned;
            _emailController.selection = TextSelection.fromPosition(
              TextPosition(offset: cleaned.length),
            );
          }
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your mobile number';
          }
          final digits = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.length != 10) {
            return 'Mobile number must be 10 digits';
          }
          return null;
        },
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
        ),
        decoration: InputDecoration(
          hintText: 'Mobile Number',
          hintStyle: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone, color: Colors.black54, size: 20),
                const SizedBox(width: 6),
                const Text('+91', style: TextStyle(fontSize: 15, color: Color(0xFF2C3E50), fontWeight: FontWeight.w500)),
                Container(width: 1, height: 20, margin: const EdgeInsets.only(left: 8), color: Colors.black26),
              ],
            ),
          ),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          return null;
        },
        onFieldSubmitted: (_) => _handleLogin(),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
        ),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.lock_outlined,
            color: Colors.black54,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.black54,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: VillageTheme.primaryGreen,
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Flexible(
                child: Text(
                  'Remember me',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: TextButton(
            onPressed: () {
              context.push('/forgot-password');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 14,
                color: VillageTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoggingIn ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: VillageTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoggingIn
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                langProvider.getText('Login', 'உள்நுழை'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    return Column(
      children: [
        Text(
          langProvider.getText('New to Namma Ooru Connect?', 'நம்ம ஊரு கனெக்ட்-வில் புதியவரா?'),
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              context.go('/register');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VillageTheme.primaryGreen.withOpacity(0.1),
              foregroundColor: VillageTheme.primaryGreen,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              langProvider.getText('Register', 'பதிவு செய்'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}