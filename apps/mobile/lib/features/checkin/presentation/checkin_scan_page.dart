import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/features/checkin/presentation/checkin_providers.dart';
import 'package:gdg_events/features/events/presentation/events_providers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CheckInScanPage extends ConsumerStatefulWidget {
  const CheckInScanPage({super.key, this.initialEventId});

  final String? initialEventId;

  @override
  ConsumerState<CheckInScanPage> createState() => _CheckInScanPageState();
}

class _CheckInScanPageState extends ConsumerState<CheckInScanPage> {
  String? _eventId;
  var _submitting = false;
  String? _lastCode;
  DateTime? _lastScanAt;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsListProvider);

    eventsAsync.whenData((list) {
      if (list.isEmpty || _eventId != null) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _eventId != null) {
          return;
        }
        final initial = widget.initialEventId;
        setState(() {
          _eventId = initial != null && list.any((e) => e.id == initial)
              ? initial
              : list.first.id;
        });
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e is FailureException ? e.failure.asUserMessage : '$e',
            ),
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Text('No published events to check in against.'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Event',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _eventId,
                      isExpanded: true,
                      hint: const Text('Select event'),
                      items: events
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.title),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _eventId = v),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Point the camera at an attendee ticket QR code.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _eventId == null
                        ? const ColoredBox(
                            color: Colors.black12,
                            child: Center(child: Text('Select an event')),
                          )
                        : MobileScanner(
                            onDetect: _onDetect,
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

  Future<void> _onDetect(BarcodeCapture capture) async {
    final eventId = _eventId;
    if (eventId == null || _submitting) {
      return;
    }
    String? code;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) {
        code = v;
        break;
      }
    }
    if (code == null) {
      return;
    }
    final now = DateTime.now();
    if (_lastCode == code &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastCode = code;
    _lastScanAt = now;

    setState(() => _submitting = true);
    final result = await ref.read(checkInRepositoryProvider).checkInByQr(
          eventId: eventId,
          qrCode: code,
        );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    result.fold(
      (Failure f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.asUserMessage)),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checked in successfully')),
        );
      },
    );
  }
}
