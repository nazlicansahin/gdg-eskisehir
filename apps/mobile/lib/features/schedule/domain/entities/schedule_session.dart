import 'package:equatable/equatable.dart';
import 'package:gdg_events/features/speakers/domain/entities/speaker.dart';

class ScheduleSession extends Equatable {
  const ScheduleSession({
    required this.id,
    required this.eventId,
    required this.title,
    this.description,
    this.room,
    required this.startsAt,
    required this.endsAt,
    required this.speakers,
  });

  final String id;
  final String eventId;
  final String title;
  final String? description;
  final String? room;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<Speaker> speakers;

  @override
  List<Object?> get props =>
      [id, eventId, title, description, room, startsAt, endsAt, speakers];
}
