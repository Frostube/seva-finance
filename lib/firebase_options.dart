import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyBDUw0xs0xlLCaWts9A1KJenYJyJlb-fGo',
    appId: '1:741018143182:web:3e9ea6caf2134652e4439f',
    messagingSenderId: '741018143182',
    projectId: 'seva-finance-app',
    authDomain: 'seva-finance-app.firebaseapp.com',
    storageBucket: 'seva-finance-app.firebasestorage.app',
    measurementId: 'G-PRDFE66X52',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZPHhpb2fTZJEogfy8_hIWN2X5bWFno2M',
    appId: '1:741018143182:android:5e9ba75fce8a0489e4439f',
    messagingSenderId: '741018143182',
    projectId: 'seva-finance-app',
    storageBucket: 'seva-finance-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBIFwyg_ZgDl_PA-oiV5FLr_Tv29SS9wew',
    appId: '1:741018143182:ios:77935fb964d1d906e4439f',
    messagingSenderId: '741018143182',
    projectId: 'seva-finance-app',
    storageBucket: 'seva-finance-app.firebasestorage.app',
    iosBundleId: 'com.example.sevaFinance',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBIFwyg_ZgDl_PA-oiV5FLr_Tv29SS9wew',
    appId: '1:741018143182:ios:77935fb964d1d906e4439f',
    messagingSenderId: '741018143182',
    projectId: 'seva-finance-app',
    storageBucket: 'seva-finance-app.firebasestorage.app',
    iosBundleId: 'com.example.sevaFinance',
  );

} 