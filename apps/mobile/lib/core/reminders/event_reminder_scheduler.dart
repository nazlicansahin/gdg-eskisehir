import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gdg_events/core/push/push_service.dart';
import 'package:gdg_events/core/reminders/event_reminder_prefs.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
import 'package:timezone/timezone.dart' as tz;

/// Local-only reminders at T-7 days and T-1 day (same instant offsets as [Event.startsAt]).
class EventReminderScheduler {
  EventReminderScheduler(this._push);

  final PushService _push;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'event_reminders',
    'Event reminders',
    channelDescription:
        'Scheduled on this device — 7 days and 1 day before events you follow.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const DarwinNotificationDetails _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  /// Cancels tracked reminder notifications, then schedules new ones from [events].
  Future<void> replaceAllScheduled(
    List<Event> events, {
    required String reminderWeekTitle,
    required String reminderDayTitle,
  }) async {
    await _push.init();
    final plugin = _push.localNotificationsPlugin;

    final prev = await loadStoredNotificationIds();
    for (final id in prev) {
      await plugin.cancel(id);
    }

    final now = DateTime.now();
    final ids = <int>[];
    for (final event in events) {
      if (!event.startsAt.isAfter(now)) continue;

      final weekInstant = event.startsAt.subtract(const Duration(days: 7));
      final dayInstant = event.startsAt.subtract(const Duration(days: 1));

      final titleBase = event.title.length > 80
          ? '${event.title.substring(0, 77)}...'
          : event.title;

      if (weekInstant.isAfter(now)) {
        final id = _notificationId(event.id, 'week');
        try {
          await plugin.zonedSchedule(
            id,
            reminderWeekTitle,
            titleBase,
            tz.TZDateTime.from(weekInstant, tz.local),
            const NotificationDetails(
              android: _androidDetails,
              iOS: _iosDetails,
            ),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: 'eventId:${event.id}',
          );
          ids.add(id);
        } catch (e, st) {
          debugPrint('[reminders] week schedule failed ${event.id}: $e\n$st');
        }
      }

      if (dayInstant.isAfter(now)) {
        final id = _notificationId(event.id, 'day');
        try {
          await plugin.zonedSchedule(
            id,
            reminderDayTitle,
            titleBase,
            tz.TZDateTime.from(dayInstant, tz.local),
            const NotificationDetails(
              android: _androidDetails,
              iOS: _iosDetails,
            ),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: 'eventId:${event.id}',
          );
          ids.add(id);
        } catch (e, st) {
          debugPrint('[reminders] day schedule failed ${event.id}: $e\n$st');
        }
      }
    }

    await saveStoredNotificationIds(ids);
    debugPrint('[reminders] scheduled ${ids.length} local notifications');
  }

  Future<void> cancelAllTracked() async {
    await _push.init();
    final plugin = _push.localNotificationsPlugin;
    final prev = await loadStoredNotificationIds();
    for (final id in prev) {
      await plugin.cancel(id);
    }
    await saveStoredNotificationIds([]);
  }

  static int _notificationId(String eventId, String suffix) {
    final h = Object.hash(eventId, suffix);
    final v = h & 0x7fffffff;
    return v == 0 ? 1 : v;
  }
}
