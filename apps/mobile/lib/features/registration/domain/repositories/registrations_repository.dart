import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/registration/domain/entities/registration_ticket.dart';

abstract class RegistrationsRepository {
  Future<Either<Failure, List<RegistrationTicket>>> myRegistrations();

  Future<Either<Failure, RegistrationTicket>> registerForEvent(String eventId);

  Future<Either<Failure, RegistrationTicket?>> myTicket(String eventId);
}
