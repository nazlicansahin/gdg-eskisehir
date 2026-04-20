import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/profile/presentation/profile_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:gdg_events/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _displayName = TextEditingController();
  var _saving = false;
  var _deletingAccount = false;

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
              if (AppConfig.legalSiteBaseUrl.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  'Legal',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.privacy_tip_outlined,
                          color: GdgTheme.googleBlue,
                        ),
                        title: const Text('Privacy policy'),
                        trailing: Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        onTap: () => _openLegalPage('privacy'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.description_outlined,
                          color: Colors.grey[700],
                        ),
                        title: const Text('Terms of use'),
                        trailing: Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        onTap: () => _openLegalPage('terms'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.support_agent_outlined,
                          color: GdgTheme.googleGreen,
                        ),
                        title: const Text('Support'),
                        trailing: Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        onTap: () => _openLegalPage('support'),
                      ),
                    ],
                  ),
                ),
              ],
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: GdgTheme.googleRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _deletingAccount
                      ? null
                      : () => _confirmDeleteAccount(profile.email),
                  child: _deletingAccount
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Delete account'),
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

  Future<void> _openLegalPage(String segment) async {
    final lang = Localizations.localeOf(context)
            .languageCode
            .toLowerCase()
            .startsWith('tr')
        ? 'tr'
        : 'en';
    final uri =
        AppConfig.legalDocumentUri(localeCode: lang, segment: segment);
    final ok =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || ok) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open link')),
    );
  }

  Future<void> _confirmDeleteAccount(String accountEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) {
      return;
    }

    final usesPasswordProvider = user.providerData
        .any((p) => p.providerId == EmailAuthProvider.PROVIDER_ID);

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteAccountDialog(
        email: accountEmail,
        requirePassword: usesPasswordProvider,
      ),
    );

    if (password == null || !mounted) {
      return;
    }

    setState(() => _deletingAccount = true);

    try {
      if (usesPasswordProvider) {
        final cred = EmailAuthProvider.credential(
          email: user.email ?? accountEmail,
          password: password,
        );
        await user.reauthenticateWithCredential(cred);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _deletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not verify password (${e.code})'),
        ),
      );
      return;
    }

    final result = await ref.read(profileRepositoryProvider).deleteMyAccount();

    if (!mounted) {
      return;
    }

    await result.fold(
      (Failure f) async {
        setState(() => _deletingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.asUserMessage)),
        );
      },
      (_) async {
        try {
          await FirebaseAuth.instance.currentUser?.delete();
        } on FirebaseAuthException catch (e) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) {
            return;
          }
          setState(() => _deletingAccount = false);
          context.go('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.code == 'requires-recent-login'
                    ? 'Server data was removed. Sign in again, then try deleting your account once more, or contact support.'
                    : (e.message ?? 'Could not remove login'),
              ),
            ),
          );
          return;
        }

        if (!mounted) {
          return;
        }
        setState(() => _deletingAccount = false);
        context.go('/login');
      },
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

/// Confirmation + optional password for Firebase reauthentication before deletion.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({
    required this.email,
    required this.requirePassword,
  });

  final String email;
  final bool requirePassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.requirePassword) {
      final p = _password.text.trim();
      if (p.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter your password to confirm')),
        );
        return;
      }
      Navigator.of(context).pop(p);
      return;
    }
    Navigator.of(context).pop('');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This permanently deletes your profile, registrations, and related data. '
              'You will not be able to recover this information.',
            ),
            const SizedBox(height: 12),
            Text(
              widget.email,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (widget.requirePassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: _obscure,
                autofocus: true,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password to confirm',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: GdgTheme.googleRed),
          onPressed: _submit,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
