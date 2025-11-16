import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'firebase_options.dart';
import 'screens/dashboard/main_navigation.dart';
import 'utils/app_theme.dart';
import 'utils/app_config.dart';
import 'widgets/modern_button.dart';
import 'widgets/update_dialog.dart';
import 'providers/product_provider.dart';
import 'providers/language_provider.dart';
import 'services/version_service.dart';
import 'screens/auth/forgot_password_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final AudioPlayer audioPlayer = AudioPlayer();

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only on mobile platforms
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Create notification channel for new orders
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'shop_owner_orders',
        'Order Notifications',
        description: 'Notifications for shop orders',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('new_order'),
        playSound: true,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Request notification permissions
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('🔔 Got a message whilst in the foreground!');
        print('📦 Message data: ${message.data}');

        if (message.notification != null) {
          print(
              '📬 Notification: ${message.notification!.title} - ${message.notification!.body}');

          try {
            // Play notification sound
            print('🔊 Attempting to play notification sound...');
            await audioPlayer.stop(); // Stop any currently playing sound
            await audioPlayer.play(AssetSource('sounds/new_order.mp3'));
            print('✅ Sound played successfully');
          } catch (e) {
            print('❌ Error playing sound: $e');
          }

          try {
            // Show local notification
            print('📱 Showing local notification...');
            await flutterLocalNotificationsPlugin.show(
              message.hashCode,
              message.notification!.title,
              message.notification!.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  importance: Importance.max,
                  priority: Priority.high,
                  sound: const RawResourceAndroidNotificationSound('new_order'),
                  playSound: true,
                  icon: '@mipmap/ic_launcher',
                ),
              ),
            );
            print('✅ Local notification shown successfully');
          } catch (e) {
            print('❌ Error showing notification: $e');
          }
        }
      });

      // Get FCM token
      String? token = await messaging.getToken();
      print('FCM Token: $token');

      debugPrint('✅ Firebase and notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
    }
  } else {
    debugPrint('Running on web - Firebase initialization skipped');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        title: 'Shop Owner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _checkingAuth = true;

  // API configuration - Use centralized AppConfig
  static String get baseUrl => AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userDataStr = prefs.getString('user_data');

      if (token != null && userDataStr != null) {
        print('Found existing auth token, validating role...');
        final userData = jsonDecode(userDataStr);

        // Check user role - only SHOP_OWNER allowed
        final String? userRole = userData['role']?.toString();
        print('Stored user role: $userRole');

        if (userRole != 'SHOP_OWNER') {
          print('Access denied: Stored user role is not SHOP_OWNER, clearing auth');
          // Clear invalid auth data
          await prefs.remove('auth_token');
          await prefs.remove('user_data');
          setState(() {
            _checkingAuth = false;
          });
          return;
        }

        if (!mounted) return;

        // Navigate to dashboard with stored credentials
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(
              userName: userData['username'] ?? 'Shop Owner',
              token: token,
            ),
          ),
        );
      } else {
        print('No existing auth found');
        setState(() {
          _checkingAuth = false;
        });
      }
    } catch (e) {
      print('Error checking auth: $e');
      setState(() {
        _checkingAuth = false;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      print('Login response: $data');
      print(
          'Status code check: ${response.statusCode} == 200 && ${data['statusCode']} == 0000');

      // Backend returns accessToken, not token
      final token = data['data']?['accessToken']?.toString() ??
          data['data']?['token']?.toString() ??
          '';
      print('Token from response: $token');
      print('Token type: ${token.runtimeType}');

      if (response.statusCode == 200 && data['statusCode'] == '0000') {
        print('Login successful, checking user role...');
        print('Token to save: $token');
        print('Token length: ${token.length}');

        // Check user role - only SHOP_OWNER allowed
        final String? userRole = data['data']?['role']?.toString();
        print('User role: $userRole');

        if (userRole != 'SHOP_OWNER') {
          print('Access denied: User role is not SHOP_OWNER');
          _showError('Access Denied: This app is only for shop owners. Your role: ${userRole ?? 'Unknown'}');
          return;
        }

        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_data', jsonEncode(data['data']));

        print('Token saved to storage: ${await prefs.getString('auth_token')}');

        // Register FCM token with backend
        try {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            print('📱 Registering FCM token: ${fcmToken.substring(0, 20)}...');
            await _registerFCMToken(fcmToken, token);
          }
        } catch (e) {
          print('⚠️ Error registering FCM token: $e');
          // Don't block login if FCM registration fails
        }

        if (!mounted) {
          print('Widget not mounted, cannot navigate');
          return;
        }

        // Navigate to dashboard
        print('Navigating to MainNavigation with token: $token');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(
              userName: data['data']['username'] ?? 'Shop Owner',
              token: token,
            ),
          ),
        );
      } else {
        print('Login failed: ${data['message']}');
        _showError(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showError('Network error: Please check your connection');
      print('Login error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerFCMToken(String fcmToken, String authToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shop-owner/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'deviceType': 'android',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['statusCode'] == '0000') {
          print('✅ FCM token registered successfully with backend');
        } else {
          print('⚠️ FCM token registration failed: ${data['message']}');
        }
      } else {
        print('⚠️ FCM token registration HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error registering FCM token: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking existing auth
    if (_checkingAuth) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with gradient background
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXLarge),
                      boxShadow: AppTheme.shadowLarge,
                    ),
                    child: const Icon(
                      Icons.store,
                      size: 64,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Text('NammaOoru Shop Owner', style: AppTheme.h2),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Manage your shop efficiently',
                    style: AppTheme.bodyLarge
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.space48),

                  // Mobile Number or Email field with modern styling
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number or Email',
                      hintText: 'Enter mobile number or email',
                      prefixIcon:
                          const Icon(Icons.person, color: AppTheme.primary),
                      filled: true,
                      fillColor: AppTheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number or email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Password field with modern styling
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon:
                          const Icon(Icons.lock, color: AppTheme.primary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space8),

                  // Forgot Password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Modern login button with gradient
                  ModernButton(
                    text: 'Login',
                    icon: Icons.login,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    fullWidth: true,
                    useGradient: true,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _login,
                  ),
                  const SizedBox(height: AppTheme.space16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: AppTheme.roundedMedium,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
