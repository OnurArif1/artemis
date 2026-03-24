String mapTitle(Map<String, dynamic> m) {
  final v = m['title'] ?? m['Title'] ?? m['name'] ?? m['Name'] ?? m['topicTitle'];
  if (v != null && '$v'.isNotEmpty) return '$v';
  final id = m['id'] ?? m['Id'];
  return id != null ? '#$id' : '—';
}

String? mapSubtitle(Map<String, dynamic> m) {
  final v = m['description'] ?? m['Description'] ?? m['subtitle'] ?? m['address'];
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}
