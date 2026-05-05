import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons/app_content_icons.dart';
import '../../core/navigation/app_route_observer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/ensure_room_access.dart';
import '../../core/util/party_resolver.dart';
import '../../providers/home_tab_controller.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import 'room_chat_screen.dart';
import 'start_chat_picker_screen.dart';
import 'topic_chat_screen.dart';

String? _partyNameFromLookupResponse(dynamic lu) {
  if (lu is! Map) return null;
  final vm = lu['viewModels'] ?? lu['ViewModels'];
  if (vm is! List || vm.isEmpty) return null;
  final first = vm.first;
  if (first is! Map) return null;
  final m = Map<String, dynamic>.from(first);
  final n = '${m['partyName'] ?? m['PartyName'] ?? ''}'.trim();
  return n.isEmpty ? null : n;
}

class _ConversationRow {
  _ConversationRow({
    required this.isRoom,
    required this.id,
    required this.title,
    required this.lastAt,
    this.preview,
    this.lastSenderPartyName,
    this.lastSenderPartyId,
    this.roomTopicTitle,
    this.roomLifecycleExpired = false,
  });

  final bool isRoom;
  final int id;
  final String title;
  final DateTime lastAt;
  final String? preview;

  /// API mesaj satırında varsa son gönderenin partyName'i.
  final String? lastSenderPartyName;

  /// Liste yanıtında isim yoksa lookup için gönderen party id.
  final int? lastSenderPartyId;

  /// Oda sohbeti için konu başlığı (üst çubukta parantez içinde gösterilir).
  final String? roomTopicTitle;

  /// [RoomChatScreen] süresi dolmuş görünümü ile uyum için; yalnızca oda satırlarında.
  final bool roomLifecycleExpired;
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

class _MyChatsScreenState extends State<MyChatsScreen> with RouteAware {
  final _search = TextEditingController();
  final _listScroll = ScrollController();
  List<_ConversationRow> _items = [];
  final List<Map<String, dynamic>> _allMsgMaps = [];
  final List<Map<String, dynamic>> _allCommentMaps = [];
  bool _loading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  String? _error;
  final Map<int, String> _roomTitlesCache = {};
  final Map<int, String> _roomTopicTitlesCache = {};
  final Map<int, bool> _roomLifecycleExpiredCache = {};
  final Map<int, String> _topicTitlesCache = {};
  /// Mesaj listesinde partyName gelmediğinde lookup ile doldurulur.
  final Map<int, String> _partyDisplayNamesById = {};
  DateTime? _lastLoadedAt;
  static const _minAutoReloadGap = Duration(seconds: 20);
  static const _pageSize = 50;
  int _msgPageIndex = 1;
  int _commentPageIndex = 1;
  bool _hasMoreMessages = true;
  bool _hasMoreComments = true;
  int? _partyId;
  Timer? _reloadAfterPopTimer;

  late final HomeTabController _homeTab;

  String? _resolvedRoomTopicTitle(int roomId) {
    if (!_roomTopicTitlesCache.containsKey(roomId)) return null;
    final s = _roomTopicTitlesCache[roomId]!.trim();
    return s.isEmpty ? null : s;
  }

  List<_ConversationRow> _visibleChats() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((r) {
      if (r.title.toLowerCase().contains(q)) return true;
      if (r.isRoom) {
        final tt = r.roomTopicTitle?.trim().toLowerCase();
        if (tt != null && tt.isNotEmpty && tt.contains(q)) return true;
      }
      final p = (r.preview ?? '').toLowerCase();
      if (p.contains(q)) return true;
      final inline = (r.lastSenderPartyName ?? '').toLowerCase();
      if (inline.contains(q)) return true;
      final pid = r.lastSenderPartyId;
      if (pid != null) {
        final cached = (_partyDisplayNamesById[pid] ?? '').toLowerCase();
        if (cached.contains(q)) return true;
      }
      return false;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _listScroll.addListener(_onListScroll);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _reloadAfterPopTimer?.cancel();
    appRouteObserver.unsubscribe(this);
    _search.dispose();
    _listScroll.dispose();
    _homeTab.removeListener(_onHomeTabChanged);
    super.dispose();
  }

  bool get _canLoadMore =>
      _hasMoreMessages || _hasMoreComments;

  void _onListScroll() {
    if (!_listScroll.hasClients) return;
    if (_loading || _refreshing || _loadingMore) return;
    if (_error != null) return;
    if (!_canLoadMore) return;
    final pos = _listScroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 220) {
      _loadMore();
    }
  }

