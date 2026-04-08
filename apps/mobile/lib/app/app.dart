import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/app_router.dart';
import 'package:gdg_events/app/theme.dart';

class GdgEventsApp extends ConsumerWidget {
  const GdgEventsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'GDG Eskisehir',
      debugShowCheckedModeBanner: false,
      theme: GdgTheme.light(),
      routerConfig: router,
    );
  }
}
