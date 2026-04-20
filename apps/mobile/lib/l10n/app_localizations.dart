import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get navTickets;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @eventFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get eventFallbackTitle;

  /// No description provided for @eventsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsScreenTitle;

  /// No description provided for @eventsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get eventsEmptyTitle;

  /// No description provided for @eventsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned for upcoming community meetups!'**
  String get eventsEmptySubtitle;

  /// No description provided for @eventsFilteredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No events in this category'**
  String get eventsFilteredEmptyTitle;

  /// No description provided for @eventsFilteredEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another time filter.'**
  String get eventsFilteredEmptySubtitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get filterUpcoming;

  /// No description provided for @filterLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get filterLive;

  /// No description provided for @filterPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get filterPast;

  /// No description provided for @eventCardUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventCardUpcoming;

  /// No description provided for @eventCardLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get eventCardLive;

  /// No description provided for @eventCardCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get eventCardCancelled;

  /// No description provided for @eventCardDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get eventCardDraft;

  /// No description provided for @capacityEvents.
  ///
  /// In en, this message translates to:
  /// **'Capacity {count}'**
  String capacityEvents(int count);

  /// No description provided for @myTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get myTicketsTitle;

  /// No description provided for @noTicketsYet.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get noTicketsYet;

  /// No description provided for @noTicketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register for events to get your tickets here.'**
  String get noTicketsSubtitle;

  /// No description provided for @ticketsFilteredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tickets in this category'**
  String get ticketsFilteredEmptyTitle;

  /// No description provided for @ticketsFilteredEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another time filter.'**
  String get ticketsFilteredEmptySubtitle;

  /// No description provided for @ticketsEventsLoadWarning.
  ///
  /// In en, this message translates to:
  /// **'Could not load event dates; filters may be unavailable.'**
  String get ticketsEventsLoadWarning;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @scanTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan tickets'**
  String get scanTicketsTitle;

  /// No description provided for @scanTicketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check in attendees by QR'**
  String get scanTicketsSubtitle;

  /// No description provided for @sendAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Send announcement'**
  String get sendAnnouncementTitle;

  /// No description provided for @sendAnnouncementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify attendees about updates'**
  String get sendAnnouncementSubtitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your display name'**
  String get displayNameHint;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @reminderSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Event reminders'**
  String get reminderSectionTitle;

  /// No description provided for @reminderSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders on this device 7 days and 1 day before event start. This does not change who receives organizer push announcements.'**
  String get reminderSectionBody;

  /// No description provided for @reminderAllEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'All events'**
  String get reminderAllEventsTitle;

  /// No description provided for @reminderAllEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders for every published event'**
  String get reminderAllEventsSubtitle;

  /// No description provided for @reminderRegisteredOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered only'**
  String get reminderRegisteredOnlyTitle;

  /// No description provided for @reminderRegisteredOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders only for events I registered for'**
  String get reminderRegisteredOnlySubtitle;

  /// No description provided for @legalSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalSectionTitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile, registrations, and related data. You will not be able to recover this information.'**
  String get deleteAccountBody;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get passwordConfirmHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @enterPasswordToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get enterPasswordToConfirm;

  /// No description provided for @communityEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Community Events'**
  String get communityEventsSubtitle;

  /// No description provided for @eskisehirBrand.
  ///
  /// In en, this message translates to:
  /// **'Eskisehir'**
  String get eskisehirBrand;

  /// No description provided for @signInSegment.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInSegment;

  /// No description provided for @createAccountSegment.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountSegment;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @submitSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get submitSignIn;

  /// No description provided for @submitCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get submitCreateAccount;

  /// No description provided for @reminderNotificationWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'In one week'**
  String get reminderNotificationWeekTitle;

  /// No description provided for @reminderNotificationDayTitle.
  ///
  /// In en, this message translates to:
  /// **'In one day'**
  String get reminderNotificationDayTitle;

  /// No description provided for @ticketStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String ticketStatusLabel(Object status);

  /// No description provided for @addToCalendarButton.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addToCalendarButton;

  /// No description provided for @ticketScanHeading.
  ///
  /// In en, this message translates to:
  /// **'Scan at check-in'**
  String get ticketScanHeading;

  /// No description provided for @ticketCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get ticketCopyCode;

  /// No description provided for @ticketCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Ticket code copied'**
  String get ticketCodeCopied;

  /// No description provided for @eventDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get eventDetailsButton;

  /// No description provided for @ticketPageTitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Your ticket'**
  String get ticketPageTitleDefault;

  /// No description provided for @ticketNoTicketYet.
  ///
  /// In en, this message translates to:
  /// **'No ticket for this event yet.'**
  String get ticketNoTicketYet;

  /// No description provided for @ticketRegisterFirst.
  ///
  /// In en, this message translates to:
  /// **'Register from the event page first.'**
  String get ticketRegisterFirst;

  /// No description provided for @pillReadyToScan.
  ///
  /// In en, this message translates to:
  /// **'Ready to scan'**
  String get pillReadyToScan;

  /// No description provided for @pillCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get pillCheckedIn;

  /// No description provided for @pillCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get pillCancelled;

  /// No description provided for @ticketRegistrationPrefix.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get ticketRegistrationPrefix;

  /// No description provided for @ticketCheckedInPrefix.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get ticketCheckedInPrefix;

  /// No description provided for @settingsSavedToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Saved to calendar'**
  String get settingsSavedToCalendar;

  /// No description provided for @settingsCouldNotAddCalendar.
  ///
  /// In en, this message translates to:
  /// **'Could not add to calendar: {error}'**
  String settingsCouldNotAddCalendar(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
