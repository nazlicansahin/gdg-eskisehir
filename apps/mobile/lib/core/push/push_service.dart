import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  /// Used to show FCM in foreground and for on-device event reminder schedules.
  FlutterLocalNotificationsPlugin get localNotificationsPlugin =>
      _localNotifications;

  Future<void>? _initFuture;

  Future<void> init() {
    _initFuture ??= _initImpl();
    return _initFuture!;
  }

  Future<void> _initImpl() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    const androidChannel = AndroidNotificationChannel(
      'gdg_events_channel',
      'GDG Events',
      description: 'Event and announcement notifications',
      importance: Importance.high,
    );

    const remindersChannel = AndroidNotificationChannel(
      'event_reminders',
      'Event reminders',
      description:
          'On-device reminders before events you follow (7 days and 1 day).',
      importance: Importance.defaultImportance,
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(androidChannel);
    await androidImpl?.createNotificationChannel(remindersChannel);
    if (Platform.isAndroid) {
      await androidImpl?.requestNotificationsPermission();
    }

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '[push] onMessage id=${message.messageId} '
        'notification=${message.notification?.title}/${message.notification?.body} '
        'data=${message.data}',
      );
      _onForegroundMessage(message);
    });

    try {
      _messaging.onTokenRefresh.listen((t) {
        _sendTokenToBackend(t);
      });
    } catch (e, st) {
      debugPrint('[push] onTokenRefresh setup failed: $e\n$st');
    }
  }

  /// Call after Firebase Auth sign-in so [device_tokens] row uses the current user.
  /// Safe to call on every auth session start.
  Future<void> registerDeviceTokenWithBackend() async {
    await init();
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[push] FCM getToken returned empty (simulator or misconfigured APNs?)');
        return;
      }
      await _sendTokenToBackend(token);
    } catch (e, st) {
      debugPrint('[push] registerDeviceTokenWithBackend: $e\n$st');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if (title == null && body == null) {
      debugPrint('[push] foreground message without notification payload: ${message.data}');
      return;
    }

    var localId =
        (message.messageId?.hashCode ?? message.hashCode) & 0x7fffffff;
    if (localId == 0) localId = 1;
    _localNotifications.show(
      localId,
      title ?? 'GDG Eskisehir',
      body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gdg_events_channel',
          'GDG Events',
          channelDescription: 'Event and announcement notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showTestNotification() async {
    await init();

    if (Platform.isIOS) {
      final allowed = await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      if (allowed == false) {
        return;
      }
    }

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    await _localNotifications.show(
      0,
      'GDG Eskisehir',
      'Local notification test — if you see this, on-device alerts are working.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gdg_events_channel',
          'GDG Events',
          channelDescription: 'Event and announcement notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> _sendTokenToBackend(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      final result = await _graphQLClient.mutate(
        MutationOptions(
          document: gql(_registerDeviceTokenMutation),
          variables: {'token': token, 'platform': platform},
          fetchPolicy: FetchPolicy.noCache,
        ),
      );
      if (result.hasException) {
        debugPrint('[push] registerDeviceToken failed: ${result.exception}');
        return;
      }
      if (result.data?['registerDeviceToken'] != true) {
        debugPrint('[push] registerDeviceToken unexpected: ${result.data}');
        return;
      }
      debugPrint('[push] device token registered for $platform');
    } catch (e, st) {
      debugPrint('[push] registerDeviceToken error: $e\n$st');
    }
  }
}
