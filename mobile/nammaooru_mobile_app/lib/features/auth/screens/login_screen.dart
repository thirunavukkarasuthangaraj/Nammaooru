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
      backgroundColor: VillageTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<AuthProvider, LanguageProvider>(
          builder: (context, authProvider, languageProvider, child) {
            return LoadingOverlay(
              isLoading: authProvider.authState == AuthState.loading,
              loadingMessage: 'Logging in...',
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: VillageTheme.spacingXL),
                      _buildHeader(),
                      const SizedBox(height: VillageTheme.spacingXL),
                      _buildEmailField(),
                      const SizedBox(height: VillageTheme.spacingM),
                      _buildPasswordField(),
                      const SizedBox(height: VillageTheme.spacingM),
                      _buildRememberMeAndForgotPassword(),
                      const SizedBox(height: VillageTheme.spacingL),
                      _buildLoginButton(),
                      const SizedBox(height: VillageTheme.spacingL),
                      _buildSignUpLink(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: VillageTheme.primaryGradient,
            borderRadius: BorderRadius.circular(VillageTheme.cardRadius * 2),
            boxShadow: VillageTheme.buttonShadow,
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🏪', style: TextStyle(fontSize: 40)),
              Text('கடை', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: VillageTheme.spacingL),
        Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🙏 ', style: TextStyle(fontSize: 24)),
                Column(
                  children: [
                    Text(
                      languageProvider.welcome,
                      style: VillageTheme.headingLarge.copyWith(
                        color: VillageTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      languageProvider.getText('Welcome Back!', 'மீண்டும் வரவேற்கிறோம்!'),
                      style: VillageTheme.headingMedium.copyWith(
                        color: VillageTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: VillageTheme.spacingM),
        Text(
          'உள்நுழையுங்கள் / Sign in to continue',
          style: VillageTheme.bodyLarge.copyWith(
            color: VillageTheme.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: VillageTheme.cardDecoration,
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.validateEmail,
            style: VillageTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: languageProvider.getText('📧 Email', '📧 மின்னஞ்சல்'),
              labelStyle: VillageTheme.labelText.copyWith(
                color: VillageTheme.primaryGreen,
              ),
          hintText: 'example@email.com',
          hintStyle: VillageTheme.bodyMedium.copyWith(
            color: VillageTheme.hintText,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: VillageTheme.primaryGreen,
            size: VillageTheme.iconMedium,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
            borderSide: BorderSide(color: VillageTheme.primaryGreen.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
            borderSide: BorderSide(color: VillageTheme.primaryGreen.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
            borderSide: BorderSide(color: VillageTheme.primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
            borderSide: BorderSide(color: VillageTheme.errorRed, width: 2),
          ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
                borderSide: BorderSide(color: VillageTheme.errorRed, width: 2),
              ),
              filled: true,
              fillColor: VillageTheme.cardBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: VillageTheme.spacingM,
                vertical: VillageTheme.spacingM,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: VillageTheme.cardDecoration,
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: Validators.validatePassword,
            onFieldSubmitted: (_) => _handleLogin(),
            style: VillageTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: languageProvider.getText('🔒 Password', '🔒 கடவுச்சொல்'),
              labelStyle: VillageTheme.labelText.copyWith(
                color: VillageTheme.primaryGreen,
              ),
          hintText: 'Enter your password',
          hintStyle: VillageTheme.bodyMedium.copyWith(
            color: VillageTheme.hintText,
          ),
          prefixIcon: Icon(
            Icons.lock_outlined,
            color: VillageTheme.primaryGreen,
            size: VillageTheme.iconMedium,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: VillageTheme.secondaryText,
              size: VillageTheme.iconMedium,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
            borderSide: BorderSide(color: VillageTheme.primaryGreen.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
            borderSide: BorderSide(color: VillageTheme.primaryGreen.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
            borderSide: BorderSide(color: VillageTheme.primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
            borderSide: BorderSide(color: VillageTheme.errorRed, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
            borderSide: BorderSide(color: VillageTheme.errorRed, width: 2),
          ),
              filled: true,
              fillColor: VillageTheme.cardBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: VillageTheme.spacingM,
                vertical: VillageTheme.spacingM,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Column(
      children: [
        Container(
          decoration: VillageTheme.cardDecoration,
          padding: const EdgeInsets.symmetric(
            horizontal: VillageTheme.spacingM,
            vertical: VillageTheme.spacingS,
          ),
          child: Row(
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: VillageTheme.primaryGreen,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: VillageTheme.spacingS),
              Expanded(
                child: Text(
                  '🤝 நினைவில் வைத்துக்கொள் / Remember me',
                  style: VillageTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VillageTheme.spacingS),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              context.push('/forgot-password');
            },
            icon: Text('🔑', style: TextStyle(fontSize: 16)),
            label: Text(
              'கடவுச்சொல் மறந்தீர்களா? / Forgot Password?',
              style: VillageTheme.bodyMedium.copyWith(
                color: VillageTheme.accentOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: VillageTheme.spacingS,
                vertical: VillageTheme.spacingXS,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return VillageWidgets.bigButton(
          text: _isLoggingIn 
            ? languageProvider.getText('Signing In...', 'உள்நுழைகிறோம்...') 
            : languageProvider.login,
          icon: Icons.login,
          onPressed: _handleLogin,
          isLoading: _isLoggingIn,
          backgroundColor: VillageTheme.primaryGreen,
        );
      },
    );
  }


  Widget _buildSignUpLink() {
    return Column(
      children: [
        Container(
          decoration: VillageTheme.cardDecoration,
          padding: const EdgeInsets.all(VillageTheme.spacingM),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '👋 புதிதாக வருகிறீர்களா? / New to NammaOoru?',
                    style: VillageTheme.bodyMedium.copyWith(
                      color: VillageTheme.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VillageTheme.spacingS),
              TextButton.icon(
                onPressed: () {
                  context.go('/register');
                },
                icon: Text('📝', style: TextStyle(fontSize: 18)),
                label: Text(
                  'கணக்கு உருவாக்க / Create Account',
                  style: VillageTheme.bodyLarge.copyWith(
                    color: VillageTheme.accentOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: VillageTheme.accentOrange.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: VillageTheme.spacingL,
                    vertical: VillageTheme.spacingS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VillageTheme.spacingM),
        Container(
          padding: const EdgeInsets.all(VillageTheme.spacingM),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VillageTheme.primaryGreen.withOpacity(0.05),
                VillageTheme.lightGreen.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
            border: Border.all(
              color: VillageTheme.primaryGreen.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ℹ️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: VillageTheme.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'கடை உரிமையாளர்கள் மற்றும் டெலிவரி பார்ட்னர்கள்:',
                      style: VillageTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: VillageTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: VillageTheme.spacingXS),
                    Text(
                      'Shop owners and delivery partners: Use your company-provided credentials to sign in',
                      style: VillageTheme.bodySmall.copyWith(
                        color: VillageTheme.primaryGreen,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}