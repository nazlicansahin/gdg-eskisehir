import 'package:equatable/equatable.dart';
import 'package:gdg_events/features/events/domain/event_status.dart';

class Event extends Equatable {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.capacity,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String title;
  final String? description;
  final EventStatus status;
  final int capacity;
  final DateTime startsAt;
  final DateTime endsAt;

  bool get isRegisterable => status == EventStatus.published;

  @override
  List<Object?> get props =>
      [id, title, description, status, capacity, startsAt, endsAt];
}
