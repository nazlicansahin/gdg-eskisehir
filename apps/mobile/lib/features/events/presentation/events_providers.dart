import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';

final eventsListProvider = FutureProvider<List<Event>>((ref) async {
  final result = await ref.watch(eventsRepositoryProvider).listPublished();
  return result.fold(
    (f) => throw FailureException(f),
    (events) => events,
  );
});

final eventDetailProvider = FutureProvider.family<Event, String>((ref, id) async {
  final result = await ref.watch(eventsRepositoryProvider).getPublished(id);
  return result.fold(
    (f) => throw FailureException(f),
    (event) => event,
  );
});
