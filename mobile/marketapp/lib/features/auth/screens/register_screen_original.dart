import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/validators.dart';
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

  String _generateUsername(String name) {
    final cleanName = name.trim().toLowerCase().replaceAll(' ', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '${cleanName}_$timestamp';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please accept the terms and conditions'),
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
      backgroundColor: Colors.white,
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
                      'Creating Account...',
                      style: VillageTheme.bodyLarge.copyWith(
                        color: VillageTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildTabButtons(),
                    const SizedBox(height: 24),
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPhoneField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 16),
                    _buildTermsAndConditions(),
                    const SizedBox(height: 24),
                    _buildRegisterButton(),
                    const SizedBox(height: 16),
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

  Widget _buildTabButtons() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                context.go('/login');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text(
                  'Sign In',
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
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ),
        ],
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
          'Create Account!',
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

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _nameController,
        textInputAction: TextInputAction.next,
        validator: Validators.validateName,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
        ),
        decoration: InputDecoration(
          hintText: 'Enter your full name',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.person_outlined,
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
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!EmailValidator.validate(value)) {
            return 'Please enter a valid email address';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Enter your email address',
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

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          if (value.length < 10) {
            return 'Please enter a valid phone number';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Enter your phone number',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.phone_outlined,
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
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Eg: Pass@000',
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

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
        onFieldSubmitted: (_) => _handleRegister(),
        decoration: InputDecoration(
          hintText: 'Confirm your password',
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
              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.grey[600],
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
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
                  '📋 I agree to the following:',
                  style: VillageTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: VillageTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: VillageTheme.spacingXS),
                Wrap(
                  children: [
                    Text(
                      'I agree to the ',
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
                      ' and ',
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
        onPressed: _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF7F8C8D),
          ),
        ),
        TextButton(
          onPressed: () {
            context.go('/login');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign In',
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