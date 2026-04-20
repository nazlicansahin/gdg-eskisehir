import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/app_locale_provider.dart';
import 'package:gdg_events/app/app_router.dart';
import 'package:gdg_events/app/event_reminders_coordinator.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/l10n/app_localizations.dart';

class GdgEventsApp extends ConsumerStatefulWidget {
  const GdgEventsApp({super.key});

  @override
  ConsumerState<GdgEventsApp> createState() => _GdgEventsAppState();
}

class _GdgEventsAppState extends ConsumerState<GdgEventsApp> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;
      if (user == null) {
        await ref.read(eventRemindersCoordinatorProvider).cancelAll();
        return;
      }
      final push = ref.read(pushServiceProvider);
      Future.microtask(() async {
        if (!mounted) return;
        await push.init();
        await push.registerDeviceTokenWithBackend();
        await ref.read(eventRemindersCoordinatorProvider).sync();
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final localeAsync = ref.watch(appLocaleProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('en');

    return MaterialApp.router(
      title: 'GDG Eskisehir',
      debugShowCheckedModeBanner: false,
      theme: GdgTheme.light(),
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
