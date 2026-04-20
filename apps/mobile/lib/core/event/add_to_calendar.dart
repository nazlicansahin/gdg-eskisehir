import 'package:add_2_calendar/add_2_calendar.dart' as a2c;
import 'package:gdg_events/core/event/event_description.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';

const _maxCalendarDescriptionLength = 8000;

/// Opens the platform calendar UI with this event prefilled (user confirms save).
///
/// Returns `true` when the native flow reports success (platform-dependent).
Future<bool> addEventToDeviceCalendar(Event event) async {
  final parsed = parseEventDescription(event.description);
  var desc = parsed.body.trim();
  if (desc.length > _maxCalendarDescriptionLength) {
    desc = '${desc.substring(0, _maxCalendarDescriptionLength)}…';
  }
  final location = parsed.location.trim();

  final calEvent = a2c.Event(
    title: event.title,
    description: desc.isNotEmpty ? desc : null,
    location: location.isNotEmpty ? location : null,
    startDate: event.startsAt.toLocal(),
    endDate: event.endsAt.toLocal(),
    iosParams: const a2c.IOSParams(
      reminder: Duration(hours: 1),
    ),
  );

  return a2c.Add2Calendar.addEvent2Cal(calEvent);
}
