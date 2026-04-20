import 'package:gdg_events/core/reminders/event_reminder_audience.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAudience = 'event_reminder_audience';
const _kScheduledIds = 'event_reminder_notification_ids';

Future<EventReminderAudience> loadReminderAudience() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kAudience);
  if (raw == null || raw.isEmpty) {
    return EventReminderAudience.registeredOnly;
  }
  try {
    return EventReminderAudience.values.byName(raw);
  } catch (_) {
    return EventReminderAudience.registeredOnly;
  }
}

Future<void> saveReminderAudience(EventReminderAudience audience) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kAudience, audience.name);
}

Future<List<int>> loadStoredNotificationIds() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_kScheduledIds) ?? const [];
  return raw.map(int.tryParse).whereType<int>().toList();
}

Future<void> saveStoredNotificationIds(List<int> ids) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _kScheduledIds,
    ids.map((e) => e.toString()).toList(),
  );
}
