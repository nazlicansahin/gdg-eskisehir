import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/auth_refresh.dart';
import 'package:gdg_events/features/auth/presentation/login_page.dart';
import 'package:gdg_events/features/events/presentation/event_detail_page.dart';
import 'package:gdg_events/features/events/presentation/events_list_page.dart';
import 'package:gdg_events/features/announcements/presentation/create_announcement_page.dart';
import 'package:gdg_events/features/checkin/presentation/checkin_scan_page.dart';
import 'package:gdg_events/features/profile/presentation/profile_page.dart';
import 'package:gdg_events/features/registration/presentation/ticket_page.dart';
import 'package:gdg_events/features/registration/presentation/tickets_list_page.dart';
import 'package:gdg_events/features/shell/main_shell.dart';
import 'package:go_router/go_router.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = AuthRefreshListenable(FirebaseAuth.instance);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/events',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final onAuthPage = state.uri.path == '/login';
      if (!loggedIn && !onAuthPage) {
        return '/login';
      }
      if (loggedIn && onAuthPage) {
        return '/events';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/events',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EventsListPage(),
            ),
            routes: [
              GoRoute(
                path: ':eventId',
                builder: (context, state) {
                  final id = state.pathParameters['eventId']!;
                  return EventDetailPage(eventId: id);
                },
                routes: [
                  GoRoute(
                    path: 'ticket',
                    builder: (context, state) {
                      final id = state.pathParameters['eventId']!;
                      return TicketPage(eventId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/tickets',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TicketsListPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
          GoRoute(
            path: '/check-in',
            builder: (context, state) {
              final eventId = state.uri.queryParameters['eventId'];
              return CheckInScanPage(initialEventId: eventId);
            },
          ),
          GoRoute(
            path: '/announcements/new',
            builder: (context, state) => const CreateAnnouncementPage(),
          ),
        ],
      ),
    ],
  );
});
