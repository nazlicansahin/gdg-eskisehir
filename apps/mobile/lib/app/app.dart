import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/app_router.dart';

class GdgEventsApp extends ConsumerWidget {
  const GdgEventsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'GDG Eskişehir',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4285F4),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
