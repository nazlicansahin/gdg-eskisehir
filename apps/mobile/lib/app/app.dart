import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/app_router.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/app/theme.dart';

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
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user == null) return;
      final push = ref.read(pushServiceProvider);
      Future.microtask(() async {
        await push.init();
        await push.registerDeviceTokenWithBackend();
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

    return MaterialApp.router(
      title: 'GDG Eskisehir',
      debugShowCheckedModeBanner: false,
      theme: GdgTheme.light(),
      routerConfig: router,
    );
  }
}
