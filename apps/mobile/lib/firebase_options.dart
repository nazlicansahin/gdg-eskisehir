// Placeholder until `flutterfire configure` generates real values.
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Replace with generated file from FlutterFire CLI, or fill in your Firebase console values.
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
    apiKey: 'CONFIGURE_ME',
    appId: 'CONFIGURE_ME',
    messagingSenderId: 'CONFIGURE_ME',
    projectId: 'CONFIGURE_ME',
    authDomain: 'CONFIGURE_ME',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'CONFIGURE_ME',
    appId: 'CONFIGURE_ME',
    messagingSenderId: 'CONFIGURE_ME',
    projectId: 'CONFIGURE_ME',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'CONFIGURE_ME',
    appId: 'CONFIGURE_ME',
    messagingSenderId: 'CONFIGURE_ME',
    projectId: 'CONFIGURE_ME',
    iosBundleId: 'com.example.gdgEvents',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'CONFIGURE_ME',
    appId: 'CONFIGURE_ME',
    messagingSenderId: 'CONFIGURE_ME',
    projectId: 'CONFIGURE_ME',
    iosBundleId: 'com.example.gdgEvents',
  );
}
