import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/domain/event_status.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
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
              // Hero header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GdgTheme.googleBlue,
                      GdgTheme.googleBlue.withOpacity(0.85),
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
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
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
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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

                    // Register CTA
                    if (event.status == EventStatus.cancelled)
                      _InfoBanner(
                        icon: Icons.cancel_outlined,
                        color: GdgTheme.googleRed,
                        text: 'This event has been cancelled.',
                      )
                    else if (!event.isRegisterable)
                      _InfoBanner(
                        icon: Icons.lock_outline,
                        color: GdgTheme.googleYellow,
                        text: 'Registration is not open.',
                      )
                    else if (hasTicket)
                      _InfoBanner(
                        icon: Icons.check_circle_outline,
                        color: GdgTheme.googleGreen,
                        text: 'You are registered!',
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              registerForEventTap(context, ref, eventId),
                          icon: const Icon(Icons.how_to_reg_rounded),
                          label: const Text('Register for this event'),
                        ),
                      ),
                    if (hasTicket) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.invalidate(myTicketProvider(eventId));
                            context.push('/events/$eventId/ticket');
                          },
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: const Text('View my ticket'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Schedule
                    _SectionHeader(title: 'Schedule'),
                    const SizedBox(height: 8),
                    scheduleAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Text(
                        e is FailureException
                            ? e.failure.asUserMessage
                            : '$e',
                      ),
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return _EmptyHint(text: 'Schedule will be announced soon.');
                        }
                        final tf = DateFormat.Hm();
                        return Column(
                          children: sessions.map((s) {
                            return Card(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: GdgTheme.googleBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.mic_rounded,
                                      color: GdgTheme.googleBlue, size: 20),
                                ),
                                title: Text(s.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                subtitle: Text(
                                  '${tf.format(s.startsAt.toLocal())} - '
                                  '${tf.format(s.endsAt.toLocal())}'
                                  '${s.room == null || s.room!.isEmpty ? '' : ' · ${s.room}'}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Speakers
                    _SectionHeader(title: 'Speakers'),
                    const SizedBox(height: 8),
                    scheduleAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => Text(
                        e is FailureException
                            ? e.failure.asUserMessage
                            : '$e',
                      ),
                      data: (sessions) {
                        final byId = <String, String>{};
                        for (final s in sessions) {
                          for (final sp in s.speakers) {
                            byId[sp.id] = sp.fullName;
                          }
                        }
                        if (byId.isEmpty) {
                          return _EmptyHint(
                              text: 'Speakers will be announced soon.');
                        }
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: byId.entries.map((entry) {
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor:
                                    GdgTheme.googleGreen.withOpacity(0.15),
                                child: Text(
                                  entry.value[0].toUpperCase(),
                                  style: TextStyle(
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
                    ),

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
  const _InfoBanner({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w500, fontSize: 14)),
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
      child: Text(text,
          style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
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
