import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<Either<Failure, Unit>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
