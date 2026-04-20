import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/app_locale_provider.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/l10n/app_localizations.dart';
import 'package:gdg_events/core/reminders/event_reminder_audience.dart';
import 'package:gdg_events/core/reminders/event_reminder_prefs.dart';
import 'package:gdg_events/core/reminders/event_reminder_scheduler.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:gdg_events/features/registration/domain/registration_status.dart';
import 'package:gdg_events/features/registration/presentation/registration_providers.dart';

final eventReminderSchedulerProvider = Provider<EventReminderScheduler>((ref) {
  return EventReminderScheduler(ref.watch(pushServiceProvider));
});

final eventRemindersCoordinatorProvider =
    Provider<EventRemindersCoordinator>((ref) {
  return EventRemindersCoordinator(ref);
});

/// Reschedules **local** T-7 / T-1 reminders. Does not affect FCM / server audiences.
class EventRemindersCoordinator {
  EventRemindersCoordinator(this._ref);

  final Ref _ref;

  Future<void> sync() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    final audience = await loadReminderAudience();

    List<Event> events;
    try {
      events = await _ref.read(eventsListProvider.future);
    } catch (e, st) {
      debugPrint('[reminders] skip sync: events failed: $e\n$st');
      return;
    }

    final now = DateTime.now();
    final upcoming =
        events.where((e) => e.endsAt.isAfter(now)).toList();

    List<Event> target;
    if (audience == EventReminderAudience.allPublishedEvents) {
      target = upcoming;
    } else {
      try {
        final tickets = await _ref.read(myRegistrationsProvider.future);
        final registeredIds = tickets
            .where((t) => t.status == RegistrationStatus.active)
            .map((t) => t.eventId)
            .toSet();
        target =
            upcoming.where((e) => registeredIds.contains(e.id)).toList();
      } catch (e, st) {
        debugPrint('[reminders] skip sync: registrations failed: $e\n$st');
        return;
      }
    }

    final locale = await _ref.read(appLocaleProvider.future);
    final l10n = lookupAppLocalizations(locale);
    await _ref.read(eventReminderSchedulerProvider).replaceAllScheduled(
          target,
          reminderWeekTitle: l10n.reminderNotificationWeekTitle,
          reminderDayTitle: l10n.reminderNotificationDayTitle,
        );
  }

  Future<void> cancelAll() async {
    await _ref.read(eventReminderSchedulerProvider).cancelAllTracked();
  }
}
