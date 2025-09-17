import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/providers/delivery_partner_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/realtime_provider.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/profile/screens/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set up Firebase background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const DeliveryPartnerApp());
}

class DeliveryPartnerApp extends StatelessWidget {
  const DeliveryPartnerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DeliveryPartnerProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
        ChangeNotifierProvider(create: (context) => RealtimeProvider()),
      ],
      child: MaterialApp(
        title: 'NammaOoru Delivery Partner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppInitializer(),
        routes: {
          '/change-password': (context) => const ChangePasswordScreen(),
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
    await provider.checkLoginStatus();
    
    if (mounted) {
      if (provider.isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delivery_dining,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'NammaOoru Delivery Partner',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your partner for swift deliveries',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

