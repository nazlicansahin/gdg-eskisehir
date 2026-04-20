import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/core/event/event_time_filter.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:gdg_events/features/registration/presentation/registration_providers.dart';
import 'package:gdg_events/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class TicketsListPage extends ConsumerStatefulWidget {
  const TicketsListPage({super.key});

  @override
  ConsumerState<TicketsListPage> createState() => _TicketsListPageState();
}

class _TicketsListPageState extends ConsumerState<TicketsListPage> {
  EventTimeFilter _filter = EventTimeFilter.all;

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(myRegistrationsProvider);
    final eventsAsync = ref.watch(eventsListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTicketsTitle)),
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
                    l10n.noTicketsYet,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.noTicketsSubtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final eventsErrored = eventsAsync.hasError;
          final eventsLoading =
              eventsAsync.isLoading && eventsAsync.valueOrNull == null;
          if (_filter != EventTimeFilter.all && eventsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final eventsList = eventsAsync.valueOrNull ?? const <Event>[];
          final eventById = {for (final e in eventsList) e.id: e};
          final eventTitleByID = {for (final e in eventsList) e.id: e.title};

          final filtered = filterAndSortTicketsByEventTime(
            tickets,
            eventById,
            _filter,
            showAllIfEventMissing: eventsErrored,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (eventsErrored)
                Material(
                  color: GdgTheme.googleYellow.withValues(alpha: 0.12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: Colors.grey[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.ticketsEventsLoadWarning,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                                l10n.ticketsFilteredEmptyTitle,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.ticketsFilteredEmptySubtitle,
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
                          ref.invalidate(myRegistrationsProvider);
                          ref.invalidate(eventsListProvider);
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.only(top: 4, bottom: 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final t = filtered[i];
                            final title =
                                eventTitleByID[t.eventId] ??
                                    l10n.eventFallbackTitle;
                            return Card(
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: GdgTheme.googleBlue
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.qr_code_2_rounded,
                                      color: GdgTheme.googleBlue, size: 22),
                                ),
                                title: Text(title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  l10n.ticketStatusLabel(t.status.name),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                                trailing: const Icon(Icons.chevron_right,
                                    color: Colors.grey),
                                onTap: () => context
                                    .push('/events/${t.eventId}/ticket'),
                              ),
                            );
                          },
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
