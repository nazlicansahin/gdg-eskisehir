import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/profile/domain/entities/profile_user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileUser>> me();

  Future<Either<Failure, ProfileUser>> updateMyProfile({
    required String displayName,
  });

  /// Deletes application data via GraphQL; caller should also delete the Firebase Auth user.
  Future<Either<Failure, Unit>> deleteMyAccount();
}
