import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../core/location/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/ensure_room_access.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/privacy_label.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/party_resolver.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../services/chat_hub_session.dart';
import '../../widgets/artemis_snackbar.dart';

class RoomChatScreen extends StatefulWidget {
  const RoomChatScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
    this.topicTitle,
  });

  final int roomId;
  final String roomTitle;

  /// Bağlı konu başlığı; doluysa üst başlıkta oda adının altında ikinci satır olarak gösterilir.
  final String? topicTitle;

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _ChatLine {
  _ChatLine({
    required this.id,
    required this.partyId,
    required this.partyName,
    required this.content,
    required this.at,
  });

  final int id;
  final int partyId;
  final String partyName;
  final String content;
  final DateTime at;
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final _scroll = ScrollController();
  final _text = TextEditingController();

  ChatHubSession? _hub;
  List<_ChatLine> _messages = [];
  final Map<int, String> _partyNames = {};
  final Set<int> _speakerPartyIds = {};
  DateTime? _lifecycleEndsAtUtc;
  bool _lifecycleExpired = false;
  Timer? _countdownTimer;
  DateTime _countdownTick = DateTime.now();

  bool _loading = true;
  bool _sending = false;
  String? _error;
  bool _hubReady = false;
  bool _readOnlyExpired = false;
  int? _partyId;
  MethodInvocationFunc? _receiveHandler;
  MethodInvocationFunc? _errorHandler;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _detachHub();
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  void _ensureCountdownTimer() {
    _countdownTimer?.cancel();
    if (_lifecycleEndsAtUtc == null ||
        _lifecycleExpired ||
        _readOnlyExpired ||
        DateTime.now().toUtc().isAfter(_lifecycleEndsAtUtc!)) {
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final end = _lifecycleEndsAtUtc;
      if (end != null && DateTime.now().toUtc().isAfter(end)) {
        _countdownTimer?.cancel();
        _countdownTimer = null;
        setState(() => _lifecycleExpired = true);
        return;
      }
      setState(() => _countdownTick = DateTime.now());
    });
  }

  String _lifecycleSubtitle(BuildContext context) {
    if (_lifecycleExpired || _readOnlyExpired) {
      return 'Yaşam döngüsü sona erdi';
    }
    final end = _lifecycleEndsAtUtc;
    if (end == null) return 'Yaşam döngüsü bilinmiyor';
    final nowUtc = _countdownTick.toUtc();
    if (!nowUtc.isBefore(end)) {
      return 'Yaşam döngüsü sona erdi';
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
    if (d > 0) parts.add('${d}g');
    if (h > 0 || d > 0) parts.add('${h}s');
    parts.add('${min}dk');
    parts.add('${sec}sn');
    final countdown = parts.join(' ');
    return 'Bitiş $dateStr $timeStr · Kalan $countdown';
  }

  Future<Map<String, dynamic>?> _fetchRoomMap(
    AppServices app,
    String? userEmail,
  ) async {
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
      final rooms = raw is Map ? asMapList(raw) : <Map<String, dynamic>>[];
      for (final e in rooms) {
        if (entityId(e) == widget.roomId) return e;
      }
    } catch (_) {}
    return null;
  }

  DateTime? _lifecycleEndUtcFromRoom(Map<String, dynamic> room) =>
      lifecycleEndUtcFromRoomMap(room);

  Future<void> _loadUniqueSpeakerCount(AppServices app) async {
    const pageSize = 500;
    var pageIndex = 1;
    final ids = <int>{};
    try {
      while (true) {
        final raw = await app.messages.getList({
          'roomId': widget.roomId,
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
          if (id != null && id > 0) ids.add(id);
        }
        if (items.length < pageSize) break;
        pageIndex++;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _speakerPartyIds.addAll(ids));
  }

  Future<void> _detachHub() async {
    final h = _hub;
    final rh = _receiveHandler;
    final eh = _errorHandler;
    if (h != null) {
      if (rh != null) {
        try {
          h.offReceiveMessage(rh);
        } catch (_) {}
      }
      if (eh != null) {
        try {
          h.offReceiveError(eh);
        } catch (_) {}
      }
      try {
        await h.leaveRoom(widget.roomId);
      } catch (_) {}
      await h.disconnect();
    }
    _hub = null;
    _receiveHandler = null;
    _errorHandler = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final app = context.read<AppServices>();
    final email = emailFromAccessToken(context.read<AuthService>().token);

    final pid = await resolveCurrentPartyId(app, email);
    if (!mounted) return;
    if (pid == null) {
      setState(() {
        _loading = false;
        _error = 'Kullanıcı (party) bilgisi bulunamadı.';
      });
      return;
    }
    _partyId = pid;

    final entry = await resolveRoomEntry(
      app: app,
      roomId: widget.roomId,
      userPartyId: pid,
      userEmail: email,
    );
    if (!mounted) return;
    if (!entry.allowed) {
      setState(() {
        _loading = false;
        _error = entry.errorMessage ??
            'Bu odaya sohbet için erişiminiz yok veya oda bulunamadı.';
      });
      return;
    }

    _readOnlyExpired = entry.readOnlyExpired;

    final roomMap = await _fetchRoomMap(app, email);
    if (mounted && roomMap != null) {
      final expired = lifecycleExpiredFromRoomMap(roomMap);
      final endUtc = _lifecycleEndUtcFromRoom(roomMap);
      setState(() {
        _lifecycleExpired = expired;
        _lifecycleEndsAtUtc = endUtc;
      });
      _ensureCountdownTimer();
    }

    await Future.wait<void>([
      _loadUniqueSpeakerCount(app),
      _loadHistory(app),
    ]);
    if (!mounted) return;

    if (_readOnlyExpired) {
      setState(() {
        _loading = false;
        _hubReady = false;
      });
      _showExpiredReadOnlyDialog();
      return;
    }

    final session = ChatHubSession(
      getAccessToken: () async => context.read<AuthService>().token,
    );

    try {
      await session.connect();
      _receiveHandler = (args) {
        if (args == null || args.length < 4) return;
        final partyId = (args[0] as num).toInt();
        final partyName = '${args[1]}';
        final message = '${args[2]}';
        final rid = (args[3] as num).toInt();
        if (rid != widget.roomId) return;
        _ingestIncoming(partyId, partyName, message);
      };
      _errorHandler = (args) {
        if (args == null || args.isEmpty) return;
        if (!mounted) return;
        showAppSnackBar(context, '${args.first}', error: true);
      };
      session.onReceiveMessage(_receiveHandler!);
      session.onReceiveError(_errorHandler!);
      await session.joinRoom(widget.roomId);
      if (!mounted) return;
      _hub = session;
      setState(() {
        _hubReady = true;
        _loading = false;
      });
      _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
      await session.disconnect();
      setState(() {
        _loading = false;
        _error =
            'Canlı bağlantı kurulamadı (SignalR). Sunucu adresi ve SIGNALR_PORT (varsayılan 5094) kontrol edin.';
      });
    }
  }

  void _showExpiredReadOnlyDialog() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: const Text('Oda artık aktif değil'),
          content: const Text(
            'Bu oda için süre dolmuş. Geçmiş mesajları görebilirsiniz; yeni mesaj gönderemezsiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _loadHistory(AppServices app) async {
    try {
      final raw = await app.messages.getList({
        'roomId': widget.roomId,
        'pageIndex': 1,
        'pageSize': 1000,
      });
      final items = extractItems(raw);
      final ids = <int>{};
      for (final e in items) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final pid = m['partyId'] ?? m['PartyId'];
        if (pid is int) ids.add(pid);
        if (pid is num) ids.add(pid.toInt());
      }
      for (final id in ids) {
        if (_partyNames.containsKey(id)) continue;
        try {
          final lu = await app.parties.getLookup({'PartyId': id});
          if (lu is Map) {
            final vm = lu['viewModels'] ?? lu['ViewModels'];
            if (vm is List && vm.isNotEmpty && vm.first is Map) {
              final p = Map<String, dynamic>.from(vm.first as Map);
              final n = p['partyName'] ?? p['PartyName'];
              if (n != null) _partyNames[id] = '$n';
            }
          }
        } catch (_) {}
      }

      final lines = <_ChatLine>[];
      for (final e in items) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final id = entityId(m) ?? 0;
        final pid = m['partyId'] ?? m['PartyId'];
        final pi = pid is int ? pid : (pid is num ? pid.toInt() : 0);
        final content = '${m['content'] ?? m['Content'] ?? ''}';
        final cd = m['createDate'] ?? m['CreateDate'];
        final at = DateTime.tryParse('$cd') ?? DateTime.now();
        final name = _partyNames[pi] ?? 'Kullanıcı $pi';
        lines.add(
          _ChatLine(
            id: id,
            partyId: pi,
            partyName: name,
            content: content,
            at: at,
          ),
        );
      }
      lines.sort((a, b) => a.at.compareTo(b.at));
      if (!mounted) return;
      setState(() {
        _messages = lines;
        for (final line in lines) {
          if (line.partyId > 0) _speakerPartyIds.add(line.partyId);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Mesajlar yüklenemedi');
    }
  }

  void _ingestIncoming(int partyId, String partyName, String message) {
    if (!mounted) return;
    final now = DateTime.now();
    final dup = _messages.any(
      (m) =>
          m.partyId == partyId &&
          m.content == message &&
          now.difference(m.at).inMilliseconds.abs() < 5000,
    );
    if (dup) return;
    setState(() {
      _speakerPartyIds.add(partyId);
      _partyNames[partyId] = partyName;
      _messages = [
        ..._messages,
        _ChatLine(
          id: now.millisecondsSinceEpoch,
          partyId: partyId,
          partyName: partyName,
          content: message,
          at: now,
        ),
      ];
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    if (_readOnlyExpired) return;
    final t = _text.text.trim();
    final pid = _partyId;
    final hub = _hub;
    if (t.isEmpty || pid == null || hub == null || !_hubReady) {
      if (t.isNotEmpty && !_hubReady) {
        showAppSnackBar(context, 'Bağlantı hazır değil.', error: true);
      }
      return;
    }
    setState(() => _sending = true);
    try {
      await hub.sendRoomMessage(
        partyId: pid,
        roomId: widget.roomId,
        message: t,
        mentionedPartyIds: null,
      );
      final selfName = _partyNames[pid] ?? 'Sen';
      _partyNames[pid] = selfName;
      _ingestIncoming(pid, selfName, t);
      _text.clear();
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Gönderilemedi', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myParty = _partyId;
    final expiredLook = _lifecycleExpired || _readOnlyExpired;
    final canSend = !_readOnlyExpired && !_sending && _hubReady;
    // Başlıktaki süresi dolmuş gradient ile uyumlu ( _RoomChatHeader )
    const expiredBubble = Color(0xFF5C3D3D);
    const expiredBubbleDeep = Color(0xFF4A2C2C);
    final mineBubble =
        expiredLook ? expiredBubble : AppColors.purple500;
    final mineShadow = expiredLook
        ? expiredBubbleDeep.withValues(alpha: 0.32)
        : AppColors.purple500.withValues(alpha: 0.26);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoomChatHeader(
            roomTitle: widget.roomTitle,
            topicTitle: widget.topicTitle,
            lifecycleLine: _lifecycleSubtitle(context),
            participantCount: _speakerPartyIds.length,
            expiredVisual: expiredLook,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kapat'),
                ),
              ],
            ),
          Expanded(
            child: ColoredBox(
              color: AppColors.surfaceLight,
              child: _loading && _messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.purple500,
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        final mine = myParty != null && m.partyId == myParty;
                        final bubbleRadius = BorderRadius.only(
                          topLeft: Radius.circular(mine ? 18 : 6),
                          topRight: Radius.circular(mine ? 6 : 18),
                          bottomLeft: const Radius.circular(18),
                          bottomRight: const Radius.circular(18),
                        );
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.sizeOf(context).width * 0.82,
                            ),
                            decoration: BoxDecoration(
                              color: mine ? mineBubble : AppColors.surfaceCard,
                              borderRadius: bubbleRadius,
                              border: mine
                                  ? null
                                  : Border.all(
                                      color: AppColors.outlineMuted
                                          .withValues(alpha: 0.85),
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: mine
                                      ? mineShadow
                                      : Colors.black
                                          .withValues(alpha: 0.06),
                                  blurRadius: mine ? 12 : 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: mine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  maskEmailLikeLabel(
                                    m.partyName,
                                    showFull: mine,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 0.15,
                                    color: mine
                                        ? Colors.white.withValues(alpha: 0.92)
                                        : (expiredLook
                                            ? expiredBubble
                                            : AppColors.purple700),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  m.content,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: mine
                                        ? Colors.white
                                        : AppColors.darkCharcoal,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Material(
                color: AppColors.surfaceCard,
                elevation: 0,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(
                    color: AppColors.outlineMuted.withValues(alpha: 0.9),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _text,
                          enabled: !_readOnlyExpired,
                          minLines: 1,
                          maxLines: 5,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: AppColors.darkCharcoal,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: _readOnlyExpired
                                ? 'Bu odada mesaj gönderilemez'
                                : 'Mesaj yazın…',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: canSend
                              ? mineBubble
                              : (expiredLook
                                  ? expiredBubble.withValues(alpha: 0.22)
                                  : AppColors.purple100),
                          foregroundColor: canSend
                              ? Colors.white
                              : (expiredLook
                                  ? expiredBubbleDeep.withValues(alpha: 0.42)
                                  : AppColors.purple300),
                          disabledBackgroundColor: expiredLook
                              ? expiredBubble.withValues(alpha: 0.18)
                              : AppColors.purple50,
                          disabledForegroundColor: expiredLook
                              ? expiredBubbleDeep.withValues(alpha: 0.36)
                              : AppColors.purple200,
                        ),
                        onPressed:
                            (_readOnlyExpired || _sending || !_hubReady)
                                ? null
                                : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomChatHeader extends StatelessWidget {
  const _RoomChatHeader({
    required this.roomTitle,
    this.topicTitle,
    required this.lifecycleLine,
    required this.participantCount,
    required this.expiredVisual,
    required this.onBack,
  });

  final String roomTitle;
  final String? topicTitle;
  final String lifecycleLine;
  final int participantCount;
  final bool expiredVisual;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topicTrimmed = topicTitle?.trim();
    final gradient = expiredVisual
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

    final capsStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.65,
      color: Colors.white.withValues(alpha: 0.58),
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: onBack,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ODA', style: capsStyle),
                    const SizedBox(height: 4),
                    Text(
                      roomTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                      ),
                    ),
                    if (topicTrimmed != null &&
                        topicTrimmed.isNotEmpty &&
                        topicTrimmed != roomTitle.trim()) ...[
                      const SizedBox(height: 10),
                      Text('KONU', style: capsStyle),
                      const SizedBox(height: 3),
                      Text(
                        topicTrimmed,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text('YAŞAM DÖNGÜSÜ', style: capsStyle),
                    const SizedBox(height: 3),
                    Text(
                      lifecycleLine,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 17,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '$participantCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
