import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'core/auth/auth_provider.dart';
import 'core/storage/local_storage.dart';
import 'core/api/api_client.dart';
import 'shared/services/notification_service.dart';
import 'shared/providers/app_provider.dart';
import 'shared/providers/location_provider.dart';
import 'shared/providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await LocalStorage.init();
  ApiClient.initialize();
  await NotificationService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const NammaOoruApp(),
    ),
  );
}