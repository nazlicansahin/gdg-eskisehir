import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAlJZhnnLNgTATgCyUVJYkePiyxUay34fQ',
    appId: '1:999201500962:web:eff795330b0874e037bf7b',
    messagingSenderId: '999201500962',
    projectId: 'gdg-eskisehir-dev',
    authDomain: 'gdg-eskisehir-dev.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBkxpGOb0VvuAKm6mfvamHL2U_6r-DcLqI',
    appId: '1:999201500962:android:687f68f98489fc9a37bf7b',
    messagingSenderId: '999201500962',
    projectId: 'gdg-eskisehir-dev',
    storageBucket: 'gdg-eskisehir-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAjx39H8zDmcpfKpnEW-VfSxKNE8euxx-0',
    appId: '1:999201500962:ios:a7c2d37f565e4b0037bf7b',
    messagingSenderId: '999201500962',
    projectId: 'gdg-eskisehir-dev',
    storageBucket: 'gdg-eskisehir-dev.firebasestorage.app',
    iosBundleId: 'com.example.gdgEvents',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAjx39H8zDmcpfKpnEW-VfSxKNE8euxx-0',
    appId: '1:999201500962:ios:a7c2d37f565e4b0037bf7b',
    messagingSenderId: '999201500962',
    projectId: 'gdg-eskisehir-dev',
    storageBucket: 'gdg-eskisehir-dev.firebasestorage.app',
    iosBundleId: 'com.example.gdgEvents',
  );
}
