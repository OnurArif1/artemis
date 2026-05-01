import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/location/location_service.dart';
import '../../core/icons/app_content_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/ensure_room_access.dart';
import '../../core/util/map_helpers.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/subscription_display.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import 'room_chat_screen.dart';
import 'topic_chat_screen.dart';

String _pickerRoomPrimaryTitle(Map<String, dynamic> m) {
  final room = entityString(m, ['title', 'Title']);
  if (room != null && room.isNotEmpty) return room;
  final topicOnly = entityString(m, ['topicTitle', 'TopicTitle', 'topicName']);
  if (topicOnly != null && topicOnly.isNotEmpty) return topicOnly;
  return mapTitle(m);
}

String? _pickerRoomTopicLine(Map<String, dynamic> m) {
  final room = entityString(m, ['title', 'Title']);
  final topic = entityString(m, ['topicTitle', 'TopicTitle', 'topicName']);
  if (topic == null || topic.isEmpty) return null;
  if (room != null && room.isNotEmpty && topic != room) return topic;
  return null;
}

class StartChatPickerScreen extends StatefulWidget {
  const StartChatPickerScreen({super.key});

  @override
  State<StartChatPickerScreen> createState() => _StartChatPickerScreenState();
}

class _StartChatPickerScreenState extends State<StartChatPickerScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late final TabController _tabController;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _allRooms = [];
  List<Map<String, dynamic>> _allTopics = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final app = context.read<AppServices>();
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);

    try {
      final loc = LocationService.cached;
      final results = await Future.wait([
        app.rooms.getList({
          'pageIndex': 1,
          'pageSize': 20,
          'startChatPickerMode': true,
          'listMode': 'startChat',
          if (loc != null) ...{
            'userLatitude': loc.lat,
            'userLongitude': loc.lng,
          },
          if (email != null) 'userEmail': email,
        }),
        app.topics.getList({
          'pageIndex': 1,
          'pageSize': 20,
          'sortByUpvoteDesc': true,
        }),
      ]);

      if (!mounted) return;
      final roomMaps = asMapList(results[0]);
      final topicMaps = asMapList(results[1]);
      final activeRooms =
          roomMaps.where((m) => !lifecycleExpiredFromRoomMap(m)).toList();

      setState(() {
        _allRooms = activeRooms;
        _allTopics = topicMaps;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message ?? 'Yüklenemedi';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Yüklenemedi';
      });
    }
  }

  String _q() => _search.text.trim().toLowerCase();

  List<Map<String, dynamic>> _visibleRooms() {
    final q = _q();
    if (q.isEmpty) return _allRooms;
    return _allRooms.where((m) {
      if (_pickerRoomPrimaryTitle(m).toLowerCase().contains(q)) return true;
      final t = _pickerRoomTopicLine(m)?.toLowerCase();
      return t != null && t.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _visibleTopics() {
    final q = _q();
    if (q.isEmpty) return _allTopics;
    return _allTopics.where((m) => mapTitle(m).toLowerCase().contains(q)).toList();
  }

  void _openRoom(Map<String, dynamic> m) {
    final id = entityId(m);
    if (id == null) return;
    final roomTitle = _pickerRoomPrimaryTitle(m);
    final topicTitle = entityString(m, ['topicTitle', 'TopicTitle']);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RoomChatScreen(
          roomId: id,
          roomTitle: roomTitle,
          topicTitle: topicTitle,
        ),
      ),
    );
  }

  /// Aktif odalar için bitiş + kalan süre özeti; bilinmiyorsa `null`.
  String? _lifecycleLineForRoom(BuildContext context, Map<String, dynamic> m) {
    final end = lifecycleEndUtcFromRoomMap(m);
    if (end == null) return null;
    final nowUtc = DateTime.now().toUtc();
    if (!nowUtc.isBefore(end)) return null;
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
    final parts = <String>[];
    if (d > 0) parts.add('${d}g');
    if (h > 0 || d > 0) parts.add('${h}s');
    parts.add('${min}dk');
    final countdown = parts.join(' ');
    return 'Bitiş $dateStr $timeStr · Kalan $countdown';
  }

  void _openTopic(Map<String, dynamic> m) {
    final id = entityId(m);
    if (id == null) return;
    final title = mapTitle(m);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TopicChatScreen(
          topicId: id,
          topicTitle: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Sohbete Katıl',
          style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.darkCharcoal,
              ),
        ),
        bottom: _loading || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppColors.purple600,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppColors.purple600,
                indicatorWeight: 3,
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                tabs: [
                  Tab(text: 'Odalar (${_visibleRooms().length})'),
                  Tab(text: 'Konular (${_visibleTopics().length})'),
                ],
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple500))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Yeniden dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Ara…',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.grey.shade600,
                            ),
                            suffixIcon: _search.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _search.clear();
                                      setState(() {});
                                    },
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.surfaceCard,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color:
                                    Colors.grey.shade300.withValues(alpha: 0.6),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color:
                                    Colors.grey.shade300.withValues(alpha: 0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.purple500,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ColoredBox(
                        color: AppColors.surfaceLight,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildRoomList(theme),
                            _buildTopicList(theme),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRoomList(ThemeData theme) {
    final items = _visibleRooms();
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _q().isNotEmpty
                ? 'Aramanızla eşleşen oda yok.'
                : 'Paketinizle girilebilecek oda bulunmuyor.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final m = items[i];
        final st = parseSubscriptionType(Map<String, dynamic>.from(m));
        final primary = _pickerRoomPrimaryTitle(m);
        final topicLine = _pickerRoomTopicLine(m);
        final lifecycleLine = _lifecycleLineForRoom(context, m);
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
            side: BorderSide(
              color: AppColors.outlineMuted.withValues(alpha: 0.85),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openRoom(m),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.purple700,
                          AppColors.purple400,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.purple50,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(14)),
                            ),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: Icon(
                                AppContentIcons.room,
                                color: AppColors.purple600,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  primary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.25,
                                        color: AppColors.darkCharcoal,
                                      ),
                                ),
                                if (topicLine != null) ...[
                                  const SizedBox(height: 8),
                                  Text('KONU', style: capsStyle),
                                  const SizedBox(height: 3),
                                  Text(
                                    topicLine,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.purple700,
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                        ),
                                  ),
                                ],
                                if (lifecycleLine != null) ...[
                                  const SizedBox(height: 8),
                                  Text('YAŞAM DÖNGÜSÜ', style: capsStyle),
                                  const SizedBox(height: 3),
                                  Text(
                                    lifecycleLine,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                        ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    st != null && st > 0
                                        ? 'Konuşmak için: ${subscriptionTierLabelTr(st)}'
                                        : 'Herkes katılabilir',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                          color: AppColors.purple700,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.shade400,
                              size: 26,
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
      },
    );
  }

  Widget _buildTopicList(ThemeData theme) {
    final items = _visibleTopics();

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _q().isNotEmpty ? 'Aramanızla eşleşen konu yok.' : 'Konu bulunamadı.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final m = items[i];
        final title = mapTitle(m);
        final sub = mapSubtitle(m);
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
            side: BorderSide(
              color: AppColors.outlineMuted.withValues(alpha: 0.85),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openTopic(m),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.topicTeal,
                          AppColors.topicTealAccent,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.topicMint,
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                            ),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: Icon(
                                AppContentIcons.topic,
                                color: AppColors.topicTeal,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('KONU', style: capsStyle),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.25,
                                        color: AppColors.darkCharcoal,
                                      ),
                                ),
                                if (sub != null && sub.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    sub,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                          height: 1.35,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.shade400,
                              size: 26,
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
      },
    );
  }
}
