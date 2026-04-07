import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

const double cityClusterDistanceKm = 50;

double calculateDistanceKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double? _coord(Map<String, dynamic> item, String camel, String pascal) {
  final v = item[camel] ?? item[pascal];
  if (v == null) return null;
  return double.tryParse(v.toString());
}

LatLng? itemLatLng(Map<String, dynamic> item) {
  final lat = _coord(item, 'locationY', 'LocationY');
  final lng = _coord(item, 'locationX', 'LocationX');
  if (lat == null || lng == null) return null;
  return LatLng(lat, lng);
}

class CombinedRegion {
  CombinedRegion({
    required this.center,
    required this.key,
    required this.roomItems,
    required this.topicItems,
  });

  final LatLng center;
  final String key;
  final List<Map<String, dynamic>> roomItems;
  final List<Map<String, dynamic>> topicItems;

  int get roomCount => roomItems.length;
  int get topicCount => topicItems.length;
}

class _SplitRegion {
  _SplitRegion({
    required this.items,
    required this.center,
    required this.key,
  });

  final List<Map<String, dynamic>> items;
  final LatLng center;
  final String key;
}

List<_SplitRegion> _groupByRegion(List<Map<String, dynamic>> items) {
  final regions = <_SplitRegion>[];
  final processed = <int>{};

  for (var i = 0; i < items.length; i++) {
    if (processed.contains(i)) continue;
    final item = items[i];
    final ll = itemLatLng(item);
    if (ll == null) continue;

    final regionItems = <Map<String, dynamic>>[item];
    processed.add(i);

    for (var j = i + 1; j < items.length; j++) {
      if (processed.contains(j)) continue;
      final other = items[j];
      final oll = itemLatLng(other);
      if (oll == null) continue;
      final dist = calculateDistanceKm(
        ll.latitude,
        ll.longitude,
        oll.latitude,
        oll.longitude,
      );
      if (dist <= cityClusterDistanceKm) {
        regionItems.add(other);
        processed.add(j);
      }
    }

    var totalLat = 0.0;
    var totalLng = 0.0;
    for (final it in regionItems) {
      final p = itemLatLng(it)!;
      totalLat += p.latitude;
      totalLng += p.longitude;
    }
    final n = regionItems.length;
    final center = LatLng(totalLat / n, totalLng / n);
    final key =
        '${(center.latitude * 10).round() / 10}_${(center.longitude * 10).round() / 10}';

    regions.add(_SplitRegion(items: regionItems, center: center, key: key));
  }

  return regions;
}

List<CombinedRegion> buildCombinedRegions(
  List<Map<String, dynamic>> rooms,
  List<Map<String, dynamic>> topics,
) {
  final roomRegions = _groupByRegion(rooms);
  final topicRegions = _groupByRegion(topics);

  final entries = <({_SplitRegion r, bool isRoom})>[
    ...roomRegions.map((r) => (r: r, isRoom: true)),
    ...topicRegions.map((r) => (r: r, isRoom: false)),
  ];

  final combined = <CombinedRegion>[];
  final processedRooms = <int>{};
  final processedTopics = <int>{};

  for (var i = 0; i < entries.length; i++) {
    final isRoom = entries[i].isRoom;
    final r = entries[i].r;
    if (isRoom && processedRooms.contains(i)) continue;
    if (!isRoom && processedTopics.contains(i)) continue;

    final roomItems = <Map<String, dynamic>>[];
    final topicItems = <Map<String, dynamic>>[];
    if (isRoom) {
      processedRooms.add(i);
      roomItems.addAll(r.items);
    } else {
      processedTopics.add(i);
      topicItems.addAll(r.items);
    }

    var center = r.center;

    for (var j = i + 1; j < entries.length; j++) {
      final other = entries[j];
      final otherIsRoom = other.isRoom;
      if (otherIsRoom && processedRooms.contains(j)) continue;
      if (!otherIsRoom && processedTopics.contains(j)) continue;

      final dist = calculateDistanceKm(
        center.latitude,
        center.longitude,
        other.r.center.latitude,
        other.r.center.longitude,
      );

      if (dist <= cityClusterDistanceKm) {
        if (otherIsRoom) {
          roomItems.addAll(other.r.items);
          processedRooms.add(j);
        } else {
          topicItems.addAll(other.r.items);
          processedTopics.add(j);
        }
      }
    }

    final allItems = [...roomItems, ...topicItems];
    if (allItems.isEmpty) continue;
    var totalLat = 0.0;
    var totalLng = 0.0;
    for (final it in allItems) {
      final p = itemLatLng(it)!;
      totalLat += p.latitude;
      totalLng += p.longitude;
    }
    final n = allItems.length;
    center = LatLng(totalLat / n, totalLng / n);
    final key =
        '${(center.latitude * 10).round() / 10}_${(center.longitude * 10).round() / 10}';

    combined.add(CombinedRegion(
      center: center,
      key: key,
      roomItems: roomItems,
      topicItems: topicItems,
    ));
  }

  return combined;
}

List<Map<String, dynamic>> filterWithinKm(
  List<Map<String, dynamic>> items,
  double userLat,
  double userLng,
  double radiusKm,
) {
  return items.where((it) {
    final p = itemLatLng(it);
    if (p == null) return false;
    return calculateDistanceKm(userLat, userLng, p.latitude, p.longitude) <=
        radiusKm;
  }).toList();
}
