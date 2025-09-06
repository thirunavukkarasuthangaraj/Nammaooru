import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/theme/village_theme.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _generateUsername(String fullName) {
    final name = fullName.trim().toLowerCase();
    final parts = name.split(' ');
    
    if (parts.length >= 2) {
      return '${parts[0]}.${parts[parts.length - 1]}';
    } else {
      return parts[0];
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('कृपया नियम और शर्तों को स्वीकार करें / Please accept the terms and conditions'),
          backgroundColor: VillageTheme.errorRed,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final generatedUsername = _generateUsername(_nameController.text);
    
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim(),
      role: 'CUSTOMER',
      username: generatedUsername,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: _emailController.text.trim(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.authState == AuthState.loading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: VillageTheme.primaryGreen,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: VillageTheme.spacingM),
                    Text(
                      '🔄 பதிவு செய்யப்படுகிறது... / Creating Account...',
                      style: VillageTheme.bodyLarge.copyWith(
                        color: VillageTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(VillageTheme.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: VillageTheme.spacingXL),
                    _buildHeader(),
                    const SizedBox(height: VillageTheme.spacingXL),
                    _buildNameField(),
                    const SizedBox(height: VillageTheme.spacingM),
                    _buildEmailField(),
                    const SizedBox(height: VillageTheme.spacingM),
                    _buildPhoneField(),
                    const SizedBox(height: VillageTheme.spacingM),
                    _buildPasswordField(),
                    const SizedBox(height: VillageTheme.spacingM),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: VillageTheme.spacingM),
                    _buildTermsAndConditions(),
                    const SizedBox(height: VillageTheme.spacingXL),
                    _buildRegisterButton(),
                    const SizedBox(height: VillageTheme.spacingL),
                    _buildLoginLink(),
                  ],
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
              Text('📝', style: TextStyle(fontSize: 40)),
              Text('பதிவு', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: VillageTheme.spacingL),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✨ ', style: TextStyle(fontSize: 24)),
            Column(
              children: [
                Text(
                  'புதிய கணக்கு!',
                  style: VillageTheme.headingLarge.copyWith(
                    color: VillageTheme.primaryGreen,
                  ),
                ),
                Text(
                  'Create Account!',
                  style: VillageTheme.headingMedium.copyWith(
                    color: VillageTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: VillageTheme.spacingM),
        Text(
          'உள்ளூர் கடைகளில் இருந்து வாங்க சேருங்கள் / Join to order from local shops',
          style: VillageTheme.bodyLarge.copyWith(
            color: VillageTheme.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: VillageTheme.cardDecoration,
      child: TextFormField(
        controller: _nameController,
        textInputAction: TextInputAction.next,
        style: VillageTheme.bodyLarge,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'कृपया अपना पूरा नाम दर्ज करें / Please enter your full name';
          }
          if (value.trim().length < 2) {
            return 'Name must be at least 2 characters';
          }
          if (!RegExp(r'^[a-zA-Z\s]+\$').hasMatch(value.trim())) {
            return 'Name can only contain letters and spaces';
          }
          if (value.trim().split(' ').length < 2) {
            return 'Please enter both first and last name';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: '👤 முழு பெயர் / Full Name',
          labelStyle: VillageTheme.labelText.copyWith(
            color: VillageTheme.primaryGreen,
          ),
          hintText: 'e.g., राम कुमार / Ram Kumar',
          hintStyle: VillageTheme.bodyMedium.copyWith(
            color: VillageTheme.hintText,
          ),
          prefixIcon: Icon(
            Icons.person_outlined,
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
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: VillageTheme.cardDecoration,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        style: VillageTheme.bodyLarge,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'कृपया अपना ईमेल दर्ज करें / Please enter your email';
          }
          if (!EmailValidator.validate(value)) {
            return 'Please enter a valid email address';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: '📧 மின்னஞ்சல் / Email',
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
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: VillageTheme.cardDecoration,
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        style: VillageTheme.bodyLarge,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'कृपया अपना फोन नंबर दर्ज करें / Please enter your phone number';
          }
          if (value.length < 10) {
            return 'Please enter a valid phone number';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: '📱 தொலைபேசி / Phone Number',
          labelStyle: VillageTheme.labelText.copyWith(
            color: VillageTheme.primaryGreen,
          ),
          hintText: '10 digit mobile number',
          hintStyle: VillageTheme.bodyMedium.copyWith(
            color: VillageTheme.hintText,
          ),
          prefixIcon: Icon(
            Icons.phone_outlined,
            color: VillageTheme.primaryGreen,
            size: VillageTheme.iconMedium,
          ),
          prefixText: '+91 ',
          prefixStyle: VillageTheme.bodyLarge.copyWith(
            color: VillageTheme.primaryGreen,
            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: VillageTheme.cardDecoration,
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        style: VillageTheme.bodyLarge,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'कृपया एक पासवर्ड दर्ज करें / Please enter a password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: '🔐 கடவுச்சொல் / Password',
          labelStyle: VillageTheme.labelText.copyWith(
            color: VillageTheme.primaryGreen,
          ),
          hintText: 'Minimum 6 characters',
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
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: VillageTheme.cardDecoration,
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        textInputAction: TextInputAction.done,
        style: VillageTheme.bodyLarge,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'कृपया अपना पासवर्ड कन्फर्म करें / Please confirm your password';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
        onFieldSubmitted: (_) => _handleRegister(),
        decoration: InputDecoration(
          labelText: '🔒 கடவுச்சொல் உறுதிப்படுத்தல் / Confirm Password',
          labelStyle: VillageTheme.labelText.copyWith(
            color: VillageTheme.primaryGreen,
          ),
          hintText: 'Re-enter your password',
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
              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: VillageTheme.secondaryText,
              size: VillageTheme.iconMedium,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
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
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      decoration: VillageTheme.cardDecoration,
      padding: const EdgeInsets.all(VillageTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.3,
            child: Checkbox(
              value: _acceptTerms,
              onChanged: (value) {
                setState(() {
                  _acceptTerms = value ?? false;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 मैं निम्नलिखित से सहमत हूं:',
                  style: VillageTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: VillageTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: VillageTheme.spacingXS),
                Wrap(
                  children: [
                    Text(
                      'நான் ஒப்புக்கொள்கிறேன் / I agree to the ',
                      style: VillageTheme.bodyMedium.copyWith(
                        color: VillageTheme.secondaryText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Show terms and conditions
                      },
                      child: Text(
                        'Terms & Conditions',
                        style: VillageTheme.bodyMedium.copyWith(
                          color: VillageTheme.accentOrange,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' மற்றும் / and ',
                      style: VillageTheme.bodyMedium.copyWith(
                        color: VillageTheme.secondaryText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Show privacy policy
                      },
                      child: Text(
                        'Privacy Policy',
                        style: VillageTheme.bodyMedium.copyWith(
                          color: VillageTheme.accentOrange,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return VillageWidgets.bigButton(
      text: 'கணக்கு உருவாக்கு / Create Account',
      icon: Icons.person_add,
      onPressed: _handleRegister,
      backgroundColor: VillageTheme.primaryGreen,
    );
  }

  Widget _buildLoginLink() {
    return Container(
      decoration: VillageTheme.cardDecoration,
      padding: const EdgeInsets.all(VillageTheme.spacingM),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🤔 ஏற்கனவே கணக்கு வைத்துள்ளீர்களா? / Already have an account?',
                style: VillageTheme.bodyMedium.copyWith(
                  color: VillageTheme.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: VillageTheme.spacingS),
          TextButton.icon(
            onPressed: () {
              context.go('/login');
            },
            icon: Text('🚪', style: TextStyle(fontSize: 18)),
            label: Text(
              'உள்நுழைய / Sign In',
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
    );
  }
}