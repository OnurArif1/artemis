import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/party_resolver.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../services/chat_hub_session.dart';
import '../../widgets/artemis_snackbar.dart';

class TopicChatScreen extends StatefulWidget {
  const TopicChatScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  final int topicId;
  final String topicTitle;

  @override
  State<TopicChatScreen> createState() => _TopicChatScreenState();
}

class _CommentLine {
  _CommentLine({
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

class _TopicChatScreenState extends State<TopicChatScreen> {
  final _scroll = ScrollController();
  final _text = TextEditingController();

  ChatHubSession? _hub;
  List<_CommentLine> _comments = [];
  final Map<int, String> _partyNames = {};
  bool _loading = true;
  bool _sending = false;
  String? _error;
  bool _hubReady = false;
  int? _partyId;
  MethodInvocationFunc? _receiveHandler;
  MethodInvocationFunc? _errorHandler;

  @override
  void dispose() {
    _detachHub();
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _detachHub() async {
    final h = _hub;
    final rh = _receiveHandler;
    final eh = _errorHandler;
    if (h != null) {
      if (rh != null) {
        try {
          h.offReceiveComment(rh);
        } catch (_) {}
      }
      if (eh != null) {
        try {
          h.offReceiveError(eh);
        } catch (_) {}
      }
      try {
        await h.leaveTopic(widget.topicId);
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

    await _loadHistory(app);
    if (!mounted) return;

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
        final tid = (args[3] as num).toInt();
        if (tid != widget.topicId) return;
        _ingestIncoming(partyId, partyName, message);
      };
      _errorHandler = (args) {
        if (args == null || args.isEmpty) return;
        if (!mounted) return;
        showAppSnackBar(context, '${args.first}', error: true);
      };
      session.onReceiveComment(_receiveHandler!);
      session.onReceiveError(_errorHandler!);
      await session.joinTopic(widget.topicId);
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
            'Canlı bağlantı kurulamadı (SignalR). SIGNALR_PORT ve sunucu adresini kontrol edin.';
      });
    }
  }

  Future<void> _loadHistory(AppServices app) async {
    try {
      final raw = await app.comments.getList({
        'topicId': widget.topicId,
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

      final lines = <_CommentLine>[];
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
          _CommentLine(
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
      setState(() => _comments = lines);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Yorumlar yüklenemedi');
    }
  }

  void _ingestIncoming(int partyId, String partyName, String message) {
    if (!mounted) return;
    final now = DateTime.now();
    final dup = _comments.any(
      (c) =>
          c.partyId == partyId &&
          c.content == message &&
          now.difference(c.at).inMilliseconds.abs() < 5000,
    );
    if (dup) return;
    setState(() {
      _partyNames[partyId] = partyName;
      _comments = [
        ..._comments,
        _CommentLine(
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
      await hub.sendTopicComment(
        partyId: pid,
        topicId: widget.topicId,
        message: t,
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.topicTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _hubReady
                  ? 'Canlı yorumlar'
                  : _loading
                      ? 'Yükleniyor…'
                      : 'Bağlantı yok',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
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
            child: _loading && _comments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _comments.length,
                    itemBuilder: (context, i) {
                      final m = _comments[i];
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
                                m.partyName,
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
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Yorum yazın…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (_sending || !_hubReady) ? null : _send,
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
