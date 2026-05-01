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

  String _lifecycleRemainingCompact() {
    if (_lifecycleEndsAtUtc == null) return '';
    if (_expired) return 'Sona erdi';
    final end = _lifecycleEndsAtUtc!;
    final nowUtc = _lifecycleTick.toUtc();
    if (!nowUtc.isBefore(end)) return 'Sona erdi';
    final remaining = end.difference(nowUtc);
    final d = remaining.inDays;
    final h = remaining.inHours.remainder(24);
    final min = remaining.inMinutes.remainder(60);
    final sec = remaining.inSeconds.remainder(60);
    final parts = <String>[];
    if (d > 0) parts.add('${d}g');
    if (h > 0 || d > 0) parts.add('${h}s');
    parts.add('${min}dk');
    parts.add('${sec}sn');
    return parts.join(' ');
  }

  String _lifecycleEndFormatted(BuildContext context) {
    if (_lifecycleEndsAtUtc == null) return '';
    final endLocal = _lifecycleEndsAtUtc!.toLocal();
    final loc = MaterialLocalizations.of(context);
    final dateStr = loc.formatCompactDate(endLocal);
    final timeStr = loc.formatTimeOfDay(
      TimeOfDay.fromDateTime(endLocal),
      alwaysUse24HourFormat: true,
    );
    return '$dateStr · $timeStr';
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

  static const _splitFlexLeft = 11;
  static const _splitFlexRight = 13;

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Color(0xFF8B8798),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: AppColors.darkCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final id = entityId(room);
    final title =
        entityString(room, ['title', 'Title']) ?? 'Oda #${id ?? '—'}';
    final topicTitle =
        entityString(room, ['topicTitle', 'TopicTitle', 'topicName']);
    final topicTrimmed = topicTitle?.trim();
    final desc = entityString(room, ['description', 'Description']);
    final roomType = room['roomType'] ?? room['RoomType'];
    final range = room['roomRange'] ?? room['RoomRange'];
    final distance = room['distance'] ?? room['Distance'];
    final ll = itemLatLng(room);
    final subType = parseSubscriptionType(Map<String, dynamic>.from(room));
    final leftGradient = _expired
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5C3D3D),
              Color(0xFF4A2C2C),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.purple800,
              AppColors.purple600,
            ],
          );

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: _splitFlexLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: leftGradient),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(height: 12),
                      Icon(
                        AppContentIcons.room,
                        size: 36,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (topicTrimmed != null &&
                          topicTrimmed.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'KONU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.7,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topicTrimmed,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (desc != null && desc.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          desc,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (_lifecycleEndsAtUtc != null) ...[
                        Text(
                          'YAŞAM DÖNGÜSÜ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.7,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lifecycleRemainingCompact(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _expired
                              ? 'Bu oda kapandı'
                              : 'Bitiş ${_lifecycleEndFormatted(context)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: _splitFlexRight,
              child: ColoredBox(
                color: AppColors.surfaceLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detaylar',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkCharcoal,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            if (roomType != null)
                              _detailRow('Oda tipi', roomTypeLabelTr(roomType)),
                            if (range != null)
                              _detailRow('Menzil', '$range km'),
                            if (distance != null)
                              _detailRow(
                                'Mesafe',
                                distance is num
                                    ? '${distance.toStringAsFixed(2)} km'
                                    : '$distance',
                              ),
                            if (ll != null)
                              _detailRow(
                                'Konum',
                                '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}',
                              ),
                            if (_loadingMessageParticipantCount)
                              _detailRow('Mesajlaşan', '…'),
                            if (!_loadingMessageParticipantCount &&
                                _messageParticipantCount != null)
                              _detailRow(
                                'Mesajlaşan',
                                '$_messageParticipantCount kişi',
                              ),
                            if (subType != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'PAKET',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                      color: const Color(0xFF8B8798),
                                      fontSize: 10,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              SubscriptionTierBadge(
                                subscriptionType: subType,
                                compact: false,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_expired)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Bu oda için süre dolmuş.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                              ),
                            ),
                          if (id != null)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _chatAllowed
                                  ? null
                                  : () {
                                      showAppSnackBar(
                                        context,
                                        'Bu odaya giremezsin çünkü artık aktif değil.',
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
                                              topicTitle: topicTrimmed != null &&
                                                      topicTrimmed.isNotEmpty
                                                  ? topicTrimmed
                                                  : null,
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
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
