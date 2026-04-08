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
  var _pushInitialized = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    if (!_pushInitialized && FirebaseAuth.instance.currentUser != null) {
      _pushInitialized = true;
      Future.microtask(() => ref.read(pushServiceProvider).init());
    }

    return MaterialApp.router(
      title: 'GDG Eskisehir',
      debugShowCheckedModeBanner: false,
      theme: GdgTheme.light(),
      routerConfig: router,
    );
  }
}
