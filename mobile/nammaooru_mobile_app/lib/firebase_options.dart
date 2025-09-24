import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'your-web-api-key',
    appId: 'your-web-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'nammaooru-app',
    authDomain: 'nammaooru-app.firebaseapp.com',
    storageBucket: 'nammaooru-app.appspot.com',
    measurementId: 'your-measurement-id',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwZASRn_-unR7l6ksgezzjiattZQm3ysE',
    appId: '1:913325898379:android:7beca981a84f8b135b328e',
    messagingSenderId: '913325898379',
    projectId: 'nammaooru-shop-management',
    storageBucket: 'nammaooru-shop-management.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-ios-api-key',
    appId: 'your-ios-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'nammaooru-app',
    storageBucket: 'nammaooru-app.appspot.com',
    iosBundleId: 'com.nammaooru.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-macos-api-key',
    appId: 'your-macos-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'nammaooru-app',
    storageBucket: 'nammaooru-app.appspot.com',
    iosBundleId: 'com.nammaooru.app',
  );
}