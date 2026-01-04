import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/providers/delivery_partner_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/constants/app_theme.dart';
import 'core/services/version_service.dart';
import 'core/widgets/update_dialog.dart';
import 'core/storage/local_storage.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/orders/screens/available_orders_screen.dart';
import 'features/orders/screens/active_orders_screen.dart';
import 'features/orders/screens/order_history_screen.dart';
import 'features/earnings/screens/earnings_screen.dart';

// Conditional imports for Firebase (mobile only)
import 'firebase_mobile_init.dart' if (dart.library.html) 'firebase_web_stub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize LocalStorage (SharedPreferences) - MUST be called before using LocalStorage
  await LocalStorage.init();
  debugPrint('✅ LocalStorage initialized');

  // Initialize Firebase only on mobile platforms
  if (!kIsWeb) {
    await initializeFirebase();
  } else {
    debugPrint('Running on web - Firebase initialization skipped');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const DeliveryPartnerApp());
}

class DeliveryPartnerApp extends StatefulWidget {
  const DeliveryPartnerApp({Key? key}) : super(key: key);

  @override
  State<DeliveryPartnerApp> createState() => _DeliveryPartnerAppState();
}

class _DeliveryPartnerAppState extends State<DeliveryPartnerApp> {
  @override
  void initState() {
    super.initState();
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    try {
      // Wait a bit for the app to fully initialize
      await Future.delayed(const Duration(seconds: 2));

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Check for updates
      final versionInfo = await VersionService.checkVersion(currentVersion);

      if (versionInfo != null && mounted) {
        // Show update dialog if context is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showUpdateDialog(versionInfo, currentVersion);
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking app version: $e');
    }
  }

  void _showUpdateDialog(Map<String, dynamic> versionInfo, String currentVersion) {
    final context = this.context;
    if (!context.mounted) return;

    final bool updateRequired = versionInfo['updateRequired'] ?? false;
    final bool isMandatory = versionInfo['isMandatory'] ?? false;

    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => UpdateDialog(
        currentVersion: currentVersion,
        newVersion: versionInfo['currentVersion'] ?? 'Unknown',
        releaseNotes: versionInfo['releaseNotes'] ?? '',
        updateUrl: versionInfo['updateUrl'] ?? '',
        isMandatory: isMandatory,
        updateRequired: updateRequired,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DeliveryPartnerProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'NammaOoru Delivery Partner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppInitializer(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/available-orders': (context) => const AvailableOrdersScreen(),
          '/active-orders': (context) => const ActiveOrdersScreen(),
          '/order-history': (context) => const OrderHistoryScreen(),
          '/earnings': (context) => const EarningsScreen(),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFC107), Color(0xFFFFA000)],
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

