enum EventStatus {
  draft,
  published,
  cancelled;

  static EventStatus fromJson(String raw) {
    return EventStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => EventStatus.draft,
    );
  }
}
