// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get navEvents => 'Etkinlikler';

  @override
  String get navTickets => 'Biletler';

  @override
  String get navProfile => 'Profil';

  @override
  String get eventFallbackTitle => 'Etkinlik';

  @override
  String get eventsScreenTitle => 'Etkinlikler';

  @override
  String get eventsEmptyTitle => 'Henüz etkinlik yok';

  @override
  String get eventsEmptySubtitle =>
      'Yakında topluluk buluşmaları için takipte kalın!';

  @override
  String get eventsFilteredEmptyTitle => 'Bu kategoride etkinlik yok';

  @override
  String get eventsFilteredEmptySubtitle => 'Başka bir zaman filtresi deneyin.';

  @override
  String get filterAll => 'Tümü';

  @override
  String get filterUpcoming => 'Yaklaşan';

  @override
  String get filterLive => 'Şimdi';

  @override
  String get filterPast => 'Geçmiş';

  @override
  String get eventCardUpcoming => 'Yaklaşan';

  @override
  String get eventCardLive => 'Canlı';

  @override
  String get eventCardCancelled => 'İptal';

  @override
  String get eventCardDraft => 'Taslak';

  @override
  String capacityEvents(int count) {
    return 'Kapasite $count';
  }

  @override
  String get myTicketsTitle => 'Biletlerim';

  @override
  String get noTicketsYet => 'Henüz biletiniz yok';

  @override
  String get noTicketsSubtitle =>
      'Biletlerinizi görmek için etkinliklere kaydolun.';

  @override
  String get ticketsFilteredEmptyTitle => 'Bu kategoride bilet yok';

  @override
  String get ticketsFilteredEmptySubtitle =>
      'Başka bir zaman filtresi deneyin.';

  @override
  String get ticketsEventsLoadWarning =>
      'Etkinlik tarihleri yüklenemedi; filtreler kısıtlı olabilir.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get languageSectionTitle => 'Dil';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get scanTicketsTitle => 'Bilet okut';

  @override
  String get scanTicketsSubtitle => 'Katılımcıları QR ile check-in yap';

  @override
  String get sendAnnouncementTitle => 'Duyuru gönder';

  @override
  String get sendAnnouncementSubtitle => 'Katılımcılara güncelleme bildir';

  @override
  String get displayNameLabel => 'Görünen ad';

  @override
  String get displayNameHint => 'Görünen adınız';

  @override
  String get saveProfile => 'Profili kaydet';

  @override
  String get reminderSectionTitle => 'Etkinlik hatırlatıcıları';

  @override
  String get reminderSectionBody =>
      'Bu cihazda etkinlik başlangıcından 7 gün ve 1 gün önce hatırlatıcılar. Organizatörün push duyurusunun kime gideceğini bu ayar değiştirmez.';

  @override
  String get reminderAllEventsTitle => 'Tüm etkinlikler';

  @override
  String get reminderAllEventsSubtitle =>
      'Yayınlanan her etkinlik için hatırlatıcı';

  @override
  String get reminderRegisteredOnlyTitle => 'Kayıtlı olduklarım';

  @override
  String get reminderRegisteredOnlySubtitle =>
      'Yalnızca kayıt olduğum etkinlikler için hatırlatıcı';

  @override
  String get legalSectionTitle => 'Yasal';

  @override
  String get privacyPolicy => 'Gizlilik politikası';

  @override
  String get termsOfUse => 'Kullanım şartları';

  @override
  String get support => 'Destek';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get deleteAccount => 'Hesabı sil';

  @override
  String get profileUpdated => 'Profil güncellendi';

  @override
  String get couldNotOpenLink => 'Bağlantı açılamadı';

  @override
  String get deleteAccountTitle => 'Hesap silinsin mi?';

  @override
  String get deleteAccountBody =>
      'Profiliniz, kayıtlarınız ve ilgili veriler kalıcı olarak silinir. Bu bilgileri geri getiremezsiniz.';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get passwordConfirmHint => 'Onaylamak için şifrenizi girin';

  @override
  String get cancel => 'İptal';

  @override
  String get delete => 'Sil';

  @override
  String get enterPasswordToConfirm => 'Onaylamak için şifrenizi girin';

  @override
  String get communityEventsSubtitle => 'Topluluk etkinlikleri';

  @override
  String get eskisehirBrand => 'Eskişehir';

  @override
  String get signInSegment => 'Giriş';

  @override
  String get createAccountSegment => 'Hesap oluştur';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get requiredField => 'Zorunlu';

  @override
  String get submitSignIn => 'Giriş yap';

  @override
  String get submitCreateAccount => 'Hesap oluştur';

  @override
  String get reminderNotificationWeekTitle => 'Bir hafta sonra';

  @override
  String get reminderNotificationDayTitle => 'Bir gün sonra';

  @override
  String ticketStatusLabel(Object status) {
    return 'Durum: $status';
  }

  @override
  String get addToCalendarButton => 'Takvime ekle';

  @override
  String get ticketScanHeading => 'Girişte okutun';

  @override
  String get ticketCopyCode => 'Kodu kopyala';

  @override
  String get ticketCodeCopied => 'Bilet kodu kopyalandı';

  @override
  String get eventDetailsButton => 'Etkinlik detayı';

  @override
  String get ticketPageTitleDefault => 'Biletiniz';

  @override
  String get ticketNoTicketYet => 'Bu etkinlik için henüz biletiniz yok.';

  @override
  String get ticketRegisterFirst => 'Önce etkinlik sayfasından kayıt olun.';

  @override
  String get pillReadyToScan => 'Okutmaya hazır';

  @override
  String get pillCheckedIn => 'Giriş yapıldı';

  @override
  String get pillCancelled => 'İptal';

  @override
  String get ticketRegistrationPrefix => 'Kayıt';

  @override
  String get ticketCheckedInPrefix => 'Giriş yapıldı';

  @override
  String get settingsSavedToCalendar => 'Takvime kaydedildi';

  @override
  String settingsCouldNotAddCalendar(Object error) {
    return 'Takvime eklenemedi: $error';
  }
}
