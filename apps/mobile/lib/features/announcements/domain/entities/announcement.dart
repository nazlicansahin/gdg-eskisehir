import 'package:equatable/equatable.dart';

class Announcement extends Equatable {
  const Announcement({
    required this.id,
    this.eventId,
    required this.title,
    required this.body,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String? eventId;
  final String title;
  final String body;
  final String createdBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, eventId, title, body, createdBy, createdAt];
}
