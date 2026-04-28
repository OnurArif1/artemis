String maskEmailLikeLabel(String label, {required bool showFull}) {
  if (showFull) return label;
  final s = label.trim();
  if (s.isEmpty) return s;
  if (!s.contains('@')) return s;
  if (s.length <= 2) return '${s[0]}*';
  final prefix = s.substring(0, 2);
  return '$prefix${'*' * (s.length - 2)}';
}
