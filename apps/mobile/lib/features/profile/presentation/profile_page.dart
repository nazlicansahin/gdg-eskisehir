import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/app/theme.dart';
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

          final initial = profile.displayName.isNotEmpty
              ? profile.displayName[0].toUpperCase()
              : '?';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar + name header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: GdgTheme.googleBlue.withOpacity(0.12),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: GdgTheme.googleBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: profile.roles.map((role) {
                        final color = _roleColor(role);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              if (profile.canScanTickets) ...[
                Card(
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: GdgTheme.googleGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.qr_code_scanner,
                          color: GdgTheme.googleGreen, size: 20),
                    ),
                    title: const Text('Scan tickets',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Check in attendees by QR'),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => context.push('/check-in'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (profile.canEditEvents) ...[
                Card(
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: GdgTheme.googleYellow.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.campaign_rounded,
                          color: GdgTheme.googleYellow, size: 20),
                    ),
                    title: const Text('Send announcement',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle:
                        const Text('Notify attendees about updates'),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => context.push('/announcements/new'),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Edit display name
              Text('Display name',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: _displayName,
                decoration: const InputDecoration(
                  hintText: 'Your display name',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveProfile,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save profile'),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  child: const Text('Sign out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _roleColor(String role) => switch (role) {
        'organizer' => GdgTheme.googleBlue,
        'super_admin' => GdgTheme.googleRed,
        'team_member' => GdgTheme.googleGreen,
        'crew' => GdgTheme.googleYellow,
        _ => Colors.grey,
      };

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
