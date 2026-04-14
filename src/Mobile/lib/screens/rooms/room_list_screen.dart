import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/location/location_service.dart';
import '../../core/icons/app_content_icons.dart';
import '../../core/theme/app_colors.dart';
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
      setState(() {
        _items = asMapList(data);
        _total = extractCount(data);
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Odalar${_total > 0 ? ' ($_total)' : ''}'),
        automaticallyImplyLeading: !rail,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _searchDebounce?.cancel();
                _load();
              },
              decoration: InputDecoration(
                hintText: 'Oda ara…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchDebounce?.cancel();
                          _search.clear();
                          _load();
                        },
                        icon: const Icon(Icons.clear_rounded),
                      )
                    : null,
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final m = _items[i];
          final title = mapTitle(m);
          final sub = mapSubtitle(m);
          final subType = parseSubscriptionType(Map<String, dynamic>.from(m));
          return Card(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => RoomDetailScreen(room: Map<String, dynamic>.from(m)),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.purple100,
                      foregroundColor: AppColors.purple700,
                      child: Icon(AppContentIcons.room),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (subType != null) ...[
                            SubscriptionTierBadge(subscriptionType: subType, compact: true),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (sub != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              sub,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                            ),
                          ],
                          if (subType != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Konuşmak için: ${subscriptionTierLabelTr(subType)}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.purple700,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
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
