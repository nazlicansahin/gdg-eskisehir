import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/domain/event_status.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg = e is FailureException
              ? e.failure.asUserMessage
              : e.toString();
          return Center(child: Text(msg));
        },
        data: (event) {
          final df = DateFormat.yMMMd().add_Hm();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '${df.format(event.startsAt.toLocal())} – '
                '${df.format(event.endsAt.toLocal())}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text('Capacity: ${event.capacity}'),
              if (event.description != null && event.description!.isNotEmpty) ...[
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
              else
                FilledButton(
                  onPressed: () => registerForEventTap(context, ref, eventId),
                  child: const Text('Register'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/events/$eventId/ticket'),
                child: const Text('View my ticket'),
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
    (_) => context.push('/events/$eventId/ticket'),
  );
}
