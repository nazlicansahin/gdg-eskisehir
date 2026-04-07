import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/auth/domain/entities/app_user.dart';
import 'package:gdg_events/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._firebaseAuth);

  final fb.FirebaseAuth _firebaseAuth;

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((u) {
      if (u == null) return null;
      return AppUser(id: u.uid, email: u.email, displayName: u.displayName);
    });
  }

  @override
  Future<Either<Failure, Unit>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return const Right(unit);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();
}
