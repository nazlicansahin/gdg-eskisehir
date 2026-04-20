import 'package:flutter/material.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
import 'package:gdg_events/features/registration/domain/entities/registration_ticket.dart';

/// Time scope for event lists (events + tickets).
enum EventTimeFilter {
  all,
  upcoming,
  live,
  past,
}

bool eventMatchesTimeFilter(Event event, EventTimeFilter filter, DateTime now) {
  switch (filter) {
    case EventTimeFilter.all:
      return true;
    case EventTimeFilter.upcoming:
      return event.startsAt.isAfter(now);
    case EventTimeFilter.live:
      return !event.startsAt.isAfter(now) && !event.endsAt.isBefore(now);
    case EventTimeFilter.past:
      return event.endsAt.isBefore(now);
  }
}

List<Event> filterAndSortEvents(List<Event> events, EventTimeFilter filter) {
  final now = DateTime.now();
  final filtered =
      events.where((e) => eventMatchesTimeFilter(e, filter, now)).toList();
  filtered.sort((a, b) {
    if (filter == EventTimeFilter.past) {
      return b.startsAt.compareTo(a.startsAt);
    }
    return a.startsAt.compareTo(b.startsAt);
  });
  return filtered;
}

List<RegistrationTicket> filterAndSortTicketsByEventTime(
  List<RegistrationTicket> tickets,
  Map<String, Event> eventById,
  EventTimeFilter filter, {
  bool showAllIfEventMissing = false,
}) {
  final now = DateTime.now();
  final filtered = tickets.where((t) {
    final e = eventById[t.eventId];
    if (e == null) {
      return filter == EventTimeFilter.all || showAllIfEventMissing;
    }
    return eventMatchesTimeFilter(e, filter, now);
  }).toList();
  filtered.sort((a, b) {
    final ea = eventById[a.eventId];
    final eb = eventById[b.eventId];
    if (ea == null || eb == null) {
      return 0;
    }
    if (filter == EventTimeFilter.past) {
      return eb.startsAt.compareTo(ea.startsAt);
    }
    return ea.startsAt.compareTo(eb.startsAt);
  });
  return filtered;
}

/// Horizontal scrollable chips — common pattern for list filters.
class EventTimeFilterBar extends StatelessWidget {
  const EventTimeFilterBar({
    required this.selected,
    required this.onSelected,
    required this.labelFor,
    super.key,
  });

  final EventTimeFilter selected;
  final ValueChanged<EventTimeFilter> onSelected;
  final String Function(EventTimeFilter filter) labelFor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final f in EventTimeFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected == f,
                label: Text(labelFor(f)),
                showCheckmark: false,
                onSelected: (_) => onSelected(f),
                selectedColor: scheme.primary.withValues(alpha: 0.14),
                side: BorderSide(
                  color: selected == f
                      ? scheme.primary.withValues(alpha: 0.35)
                      : scheme.outlineVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
