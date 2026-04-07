import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/domain/event_status.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:gdg_events/features/registration/presentation/registration_providers.dart';
import 'package:gdg_events/features/schedule/presentation/schedule_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventDetailProvider(eventId));
    final myTicketAsync = ref.watch(myTicketProvider(eventId));
    final scheduleAsync = ref.watch(eventScheduleProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg =
              e is FailureException ? e.failure.asUserMessage : e.toString();
          return Center(child: Text(msg));
        },
        data: (event) {
          final hasTicket = myTicketAsync.valueOrNull != null;
          final df = DateFormat.yMMMd().add_Hm();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${df.format(event.startsAt.toLocal())} – '
                '${df.format(event.endsAt.toLocal())}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text('Capacity: ${event.capacity}'),
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(event.description!),
              ],
              const SizedBox(height: 24),
              if (event.status == EventStatus.cancelled)
                const Text(
                  'Registration is closed for cancelled events.',
                )
              else if (!event.isRegisterable)
                const Text('This event is not open for registration.')
              else if (hasTicket)
                const Text('You are already registered for this event.')
              else
                FilledButton(
                  onPressed: () => registerForEventTap(context, ref, eventId),
                  child: const Text('Register'),
                ),
              if (hasTicket) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    ref.invalidate(myTicketProvider(eventId));
                    context.push('/events/$eventId/ticket');
                  },
                  child: const Text('View my ticket'),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Schedule',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              scheduleAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Text(
                  e is FailureException ? e.failure.asUserMessage : '$e',
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const Text('No sessions yet.');
                  }
                  final tf = DateFormat.Hm();
                  return Column(
                    children: sessions
                        .map(
                          (s) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(s.title),
                            subtitle: Text(
                              '${tf.format(s.startsAt.toLocal())} - '
                              '${tf.format(s.endsAt.toLocal())}'
                              '${s.room == null || s.room!.isEmpty ? '' : ' · ${s.room}'}',
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Speakers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              scheduleAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text(
                  e is FailureException ? e.failure.asUserMessage : '$e',
                ),
                data: (sessions) {
                  final byId = <String, String>{};
                  for (final s in sessions) {
                    for (final sp in s.speakers) {
                      byId[sp.id] = sp.fullName;
                    }
                  }
                  if (byId.isEmpty) {
                    return const Text('No speakers yet.');
                  }
                  return Column(
                    children: byId.values
                        .map(
                          (name) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.person_outline),
                            title: Text(name),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> registerForEventTap(
  BuildContext context,
  WidgetRef ref,
  String eventId,
) async {
  final result =
      await ref.read(registrationsRepositoryProvider).registerForEvent(eventId);
  if (!context.mounted) {
    return;
  }
  result.fold(
    (Failure f) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.asUserMessage)),
      );
    },
    (_) {
      ref.invalidate(myTicketProvider(eventId));
      ref.invalidate(myRegistrationsProvider);
      context.push('/events/$eventId/ticket');
    },
  );
}
