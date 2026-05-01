import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/location/location_service.dart';
import '../../core/icons/app_content_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/ensure_room_access.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/map_helpers.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/room_create_policy.dart';
import '../../core/util/subscription_display.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/subscription_tier_badge.dart';
import 'create_room_screen.dart';
import 'room_detail_screen.dart';

String _roomListPrimaryTitle(Map<String, dynamic> m) {
  final room = entityString(m, ['title', 'Title']);
  if (room != null && room.isNotEmpty) return room;
  final topicOnly = entityString(m, ['topicTitle', 'TopicTitle', 'topicName']);
  if (topicOnly != null && topicOnly.isNotEmpty) return topicOnly;
  return mapTitle(m);
}

/// Oda adı doluysa ve konudan farklıysa gösterilir.
String? _roomListTopicLine(Map<String, dynamic> m) {
  final room = entityString(m, ['title', 'Title']);
  final topic = entityString(m, ['topicTitle', 'TopicTitle', 'topicName']);
  if (topic == null || topic.isEmpty) return null;
  if (room != null && room.isNotEmpty && topic != room) return topic;
  return null;
}

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _search = TextEditingController();
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  final int _pageSize = 50;
  int _total = 0;

  int? _mySubscriptionType;
  bool _tierLoading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadMySubscriptionTier();
    });
  }

  void _onSearchChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadMySubscriptionTier() async {
    final app = context.read<AppServices>();
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);
    final t = await resolveMySubscriptionTypeForRoomCreate(app, token, email);
    if (!mounted) return;
    setState(() {
      _mySubscriptionType = t;
      _tierLoading = false;
    });
  }

  Future<void> _onCreateRoomPressed() async {
    if (_tierLoading) return;
    if (!canCreateRoom(_mySubscriptionType)) {
      await showRoomCreateNotAllowedDialog(context);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CreateRoomScreen(),
      ),
    );
    if (context.mounted) await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = context.read<AppServices>().rooms;
      final token = context.read<AuthService>().token;
      final email = emailFromAccessToken(token);
      final loc = LocationService.cached;
      final data = await svc.getList({
        'pageIndex': 1,
        'pageSize': _pageSize,
        if (_search.text.trim().isNotEmpty) 'title': _search.text.trim(),
        if (loc != null) ...{
          'userLatitude': loc.lat,
          'userLongitude': loc.lng,
        },
        if (email != null) 'userEmail': email,
      });
      if (!mounted) return;
      final rows = asMapList(data)
          .where((r) => !lifecycleExpiredFromRoomMap(r))
          .toList();
      setState(() {
        _items = rows;
        _total = rows.length;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message ?? 'Odalar yüklenemedi';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Odalar yüklenemedi';
      });
    }
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
          'Odalar${_total > 0 ? ' ($_total)' : ''}',
          style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.darkCharcoal,
              ),
        ),
        automaticallyImplyLeading: !rail,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _load,
            icon: Icon(
              Icons.refresh_rounded,
              color: _loading ? Colors.grey.shade400 : AppColors.purple600,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _searchDebounce?.cancel();
                _load();
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceCard,
                hintText: 'Oda ara…',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchDebounce?.cancel();
                          _search.clear();
                          _load();
                        },
                        icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300.withValues(alpha: 0.6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.purple500, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
      floatingActionButton: _tierLoading
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey.shade400,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            )
          : FloatingActionButton(
              onPressed: _onCreateRoomPressed,
              backgroundColor: canCreateRoom(_mySubscriptionType)
                  ? AppColors.purple600
                  : Colors.grey.shade500,
              child: const Icon(Icons.add_rounded),
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Web’de harita görünümü kullanılır; mobilde liste önizlemesi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Yeniden dene')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          _search.text.trim().isNotEmpty
              ? 'Henüz oda yok veya aramanızla eşleşmedi.'
              : 'Henüz oda yok.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.purple500,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final m = _items[i];
          final primary = _roomListPrimaryTitle(m);
          final topicLine = _roomListTopicLine(m);
          final sub = mapSubtitle(m);
          final subType = parseSubscriptionType(Map<String, dynamic>.from(m));
          final theme = Theme.of(context);

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
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        RoomDetailScreen(room: Map<String, dynamic>.from(m)),
                  ),
                );
              },
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
                                borderRadius: BorderRadius.all(Radius.circular(14)),
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
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              primary,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                height: 1.25,
                                                color: AppColors.darkCharcoal,
                                              ),
                                            ),
                                            if (topicLine != null) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'KONU',
                                                style: theme.textTheme.labelSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.65,
                                                  fontSize: 10,
                                                  color: const Color(0xFF8B8798),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                topicLine,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: AppColors.purple700,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (subType != null) ...[
                                        const SizedBox(width: 8),
                                        SubscriptionTierBadge(
                                          subscriptionType: subType,
                                          compact: true,
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (sub != null) ...[
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
      ),
    );
  }
}
