import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/features/auth/presentation/auth_providers.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ListTile(
                title: const Text('Email'),
                subtitle: Text(user.email ?? '—'),
              ),
              ListTile(
                title: const Text('Display name'),
                subtitle: Text(user.displayName ?? '—'),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
