import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/registration/presentation/registration_providers.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketPage extends ConsumerWidget {
  const TicketPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myTicketProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Your ticket')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg = e is FailureException
              ? e.failure.asUserMessage
              : e.toString();
          return Center(child: Text(msg));
        },
        data: (ticket) {
          if (ticket == null) {
            return const Center(
              child: Text('No ticket for this event yet. Register first.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: QrImageView(
                  data: ticket.qrCodeValue,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text('Status: ${ticket.status.name}'),
              if (ticket.checkedInAt != null)
                Text(
                  'Checked in: '
                  '${DateFormat.yMMMd().add_Hm().format(ticket.checkedInAt!.toLocal())}',
                ),
            ],
          );
        },
      ),
    );
  }
}
