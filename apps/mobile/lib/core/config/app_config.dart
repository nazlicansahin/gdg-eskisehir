/// Runtime configuration. Pass via `--dart-define=API_BASE_URL=https://...`.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8081',
  );

  static Uri get graphqlUri => Uri.parse('$apiBaseUrl/graphql');
}
