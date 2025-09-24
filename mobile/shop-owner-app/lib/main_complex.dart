import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'providers/auth_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/notification_provider.dart';
import 'services/notification_service.dart';
import 'services/notification_handler.dart';
import 'services/websocket_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/main_navigation.dart';
import 'utils/constants.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService.initialize();

  runApp(const ShopOwnerApp());
}

class ShopOwnerApp extends StatelessWidget {
  const ShopOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'NammaOoru Shop Owner',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: AppColors.primary,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
              ),
              fontFamily: 'Inter',
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            home: FutureBuilder<bool>(
              future: authProvider.isLoggedIn(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.data == true) {
                  return const AppWithNotifications(child: MainNavigation());
                } else {
                  return const LoginScreen();
                }
              },
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AppWithNotifications extends StatefulWidget {
  final Widget child;

  const AppWithNotifications({super.key, required this.child});

  @override
  State<AppWithNotifications> createState() => _AppWithNotificationsState();
}

class _AppWithNotificationsState extends State<AppWithNotifications> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationHandler().initialize(context);

      // Initialize WebSocket connection
      final websocketService = WebSocketService();
      await websocketService.connect();

    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}