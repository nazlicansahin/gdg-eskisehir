import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/profile/presentation/profile_providers.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _displayName = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg = e is FailureException ? e.failure.asUserMessage : '$e';
          return Center(child: Text(msg));
        },
        data: (profile) {
          if (_displayName.text != profile.displayName) {
            _displayName.text = profile.displayName;
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ListTile(
                title: const Text('Email'),
                subtitle: Text(profile.email),
              ),
              ListTile(
                title: const Text('Roles'),
                subtitle: Text(profile.roles.join(', ')),
              ),
              if (profile.canScanTickets) ...[
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Scan tickets'),
                  subtitle: const Text('Check in attendees by QR'),
                  onTap: () => context.push('/check-in'),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _displayName,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save profile'),
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

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final result = await ref.read(profileRepositoryProvider).updateMyProfile(
          displayName: _displayName.text,
        );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    result.fold(
      (Failure f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.asUserMessage)),
        );
      },
      (_) {
        ref.invalidate(profileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      },
    );
  }
}
