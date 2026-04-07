import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/schedule/domain/entities/schedule_session.dart';

abstract class ScheduleRepository {
  Future<Either<Failure, List<ScheduleSession>>> listByEvent(String eventId);
}
