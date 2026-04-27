import 'package:flutter/foundation.dart';

/// Runtime configuration. Pass via `--dart-define=API_BASE_URL=https://...`.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8081',
  );

  /// Public HTTPS origin of the legal website (Next.js `apps/web`), no trailing slash.
  /// Example: `--dart-define=LEGAL_SITE_BASE_URL=https://events.example.com`
  /// When empty, Profile hides in-app Privacy / Terms / Support links.
  static const String legalSiteBaseUrl = String.fromEnvironment(
    'LEGAL_SITE_BASE_URL',
    defaultValue: '',
  );

  /// Optional override to enforce anti-tamper checks in non-release builds.
  static const bool enforceAntiTamper = bool.fromEnvironment(
    'ENFORCE_ANTI_TAMPER',
    defaultValue: false,
  );

  static bool get shouldEnforceAntiTamper => kReleaseMode || enforceAntiTamper;

  static Uri get graphqlUri => Uri.parse('$apiBaseUrl/graphql');

  /// Resolves `/[locale]/[page]` on the configured legal site (privacy, terms, support).
  static Uri legalDocumentUri({
    required String localeCode,
    required String segment,
  }) {
    final base = legalSiteBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = '$base/$localeCode/$segment';
    return Uri.parse(path);
  }
}
