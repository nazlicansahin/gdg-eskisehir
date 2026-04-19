import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/app.dart';
import 'package:gdg_events/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  // Subscribe as early as possible so foreground FCM is not missed before PushService.init (auth).
  FirebaseMessaging.onMessage.listen((RemoteMessage m) {
    debugPrint(
      '[push][bootstrap] onMessage id=${m.messageId} '
      'from=${m.from} notification=${m.notification?.title}',
    );
  });

  runApp(
    const ProviderScope(
      child: GdgEventsApp(),
    ),
  );
}
