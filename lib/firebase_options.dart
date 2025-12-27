import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        return windows;
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

  // Web configuration - hesabati7 project
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC_demo_key_replace_with_real',
    appId: '1:1035723590876:android:7f16a5ee7c21ebf6217819',
    messagingSenderId: '117384884651307219804',
    projectId: 'hesabati7',
    authDomain: 'hesabati7.firebaseapp.com',
    storageBucket: 'hesabati7.appspot.com',
  );

  // Android configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAJqSQTHSEy-5ABbWdcvbg1gNda3LrJqk4",
    authDomain: "hesabati7.firebaseapp.com",
    projectId: "hesabati7",
    storageBucket: "hesabati7.firebasestorage.app",
    messagingSenderId: "1035723590876",
    appId: "1:1035723590876:web:a11aadbed6de349f217819",
    measurementId: "G-Y5DXZTR3CQ"
  );

  // iOS configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC_demo_key_replace_with_real',
    appId: '1:117384884651:ios:hesabati7',
    messagingSenderId: '117384884651307219804',
    projectId: 'hesabati7',
    storageBucket: 'hesabati7.appspot.com',
    iosBundleId: 'com.hesabati.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC_demo_key_replace_with_real',
    appId: '1:117384884651:macos:hesabati7',
    messagingSenderId: '117384884651307219804',
    projectId: 'hesabati7',
    storageBucket: 'hesabati7.appspot.com',
    iosBundleId: 'com.hesabati.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC_demo_key_replace_with_real',
    appId: '1:117384884651:windows:hesabati7',
    messagingSenderId: '117384884651307219804',
    projectId: 'hesabati7',
    storageBucket: 'hesabati7.appspot.com',
  );
}
