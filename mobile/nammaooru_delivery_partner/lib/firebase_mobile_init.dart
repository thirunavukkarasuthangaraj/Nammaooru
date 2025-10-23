import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

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

    debugPrint('✅ Firebase and notifications initialized successfully for delivery partner');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }
}
