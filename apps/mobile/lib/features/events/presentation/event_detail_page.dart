import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
import 'package:gdg_events/features/events/domain/event_status.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:gdg_events/features/profile/presentation/profile_providers.dart';
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
    final profileAsync = ref.watch(profileProvider);
    final canEdit = profileAsync.valueOrNull?.canEditEvents ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        actions: [
          if (canEdit)
            async.whenOrNull(
              data: (event) => IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit event',
                onPressed: () => _openEditSheet(context, ref, event),
              ),
            ) ??
                const SizedBox.shrink(),
        ],
      ),
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
            padding: const EdgeInsets.all(0),
            children: [
              _HeroHeader(event: event, df: df),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      Text(
                        event.description!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _RegisterSection(
                      event: event,
                      hasTicket: hasTicket,
                      eventId: eventId,
                    ),
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'Schedule'),
                    const SizedBox(height: 8),
                    _ScheduleSection(scheduleAsync: scheduleAsync),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'Speakers'),
                    const SizedBox(height: 8),
                    _SpeakersSection(scheduleAsync: scheduleAsync),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openEditSheet(BuildContext context, WidgetRef ref, Event event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EventEditSheet(event: event, ref: ref, eventId: eventId),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.event, required this.df});
  final Event event;
  final DateFormat df;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GdgTheme.googleBlue,
            GdgTheme.googleBlue.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${df.format(event.startsAt.toLocal())} - ${df.format(event.endsAt.toLocal())}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                'Capacity: ${event.capacity}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegisterSection extends ConsumerWidget {
  const _RegisterSection({
    required this.event,
    required this.hasTicket,
    required this.eventId,
  });
  final Event event;
  final bool hasTicket;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (event.status == EventStatus.cancelled)
          const _InfoBanner(
            icon: Icons.cancel_outlined,
            color: GdgTheme.googleRed,
            text: 'This event has been cancelled.',
          )
        else if (!event.isRegisterable)
          const _InfoBanner(
            icon: Icons.lock_outline,
            color: GdgTheme.googleYellow,
            text: 'Registration is not open.',
          )
        else if (hasTicket)
          const _InfoBanner(
            icon: Icons.check_circle_outline,
            color: GdgTheme.googleGreen,
            text: 'You are registered!',
          )
        else
          FilledButton.icon(
            onPressed: () => registerForEventTap(context, ref, eventId),
            icon: const Icon(Icons.how_to_reg_rounded),
            label: const Text('Register for this event'),
          ),
        if (hasTicket) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(myTicketProvider(eventId));
              context.push('/events/$eventId/ticket');
            },
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('View my ticket'),
          ),
        ],
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({required this.scheduleAsync});
  final AsyncValue<dynamic> scheduleAsync;

  @override
  Widget build(BuildContext context) {
    return scheduleAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Text(
        e is FailureException ? e.failure.asUserMessage : '$e',
      ),
      data: (sessions) {
        final list = sessions as List<dynamic>;
        if (list.isEmpty) {
          return const _EmptyHint(text: 'Schedule will be announced soon.');
        }
        final tf = DateFormat.Hm();
        return Column(
          children: list.map((s) {
            return Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: GdgTheme.googleBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.mic_rounded,
                      color: GdgTheme.googleBlue, size: 20),
                ),
                title: Text(s.title as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                  '${tf.format((s.startsAt as DateTime).toLocal())} - '
                  '${tf.format((s.endsAt as DateTime).toLocal())}'
                  '${s.room == null || (s.room as String).isEmpty ? '' : ' · ${s.room}'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SpeakersSection extends StatelessWidget {
  const _SpeakersSection({required this.scheduleAsync});
  final AsyncValue<dynamic> scheduleAsync;

  @override
  Widget build(BuildContext context) {
    return scheduleAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(
        e is FailureException ? e.failure.asUserMessage : '$e',
      ),
      data: (sessions) {
        final list = sessions as List<dynamic>;
        final byId = <String, String>{};
        for (final s in list) {
          for (final sp in s.speakers) {
            byId[sp.id as String] = sp.fullName as String;
          }
        }
        if (byId.isEmpty) {
          return const _EmptyHint(text: 'Speakers will be announced soon.');
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: byId.entries.map((entry) {
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: GdgTheme.googleGreen.withValues(alpha: 0.15),
                child: Text(
                  entry.value[0].toUpperCase(),
                  style: const TextStyle(
                    color: GdgTheme.googleGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              label: Text(entry.value),
            );
          }).toList(),
        );
      },
    );
  }
}

class _EventEditSheet extends StatefulWidget {
  const _EventEditSheet({
    required this.event,
    required this.ref,
    required this.eventId,
  });
  final Event event;
  final WidgetRef ref;
  final String eventId;

  @override
  State<_EventEditSheet> createState() => _EventEditSheetState();
}

class _EventEditSheetState extends State<_EventEditSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _capacity;
  late EventStatus _status;
  late final TextEditingController _cancelReason;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.event.title);
    _description = TextEditingController(text: widget.event.description ?? '');
    _capacity = TextEditingController(text: '${widget.event.capacity}');
    _status = widget.event.status;
    _cancelReason = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _capacity.dispose();
    _cancelReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Event',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _capacity,
            decoration: const InputDecoration(labelText: 'Capacity'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EventStatus>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: EventStatus.values.map((s) {
              return DropdownMenuItem(value: s, child: Text(s.name));
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
            },
          ),
          if (_status == EventStatus.cancelled) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _cancelReason,
              decoration: const InputDecoration(
                labelText: 'Cancel reason (required)',
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = widget.ref.read(eventsRepositoryProvider);
    final previousStatus = widget.event.status;

    final updateResult = await repo.updateEvent(
      id: widget.event.id,
      title: _title.text,
      description: _description.text,
      capacity: int.tryParse(_capacity.text),
    );

    if (!mounted) return;

    final updateOk = updateResult.isRight();
    if (!updateOk) {
      setState(() => _saving = false);
      updateResult.fold(
        (f) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
        (_) {},
      );
      return;
    }

    if (_status != previousStatus) {
      if (_status == EventStatus.published) {
        final r = await repo.publishEvent(widget.event.id);
        if (!mounted) return;
        r.fold(
          (f) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
          (_) {},
        );
      } else if (_status == EventStatus.cancelled) {
        final reason = _cancelReason.text.trim();
        if (reason.isEmpty) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cancel reason is required')),
          );
          return;
        }
        final r = await repo.cancelEvent(widget.event.id, reason);
        if (!mounted) return;
        r.fold(
          (f) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
          (_) {},
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    widget.ref.invalidate(eventDetailProvider(widget.eventId));
    widget.ref.invalidate(eventsListProvider);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event updated')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: GdgTheme.googleBlue),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
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
