import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/domain/event_status.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventsListPage extends ConsumerWidget {
  const EventsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg = e is FailureException
              ? e.failure.asUserMessage
              : e.toString();
          return Center(child: Text(msg));
        },
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No published events yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventsListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: events.length,
              itemBuilder: (context, i) {
                final event = events[i];
                final df = DateFormat.yMMMd().add_Hm();
                return ListTile(
                  title: Text(event.title),
                  subtitle: Text(df.format(event.startsAt.toLocal())),
                  trailing: _StatusChip(status: event.status),
                  onTap: () => context.push('/events/${event.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      EventStatus.published => 'Live',
      EventStatus.cancelled => 'Cancelled',
      EventStatus.draft => 'Draft',
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }
}
