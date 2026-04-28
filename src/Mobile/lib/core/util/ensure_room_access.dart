import '../../services/app_services.dart';
import '../location/location_service.dart';
import 'entity_map.dart';
import 'paged_result.dart';

class RoomEntryResult {
  const RoomEntryResult._({
    required this.allowed,
    this.readOnlyExpired = false,
    this.errorMessage,
  });

  final bool allowed;
  final bool readOnlyExpired;
  final String? errorMessage;

  factory RoomEntryResult.active() =>
      const RoomEntryResult._(allowed: true, readOnlyExpired: false);

  factory RoomEntryResult.readOnlyExpired() =>
      const RoomEntryResult._(allowed: true, readOnlyExpired: true);

  factory RoomEntryResult.denied(String message) =>
      RoomEntryResult._(allowed: false, errorMessage: message);
}

bool lifecycleExpiredFromRoomMap(Map<String, dynamic> room) {
  final s = room['lifecycleExpired'] ?? room['LifecycleExpired'];
  if (s is bool) return s;

  final lc = room['lifeCycle'] ?? room['LifeCycle'];
  final cd = room['createDate'] ?? room['CreateDate'];
  final minutes = lc is num ? lc.toDouble() : double.tryParse('$lc');
  if (minutes == null) return false;
  final created = DateTime.tryParse('$cd');
  if (created == null) return false;
  final startUtc = created.isUtc ? created : created.toUtc();
  final expires = startUtc.add(
    Duration(milliseconds: (minutes * 60000).round()),
  );
  return DateTime.now().toUtc().isAfter(expires);
}

Future<bool> userHasMessageInRoom(
  AppServices app, {
  required int roomId,
  required int partyId,
}) async {
  try {
    final raw = await app.messages.getList({
      'roomId': roomId,
      'partyId': partyId,
      'pageIndex': 1,
      'pageSize': 1,
    });
    return extractItems(raw).isNotEmpty;
  } catch (_) {
    return false;
  }
}

Future<RoomEntryResult> resolveRoomEntry({
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
    if (list is! List) {
      return RoomEntryResult.denied('Oda bulunamadı.');
    }

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
    if (room == null) {
      return RoomEntryResult.denied('Oda bulunamadı.');
    }

    if (room['subscriptionAccessDenied'] == true ||
        room['SubscriptionAccessDenied'] == true) {
      return RoomEntryResult.denied(
        'Bu odaya sohbet için erişiminiz yok (üyelik kısıtı).',
      );
    }
    final canAccess = room['canAccess'];
    final roomRange = room['roomRange'] ?? room['RoomRange'];
    if (roomRange != null && canAccess == false) {
      return RoomEntryResult.denied(
        'Bu odaya konumunuz nedeniyle erişilemiyor.',
      );
    }

    final expired = lifecycleExpiredFromRoomMap(room);
    if (!expired) {
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
      return RoomEntryResult.active();
    }

    final hasPriorChat = await userHasMessageInRoom(
      app,
      roomId: roomId,
      partyId: userPartyId,
    );
    if (!hasPriorChat) {
      return RoomEntryResult.denied(
        'Bu oda için süre dolmuş; artık bu odaya giriş yapılamıyor.',
      );
    }
    return RoomEntryResult.readOnlyExpired();
  } catch (_) {
    return RoomEntryResult.denied(
      'Bu odaya sohbet için erişiminiz yok veya oda bulunamadı.',
    );
  }
}
