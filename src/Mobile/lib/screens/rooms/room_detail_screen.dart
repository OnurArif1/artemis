import 'dart:async';

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

  DateTime? _lifecycleEndsAtUtc;
  Timer? _lifecycleTimer;
  DateTime _lifecycleTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    _expired = lifecycleExpiredFromRoomMap(widget.room);
    _lifecycleEndsAtUtc = lifecycleEndUtcFromRoomMap(widget.room);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveChatState();
      _loadMessageParticipantCount();
    });
    _startLifecycleCountdown();
  }

  @override
  void dispose() {
    _lifecycleTimer?.cancel();
    super.dispose();
  }

  void _startLifecycleCountdown() {
    _lifecycleTimer?.cancel();
    final end = _lifecycleEndsAtUtc;
    if (end == null) return;
    if (DateTime.now().toUtc().isAfter(end)) {
      if (!_expired && mounted) {
        setState(() {
          _expired = true;
          _chatAllowed = false;
        });
      }
      return;
    }
    _lifecycleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final e = _lifecycleEndsAtUtc;
      if (e != null && DateTime.now().toUtc().isAfter(e)) {
        _lifecycleTimer?.cancel();
        _lifecycleTimer = null;
        setState(() {
          _lifecycleTick = DateTime.now();
          _expired = true;
          _chatAllowed = false;
        });
        return;
      }
      setState(() => _lifecycleTick = DateTime.now());
    });
  }

  String _lifecycleCountdownText(BuildContext context) {
    if (_lifecycleEndsAtUtc == null) return '';
    if (_expired) {
      return 'Bu oda için yaşam döngüsü sona erdi.';
    }
    final end = _lifecycleEndsAtUtc!;
    final nowUtc = _lifecycleTick.toUtc();
    if (!nowUtc.isBefore(end)) {
      return 'Bu oda için yaşam döngüsü sona erdi.';
    }
    final remaining = end.difference(nowUtc);
    final endLocal = end.toLocal();
    final loc = MaterialLocalizations.of(context);
    final dateStr = loc.formatCompactDate(endLocal);
    final timeStr = loc.formatTimeOfDay(
      TimeOfDay.fromDateTime(endLocal),
      alwaysUse24HourFormat: true,
    );
    final d = remaining.inDays;
    final h = remaining.inHours.remainder(24);
    final min = remaining.inMinutes.remainder(60);
    final sec = remaining.inSeconds.remainder(60);
    final parts = <String>[];
    if (d > 0) parts.add('$d gün');
    if (h > 0 || d > 0) parts.add('$h sa');
    parts.add('$min dk');
    parts.add('$sec sn');
    final countdown = parts.join(' ');
    return 'Bitiş: $dateStr $timeStr\nKalan süre: $countdown';
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
          if (_lifecycleEndsAtUtc != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _expired ? Colors.red.shade50 : AppColors.purple50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _expired ? Colors.red.shade200 : AppColors.purple200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yaşam döngüsü',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _expired ? Colors.red.shade900 : AppColors.purple700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _lifecycleCountdownText(context),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          color: _expired
                              ? Colors.red.shade900
                              : AppColors.darkCharcoal,
                        ),
                  ),
                ],
              ),
            ),
          ],
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
