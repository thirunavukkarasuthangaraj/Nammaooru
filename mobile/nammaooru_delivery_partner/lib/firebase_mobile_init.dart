import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/notification_api_service.dart';
import 'core/storage/local_storage.dart';

// Audio player for notification sounds
final AudioPlayer audioPlayer = AudioPlayer();

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeFirebase() async {
  try {
    debugPrint('🔥 Initializing Firebase for delivery partner app...');

    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create notification channel for delivery assignments
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'delivery_assignment_channel',
      'Delivery Assignments',
      description: 'Notifications for new delivery assignments',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('new_order'),
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
      debugPrint('🔔 Delivery Partner: Got a message whilst in the foreground!');
      debugPrint('📦 Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('📬 Notification: ${message.notification!.title} - ${message.notification!.body}');

        try {
          // Play notification sound
          debugPrint('🔊 Attempting to play notification sound...');
          await audioPlayer.stop(); // Stop any currently playing sound
          await audioPlayer.play(AssetSource('sounds/new_order.mp3'));
          debugPrint('✅ Sound played successfully');
        } catch (e) {
          debugPrint('❌ Error playing sound: $e');
        }

        try {
          // Show local notification
          debugPrint('📱 Showing local notification...');
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
          debugPrint('✅ Local notification shown successfully');
        } catch (e) {
          debugPrint('❌ Error showing notification: $e');
        }
      }
    });

    // Get FCM token
    String? token = await messaging.getToken();
    debugPrint('FCM Token: $token');

    // Register FCM token with backend if user is logged in
    if (token != null) {
      await _registerFcmToken(token);
    }

    // Listen for token refresh and re-register
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      await _registerFcmToken(newToken);
    });

    debugPrint('✅ Firebase and notifications initialized successfully for delivery partner');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }
}

/// Register FCM token with backend
Future<void> _registerFcmToken(String token) async {
  try {
    final authToken = await LocalStorage.getToken();
    if (authToken == null || authToken.isEmpty) {
      debugPrint('⏳ User not logged in yet, FCM token will be registered after login');
      return;
    }

    debugPrint('📤 Registering FCM token with backend...');
    final response = await NotificationApiService.instance.updateDeliveryPartnerFcmToken(token);

    if (response['success'] == true) {
      debugPrint('✅ FCM token registered with backend successfully');
    } else {
      debugPrint('❌ Failed to register FCM token: ${response['message']}');
    }
  } catch (e) {
    debugPrint('❌ Error registering FCM token: $e');
  }
}

/// Re-register FCM token (call this after login or when app resumes)
/// This is critical - Firebase can rotate tokens at any time.
/// Always call this when:
/// 1. User logs in
/// 2. App comes to foreground
/// 3. Dashboard is opened
Future<void> reRegisterFcmToken() async {
  try {
    debugPrint('🔄 Force refreshing FCM token...');
    final messaging = FirebaseMessaging.instance;

    // Delete old token and get fresh one to ensure we have latest
    // This helps when Firebase has rotated the token
    await messaging.deleteToken();
    final token = await messaging.getToken();

    if (token != null) {
      debugPrint('📱 Got fresh FCM token: ${token.substring(0, 50)}...');
      await _registerFcmToken(token);
    } else {
      debugPrint('⚠️ Could not get FCM token');
    }
  } catch (e) {
    debugPrint('❌ Error re-registering FCM token: $e');
  }
}

/// Ensure FCM token is registered (less aggressive, doesn't delete token)
/// Use this for periodic checks like when dashboard opens
Future<void> ensureFcmTokenRegistered() async {
  try {
    final authToken = await LocalStorage.getToken();
    if (authToken == null || authToken.isEmpty) {
      debugPrint('⏳ User not logged in, skipping FCM token check');
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();

    if (token != null) {
      debugPrint('🔔 Ensuring FCM token is registered...');
      await _registerFcmToken(token);
    }
  } catch (e) {
    debugPrint('❌ Error ensuring FCM token: $e');
  }
}
