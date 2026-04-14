import 'package:flutter/material.dart';

import '../../core/icons/app_content_icons.dart';
import '../../core/geo/room_map_clustering.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/room_display.dart';
import '../../core/util/subscription_display.dart';
import '../../widgets/subscription_tier_badge.dart';
import '../chat/room_chat_screen.dart';

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
    final subType = parseSubscriptionType(Map<String, dynamic>.from(room));
    final appBarTitle = (topicTitle != null && topicTitle.isNotEmpty)
        ? '$title ($topicTitle)'
        : title;

    String row(String label, String? value) {
      if (value == null || value.isEmpty) return '';
      return '$label: $value';
    }

    final rows = <String>[
      if (roomType != null) row('Oda tipi', roomTypeLabelTr(roomType)),
      if (range != null) row('Menzil (km)', '$range'),
      if (distance != null) row('Mesafe', distance is num ? '${distance.toStringAsFixed(2)} km' : '$distance'),
      if (ll != null)
        row('Koordinat',
            '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}'),
    ].where((s) => s.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.purple100,
                foregroundColor: AppColors.purple700,
                child: Icon(AppContentIcons.room),
              ),
              if (subType != null) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: SubscriptionTierBadge(
                    subscriptionType: subType,
                    compact: false,
                  ),
                ),
              ],
            ],
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
          const SizedBox(height: 16),
          if (id != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => RoomChatScreen(
                      roomId: id,
                      roomTitle: appBarTitle,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.forum_rounded),
              label: const Text('Canlı sohbete gir'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple600,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
        ],
      ),
    );
  }
}
