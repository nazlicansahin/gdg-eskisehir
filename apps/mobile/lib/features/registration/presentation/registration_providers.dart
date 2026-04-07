import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/features/registration/domain/entities/registration_ticket.dart';

final myRegistrationsProvider =
    FutureProvider.autoDispose<List<RegistrationTicket>>((ref) async {
  final result =
      await ref.watch(registrationsRepositoryProvider).myRegistrations();
  return result.fold(
    (f) => throw FailureException(f),
    (list) => list,
  );
});

final myTicketProvider = FutureProvider.autoDispose
    .family<RegistrationTicket?, String>((ref, eventId) async {
  final result =
      await ref.watch(registrationsRepositoryProvider).myTicket(eventId);
  return result.fold(
    (f) => throw FailureException(f),
    (t) => t,
  );
});
