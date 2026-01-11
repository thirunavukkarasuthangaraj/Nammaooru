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

/// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed (background isolate)
  await Firebase.initializeApp();

  debugPrint('🌙 Background message received: ${message.notification?.title}');
  debugPrint('📦 Background data: ${message.data}');

  // Initialize local notifications plugin for background isolate
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  // Initialize Android settings for background
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
  await plugin.initialize(initSettings);

  // Show local notification for background messages
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'delivery_assignment_channel_v2',
    'Delivery Assignments',
    description: 'Notifications for new delivery assignments',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  // Create channel
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  String title = message.notification?.title ?? message.data['title'] ?? 'New Delivery!';
  String body = message.notification?.body ?? message.data['body'] ?? 'You have a new delivery assignment';

  await plugin.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      ),
    ),
  );
}

Future<void> initializeFirebase() async {
  try {
    debugPrint('🔥 Initializing Firebase for delivery partner app...');

    // Initialize Firebase
    await Firebase.initializeApp();

    // Register background message handler - CRITICAL for background notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create notification channel for delivery assignments with DEFAULT ALARM sound
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'delivery_assignment_channel_v2',  // New channel ID to force new settings
      'Delivery Assignments',
      description: 'Notifications for new delivery assignments',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      // Use default notification sound (system will use alarm/ringtone based on importance)
    );

    // Delete old channels and create new one
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('delivery_assignment_channel');
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('delivery_assignment_channel_v2');

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

    // Handle foreground messages - play sound for ALL messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('🔔 Delivery Partner: Got a message whilst in the foreground!');
      debugPrint('📦 Message data: ${message.data}');
      debugPrint('📬 Notification: ${message.notification?.title} - ${message.notification?.body}');

      // ALWAYS play sound for ANY incoming message
      try {
        debugPrint('🔊 Playing notification sound...');
        await audioPlayer.stop();
        await audioPlayer.setVolume(1.0); // MAX volume
        await audioPlayer.play(AssetSource('sounds/new_order_notification.wav'));
        debugPrint('✅ Sound played successfully');
      } catch (e) {
        debugPrint('❌ Error playing sound: $e');
      }

      // Show local notification
      String title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
      String body = message.notification?.body ?? message.data['body'] ?? 'You have a new message';

      try {
        debugPrint('📱 Showing local notification...');
        await flutterLocalNotificationsPlugin.show(
          message.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              icon: '@mipmap/ic_launcher',
              fullScreenIntent: true,  // Makes it more attention-grabbing
            ),
          ),
        );
        debugPrint('✅ Local notification shown successfully');
      } catch (e) {
        debugPrint('❌ Error showing notification: $e');
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