  void _scheduleReloadChatsAfterOverlayPop() {
    _reloadAfterPopTimer?.cancel();
    _reloadAfterPopTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_homeTab.currentIndex != HomeTabController.chatsTabIndex) return;
      _load(fullScreenLoading: false, force: true);
    });
  }

  @override
  void didPopNext() {
    _scheduleReloadChatsAfterOverlayPop();
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
    final roomSenderName = <int, String>{};
    final roomSenderPartyId = <int, int>{};
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
        final pn = '${m['partyName'] ?? m['PartyName'] ?? ''}'.trim();
        final pidRaw = m['partyId'] ?? m['PartyId'];
        final pid = pidRaw is int ? pidRaw : int.tryParse('$pidRaw');
        if (pid != null && pid > 0) {
          roomSenderPartyId[ri] = pid;
        }
        if (pn.isNotEmpty) {
          roomSenderName[ri] = pn;
        }
      }
    }

    final topicByLast = <int, DateTime>{};
    final topicPreview = <int, String>{};
    final topicSenderName = <int, String>{};
    final topicSenderPartyId = <int, int>{};
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
        final pn = '${m['partyName'] ?? m['PartyName'] ?? ''}'.trim();
        final pidRaw = m['partyId'] ?? m['PartyId'];
        final pid = pidRaw is int ? pidRaw : int.tryParse('$pidRaw');
        if (pid != null && pid > 0) {
          topicSenderPartyId[ti] = pid;
        }
        if (pn.isNotEmpty) {
          topicSenderName[ti] = pn;
        }
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
          lastSenderPartyName: roomSenderName[e.key],
          lastSenderPartyId: roomSenderPartyId[e.key],
          roomTopicTitle: _resolvedRoomTopicTitle(e.key),
          roomLifecycleExpired: _roomLifecycleExpiredCache[e.key] ?? false,
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
          lastSenderPartyName: topicSenderName[e.key],
          lastSenderPartyId: topicSenderPartyId[e.key],
        ),
      );
    }
    rows.sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return rows;
  }

  Future<void> _resolveSenderDisplayNames(
    AppServices app,
    List<_ConversationRow> rows,
  ) async {
    final missing = <int>{};
    for (final r in rows) {
      final pid = r.lastSenderPartyId;
      if (pid == null || pid <= 0) continue;
      final inline = r.lastSenderPartyName?.trim();
      if (inline != null && inline.isNotEmpty) continue;
      if (_partyDisplayNamesById.containsKey(pid)) continue;
      missing.add(pid);
    }
    if (missing.isEmpty) return;

    final results = await Future.wait(
      missing.map((id) async {
        try {
          final lu = await app.parties.getLookup({'PartyId': id});
          return MapEntry(id, _partyNameFromLookupResponse(lu));
        } catch (_) {
          return MapEntry(id, null);
        }
      }),
    );

    if (!mounted) return;

    var touched = false;
    for (final e in results) {
      final name = e.value;
      if (name != null && name.isNotEmpty) {
        _partyDisplayNamesById[e.key] = name;
        touched = true;
      }
    }
    if (touched) setState(() {});
  }

  void _resetPagingState() {
    _allMsgMaps.clear();
    _allCommentMaps.clear();
    _msgPageIndex = 1;
    _commentPageIndex = 1;
    _hasMoreMessages = true;
    _hasMoreComments = true;
  }

  Future<void> _hydrateTitlesIfNeeded(
    AppServices app, {
    required List<Map<String, dynamic>> msgMaps,
    required List<Map<String, dynamic>> commentMaps,
  }) async {
    final neededRoomIds = <int>{
      for (final m in msgMaps)
        ((m['roomId'] ?? m['RoomId']) is int
                ? (m['roomId'] ?? m['RoomId']) as int
                : int.tryParse('${m['roomId'] ?? m['RoomId']}')) ??
            -1,
    }..removeWhere(
        (id) =>
            id <= 0 ||
            (_roomTitlesCache.containsKey(id) &&
                _roomTopicTitlesCache.containsKey(id) &&
                _roomLifecycleExpiredCache.containsKey(id)),
      );
    final neededTopicIds = <int>{
      for (final m in commentMaps)
        ((m['topicId'] ?? m['TopicId']) is int
                ? (m['topicId'] ?? m['TopicId']) as int
                : int.tryParse('${m['topicId'] ?? m['TopicId']}')) ??
            -1,
    }..removeWhere((id) => id <= 0 || _topicTitlesCache.containsKey(id));

    if (neededRoomIds.isEmpty && neededTopicIds.isEmpty) return;

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
        final tt = entityString(r, ['topicTitle', 'TopicTitle']);
        _roomTopicTitlesCache[id] = tt ?? '';
        _roomLifecycleExpiredCache[id] = lifecycleExpiredFromRoomMap(r);
      }
      for (final rid in neededRoomIds) {
        _roomTopicTitlesCache.putIfAbsent(rid, () => '');
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
  }

  Future<void> _fetchNextPage(AppServices app) async {
    if (_partyId == null) return;
    if (!_hasMoreMessages && !_hasMoreComments) return;

    final requests = <Future<dynamic>>[];
    final fetchMessages = _hasMoreMessages;
    final fetchComments = _hasMoreComments;

    if (fetchMessages) {
      requests.add(
        app.messages.getList({
          'pageIndex': _msgPageIndex,
          'pageSize': _pageSize,
          'latestInRoomsWhereParticipated': true,
          'participatingPartyId': _partyId,
        }),
      );
    }
    if (fetchComments) {
      requests.add(
        app.comments.getList({
          'pageIndex': _commentPageIndex,
          'pageSize': _pageSize,
          'latestInTopicsWhereParticipated': true,
          'participatingPartyId': _partyId,
        }),
      );
    }

    final responses = await Future.wait(requests);
    if (!mounted) return;

    var idx = 0;
    var newMsgMaps = <Map<String, dynamic>>[];
    var newCommentMaps = <Map<String, dynamic>>[];

    if (fetchMessages) {
      newMsgMaps = asMapList(responses[idx++]);
      _allMsgMaps.addAll(newMsgMaps);
      _msgPageIndex++;
      _hasMoreMessages = newMsgMaps.length >= _pageSize;
    }
    if (fetchComments) {
      newCommentMaps = asMapList(responses[idx]);
      _allCommentMaps.addAll(newCommentMaps);
      _commentPageIndex++;
      _hasMoreComments = newCommentMaps.length >= _pageSize;
    }

    final rows = _composeRows(
      msgMaps: _allMsgMaps,
      commentMaps: _allCommentMaps,
    );
    setState(() {
      _items = rows;
      _lastLoadedAt = DateTime.now();
    });

    await _resolveSenderDisplayNames(app, rows);
    await _hydrateTitlesIfNeeded(
      app,
      msgMaps: _allMsgMaps,
      commentMaps: _allCommentMaps,
    );
    if (!mounted) return;
    final rows2 = _composeRows(
      msgMaps: _allMsgMaps,
      commentMaps: _allCommentMaps,
    );
    setState(() => _items = rows2);
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
      _partyId = partyId;

      _resetPagingState();
      await _fetchNextPage(app);
      if (!mounted) return;

      setState(() {
        _loading = false;
        _refreshing = false;
      });
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

  Future<void> _loadMore() async {
    if (_loading || _refreshing || _loadingMore || !_canLoadMore) return;
    final app = context.read<AppServices>();
    setState(() => _loadingMore = true);
    try {
      await _fetchNextPage(app);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Daha fazla sohbet yüklenemedi.', error: true);
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _open(_ConversationRow r) async {
    if (r.isRoom) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RoomChatScreen(
            roomId: r.id,
            roomTitle: r.title,
            topicTitle: r.roomTopicTitle,
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
    _scheduleReloadChatsAfterOverlayPop();
  }

  @override
  Widget build(BuildContext context) {
    final rail = MediaQuery.sizeOf(context).width >= 720;

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.darkCharcoal,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Sohbetler',
          style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.darkCharcoal,
              ),
        ),
        automaticallyImplyLeading: !rail,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: (_loading || _refreshing)
                ? null
                : () => _load(fullScreenLoading: _items.isEmpty, force: true),
            icon: Icon(
              Icons.refresh_rounded,
              color: (_loading || _refreshing)
                  ? Colors.grey.shade400
                  : AppColors.purple600,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_loading || _error != null)
            ? null
            : () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const StartChatPickerScreen(),
                  ),
                );
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
        color: AppColors.surfaceLight,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return ColoredBox(
        color: AppColors.surfaceLight,
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
        color: AppColors.surfaceLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Sohbet ara…',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300.withValues(alpha: 0.6),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.purple500, width: 1.5),
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

    return Column(
      children: [
        if (_refreshing)
          const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Sohbet ara…',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300.withValues(alpha: 0.6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.purple500, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: AppColors.surfaceLight,
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
                      controller: _listScroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: visible.length + (_loadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        if (i >= visible.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              ),
                            ),
                          );
                        }
                        return _buildChatRow(context, visible[i]);
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatRow(BuildContext context, _ConversationRow r) {
    final theme = Theme.of(context);
    final pv = r.preview;
    final preview = (pv != null && pv.length > 72) ? '${pv.substring(0, 72)}…' : pv;
    final timeStr = _chatListTimeLabel(r.lastAt);
    final muted = theme.colorScheme.onSurfaceVariant;

    final secondLine = preview != null && preview.isNotEmpty
        ? preview
        : 'Sohbete dokunun';

    final roomTopicTrimmed = r.roomTopicTitle?.trim();
    final showRoomTopic = r.isRoom &&
        roomTopicTrimmed != null &&
        roomTopicTrimmed.isNotEmpty &&
        roomTopicTrimmed != r.title.trim();

    /// [RoomChatScreen] / `_RoomChatHeader` süresi dolmuş gradient ile aynı palet
    const expiredRoomAccent = Color(0xFF5C3D3D);
    const expiredRoomAccentDeep = Color(0xFF4A2C2C);
    final expiredRoom = r.isRoom && r.roomLifecycleExpired;

    final capsStyle = theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.65,
          fontSize: 10,
          color: const Color(0xFF8B8798),
        );

    return Material(
      color: AppColors.surfaceCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.outlineMuted.withValues(alpha: 0.85)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: expiredRoom
                        ? const [expiredRoomAccent, expiredRoomAccentDeep]
                        : r.isRoom
                            ? const [AppColors.purple700, AppColors.purple400]
                            : [
                                AppColors.topicTeal,
                                AppColors.topicTealAccent,
                              ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: expiredRoom
                              ? expiredRoomAccent.withValues(alpha: 0.12)
                              : r.isRoom
                                  ? AppColors.purple50
                                  : AppColors.topicMint,
                          borderRadius: const BorderRadius.all(Radius.circular(14)),
                        ),
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: Icon(
                            r.isRoom ? AppContentIcons.room : AppContentIcons.topic,
                            color: expiredRoom
                                ? expiredRoomAccent
                                : r.isRoom
                                    ? AppColors.purple600
                                    : AppColors.topicTeal,
                            size: 22,
                          ),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.isRoom ? 'ODA' : 'KONU',
                                        style: capsStyle,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              height: 1.25,
                                              color: AppColors.darkCharcoal,
                                            ),
                                        maxLines: r.isRoom ? 2 : 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (showRoomTopic) ...[
                                        const SizedBox(height: 8),
                                        Text('KONU', style: capsStyle),
                                        const SizedBox(height: 3),
                                        Text(
                                          roomTopicTrimmed,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                                color: expiredRoom
                                                    ? expiredRoomAccent
                                                    : AppColors.purple700,
                                                fontWeight: FontWeight.w600,
                                                height: 1.35,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeStr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                        color: muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              secondLine,
                              style: TextStyle(
                                color: expiredRoom
                                    ? expiredRoomAccent
                                    : muted.withValues(alpha: 0.88),
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
