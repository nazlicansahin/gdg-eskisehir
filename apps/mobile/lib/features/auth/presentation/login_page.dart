import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/app/theme.dart';
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
                    'Eskisehir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Community Events',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 36),

                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Sign in'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Create account'),
                      ),
                    ],
                    selected: {_registerMode},
                    onSelectionChanged: (s) =>
                        setState(() => _registerMode = s.first),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
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
                              _registerMode ? 'Create account' : 'Sign in'),
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
