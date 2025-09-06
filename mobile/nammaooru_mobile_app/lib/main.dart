import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/auth/auth_provider.dart';
import 'shared/providers/cart_provider.dart';
import 'core/localization/language_provider.dart';
import 'features/auth/providers/forgot_password_provider.dart';
import 'core/api/api_client.dart';
import 'core/api/api_service.dart';
import 'core/services/api_service.dart' as services;
import 'core/storage/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only on mobile platforms for now
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
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
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider(services.ApiService())),
      ],
      child: const NammaOoruApp(),
    ),
  );
}