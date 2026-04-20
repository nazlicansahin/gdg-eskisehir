import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/l10n/app_localizations.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;
  var _registerMode = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // GDG Logo text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('G',
                          style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: GdgTheme.googleBlue)),
                      Text('D',
                          style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: GdgTheme.googleRed)),
                      Text('G',
                          style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: GdgTheme.googleYellow)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.eskisehirBrand,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.communityEventsSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 36),

                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text(l10n.signInSegment),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text(l10n.createAccountSegment),
                      ),
                    ],
                    selected: {_registerMode},
                    onSelectionChanged: (s) =>
                        setState(() => _registerMode = s.first),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? l10n.requiredField
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _registerMode
                                  ? l10n.submitCreateAccount
                                  : l10n.submitSignIn),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _loading = true);
    final r = _registerMode
        ? await ref.read(authRepositoryProvider).signUpWithEmail(
              email: _email.text,
              password: _password.text,
            )
        : await ref.read(authRepositoryProvider).signInWithEmail(
              email: _email.text,
              password: _password.text,
            );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    r.fold(
      (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.asUserMessage)),
        );
      },
      (_) async {
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
        if (!mounted) {
          return;
        }
        context.go('/events');
      },
    );
  }
}
