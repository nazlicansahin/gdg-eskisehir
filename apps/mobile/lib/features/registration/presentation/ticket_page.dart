import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/core/event/add_to_calendar.dart';
import 'package:gdg_events/core/event/event_description.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:gdg_events/features/registration/domain/entities/registration_ticket.dart';
import 'package:gdg_events/features/registration/domain/registration_status.dart';
import 'package:gdg_events/features/registration/presentation/registration_providers.dart';
import 'package:gdg_events/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketPage extends ConsumerWidget {
  const TicketPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ticketAsync = ref.watch(myTicketProvider(eventId));
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          eventAsync.valueOrNull?.title ?? l10n.ticketPageTitleDefault,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg =
              e is FailureException ? e.failure.asUserMessage : e.toString();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(msg, textAlign: TextAlign.center),
            ),
          );
        },
        data: (ticket) {
          if (ticket == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.confirmation_number_outlined,
                        size: 56, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      l10n.ticketNoTicketYet,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.ticketRegisterFirst,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return eventAsync.when(
            loading: () => _TicketBody(
              ticket: ticket,
              event: null,
              onOpenEvent: () => context.go('/events/$eventId'),
            ),
            error: (_, __) => _TicketBody(
              ticket: ticket,
              event: null,
              onOpenEvent: () => context.go('/events/$eventId'),
            ),
            data: (event) => _TicketBody(
              ticket: ticket,
              event: event,
              onOpenEvent: () => context.go('/events/$eventId'),
            ),
          );
        },
      ),
    );
  }
}

class _TicketBody extends StatelessWidget {
  const _TicketBody({
    required this.ticket,
    required this.event,
    required this.onOpenEvent,
  });

  final RegistrationTicket ticket;
  final Event? event;
  final VoidCallback onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final df = DateFormat.yMMMd().add_Hm();
    final checkedIn = ticket.checkedInAt != null;
    final title = event?.title ?? l10n.ticketPageTitleDefault;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TicketHero(
            title: title,
            imageUrl:
                event != null ? eventCoverImageUrl(event!.description) : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.ticketScanHeading,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusPill(
                      status: ticket.status,
                      checkedIn: checkedIn,
                    ),
                  ],
                ),
                if (event != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${df.format(event!.startsAt.toLocal())} — '
                          '${df.format(event!.endsAt.toLocal())}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: Column(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: QrImageView(
                          data: ticket.qrCodeValue,
                          size: 260,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF202124),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF202124),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      ticket.qrCodeValue,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: ticket.qrCodeValue),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.ticketCodeCopied),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(l10n.ticketCopyCode),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${l10n.ticketRegistrationPrefix} · ${ticket.status.name}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (ticket.checkedInAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded,
                      size: 18, color: GdgTheme.googleGreen),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${l10n.ticketCheckedInPrefix} '
                      '${df.format(ticket.checkedInAt!.toLocal())}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: GdgTheme.googleGreen,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (event != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ev = event;
                  if (ev == null) return;
                  try {
                    final ok = await addEventToDeviceCalendar(ev);
                    if (!context.mounted) return;
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.settingsSavedToCalendar),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.settingsCouldNotAddCalendar(e.toString()),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.calendar_month_outlined, size: 20),
                label: Text(l10n.addToCalendarButton),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          if (event != null) const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: onOpenEvent,
              icon: const Icon(Icons.event_rounded, size: 20),
              label: Text(l10n.eventDetailsButton),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    required this.checkedIn,
  });

  final RegistrationStatus status;
  final bool checkedIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, bg, fg) = switch (status) {
      RegistrationStatus.cancelled => (
          l10n.pillCancelled,
          GdgTheme.googleRed.withValues(alpha: 0.14),
          GdgTheme.googleRed,
        ),
      RegistrationStatus.active when checkedIn => (
          l10n.pillCheckedIn,
          GdgTheme.googleGreen.withValues(alpha: 0.14),
          GdgTheme.googleGreen,
        ),
      RegistrationStatus.active => (
          l10n.pillReadyToScan,
          GdgTheme.googleBlue.withValues(alpha: 0.12),
          GdgTheme.googleBlue,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _TicketHero extends StatelessWidget {
  const _TicketHero({required this.title, this.imageUrl});

  final String title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const heroHeight = 168.0;
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
              errorBuilder: (_, __, ___) => _gradientFallback(),
            )
          else
            _gradientFallback(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.62),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
                shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [GdgTheme.googleBlue, Color(0xFF1967D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
