import 'package:flutter/material.dart';

import '../../core/geo/room_map_clustering.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';

/// Web harita / liste üzerinden oda özeti (Chat tam Web’de).
class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({super.key, required this.room});

  final Map<String, dynamic> room;

  @override
  Widget build(BuildContext context) {
    final id = entityId(room);
    final title =
        entityString(room, ['title', 'Title']) ?? 'Oda #${id ?? '—'}';
    final topicTitle =
        entityString(room, ['topicTitle', 'TopicTitle', 'topicName']);
    final desc = entityString(room, ['description', 'Description']);
    final roomType = room['roomType'] ?? room['RoomType'];
    final range = room['roomRange'] ?? room['RoomRange'];
    final distance = room['distance'] ?? room['Distance'];
    final ll = itemLatLng(room);

    String row(String label, String? value) {
      if (value == null || value.isEmpty) return '';
      return '$label: $value';
    }

    final rows = <String>[
      if (topicTitle != null) row('Konu', topicTitle),
      if (roomType != null) row('Oda tipi', '$roomType'),
      if (range != null) row('Menzil (km)', '$range'),
      if (distance != null) row('Mesafe', distance is num ? '${distance.toStringAsFixed(2)} km' : '$distance'),
      if (ll != null)
        row('Koordinat',
            '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}'),
    ].where((s) => s.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.purple100,
              foregroundColor: AppColors.purple700,
              child: Icon(Icons.meeting_room_rounded),
            ),
            title: Text(title, style: Theme.of(context).textTheme.titleLarge),
            subtitle: topicTitle != null ? Text(topicTitle) : null,
          ),
          if (desc != null && desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(desc, style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: 20),
          Text(
            'Bilgiler',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(line),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Canlı sohbet Web istemcisinde açılır; mobilde oda bilgileri WebApi ile senkron.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }
}
