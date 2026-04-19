import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/core/event/event_description.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
import 'package:gdg_events/features/events/domain/event_status.dart';
import 'package:gdg_events/features/schedule/domain/entities/schedule_session.dart';
import 'package:gdg_events/features/announcements/presentation/announcements_providers.dart';
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
    final announcementsAsync = ref.watch(eventAnnouncementsProvider(eventId));
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
          final parsed = parseEventDescription(event.description);
          return ListView(
            padding: const EdgeInsets.all(0),
            children: [
              _EventDetailHero(title: event.title, imageUrl: eventCoverImageUrl(event.description)),
              _EventInfoCard(event: event, parsed: parsed, df: df),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildBodySection(context, parsed.body),
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
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'Announcements'),
                    const SizedBox(height: 8),
                    _AnnouncementsSection(announcementsAsync: announcementsAsync),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'Sponsors'),
                    const SizedBox(height: 8),
                    const _SponsorsSection(),
                    if (canEdit) ...[
                      const SizedBox(height: 24),
                      const _SectionHeader(title: 'Developer tools'),
                      const SizedBox(height: 8),
                      _TestPushButton(ref: ref),
                    ],
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

class _EventDetailHero extends StatelessWidget {
  const _EventDetailHero({required this.title, this.imageUrl});
  final String title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const heroHeight = 220.0;
    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [GdgTheme.googleBlue, Color(0xFF1967D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [GdgTheme.googleBlue, Color(0xFF1967D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
                shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({
    required this.event,
    required this.parsed,
    required this.df,
  });
  final Event event;
  final ParsedEventDescription parsed;
  final DateFormat df;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                iconColor: GdgTheme.googleBlue,
                text:
                    '${df.format(event.startsAt.toLocal())} → ${df.format(event.endsAt.toLocal())}',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.people_outline_rounded,
                iconColor: GdgTheme.googleGreen,
                text: 'Capacity ${event.capacity}',
              ),
              if (parsed.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  iconColor: GdgTheme.googleRed,
                  text: parsed.location,
                ),
              ],
              const SizedBox(height: 8),
              _InfoRow(
                icon: parsed.isFree ? Icons.volunteer_activism_rounded : Icons.payments_outlined,
                iconColor: parsed.isFree ? GdgTheme.googleGreen : GdgTheme.googleYellow,
                text: parsed.isFree ? 'Free' : 'Paid (${parsed.price.isEmpty ? 'n/a' : parsed.price})',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });
  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
          ),
        ),
      ],
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
        final seen = <String>{};
        final speakers = <({String id, String name, String? bio, String? avatar})>[];
        for (final s in list) {
          for (final sp in s.speakers) {
            final id = sp.id as String;
            if (seen.add(id)) {
              speakers.add((
                id: id,
                name: sp.fullName as String,
                bio: sp.bio as String?,
                avatar: sp.avatarUrl as String?,
              ));
            }
          }
        }
        if (speakers.isEmpty) {
          return const _EmptyHint(text: 'Speakers will be announced soon.');
        }
        return Column(
          children: speakers.map((sp) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: GdgTheme.googleGreen.withValues(alpha: 0.15),
                  backgroundImage:
                      sp.avatar != null ? NetworkImage(sp.avatar!) : null,
                  child: sp.avatar == null
                      ? Text(
                          sp.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: GdgTheme.googleGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                title: Text(sp.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: sp.bio != null && sp.bio!.isNotEmpty
                    ? Text(
                        sp.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TalkEdit {
  _TalkEdit({
    required this.isNew,
    this.sessionId,
    this.speakerId,
    required this.topicTitle,
    required this.topicDescription,
    required this.room,
    required this.speakerName,
    required this.speakerBio,
    required this.speakerAvatar,
    required this.startsAt,
    required this.endsAt,
  });

  factory _TalkEdit.fromSession(ScheduleSession s) {
    final sp = s.speakers.isNotEmpty ? s.speakers.first : null;
    return _TalkEdit(
      isNew: false,
      sessionId: s.id,
      speakerId: sp?.id,
      topicTitle: TextEditingController(text: s.title),
      topicDescription: TextEditingController(text: s.description ?? ''),
      room: TextEditingController(text: s.room ?? ''),
      speakerName: TextEditingController(text: sp?.fullName ?? ''),
      speakerBio: TextEditingController(text: sp?.bio ?? ''),
      speakerAvatar: TextEditingController(text: sp?.avatarUrl ?? ''),
      startsAt: s.startsAt,
      endsAt: s.endsAt,
    );
  }

  factory _TalkEdit.fresh(Event ev) {
    return _TalkEdit(
      isNew: true,
      sessionId: null,
      speakerId: null,
      topicTitle: TextEditingController(),
      topicDescription: TextEditingController(),
      room: TextEditingController(),
      speakerName: TextEditingController(),
      speakerBio: TextEditingController(),
      speakerAvatar: TextEditingController(),
      startsAt: ev.startsAt,
      endsAt: ev.endsAt,
    );
  }

  final bool isNew;
  final String? sessionId;
  final String? speakerId;
  final TextEditingController topicTitle;
  final TextEditingController topicDescription;
  final TextEditingController room;
  final TextEditingController speakerName;
  final TextEditingController speakerBio;
  final TextEditingController speakerAvatar;
  DateTime startsAt;
  DateTime endsAt;

  void dispose() {
    topicTitle.dispose();
    topicDescription.dispose();
    room.dispose();
    speakerName.dispose();
    speakerBio.dispose();
    speakerAvatar.dispose();
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
  late final TextEditingController _body;
  late final TextEditingController _location;
  late final TextEditingController _eventImageUrl;
  late final TextEditingController _price;
  late final TextEditingController _capacity;
  late EventStatus _status;
  late final TextEditingController _cancelReason;
  var _isFree = true;
  late DateTime _startsAt;
  late DateTime _endsAt;
  var _saving = false;
  var _loadingTalks = true;
  final _talks = <_TalkEdit>[];

  @override
  void initState() {
    super.initState();
    final p = parseEventDescription(widget.event.description);
    _title = TextEditingController(text: widget.event.title);
    _body = TextEditingController(text: p.body);
    _location = TextEditingController(text: p.location);
    _eventImageUrl = TextEditingController(text: p.eventImageUrl);
    _price = TextEditingController(text: p.price);
    _capacity = TextEditingController(text: '${widget.event.capacity}');
    _status = widget.event.status;
    _cancelReason = TextEditingController();
    _isFree = p.isFree;
    _startsAt = widget.event.startsAt;
    _endsAt = widget.event.endsAt;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchedule());
  }

  Future<void> _loadSchedule() async {
    final sch = widget.ref.read(scheduleRepositoryProvider);
    final r = await sch.listByEvent(widget.eventId);
    if (!mounted) return;
    r.fold(
      (_) {
        setState(() {
          _loadingTalks = false;
        });
      },
      (sessions) {
        for (final t in _talks) {
          t.dispose();
        }
        _talks
          ..clear()
          ..addAll(sessions.map(_TalkEdit.fromSession));
        setState(() {
          _loadingTalks = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _location.dispose();
    _eventImageUrl.dispose();
    _price.dispose();
    _capacity.dispose();
    _cancelReason.dispose();
    for (final t in _talks) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _pickEventStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startsAt.toLocal(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt.toLocal()),
    );
    if (t == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(d.year, d.month, d.day, t.hour, t.minute).toUtc();
    });
  }

  Future<void> _pickEventEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endsAt.toLocal(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endsAt.toLocal()),
    );
    if (t == null || !mounted) return;
    setState(() {
      _endsAt = DateTime(d.year, d.month, d.day, t.hour, t.minute).toUtc();
    });
  }

  Future<void> _pickTalkTimes(_TalkEdit talk, bool isStart) async {
    final cur = isStart ? talk.startsAt : talk.endsAt;
    final d = await showDatePicker(
      context: context,
      initialDate: cur.toLocal(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(cur.toLocal()),
    );
    if (t == null || !mounted) return;
    setState(() {
      final next =
          DateTime(d.year, d.month, d.day, t.hour, t.minute).toUtc();
      if (isStart) {
        talk.startsAt = next;
      } else {
        talk.endsAt = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_Hm();
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
                'Edit event',
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
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            decoration: const InputDecoration(
              labelText: 'Description (text only)',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _eventImageUrl,
            decoration: const InputDecoration(labelText: 'Event image URL'),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Free event'),
            value: _isFree,
            onChanged: (v) => setState(() => _isFree = v ?? true),
          ),
          TextField(
            controller: _price,
            decoration: const InputDecoration(labelText: 'Price (if paid)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _capacity,
            decoration: const InputDecoration(labelText: 'Capacity'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Event starts'),
            subtitle: Text(df.format(_startsAt.toLocal())),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickEventStart,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Event ends'),
            subtitle: Text(df.format(_endsAt.toLocal())),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickEventEnd,
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          Text(
            'Sessions & speakers',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (_loadingTalks)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            for (var i = 0; i < _talks.length; i++) ...[
              const SizedBox(height: 12),
              _talkEditorCard(context, df, _talks[i], i),
            ],
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _talks.add(_TalkEdit.fresh(widget.event));
                });
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add session'),
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
                      : const Text('Save all'),
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

  Widget _talkEditorCard(
    BuildContext context,
    DateFormat df,
    _TalkEdit talk,
    int index,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              talk.isNew ? 'New session' : 'Session ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: talk.topicTitle,
              decoration: const InputDecoration(labelText: 'Talk title'),
            ),
            TextField(
              controller: talk.topicDescription,
              decoration: const InputDecoration(labelText: 'Talk description'),
            ),
            TextField(
              controller: talk.room,
              decoration: const InputDecoration(labelText: 'Room'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Session starts'),
              subtitle: Text(df.format(talk.startsAt.toLocal())),
              onTap: () => _pickTalkTimes(talk, true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Session ends'),
              subtitle: Text(df.format(talk.endsAt.toLocal())),
              onTap: () => _pickTalkTimes(talk, false),
            ),
            TextField(
              controller: talk.speakerName,
              decoration: const InputDecoration(labelText: 'Speaker name'),
            ),
            TextField(
              controller: talk.speakerBio,
              decoration: const InputDecoration(labelText: 'Speaker bio'),
            ),
            TextField(
              controller: talk.speakerAvatar,
              decoration: const InputDecoration(labelText: 'Speaker photo URL'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final eventsRepo = widget.ref.read(eventsRepositoryProvider);
    final sch = widget.ref.read(scheduleRepositoryProvider);
    final previousStatus = widget.event.status;

    final cap = int.tryParse(_capacity.text);
    if (cap == null || cap <= 0) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capacity must be a positive number')),
        );
      }
      return;
    }

    if (!_endsAt.isAfter(_startsAt)) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
      }
      return;
    }

    final composed = composeEventDescription(
      _body.text,
      location: _location.text,
      eventImageUrl: _eventImageUrl.text,
      isFree: _isFree,
      price: _price.text,
    );

    final updateResult = await eventsRepo.updateEvent(
      id: widget.event.id,
      title: _title.text.trim(),
      description: composed,
      capacity: cap,
      startsAt: _startsAt,
      endsAt: _endsAt,
    );

    if (!mounted) return;

    if (updateResult.isLeft()) {
      setState(() => _saving = false);
      updateResult.fold(
        (f) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
        (_) {},
      );
      return;
    }

    for (final talk in _talks) {
      final topic = talk.topicTitle.text.trim();
      if (topic.isEmpty) continue;
      if (!talk.endsAt.isAfter(talk.startsAt)) {
        setState(() => _saving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Session "$topic": end must be after start')),
          );
        }
        return;
      }

      if (!talk.isNew && talk.sessionId != null) {
        final u = await sch.updateSession(
          id: talk.sessionId!,
          title: topic,
          description: talk.topicDescription.text.trim().isEmpty
              ? null
              : talk.topicDescription.text.trim(),
          room: talk.room.text.trim().isEmpty ? null : talk.room.text.trim(),
          startsAt: talk.startsAt,
          endsAt: talk.endsAt,
        );
        if (u.isLeft()) {
          setState(() => _saving = false);
          u.fold(
            (f) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
            (_) {},
          );
          return;
        }

        final sid = talk.sessionId!;
        final spid = talk.speakerId;
        final spName = talk.speakerName.text.trim();
        if (spid != null) {
          final patch = <String, String>{};
          if (spName.isNotEmpty) patch['fullName'] = spName;
          if (talk.speakerBio.text.trim().isNotEmpty) {
            patch['bio'] = talk.speakerBio.text.trim();
          }
          if (talk.speakerAvatar.text.trim().isNotEmpty) {
            patch['avatarUrl'] = talk.speakerAvatar.text.trim();
          }
          if (patch.isNotEmpty) {
            final su = await sch.updateSpeaker(
              id: spid,
              fullName: patch['fullName'],
              bio: patch['bio'],
              avatarUrl: patch['avatarUrl'],
            );
            if (su.isLeft()) {
              setState(() => _saving = false);
              su.fold(
                (f) => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
                (_) {},
              );
              return;
            }
          }
        } else if (spName.isNotEmpty) {
          final cr = await sch.createSpeaker(
            fullName: spName,
            bio: talk.speakerBio.text.trim().isEmpty
                ? null
                : talk.speakerBio.text.trim(),
            avatarUrl: talk.speakerAvatar.text.trim().isEmpty
                ? null
                : talk.speakerAvatar.text.trim(),
          );
          if (cr.isLeft()) {
            setState(() => _saving = false);
            cr.fold(
              (f) => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
              (_) {},
            );
            return;
          }
          final newSpId = cr.fold((_) => '', (id) => id);
          final at = await sch.attachSpeakerToSession(
            sessionId: sid,
            speakerId: newSpId,
          );
          if (at.isLeft()) {
            setState(() => _saving = false);
            at.fold(
              (f) => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
              (_) {},
            );
            return;
          }
        }
      } else {
        final cs = await sch.createSession(
          eventId: widget.eventId,
          title: topic,
          description: talk.topicDescription.text.trim().isEmpty
              ? null
              : talk.topicDescription.text.trim(),
          startsAt: talk.startsAt,
          endsAt: talk.endsAt,
          room: talk.room.text.trim().isEmpty ? null : talk.room.text.trim(),
        );
        if (cs.isLeft()) {
          setState(() => _saving = false);
          cs.fold(
            (f) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
            (_) {},
          );
          return;
        }
        final newSid = cs.fold((_) => '', (id) => id);
        final spName = talk.speakerName.text.trim();
        if (spName.isNotEmpty) {
          final cr = await sch.createSpeaker(
            fullName: spName,
            bio: talk.speakerBio.text.trim().isEmpty
                ? null
                : talk.speakerBio.text.trim(),
            avatarUrl: talk.speakerAvatar.text.trim().isEmpty
                ? null
                : talk.speakerAvatar.text.trim(),
          );
          if (cr.isLeft()) {
            setState(() => _saving = false);
            cr.fold(
              (f) => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
              (_) {},
            );
            return;
          }
          final newSpId = cr.fold((_) => '', (id) => id);
          final at = await sch.attachSpeakerToSession(
            sessionId: newSid,
            speakerId: newSpId,
          );
          if (at.isLeft()) {
            setState(() => _saving = false);
            at.fold(
              (f) => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
              (_) {},
            );
            return;
          }
        }
      }
    }

    if (_status != previousStatus) {
      if (_status == EventStatus.published) {
        final r = await eventsRepo.publishEvent(widget.event.id);
        if (!mounted) return;
        if (r.isLeft()) {
          setState(() => _saving = false);
          r.fold(
            (f) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
            (_) {},
          );
          return;
        }
      } else if (_status == EventStatus.cancelled) {
        final reason = _cancelReason.text.trim();
        if (reason.isEmpty) {
          setState(() => _saving = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cancel reason is required')),
          );
          return;
        }
        final r = await eventsRepo.cancelEvent(widget.event.id, reason);
        if (!mounted) return;
        if (r.isLeft()) {
          setState(() => _saving = false);
          r.fold(
            (f) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(f.asUserMessage))),
            (_) {},
          );
          return;
        }
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    widget.ref.invalidate(eventDetailProvider(widget.eventId));
    widget.ref.invalidate(eventsListProvider);
    widget.ref.invalidate(eventScheduleProvider(widget.eventId));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event updated')),
    );
  }
}

class _AnnouncementsSection extends StatelessWidget {
  const _AnnouncementsSection({required this.announcementsAsync});
  final AsyncValue<dynamic> announcementsAsync;

  @override
  Widget build(BuildContext context) {
    return announcementsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const _EmptyHint(text: 'Could not load announcements.'),
      data: (announcements) {
        final list = announcements as List<dynamic>;
        if (list.isEmpty) {
          return const _EmptyHint(text: 'No announcements yet.');
        }
        final df = DateFormat.yMMMd().add_Hm();
        return Column(
          children: list.map((a) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.campaign_rounded,
                            size: 18, color: GdgTheme.googleYellow),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.title as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.body as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      df.format((a.createdAt as DateTime).toLocal()),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

List<Widget> _buildBodySection(BuildContext context, String body) {
  if (body.trim().isEmpty) return [];
  return [
    const _SectionHeader(title: 'About'),
    const SizedBox(height: 8),
    Text(
      body,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55),
    ),
    const SizedBox(height: 20),
  ];
}

class _SponsorsSection extends StatelessWidget {
  const _SponsorsSection();

  @override
  Widget build(BuildContext context) {
    // Placeholder sponsor logos with Google product colors.
    final sponsors = [
      ('Google', GdgTheme.googleBlue, Icons.flutter_dash),
      ('Firebase', GdgTheme.googleYellow, Icons.local_fire_department_rounded),
      ('Cloud', GdgTheme.googleGreen, Icons.cloud_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sponsors.map((s) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: s.$2.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: s.$2.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.$3, color: s.$2, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    s.$1,
                    style: TextStyle(
                      color: s.$2,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Interested in sponsoring? Contact organizers.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _TestPushButton extends StatefulWidget {
  const _TestPushButton({required this.ref});
  final WidgetRef ref;

  @override
  State<_TestPushButton> createState() => _TestPushButtonState();
}

class _TestPushButtonState extends State<_TestPushButton> {
  var _sending = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GdgTheme.googleRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications_active_rounded,
              color: GdgTheme.googleRed, size: 20),
        ),
        title: const Text('Test push notification',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Triggers a local notification for testing'),
        trailing: _sending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send_rounded, color: Colors.grey),
        onTap: _sending ? null : _send,
      ),
    );
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final pushService = widget.ref.read(pushServiceProvider);
      await pushService.showTestNotification();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Push test failed')),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
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
