import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app/app.dart';
import 'core/auth/auth_provider.dart'; // Use the main auth provider
import 'shared/providers/cart_provider.dart';
import 'core/localization/language_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'features/auth/providers/forgot_password_provider.dart';
import 'core/api/api_client.dart';
import 'core/api/api_service.dart';
import 'core/services/api_service.dart' as services;
import 'core/storage/local_storage.dart';
import 'services/firebase_notification_service.dart';
import 'services/local_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only on mobile platforms for now
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(FirebaseNotificationService.handleBackgroundMessage);

      // Initialize local notifications first (for displaying notifications)
      await LocalNotificationService.instance.initialize();

      // Initialize Firebase notification service
      await FirebaseNotificationService.initialize();

      debugPrint('✅ Firebase and notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
    }
  } else {
    // For web, we can optionally initialize with web-specific config later
    debugPrint('Running on web - Firebase initialization skipped');
  }
  
  // Initialize Local Storage
  await LocalStorage.init();
  
  // Initialize API Client
  ApiClient.initialize();
  
  // Initialize API Service
  ApiService().initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider(services.ApiService())),
      ],
      child: const NammaOoruApp(),
    ),
  );
}