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
    apiKey: 'AIzaSyBdwffRV7muLR616_cxTpSP4aSmrxxbetc',
    appId: '1:913325898379:web:9a39a270a6693e9a5b328e',
    messagingSenderId: '913325898379',
    projectId: 'nammaooru-shop-management',
    authDomain: 'nammaooru-shop-management.firebaseapp.com',
    storageBucket: 'nammaooru-shop-management.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwZASRn_-unR7l6ksgezzjiattZQm3ysE',
    appId: '1:913325898379:android:5936c24e33877c555b328e',
    messagingSenderId: '913325898379',
    projectId: 'nammaooru-shop-management',
    storageBucket: 'nammaooru-shop-management.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCwZASRn_-unR7l6ksgezzjiattZQm3ysE',
    appId: '1:913325898379:ios:5936c24e33877c555b328e',
    messagingSenderId: '913325898379',
    projectId: 'nammaooru-shop-management',
    storageBucket: 'nammaooru-shop-management.firebasestorage.app',
    iosBundleId: 'com.nammaooru.delivery',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCwZASRn_-unR7l6ksgezzjiattZQm3ysE',
    appId: '1:913325898379:macos:5936c24e33877c555b328e',
    messagingSenderId: '913325898379',
    projectId: 'nammaooru-shop-management',
    storageBucket: 'nammaooru-shop-management.firebasestorage.app',
    iosBundleId: 'com.nammaooru.delivery',
  );
}