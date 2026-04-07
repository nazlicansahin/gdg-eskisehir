import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] when Firebase auth state changes so redirects re-run.
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(this._auth) {
    _sub = _auth.authStateChanges().listen((_) => notifyListeners());
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
