import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_locale_language_code';

final appLocaleProvider =
    AsyncNotifierProvider<AppLocaleNotifier, Locale>(AppLocaleNotifier.new);

class AppLocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == 'tr') return const Locale('tr');
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    final code = locale.languageCode == 'tr' ? 'tr' : 'en';
    await prefs.setString(_prefsKey, code);
    final resolved =
        code == 'tr' ? const Locale('tr') : const Locale('en');
    state = AsyncData(resolved);
  }
}
