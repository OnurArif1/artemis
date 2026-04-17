import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/map_helpers.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/room_create_policy.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/fade_in_list_item.dart';
import 'create_topic_screen.dart';
import 'topic_detail_screen.dart';

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  final _search = TextEditingController();
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  final int _pageSize = 20;

  int? _mySubscriptionType;
  bool _tierLoading = true;
  late final AuthProvider _authProvider;
  int _seenSubscriptionVersion = -1;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _authProvider.addListener(_onSubscriptionChanged);
    _search.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadMySubscriptionTier();
    });
  }

  void _onSubscriptionChanged() {
    final v = _authProvider.subscriptionVersion;
    if (v == _seenSubscriptionVersion) return;
    _seenSubscriptionVersion = v;
    if (!mounted) return;
    setState(() {
      _mySubscriptionType = _authProvider.subscriptionType;
      _tierLoading = false;
    });
  }

  Future<void> _loadMySubscriptionTier() async {
    final app = context.read<AppServices>();
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);
    final t = await resolveMySubscriptionTypeForRoomCreate(app, token, email);
    if (!mounted) return;
    _authProvider.setSubscriptionType(t, notify: false);
    setState(() {
      _mySubscriptionType = t;
      _tierLoading = false;
    });
  }

  Future<void> _onCreateTopicPressed() async {
    if (_tierLoading) return;
    if (!canCreateTopic(_mySubscriptionType)) {
      await showTopicCreateNotAllowedDialog(context);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CreateTopicScreen(),
      ),
    );
    if (context.mounted) await _load();
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
    _authProvider.removeListener(_onSubscriptionChanged);
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = context.read<AppServices>().topics;
      final data = await svc.getList({
        'pageIndex': 1,
        'pageSize': _pageSize,
        'sortByUpvoteDesc': true,
        if (_search.text.trim().isNotEmpty) 'title': _search.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _items = asMapList(data);
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message ?? 'Liste yüklenemedi';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Liste yüklenemedi';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rail = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Konular${_items.isNotEmpty ? ' (${_items.length})' : ''}',
        ),
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
                hintText: 'Konu ara…',
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
              onPressed: _onCreateTopicPressed,
              backgroundColor: canCreateTopic(_mySubscriptionType)
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
              Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
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
          'Henüz konu yok veya aramanızla eşleşmedi.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.purple500,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final m = _items[i];
          final title = mapTitle(m);
          final sub = mapSubtitle(m);
          final tid = entityId(m);
          return FadeInListItem(
            key: ValueKey('topic-${tid ?? i}'),
            index: i,
            child: Card(
              elevation: 0,
              surfaceTintColor: AppColors.purple50,
              child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: tid == null
                  ? null
                  : () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => TopicDetailScreen(topicId: tid),
                        ),
                      ).then((_) => _load());
                    },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.purple50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tag_rounded, color: AppColors.purple600, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        sub,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}
