import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';

/// Reads published events from the public GraphQL API.
abstract class EventsRepository {
  Future<Either<Failure, List<Event>>> listPublished();

  Future<Either<Failure, Event>> getPublished(String id);

  Future<Either<Failure, Event>> updateEvent({
    required String id,
    String? title,
    String? description,
    int? capacity,
    DateTime? startsAt,
    DateTime? endsAt,
  });

  Future<Either<Failure, Event>> publishEvent(String id);

  Future<Either<Failure, Event>> cancelEvent(String id, String reason);
}
