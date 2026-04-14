import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/party_resolver.dart';
import '../../providers/home_tab_controller.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import 'room_chat_screen.dart';
import 'start_chat_picker_screen.dart';
import 'topic_chat_screen.dart';

class _ConversationRow {
  _ConversationRow({
    required this.isRoom,
    required this.id,
    required this.title,
    required this.lastAt,
    this.preview,
  });

  final bool isRoom;
  final int id;
  final String title;
  final DateTime lastAt;
  final String? preview;
}

String _chatListTimeLabel(DateTime at) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  if (day == today) {
    return '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  }
  final yesterday = today.subtract(const Duration(days: 1));
  if (day == yesterday) {
    return 'Dün';
  }
  return '${at.day.toString().padLeft(2, '0')}.${at.month.toString().padLeft(2, '0')}.${at.year}';
}

class MyChatsScreen extends StatefulWidget {
  const MyChatsScreen({super.key});

  @override
  State<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends State<MyChatsScreen> {
  final _search = TextEditingController();
  List<_ConversationRow> _items = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  final Map<int, String> _roomTitlesCache = {};
  final Map<int, String> _topicTitlesCache = {};
  DateTime? _lastLoadedAt;
  static const _minAutoReloadGap = Duration(seconds: 20);

  late final HomeTabController _homeTab;

  List<_ConversationRow> _visibleChats() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((r) {
      if (r.title.toLowerCase().contains(q)) return true;
      final p = (r.preview ?? '').toLowerCase();
      return p.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _homeTab = context.read<HomeTabController>();
    _homeTab.addListener(_onHomeTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_homeTab.currentIndex == HomeTabController.chatsTabIndex) {
        _load(fullScreenLoading: _items.isEmpty);
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _homeTab.removeListener(_onHomeTabChanged);
    super.dispose();
  }

  void _onHomeTabChanged() {
    if (!mounted) return;
    if (_homeTab.currentIndex == HomeTabController.chatsTabIndex) {
      _load(fullScreenLoading: _items.isEmpty);
    }
  }

  List<_ConversationRow> _composeRows({
    required List<Map<String, dynamic>> msgMaps,
    required List<Map<String, dynamic>> commentMaps,
  }) {
    final roomByLast = <int, DateTime>{};
    final roomPreview = <int, String>{};
    for (final m in msgMaps) {
      final rid = m['roomId'] ?? m['RoomId'];
      final ri = rid is int ? rid : int.tryParse('$rid');
      if (ri == null || ri <= 0) continue;
      final cd = m['createDate'] ?? m['CreateDate'];
      final at = DateTime.tryParse('$cd') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final prev = roomByLast[ri];
      if (prev == null || at.isAfter(prev)) {
        roomByLast[ri] = at;
        final c = '${m['content'] ?? m['Content'] ?? ''}'.trim();
        if (c.isNotEmpty) roomPreview[ri] = c;
      }
    }

    final topicByLast = <int, DateTime>{};
    final topicPreview = <int, String>{};
    for (final m in commentMaps) {
      final tid = m['topicId'] ?? m['TopicId'];
      final ti = tid is int ? tid : int.tryParse('$tid');
      if (ti == null || ti <= 0) continue;
      final cd = m['createDate'] ?? m['CreateDate'];
      final at = DateTime.tryParse('$cd') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final prev = topicByLast[ti];
      if (prev == null || at.isAfter(prev)) {
        topicByLast[ti] = at;
        final c = '${m['content'] ?? m['Content'] ?? ''}'.trim();
        if (c.isNotEmpty) topicPreview[ti] = c;
      }
    }

    final rows = <_ConversationRow>[];
    for (final e in roomByLast.entries) {
      rows.add(
        _ConversationRow(
          isRoom: true,
          id: e.key,
          title: _roomTitlesCache[e.key] ?? 'Oda #${e.key}',
          lastAt: e.value,
          preview: roomPreview[e.key],
        ),
      );
    }
    for (final e in topicByLast.entries) {
      rows.add(
        _ConversationRow(
          isRoom: false,
          id: e.key,
          title: _topicTitlesCache[e.key] ?? 'Konu #${e.key}',
          lastAt: e.value,
          preview: topicPreview[e.key],
        ),
      );
    }
    rows.sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return rows;
  }

  Future<void> _load({bool fullScreenLoading = true, bool force = false}) async {
    if (!force &&
        _items.isNotEmpty &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _minAutoReloadGap) {
      return;
    }
    if (fullScreenLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }
    final app = context.read<AppServices>();
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);

    try {
      final partyId = await resolveCurrentPartyId(app, email);
      if (!mounted) return;
      if (partyId == null) {
        setState(() {
          _loading = false;
          _refreshing = false;
          _items = [];
          _error =
              'Hesabınıza bağlı kullanıcı (party) bulunamadı; sohbet geçmişi listelenemiyor.';
        });
        return;
      }

      // Önce sadece kullanıcının kendi mesaj/yorumları: sohbet listesi hızlı görünsün.
      final results = await Future.wait([
        app.messages.getList({
          'pageIndex': 1,
          'pageSize': 300,
          'partyId': partyId,
        }),
        app.comments.getList({
          'pageIndex': 1,
          'pageSize': 300,
          'partyId': partyId,
        }),
      ]);

      final msgMaps = asMapList(results[0]);
      final commentMaps = asMapList(results[1]);
      final rows = _composeRows(msgMaps: msgMaps, commentMaps: commentMaps);

      if (!mounted) return;
      setState(() {
        _items = rows;
        _loading = false;
        _refreshing = false;
        _lastLoadedAt = DateTime.now();
      });

      final neededRoomIds = <int>{
        for (final m in msgMaps)
          ((m['roomId'] ?? m['RoomId']) is int
                  ? (m['roomId'] ?? m['RoomId']) as int
                  : int.tryParse('${m['roomId'] ?? m['RoomId']}')) ??
              -1,
      }..removeWhere((id) => id <= 0 || _roomTitlesCache.containsKey(id));
      final neededTopicIds = <int>{
        for (final m in commentMaps)
          ((m['topicId'] ?? m['TopicId']) is int
                  ? (m['topicId'] ?? m['TopicId']) as int
                  : int.tryParse('${m['topicId'] ?? m['TopicId']}')) ??
              -1,
      }..removeWhere((id) => id <= 0 || _topicTitlesCache.containsKey(id));

      // Eksik başlıklar varsa arka planda tamamla; ilk çizimi bekletme.
      if (neededRoomIds.isNotEmpty || neededTopicIds.isNotEmpty) {
        final titlePayloads = await Future.wait([
          if (neededRoomIds.isNotEmpty) app.rooms.getList({'pageIndex': 1, 'pageSize': 1000}),
          if (neededTopicIds.isNotEmpty) app.topics.getList({'pageIndex': 1, 'pageSize': 1000}),
        ]);
        if (!mounted) return;

        var p = 0;
        if (neededRoomIds.isNotEmpty) {
          final roomMaps = asMapList(titlePayloads[p++]);
          for (final r in roomMaps) {
            final id = entityId(r);
            if (id == null || !neededRoomIds.contains(id)) continue;
            final t = entityString(r, ['title', 'Title']);
            if (t != null && t.isNotEmpty) _roomTitlesCache[id] = t;
          }
        }
        if (neededTopicIds.isNotEmpty) {
          final topicMaps = asMapList(titlePayloads[p]);
          for (final t in topicMaps) {
            final id = entityId(t);
            if (id == null || !neededTopicIds.contains(id)) continue;
            final title = entityString(t, ['title', 'Title']);
            if (title != null && title.isNotEmpty) _topicTitlesCache[id] = title;
          }
        }

        if (!mounted) return;
        setState(() {
          _items = _composeRows(msgMaps: msgMaps, commentMaps: commentMaps);
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.message ?? 'Yüklenemedi';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = 'Yüklenemedi';
      });
    }
  }

  Future<void> _open(_ConversationRow r) async {
    if (r.isRoom) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RoomChatScreen(
            roomId: r.id,
            roomTitle: r.title,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => TopicChatScreen(
            topicId: r.id,
            topicTitle: r.title,
          ),
        ),
      );
    }
    if (!mounted) return;
    _load(fullScreenLoading: false, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final rail = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Sohbetler'),
        automaticallyImplyLeading: !rail,
        actions: [
          IconButton(
            onPressed: (_loading || _refreshing) ? null : () => _load(fullScreenLoading: _items.isEmpty, force: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_loading || _error != null)
            ? null
            : () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const StartChatPickerScreen(),
                  ),
                );
                if (mounted) _load(fullScreenLoading: false, force: true);
              },
        backgroundColor: AppColors.purple600,
        child: const Icon(Icons.add_rounded),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Color(0xFFF0F2F5),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return ColoredBox(
        color: const Color(0xFFF0F2F5),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _load(fullScreenLoading: true, force: true),
                  child: const Text('Yeniden dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final visible = _visibleChats();

    if (_items.isEmpty) {
      return ColoredBox(
        color: const Color(0xFFF0F2F5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Sohbet ara…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear_rounded),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Henüz oda veya konu sohbetinde mesajınız yok.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    const dividerIndent = 80.0;

    return Column(
      children: [
        if (_refreshing)
          const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Sohbet ara…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear_rounded),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: Colors.white,
            child: RefreshIndicator(
              color: AppColors.purple500,
              onRefresh: () => _load(fullScreenLoading: false, force: true),
              child: visible.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 48),
                      children: [
                        Center(
                          child: Text(
                            'Aramanızla eşleşen sohbet yok.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: dividerIndent,
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, i) => _buildChatRow(context, visible[i]),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  static const _avatarRadius = 28.0;

  Widget _buildChatRow(BuildContext context, _ConversationRow r) {
    final theme = Theme.of(context);
    final pv = r.preview;
    final preview = (pv != null && pv.length > 72) ? '${pv.substring(0, 72)}…' : pv;
    final timeStr = _chatListTimeLabel(r.lastAt);
    final muted = theme.colorScheme.onSurfaceVariant;

    final secondLine = preview != null && preview.isNotEmpty
        ? preview
        : 'Sohbete dokunun';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _open(r),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: _avatarRadius,
                backgroundColor:
                    r.isRoom ? AppColors.purple100 : const Color(0xFFCCFBF1),
                foregroundColor:
                    r.isRoom ? AppColors.purple700 : const Color(0xFF0F766E),
                child: Icon(
                  r.isRoom ? Icons.meeting_room_rounded : Icons.topic_rounded,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      secondLine,
                      style: TextStyle(
                        color: muted.withValues(alpha: 0.92),
                        fontSize: 14,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
