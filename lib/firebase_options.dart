// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDHz7mQgHKldkc7eiYHmivK42x7Gr24nAE',
    appId: '1:911307464919:web:fd6a88247d11cd8855d092',
    messagingSenderId: '911307464919',
    projectId: 'ipara-fd373',
    authDomain: 'ipara-fd373.firebaseapp.com',
    storageBucket: 'ipara-fd373.firebasestorage.app',
    measurementId: 'G-35L6RP8CXS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBorFK55oUNa4KX6ib1kFbncVspFSmBpZE',
    appId: '1:911307464919:android:9d88a0f78542bb3155d092',
    messagingSenderId: '911307464919',
    projectId: 'ipara-fd373',
    storageBucket: 'ipara-fd373.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDokonGqhM6LV3tAT79xMs7xrSMZOoJe5I',
    appId: '1:911307464919:ios:5fea67c01738750555d092',
    messagingSenderId: '911307464919',
    projectId: 'ipara-fd373',
    storageBucket: 'ipara-fd373.firebasestorage.app',
    iosBundleId: 'com.example.iparaNew',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDokonGqhM6LV3tAT79xMs7xrSMZOoJe5I',
    appId: '1:911307464919:ios:5fea67c01738750555d092',
    messagingSenderId: '911307464919',
    projectId: 'ipara-fd373',
    storageBucket: 'ipara-fd373.firebasestorage.app',
    iosBundleId: 'com.example.iparaNew',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDHz7mQgHKldkc7eiYHmivK42x7Gr24nAE',
    appId: '1:911307464919:web:8818c62843977a4055d092',
    messagingSenderId: '911307464919',
    projectId: 'ipara-fd373',
    authDomain: 'ipara-fd373.firebaseapp.com',
    storageBucket: 'ipara-fd373.firebasestorage.app',
    measurementId: 'G-V8P6W0BLRL',
  );
}
