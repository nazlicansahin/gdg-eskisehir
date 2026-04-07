import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation aligned with [apps/mobile/README.md] (subset for MVP).
class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  int _indexForLocation(String path) {
    if (path.startsWith('/tickets')) {
      return 1;
    }
    if (path.startsWith('/profile')) {
      return 2;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = _indexForLocation(path);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          if (i == 0) {
            context.go('/events');
          } else if (i == 1) {
            context.go('/tickets');
          } else if (i == 2) {
            context.go('/profile');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
