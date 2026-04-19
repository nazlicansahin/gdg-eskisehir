/// Parses metadata lines appended by admin/mobile create flows (Location, Pricing, Event image).
class ParsedEventDescription {
  const ParsedEventDescription({
    required this.body,
    required this.location,
    required this.eventImageUrl,
    required this.isFree,
    required this.price,
  });

  final String body;
  final String location;
  final String eventImageUrl;
  final bool isFree;
  final String price;
}

final _imageUrlPattern = RegExp(
  r'https?:\/\/[^\s)]+\.(png|jpe?g|gif|webp|avif|svg)',
  caseSensitive: false,
);

ParsedEventDescription parseEventDescription(String? raw) {
  final text = raw ?? '';
  final bodyLines = <String>[];
  var location = '';
  var eventImageUrl = '';
  var pricingLine = '';

  for (final line in text.split('\n')) {
    final t = line.trim();
    if (t.startsWith('Location:')) {
      location = t.substring('Location:'.length).trim();
    } else if (t.startsWith('Pricing:')) {
      pricingLine = t.substring('Pricing:'.length).trim();
    } else if (t.startsWith('Event image:')) {
      eventImageUrl = t.substring('Event image:'.length).trim();
    } else {
      bodyLines.add(line);
    }
  }

  final body = bodyLines.join('\n').trim();
  final paidMatch = RegExp(r'^paid\s*\(([^)]*)\)\s*$', caseSensitive: false)
      .firstMatch(pricingLine.trim());
  final price = paidMatch?.group(1)?.trim() ?? '';
  final isFree =
      pricingLine.trim().isEmpty || !RegExp(r'^paid\s*\(', caseSensitive: false).hasMatch(pricingLine.trim());

  return ParsedEventDescription(
    body: body,
    location: location,
    eventImageUrl: eventImageUrl,
    isFree: isFree,
    price: price,
  );
}

String composeEventDescription(
  String baseDescription, {
  required String location,
  required String eventImageUrl,
  required bool isFree,
  required String price,
}) {
  final lines = <String>[];
  final base = baseDescription.trim();
  if (base.isNotEmpty) lines.add(base);
  if (location.trim().isNotEmpty) lines.add('Location: ${location.trim()}');
  lines.add('Pricing: ${isFree ? 'Free' : 'Paid (${price.trim().isEmpty ? 'n/a' : price.trim()})'}');
  if (eventImageUrl.trim().isNotEmpty) {
    lines.add('Event image: ${eventImageUrl.trim()}');
  }
  return lines.join('\n\n');
}

/// Cover image: explicit metadata URL or first image-like URL in the full description.
String? eventCoverImageUrl(String? raw) {
  final p = parseEventDescription(raw);
  if (p.eventImageUrl.trim().isNotEmpty) return p.eventImageUrl.trim();
  final m = _imageUrlPattern.firstMatch(raw ?? '');
  return m?.group(0);
}
