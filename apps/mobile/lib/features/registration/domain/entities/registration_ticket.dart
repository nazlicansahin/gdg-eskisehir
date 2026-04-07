import 'package:equatable/equatable.dart';
import 'package:gdg_events/features/registration/domain/registration_status.dart';

class RegistrationTicket extends Equatable {
  const RegistrationTicket({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.qrCodeValue,
    this.checkedInAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final RegistrationStatus status;
  final String qrCodeValue;
  final DateTime? checkedInAt;

  @override
  List<Object?> get props =>
      [id, eventId, userId, status, qrCodeValue, checkedInAt];
}
