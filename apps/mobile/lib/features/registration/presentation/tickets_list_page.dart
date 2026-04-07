import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/registration/presentation/registration_providers.dart';
import 'package:go_router/go_router.dart';

class TicketsListPage extends ConsumerWidget {
  const TicketsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRegistrationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My tickets')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg = e is FailureException
              ? e.failure.asUserMessage
              : e.toString();
          return Center(child: Text(msg));
        },
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(child: Text('No registrations yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myRegistrationsProvider),
            child: ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, i) {
                final t = tickets[i];
                return ListTile(
                  title: Text('Event ${t.eventId}'),
                  subtitle: Text('Status: ${t.status.name}'),
                  trailing: const Icon(Icons.qr_code_2),
                  onTap: () => context.push('/events/${t.eventId}/ticket'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
