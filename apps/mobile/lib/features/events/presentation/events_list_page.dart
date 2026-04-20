import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/core/event/event_description.dart';
import 'package:gdg_events/core/event/event_time_filter.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
import 'package:gdg_events/features/events/domain/event_status.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:gdg_events/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventsListPage extends ConsumerStatefulWidget {
  const EventsListPage({super.key});

  @override
  ConsumerState<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends ConsumerState<EventsListPage> {
  EventTimeFilter _filter = EventTimeFilter.all;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventsListProvider);
    final l10n = AppLocalizations.of(context)!;

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
            Text(l10n.eventsScreenTitle),
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
                    l10n.eventsEmptyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.eventsEmptySubtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          final filtered = filterAndSortEvents(events, _filter);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EventTimeFilterBar(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
                labelFor: (f) => switch (f) {
                  EventTimeFilter.all => l10n.filterAll,
                  EventTimeFilter.upcoming => l10n.filterUpcoming,
                  EventTimeFilter.live => l10n.filterLive,
                  EventTimeFilter.past => l10n.filterPast,
                },
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.filter_alt_off_outlined,
                                  size: 56, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                l10n.eventsFilteredEmptyTitle,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.eventsFilteredEmptySubtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: GdgTheme.googleBlue,
                        onRefresh: () async {
                          ref.invalidate(eventsListProvider);
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _EventCard(event: filtered[i]),
                          ),
                        ),
                      ),
              ),
            ],
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
    final l10n = AppLocalizations.of(context)!;
    final df = DateFormat.yMMMd().add_Hm();
    final theme = Theme.of(context);
    final isUpcoming = event.startsAt.isAfter(DateTime.now());
    final cover = eventCoverImageUrl(event.description);
    const imgHeight = 152.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: imgHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cover != null)
                    Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _CardImageFallback(
                        event: event,
                        accent: _accentColor(event.status),
                      ),
                    )
                  else
                    _CardImageFallback(
                      event: event,
                      accent: _accentColor(event.status),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _StatusChip(status: event.status, isUpcoming: isUpcoming),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          df.format(event.startsAt.toLocal()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        l10n.capacityEvents(event.capacity),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

class _CardImageFallback extends StatelessWidget {
  const _CardImageFallback({required this.event, required this.accent});
  final Event event;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.35),
            GdgTheme.googleBlue.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          DateFormat.d().format(event.startsAt.toLocal()),
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.95),
            shadows: const [Shadow(blurRadius: 12, color: Colors.black26)],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.isUpcoming = false});

  final EventStatus status;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, bg, fg) = switch (status) {
      EventStatus.published => isUpcoming
          ? (
              l10n.eventCardUpcoming,
              GdgTheme.googleGreen.withValues(alpha: 0.12),
              GdgTheme.googleGreen,
            )
          : (
              l10n.eventCardLive,
              GdgTheme.googleBlue.withValues(alpha: 0.12),
              GdgTheme.googleBlue,
            ),
      EventStatus.cancelled => (
          l10n.eventCardCancelled,
          GdgTheme.googleRed.withValues(alpha: 0.12),
          GdgTheme.googleRed,
        ),
      EventStatus.draft => (
          l10n.eventCardDraft,
          GdgTheme.googleYellow.withValues(alpha: 0.12),
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
