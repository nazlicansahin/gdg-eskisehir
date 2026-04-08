import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:gdg_events/features/registration/presentation/registration_providers.dart';
import 'package:go_router/go_router.dart';

class TicketsListPage extends ConsumerWidget {
  const TicketsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(myRegistrationsProvider);
    final eventsAsync = ref.watch(eventsListProvider);
    final eventTitleByID = {
      for (final e in eventsAsync.valueOrNull ?? const []) e.id: e.title,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg =
              e is FailureException ? e.failure.asUserMessage : e.toString();
          return Center(child: Text(msg));
        },
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tickets yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Register for events to get your tickets here.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: GdgTheme.googleBlue,
            onRefresh: () async => ref.invalidate(myRegistrationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: tickets.length,
              itemBuilder: (context, i) {
                final t = tickets[i];
                final title = eventTitleByID[t.eventId] ?? 'Event';
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GdgTheme.googleBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.qr_code_2_rounded,
                          color: GdgTheme.googleBlue, size: 22),
                    ),
                    title: Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Status: ${t.status.name}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => context.push('/events/${t.eventId}/ticket'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
