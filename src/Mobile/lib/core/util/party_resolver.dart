import '../../services/app_services.dart';

Future<int?> resolveCurrentPartyId(AppServices app, String? email) async {
  if (email == null || email.trim().isEmpty) return null;
  final e = email.trim();

  int? pickFromLookup(dynamic data) {
    if (data is! Map) return null;
    final vm = data['viewModels'] ?? data['ViewModels'];
    if (vm is! List || vm.isEmpty) return null;
    for (final item in vm) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final name = '${m['partyName'] ?? m['PartyName'] ?? ''}';
      final pid = m['partyId'] ?? m['PartyId'];
      if (name.toLowerCase() == e.toLowerCase()) {
        if (pid is int) return pid;
        return int.tryParse('$pid');
      }
    }
    final first = vm.first;
    if (first is Map) {
      final pid = first['partyId'] ?? first['PartyId'];
      if (pid is int) return pid;
      return int.tryParse('$pid');
    }
    return null;
  }

  try {
    final d1 = await app.parties.getLookup({
      'searchText': e,
      'partyLookupSearchType': 3,
    });
    final id1 = pickFromLookup(d1);
    if (id1 != null) return id1;

    final d2 = await app.parties.getLookup({
      'searchText': e,
      'partyLookupSearchType': 1,
    });
    return pickFromLookup(d2);
  } catch (_) {
    return null;
  }
}
