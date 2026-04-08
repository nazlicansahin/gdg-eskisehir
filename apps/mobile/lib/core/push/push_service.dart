import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:graphql/client.dart';

const _registerDeviceTokenMutation = r'''
mutation RegisterDeviceToken($token: String!, $platform: String!) {
  registerDeviceToken(token: $token, platform: $platform)
}
''';

class PushService {
  PushService(this._graphQLClient);

  final GraphQLClient _graphQLClient;
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    final token = await _messaging.getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    }
    _messaging.onTokenRefresh.listen(_sendTokenToBackend);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gdg_events_channel',
          'GDG Events',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _sendTokenToBackend(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _graphQLClient.mutate(
        MutationOptions(
          document: gql(_registerDeviceTokenMutation),
          variables: {'token': token, 'platform': platform},
        ),
      );
    } catch (_) {
      // Token registration is best-effort; will retry on next app launch.
    }
  }
}
