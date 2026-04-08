import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
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
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'G',
              style: TextStyle(
                color: GdgTheme.googleBlue,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            Text(
              'D',
              style: TextStyle(
                color: GdgTheme.googleRed,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            Text(
              'G',
              style: TextStyle(
                color: GdgTheme.googleYellow,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Events'),
          ],
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg =
              e is FailureException ? e.failure.asUserMessage : e.toString();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(msg, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.celebration_outlined,
                      size: 64, color: GdgTheme.googleYellow),
                  const SizedBox(height: 16),
                  Text(
                    'No events yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stay tuned for upcoming community meetups!',
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
            onRefresh: () async {
              ref.invalidate(eventsListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: events.length,
              itemBuilder: (context, i) => _EventCard(event: events[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_Hm();
    final theme = Theme.of(context);
    final isUpcoming = event.startsAt.isAfter(DateTime.now());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _accentColor(event.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    DateFormat.d().format(event.startsAt.toLocal()),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _accentColor(event.status),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      df.format(event.startsAt.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: event.status, isUpcoming: isUpcoming),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentColor(EventStatus status) => switch (status) {
        EventStatus.published => GdgTheme.googleGreen,
        EventStatus.cancelled => GdgTheme.googleRed,
        EventStatus.draft => GdgTheme.googleYellow,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.isUpcoming = false});

  final EventStatus status;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      EventStatus.published => isUpcoming
          ? ('Upcoming', GdgTheme.googleGreen.withOpacity(0.12), GdgTheme.googleGreen)
          : ('Live', GdgTheme.googleBlue.withOpacity(0.12), GdgTheme.googleBlue),
      EventStatus.cancelled => (
          'Cancelled',
          GdgTheme.googleRed.withOpacity(0.12),
          GdgTheme.googleRed,
        ),
      EventStatus.draft => (
          'Draft',
          GdgTheme.googleYellow.withOpacity(0.12),
          const Color(0xFFE37400),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
