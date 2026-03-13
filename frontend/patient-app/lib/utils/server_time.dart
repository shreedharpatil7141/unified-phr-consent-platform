DateTime? parseServerTime(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  // Backend sometimes returns UTC ISO timestamps without timezone suffix.
  // Treat those as UTC and convert to local for UI consistency.
  final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(raw);
  final normalized = hasTimezone ? raw : "${raw}Z";

  try {
    return DateTime.parse(normalized).toLocal();
  } catch (_) {
    return null;
  }
}
