import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons/app_content_icons.dart';
import '../../core/geo/room_map_clustering.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/ensure_room_access.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/party_resolver.dart';
import '../../core/util/room_display.dart';
import '../../core/util/subscription_display.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import '../../widgets/subscription_tier_badge.dart';
import '../chat/room_chat_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.room});

  final Map<String, dynamic> room;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  bool _chatAllowed = false;
  bool _expired = false;
  int? _messageParticipantCount;
  bool _loadingMessageParticipantCount = true;

  @override
  void initState() {
    super.initState();
    _expired = lifecycleExpiredFromRoomMap(widget.room);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveChatState();
      _loadMessageParticipantCount();
    });
  }

  Future<void> _resolveChatState() async {
    final roomId = entityId(widget.room);
    if (roomId == null) return;
    final app = context.read<AppServices>();
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);
    final pid = await resolveCurrentPartyId(app, email);
    if (!mounted || pid == null) return;

    final entry = await resolveRoomEntry(
      app: app,
      roomId: roomId,
      userPartyId: pid,
      userEmail: email,
    );
    if (!mounted) return;
    setState(() {
      _expired = _expired || entry.readOnlyExpired;
      _chatAllowed = entry.allowed && !entry.readOnlyExpired;
    });
  }

  Future<void> _loadMessageParticipantCount() async {
    final roomId = entityId(widget.room);
    if (roomId == null) {
      if (!mounted) return;
      setState(() => _loadingMessageParticipantCount = false);
      return;
    }
    final app = context.read<AppServices>();
    const pageSize = 500;
    var pageIndex = 1;
    final uniquePartyIds = <int>{};
    try {
      while (true) {
        final raw = await app.messages.getList({
          'roomId': roomId,
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        });
        final items = extractItems(raw);
        if (items.isEmpty) break;
        for (final e in items) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final pid = m['partyId'] ?? m['PartyId'];
          final id = pid is int ? pid : int.tryParse('$pid');
          if (id != null && id > 0) {
            uniquePartyIds.add(id);
          }
        }
        if (items.length < pageSize) break;
        pageIndex++;
      }
    } catch (_) {
    }
    if (!mounted) return;
    setState(() {
      _messageParticipantCount = uniquePartyIds.length;
      _loadingMessageParticipantCount = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
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
    final headerTitle = (topicTitle != null && topicTitle.isNotEmpty)
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
      if (_loadingMessageParticipantCount)
        row('Mesajlaşan kişi', 'Yükleniyor...'),
      if (!_loadingMessageParticipantCount && _messageParticipantCount != null)
        row('Mesajlaşan kişi', '$_messageParticipantCount'),
    ].where((s) => s.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(AppContentIcons.room, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                headerTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
          if (subType != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Paket:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                SubscriptionTierBadge(
                  subscriptionType: subType,
                  compact: true,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (id != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _chatAllowed
                  ? null
                  : () {
                      showAppSnackBar(
                        context,
                        _expired
                            ? 'Bu odaya giremezsin çünkü artık aktif değil.'
                            : 'Bu odaya giremezsin çünkü artık aktif değil.',
                        error: true,
                      );
                    },
              child: FilledButton.icon(
                onPressed: _chatAllowed
                    ? () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => RoomChatScreen(
                              roomId: id,
                              roomTitle: title,
                              topicTitle: topicTitle,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.forum_rounded),
                label: Text(
                  _expired ? 'Süre doldu' : 'Canlı sohbete gir',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _expired
                      ? Colors.grey.shade500
                      : AppColors.purple600,
                  disabledBackgroundColor: Colors.grey.shade400,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          if (_expired) ...[
            const SizedBox(height: 8),
            Text(
              'Bu oda için süre dolmuş.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
