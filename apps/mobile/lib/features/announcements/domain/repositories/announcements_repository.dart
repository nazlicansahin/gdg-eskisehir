import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/announcements/domain/entities/announcement.dart';

abstract class AnnouncementsRepository {
  Future<Either<Failure, Announcement>> create({
    String? eventId,
    required String title,
    required String body,
  });

  Future<Either<Failure, List<Announcement>>> listByEvent(String eventId);

  Future<Either<Failure, List<Announcement>>> listAll();
}
