import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/schedule/domain/entities/schedule_session.dart';

abstract class ScheduleRepository {
  Future<Either<Failure, List<ScheduleSession>>> listByEvent(String eventId);

  Future<Either<Failure, void>> updateSession({
    required String id,
    String? title,
    String? description,
    String? room,
    DateTime? startsAt,
    DateTime? endsAt,
  });

  Future<Either<Failure, void>> updateSpeaker({
    required String id,
    String? fullName,
    String? bio,
    String? avatarUrl,
  });

  Future<Either<Failure, String>> createSession({
    required String eventId,
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
    String? room,
  });

  Future<Either<Failure, String>> createSpeaker({
    required String fullName,
    String? bio,
    String? avatarUrl,
  });

  Future<Either<Failure, void>> attachSpeakerToSession({
    required String sessionId,
    required String speakerId,
  });
}
