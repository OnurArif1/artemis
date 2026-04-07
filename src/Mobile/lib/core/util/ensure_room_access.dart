import '../../services/app_services.dart';
import '../location/location_service.dart';
import 'entity_map.dart';

Future<bool> ensureUserInRoom({
  required AppServices app,
  required int roomId,
  required int userPartyId,
  required String? userEmail,
}) async {
  final filter = <String, dynamic>{
    'pageIndex': 1,
    'pageSize': 1000,
  };
  final lat = LocationService.latitude;
  final lng = LocationService.longitude;
  if (lat != null && lng != null) {
    filter['userLatitude'] = lat;
    filter['userLongitude'] = lng;
  }
  if (userEmail != null && userEmail.isNotEmpty) {
    filter['userEmail'] = userEmail;
  }

  try {
    final raw = await app.rooms.getList(filter);
    final list = raw is Map
        ? (raw['resultViewModels'] ?? raw['ResultViewModels'] ?? raw['resultViewmodels'])
        : null;
    if (list is! List) return false;

    Map<String, dynamic>? room;
    for (final e in list) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final id = entityId(m);
      if (id == roomId) {
        room = m;
        break;
      }
    }
    if (room == null) return false;

    if (room['subscriptionAccessDenied'] == true ||
        room['SubscriptionAccessDenied'] == true) {
      return false;
    }
    final canAccess = room['canAccess'];
    final roomRange = room['roomRange'] ?? room['RoomRange'];
    if (roomRange != null && canAccess == false) {
      return false;
    }

    final parties = room['parties'] ?? room['Parties'];
    var inRoom = false;
    if (parties is List) {
      for (final p in parties) {
        if (p is! Map) continue;
        final m = Map<String, dynamic>.from(p);
        final pid = entityId(m) ??
            (m['partyId'] is int
                ? m['partyId'] as int
                : int.tryParse('${m['partyId'] ?? m['PartyId']}'));
        if (pid == userPartyId) {
          inRoom = true;
          break;
        }
      }
    }

    if (!inRoom) {
      await app.rooms.addPartyToRoom({
        'roomId': roomId,
        'partyId': userPartyId,
      });
    }
    return true;
  } catch (_) {
    return false;
  }
}
