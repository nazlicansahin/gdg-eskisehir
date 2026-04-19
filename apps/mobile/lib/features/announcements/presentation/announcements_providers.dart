import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/features/announcements/domain/entities/announcement.dart';

final eventAnnouncementsProvider =
    FutureProvider.family.autoDispose<List<Announcement>, String>(
  (ref, eventId) async {
    final result =
        await ref.watch(announcementsRepositoryProvider).listByEvent(eventId);
    return result.fold(
      (f) => throw FailureException(f),
      (list) => list,
    );
  },
);
