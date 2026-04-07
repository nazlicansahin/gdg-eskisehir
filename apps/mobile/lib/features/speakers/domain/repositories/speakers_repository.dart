import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/speakers/domain/entities/speaker.dart';

abstract class SpeakersRepository {
  Future<Either<Failure, List<Speaker>>> list({String? query});

  Future<Either<Failure, Speaker>> getByID(String id);
}
