/// WebApi bazen `resultViewModels`, bazen `resultViewmodels` döndürüyor.
/// Party lookup cevabı `viewModels` kullanır (`ResultPartyLookupViewModel`).
List<dynamic> extractItems(dynamic data) {
  if (data is List) return data;
  if (data is! Map) return const [];
  final m = Map<String, dynamic>.from(data);
  final a = m['resultViewModels'] ??
      m['resultViewmodels'] ??
      m['viewModels'] ??
      m['ViewModels'];
  if (a is List) return a;
  return const [];
}

int extractCount(dynamic data) {
  if (data is List) return data.length;
  if (data is! Map) return 0;
  final m = Map<String, dynamic>.from(data);
  final c = m['count'] ?? m['Count'];
  if (c is int) return c;
  if (c is num) return c.toInt();
  return extractItems(data).length;
}

List<Map<String, dynamic>> asMapList(dynamic data) {
  return extractItems(data)
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}
