int? entityId(Map<String, dynamic> m) {
  final v = m['id'] ?? m['Id'];
  if (v is int) return v;
  return int.tryParse('$v');
}

String? entityString(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
  }
  return null;
}

String formatTrDate(dynamic raw) {
  if (raw == null) return '—';
  final d = DateTime.tryParse(raw.toString());
  if (d == null) return raw.toString();
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
