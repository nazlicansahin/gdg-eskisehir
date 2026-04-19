import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/app/theme.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:go_router/go_router.dart';

class CreateAnnouncementPage extends ConsumerStatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  ConsumerState<CreateAnnouncementPage> createState() =>
      _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState
    extends ConsumerState<CreateAnnouncementPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _selectedEventId;
  var _isGeneral = true;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    // Re-register FCM token so backend has a row before user sends an announcement.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pushServiceProvider).registerDeviceTokenWithBackend();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  List<Event> _filterRecentEvents(List<Event> events) {
    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));
    return events
        .where(
          (e) =>
              e.startsAt.isAfter(threeMonthsAgo) || e.endsAt.isAfter(now),
        )
        .toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Announcement')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionHeader(title: 'Announcement type'),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('General')),
              ButtonSegment(value: false, label: Text('Event-specific')),
            ],
            selected: {_isGeneral},
            onSelectionChanged: (s) => setState(() {
              _isGeneral = s.first;
              if (_isGeneral) _selectedEventId = null;
            }),
          ),
          if (!_isGeneral) ...[
            const SizedBox(height: 16),
            const _SectionHeader(title: 'Select event'),
            const SizedBox(height: 8),
            eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load events'),
              data: (events) {
                final filtered = _filterRecentEvents(events);
                if (filtered.isEmpty) {
                  return const Text('No events in the last 3 months or upcoming.');
                }
                return DropdownButtonFormField<String>(
                  value: _selectedEventId,
                  decoration: const InputDecoration(
                    hintText: 'Choose an event',
                  ),
                  items: filtered.map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        e.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedEventId = v),
                );
              },
            ),
          ],
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Announcement content'),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            decoration: const InputDecoration(labelText: 'Body'),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send_rounded),
              label: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send announcement'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and body are required')),
      );
      return;
    }
    if (!_isGeneral && _selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event')),
      );
      return;
    }
    setState(() => _sending = true);
    // Ensure FCM token is registered before server notifies device_tokens (avoids race if user taps Send immediately).
    await ref.read(pushServiceProvider).registerDeviceTokenWithBackend();
    final eventId = _isGeneral ? null : _selectedEventId;
    debugPrint(
      '[announcement] send start general=$_isGeneral eventId=$eventId '
      'titleLen=${_title.text.trim().length} bodyLen=${_body.text.trim().length}',
    );
    final result = await ref.read(announcementsRepositoryProvider).create(
          eventId: eventId,
          title: _title.text.trim(),
          body: _body.text.trim(),
        );
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold(
      (Failure f) {
        debugPrint('[announcement] send failed: ${f.runtimeType} ${f.asUserMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.asUserMessage)),
        );
      },
      (ann) {
        debugPrint(
          '[announcement] send ok id=${ann.id} createdBy=${ann.createdBy} '
          'createdAt=${ann.createdAt.toIso8601String()}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement sent!')),
        );
        context.pop();
      },
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
