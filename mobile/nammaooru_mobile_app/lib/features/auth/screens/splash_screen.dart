import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../shared/widgets/loading_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthStatus();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  void _checkAuthStatus() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      // First launch: show language selection
      final prefs = await SharedPreferences.getInstance();
      final languageSelected = prefs.getBool('language_selected') ?? false;
      if (!mounted) return;
      if (!languageSelected) {
        context.go('/language-select');
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      switch (authProvider.authState) {
        case AuthState.authenticated:
          context.go(authProvider.getHomeRoute());
          break;
        case AuthState.unauthenticated:
          context.go('/customer/dashboard');
          break;
        case AuthState.loading:
          context.go('/customer/dashboard');
          break;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Container(
            color: AppColors.primary,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/icons/logo-new.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Namma Ooru Connect',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const Text(
                              'உங்கள் ஊரின் சூப்பர் ஆப்',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your Village Super App',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.75),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                  if (authProvider.authState == AuthState.loading)
                    const LoadingWidget(
                      message: 'Loading...',
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
