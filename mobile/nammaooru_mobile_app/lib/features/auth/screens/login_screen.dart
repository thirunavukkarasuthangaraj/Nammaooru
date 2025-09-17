import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/services/post_login_service.dart';

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
            context.go('/customer/dashboard');
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B5A96),
              Color(0xFF6B4F72),
              Color(0xFF5D4E75),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer2<AuthProvider, LanguageProvider>(
            builder: (context, authProvider, languageProvider, child) {
              return LoadingOverlay(
                isLoading: authProvider.authState == AuthState.loading,
                loadingMessage: 'Logging in...',
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.all(24.0),
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 32),
                            _buildTabButtons(),
                            const SizedBox(height: 24),
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            _buildPasswordField(),
                            const SizedBox(height: 12),
                            _buildRememberMeAndForgotPassword(),
                            const SizedBox(height: 24),
                            _buildLoginButton(),
                            const SizedBox(height: 16),
                            _buildSignUpLink(),
                            const SizedBox(height: 20),
                            _buildBusinessPartnersSection(),
                          ],
                        ),
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
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: VillageTheme.primaryGreen,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: VillageTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.home,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Join NammaOoru',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF7F8C8D),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Connect with your local community',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF95A5A6),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: Validators.validateEmail,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
        ),
        decoration: InputDecoration(
          hintText: 'Enter your email',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Colors.grey[600],
            size: 20,
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

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        validator: Validators.validatePassword,
        onFieldSubmitted: (_) => _handleLogin(),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
        ),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.lock_outlined,
            color: Colors.grey[600],
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.grey[600],
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
      children: [
        Row(
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
            const Text(
              'Remember me',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            context.push('/forgot-password');
          },
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 14,
              color: VillageTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [VillageTheme.primaryGreen, Color(0xFF45A049)],
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoggingIn ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoggingIn
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }


  Widget _buildTabButtons() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Sign In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                context.go('/register');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF95A5A6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessPartnersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: VillageTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.business,
              color: VillageTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'For Business Partners: Use your company-provided credentials to sign in',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7F8C8D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'New to NammaOoru? ',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF7F8C8D),
          ),
        ),
        TextButton(
          onPressed: () {
            context.go('/register');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 14,
              color: VillageTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}