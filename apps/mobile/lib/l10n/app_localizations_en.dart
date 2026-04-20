// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navEvents => 'Events';

  @override
  String get navTickets => 'Tickets';

  @override
  String get navProfile => 'Profile';

  @override
  String get eventFallbackTitle => 'Event';

  @override
  String get eventsScreenTitle => 'Events';

  @override
  String get eventsEmptyTitle => 'No events yet';

  @override
  String get eventsEmptySubtitle =>
      'Stay tuned for upcoming community meetups!';

  @override
  String get eventsFilteredEmptyTitle => 'No events in this category';

  @override
  String get eventsFilteredEmptySubtitle => 'Try another time filter.';

  @override
  String get filterAll => 'All';

  @override
  String get filterUpcoming => 'Upcoming';

  @override
  String get filterLive => 'Live';

  @override
  String get filterPast => 'Past';

  @override
  String get eventCardUpcoming => 'Upcoming';

  @override
  String get eventCardLive => 'Live';

  @override
  String get eventCardCancelled => 'Cancelled';

  @override
  String get eventCardDraft => 'Draft';

  @override
  String capacityEvents(int count) {
    return 'Capacity $count';
  }

  @override
  String get myTicketsTitle => 'My Tickets';

  @override
  String get noTicketsYet => 'No tickets yet';

  @override
  String get noTicketsSubtitle =>
      'Register for events to get your tickets here.';

  @override
  String get ticketsFilteredEmptyTitle => 'No tickets in this category';

  @override
  String get ticketsFilteredEmptySubtitle => 'Try another time filter.';

  @override
  String get ticketsEventsLoadWarning =>
      'Could not load event dates; filters may be unavailable.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get scanTicketsTitle => 'Scan tickets';

  @override
  String get scanTicketsSubtitle => 'Check in attendees by QR';

  @override
  String get sendAnnouncementTitle => 'Send announcement';

  @override
  String get sendAnnouncementSubtitle => 'Notify attendees about updates';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get displayNameHint => 'Your display name';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get reminderSectionTitle => 'Event reminders';

  @override
  String get reminderSectionBody =>
      'Reminders on this device 7 days and 1 day before event start. This does not change who receives organizer push announcements.';

  @override
  String get reminderAllEventsTitle => 'All events';

  @override
  String get reminderAllEventsSubtitle => 'Reminders for every published event';

  @override
  String get reminderRegisteredOnlyTitle => 'Registered only';

  @override
  String get reminderRegisteredOnlySubtitle =>
      'Reminders only for events I registered for';

  @override
  String get legalSectionTitle => 'Legal';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get support => 'Support';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your profile, registrations, and related data. You will not be able to recover this information.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordConfirmHint => 'Enter your password to confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get enterPasswordToConfirm => 'Enter your password to confirm';

  @override
  String get communityEventsSubtitle => 'Community Events';

  @override
  String get eskisehirBrand => 'Eskisehir';

  @override
  String get signInSegment => 'Sign in';

  @override
  String get createAccountSegment => 'Create account';

  @override
  String get emailLabel => 'Email';

  @override
  String get requiredField => 'Required';

  @override
  String get submitSignIn => 'Sign in';

  @override
  String get submitCreateAccount => 'Create account';

  @override
  String get reminderNotificationWeekTitle => 'In one week';

  @override
  String get reminderNotificationDayTitle => 'In one day';

  @override
  String ticketStatusLabel(Object status) {
    return 'Status: $status';
  }

  @override
  String get addToCalendarButton => 'Add to calendar';

  @override
  String get ticketScanHeading => 'Scan at check-in';

  @override
  String get ticketCopyCode => 'Copy code';

  @override
  String get ticketCodeCopied => 'Ticket code copied';

  @override
  String get eventDetailsButton => 'Event details';

  @override
  String get ticketPageTitleDefault => 'Your ticket';

  @override
  String get ticketNoTicketYet => 'No ticket for this event yet.';

  @override
  String get ticketRegisterFirst => 'Register from the event page first.';

  @override
  String get pillReadyToScan => 'Ready to scan';

  @override
  String get pillCheckedIn => 'Checked in';

  @override
  String get pillCancelled => 'Cancelled';

  @override
  String get ticketRegistrationPrefix => 'Registration';

  @override
  String get ticketCheckedInPrefix => 'Checked in';

  @override
  String get settingsSavedToCalendar => 'Saved to calendar';

  @override
  String settingsCouldNotAddCalendar(Object error) {
    return 'Could not add to calendar: $error';
  }
}
