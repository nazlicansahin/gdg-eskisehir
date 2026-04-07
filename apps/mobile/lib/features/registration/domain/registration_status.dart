enum RegistrationStatus {
  active,
  cancelled;

  static RegistrationStatus fromJson(String raw) {
    return RegistrationStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => RegistrationStatus.active,
    );
  }
}
