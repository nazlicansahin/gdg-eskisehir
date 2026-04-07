import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';

abstract class CheckInRepository {
  Future<Either<Failure, void>> checkInByQr({
    required String eventId,
    required String qrCode,
  });
}
