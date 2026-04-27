import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/map_helpers.dart';
import '../../core/util/paged_result.dart';
import '../../services/app_services.dart';
import '../../widgets/artemis_snackbar.dart';
import '../../widgets/fade_in_list_item.dart';
import '../chat/topic_chat_screen.dart';

class CategoryTopicsScreen extends StatefulWidget {
  const CategoryTopicsScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  final int categoryId;
  final String categoryTitle;

  @override
  State<CategoryTopicsScreen> createState() => _CategoryTopicsScreenState();
}

class _CategoryTopicsScreenState extends State<CategoryTopicsScreen> {
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<AppServices>().topics.getList({
        'pageIndex': 1,
        'pageSize': 200,
        'categoryId': widget.categoryId,
        'sortByUpvoteDesc': true,
      });
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(asMapList(data));
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message ?? 'Konular yüklenemedi';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Konular yüklenemedi';
      });
    }
  }

  void _openTopicChat(Map<String, dynamic> topic) {
    final tid = entityId(topic);
    if (tid == null) {
      showAppSnackBar(context, 'Konu kimliği bulunamadı.', error: true);
      return;
    }
    final title = mapTitle(topic);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TopicChatScreen(
          topicId: tid,
          topicTitle: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.categoryTitle} konuları',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(context),
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
          'Bu kategoride henüz konu yok.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.purple500,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final m = _items[i];
          final title = mapTitle(m);
          final sub = mapSubtitle(m);
          final tid = entityId(m);
          return FadeInListItem(
            key: ValueKey('cat-topic-${tid ?? i}'),
            index: i,
            child: Card(
              elevation: 0,
              surfaceTintColor: AppColors.purple50,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.purple50,
                  foregroundColor: AppColors.purple600,
                  child: Icon(Icons.tag_rounded),
                ),
                title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: sub != null
                    ? Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis)
                    : null,
                trailing: const Icon(Icons.chat_bubble_outline_rounded),
                onTap: () => _openTopicChat(m),
              ),
            ),
          );
        },
      ),
    );
  }
}
