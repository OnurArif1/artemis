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

  /// Bağlı konu başlığı; doluysa üst başlıkta `odaAdı (konu)` gösterilir.
  final String? topicTitle;

  static String formatAppBarTitle({
    required String roomTitle,
    String? topicTitle,
  }) {
    final t = topicTitle?.trim();
    if (t != null && t.isNotEmpty) return '$roomTitle ($t)';
    return roomTitle;
  }

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
        setState(() {
          _countdownTick = DateTime.now();
          _lifecycleExpired = true;
        });
        return;
      }
      setState(() => _countdownTick = DateTime.now());
    });
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
    return 'Bitiş ~ $dateStr $timeStr · Kalan $countdown';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final appBarFg = theme.appBarTheme.foregroundColor ?? cs.onSurface;
    final subColor = cs.onSurfaceVariant;
    final mutedSub = subColor.withValues(alpha: 0.78);

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
          color: appBarFg,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ) ??
        TextStyle(color: appBarFg, fontSize: 17, fontWeight: FontWeight.w600);
    final subStyle = theme.textTheme.labelSmall?.copyWith(
          color: subColor,
          height: 1.25,
        ) ??
        TextStyle(color: subColor, fontSize: 11.5, height: 1.25);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              RoomChatScreen.formatAppBarTitle(
                roomTitle: widget.roomTitle,
                topicTitle: widget.topicTitle,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 16,
                  color: subColor,
                ),
                const SizedBox(width: 5),
                Text(
                  '${_speakerPartyIds.length}',
                  style: subStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _lifecycleSubtitle(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: subStyle,
            ),
            const SizedBox(height: 2),
            Text(
              _readOnlyExpired
                  ? 'Salt okunur — süre doldu'
                  : _hubReady
                      ? 'Bağlı'
                      : _loading
                          ? 'Yükleniyor…'
                          : 'Bağlantı yok',
              style: subStyle.copyWith(color: mutedSub),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final mine = myParty != null && m.partyId == myParty;
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                          ),
                          decoration: BoxDecoration(
                            color: mine
                                ? AppColors.purple500
                                : AppColors.purple50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: mine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                maskEmailLikeLabel(m.partyName,
                                    showFull: mine),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: mine
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : AppColors.purple700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.content,
                                style: TextStyle(
                                  color: mine ? Colors.white : AppColors.darkCharcoal,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      enabled: !_readOnlyExpired,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _readOnlyExpired
                            ? 'Bu odada mesaj gönderilemez'
                            : 'Mesaj yazın…',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (_readOnlyExpired || _sending || !_hubReady)
                        ? null
                        : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
