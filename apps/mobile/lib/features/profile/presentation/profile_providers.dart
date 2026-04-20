import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/reminders/event_reminder_audience.dart';
import 'package:gdg_events/core/reminders/event_reminder_prefs.dart';
import 'package:gdg_events/features/profile/domain/entities/profile_user.dart';

/// User choice for **on-device** event reminders (not server FCM routing).
final reminderAudienceProvider =
    FutureProvider<EventReminderAudience>((ref) async {
  return loadReminderAudience();
});

final profileProvider = FutureProvider.autoDispose<ProfileUser>((ref) async {
  final result = await ref.watch(profileRepositoryProvider).me();
  return result.fold(
    (f) => throw FailureException(f),
    (u) => u,
  );
});
