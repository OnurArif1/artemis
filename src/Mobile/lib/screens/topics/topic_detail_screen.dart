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
import '../../widgets/artemis_snackbar.dart';
import '../chat/topic_chat_screen.dart';

/// Web `TopicList.vue` kart + yorum diyaloğu + `goToRoom` akışı.
class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final int topicId;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  Map<String, dynamic>? _topic;
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _roomsForTopic = [];
  bool _loading = true;
  String? _error;
  final _commentCtrl = TextEditingController();
  bool _sending = false;
  int? _partyId;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

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
    final app = context.read<AppServices>();
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);
    try {
      final topicRaw = await app.topics.getById(widget.topicId);
      Map<String, dynamic>? topicMap;
      if (topicRaw is Map) {
        topicMap = Map<String, dynamic>.from(topicRaw);
      }

      final results = await Future.wait([
        app.comments.getList({
          'pageIndex': 1,
          'pageSize': 100,
          'topicId': widget.topicId,
        }),
        app.rooms.getList({
          'pageIndex': 1,
          'pageSize': 50,
          'topicId': widget.topicId,
        }),
      ]);

      final partyId = await resolveCurrentPartyId(app, email);

      if (!mounted) return;
      setState(() {
        _topic = topicMap;
        _comments = asMapList(results[0]);
        _roomsForTopic = asMapList(results[1]);
        _partyId = partyId;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message ?? 'Yüklenemedi';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Yüklenemedi';
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) {
      showAppSnackBar(context, 'Yorum metni yazın.', error: true);
      return;
    }
    var pid = _partyId;
    final app = context.read<AppServices>();
    if (pid == null) {
      final token = context.read<AuthService>().token;
      pid = await resolveCurrentPartyId(app, emailFromAccessToken(token));
      if (!mounted) return;
      setState(() => _partyId = pid);
    }
    if (pid == null) {
      showAppSnackBar(context, 'Kullanıcı (party) bilgisi bulunamadı.', error: true);
      return;
    }

    setState(() => _sending = true);
    try {
      final result = await app.comments.create({
        'topicId': widget.topicId,
        'partyId': pid,
        'content': text,
        'upvote': 0,
        'downvote': 0,
        'lastUpdateDate': DateTime.now().toUtc().toIso8601String(),
      });
      if (!mounted) return;
      final failed = result is Map &&
          (result['isSuccess'] == false || result['IsSuccess'] == false);
      if (failed) {
        showAppSnackBar(
          context,
          '${result['exceptionMessage'] ?? result['ExceptionMessage'] ?? 'Gönderilemedi'}',
          error: true,
        );
      } else {
        _commentCtrl.clear();
        showAppSnackBar(context, 'Yorum eklendi.');
        await _load();
      }
    } on DioException catch (e) {
      if (mounted) {
        showAppSnackBar(context, e.message ?? 'Hata', error: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _goToRoom() {
    if (_roomsForTopic.isEmpty) {
      showAppSnackBar(context, 'Bu konuya bağlı oda bulunamadı.');
      return;
    }
    final room = _roomsForTopic.first;
    final rid = entityId(room);
    if (rid == null) return;
    context.read<HomeTabController>().openRoomsTabWithRoom(rid);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = _topic != null
        ? (entityString(_topic!, ['title', 'Title']) ?? 'Konu #${widget.topicId}')
        : 'Konu #${widget.topicId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Canlı yorumlar (SignalR)',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => TopicChatScreen(
                    topicId: widget.topicId,
                    topicTitle: title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_rounded),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _topic == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Yeniden dene')),
            ],
          ),
        ),
      );
    }

    final t = _topic ?? {};
    final title =
        entityString(t, ['title', 'Title']) ?? 'Konu #${widget.topicId}';
    final category =
        entityString(t, ['categoryName', 'CategoryName', 'categoryTitle']);
    final created = formatTrDate(t['createDate'] ?? t['CreateDate']);
    final desc = entityString(t, ['description', 'Description']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        if (category != null) ...[
          Row(
            children: [
              Icon(Icons.label_outline_rounded,
                  size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(created, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        if (desc != null && desc.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(desc, style: Theme.of(context).textTheme.bodyLarge),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _roomsForTopic.isEmpty ? null : _goToRoom,
                icon: const Icon(Icons.meeting_room_outlined),
                label: const Text('Odaya git'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => TopicChatScreen(
                  topicId: widget.topicId,
                  topicTitle: title,
                ),
              ),
            );
          },
          icon: const Icon(Icons.forum_rounded),
          label: const Text('Canlı yorum sohbeti'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purple600,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Yorumlar (${_comments.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        if (_comments.isEmpty)
          Text(
            'Henüz yorum yok.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
          )
        else
          ..._comments.map((c) {
            final author = entityString(c, ['partyName', 'PartyName']) ??
                'Katılımcı #${entityId(c) ?? ''}';
            final date = formatTrDate(c['createDate'] ?? c['CreateDate']);
            final body =
                entityString(c, ['content', 'Content']) ?? '—';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            author,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          date,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(body),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 20),
        Text(
          'Yorum yaz',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentCtrl,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Düşüncelerinizi yazın…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _sending ? null : _sendComment,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purple600,
            minimumSize: const Size.fromHeight(48),
          ),
          icon: _sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_sending ? 'Gönderiliyor…' : 'Gönder'),
        ),
      ],
    );
  }
}
