/// Controls which published events receive **on-device** scheduled reminders
/// (7 days and 1 day before start). Independent of server-side FCM targeting.
enum EventReminderAudience {
  /// Reminders for every published event returned by the API.
  allPublishedEvents,

  /// Reminders only when the user has an active registration for that event.
  registeredOnly,
}
