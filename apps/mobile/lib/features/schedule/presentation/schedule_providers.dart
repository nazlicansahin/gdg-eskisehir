import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/features/schedule/domain/entities/schedule_session.dart';

final eventScheduleProvider =
    FutureProvider.autoDispose.family<List<ScheduleSession>, String>((
  ref,
  eventID,
) async {
  final result =
      await ref.watch(scheduleRepositoryProvider).listByEvent(eventID);
  return result.fold(
    (f) => throw FailureException(f),
    (rows) => rows,
  );
});
