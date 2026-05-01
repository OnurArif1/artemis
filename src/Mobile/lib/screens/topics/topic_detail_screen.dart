import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons/app_content_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/party_resolver.dart';
import '../../core/util/privacy_label.dart';
import '../../providers/home_tab_controller.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import '../chat/topic_chat_screen.dart';
import 'topic_location_map_screen.dart';

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

  static double? _readCoord(Map<String, dynamic> m, String camel, String pascal) {
    final v = m[camel] ?? m[pascal];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    final d = double.tryParse(s);
    if (d != null) return d;
    if (s.contains(',') && !s.contains('.')) {
      return double.tryParse(s.replaceAll(',', '.'));
    }
    return null;
  }

  bool _hasTopicLocation(Map<String, dynamic>? t) {
    if (t == null) return false;
    final lat = _readCoord(t, 'locationY', 'LocationY');
    final lng = _readCoord(t, 'locationX', 'LocationX');
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat == 0 && lng == 0) return false;
    return true;
  }

  void _openTopicLocationOnMap() {
    final t = _topic;
    if (t == null || !_hasTopicLocation(t)) {
      showAppSnackBar(context, 'Bu konu için konum bilgisi yok.', error: true);
      return;
    }
    final lat = _readCoord(t, 'locationY', 'LocationY')!;
    final lng = _readCoord(t, 'locationX', 'LocationX')!;
    final topicTitle =
        entityString(t, ['title', 'Title']) ?? 'Konu #${widget.topicId}';
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TopicLocationMapScreen(
          latitude: lat,
          longitude: lng,
          topicTitle: topicTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _topic != null
        ? (entityString(_topic!, ['title', 'Title']) ?? 'Konu #${widget.topicId}')
        : 'Konu #${widget.topicId}';

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.darkCharcoal,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const Icon(Icons.tag_rounded, color: AppColors.topicTeal, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkCharcoal,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Odaya git',
            onPressed: _roomsForTopic.isEmpty ? null : _goToRoom,
            icon: Icon(
              AppContentIcons.roomOutlined,
              color: _roomsForTopic.isEmpty
                  ? Colors.grey.shade400
                  : AppColors.purple600,
            ),
          ),
          IconButton(
            tooltip: 'Canlı yorum sohbeti',
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
            icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.topicTeal),
          ),
          IconButton(
            tooltip: _topic != null && _hasTopicLocation(_topic!)
                ? 'Konumu haritada göster'
                : 'Konum bilgisi yok',
            onPressed: _topic != null && _hasTopicLocation(_topic!)
                ? _openTopicLocationOnMap
                : null,
            icon: Icon(
              Icons.map_rounded,
              color: _topic != null && _hasTopicLocation(_topic!)
                  ? AppColors.topicTeal
                  : Colors.grey.shade400,
            ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.topicTeal),
      );
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
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.topicTeal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yeniden dene'),
              ),
            ],
          ),
        ),
      );
    }

    final t = _topic ?? {};
    final category =
        entityString(t, ['categoryName', 'CategoryName', 'categoryTitle']);
    final desc = entityString(t, ['description', 'Description']);

    final theme = Theme.of(context);
    final capsMuted = theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.65,
          fontSize: 10,
          color: const Color(0xFF8B8798),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        if (category != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.topicMint.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.topicTeal.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.label_outline_rounded,
                  size: 20,
                  color: AppColors.topicTeal,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category,
                    style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkCharcoal,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (desc != null && desc.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineMuted.withValues(alpha: 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              desc,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text('YORUMLAR', style: capsMuted),
        const SizedBox(height: 6),
        Text(
          '${_comments.length} gönderi',
          style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 14),
        if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Henüz yorum yok.',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          )
        else
          ..._comments.map((c) {
            final commentParty = entityPartyId(c);
            final isMine = _partyId != null &&
                commentParty != null &&
                commentParty == _partyId;
            final rawAuthor = entityString(c, ['partyName', 'PartyName']) ??
                'Katılımcı #${entityId(c) ?? ''}';
            final author =
                maskEmailLikeLabel(rawAuthor, showFull: isMine);
            final date = formatTrDate(c['createDate'] ?? c['CreateDate']);
            final body =
                entityString(c, ['content', 'Content']) ?? '—';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
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
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
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
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppColors.topicMint,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.person_outline_rounded,
                                        size: 18,
                                        color: AppColors.topicTeal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          author,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.darkCharcoal,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          date,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: Colors.grey.shade600,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                body,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.45,
                                      color: AppColors.darkCharcoal,
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
          }),
        const SizedBox(height: 24),
        Text('YORUM YAZ', style: capsMuted),
        const SizedBox(height: 10),
        Material(
          color: AppColors.surfaceCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: AppColors.outlineMuted.withValues(alpha: 0.9),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: TextField(
            controller: _commentCtrl,
            minLines: 3,
            maxLines: 6,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            decoration: InputDecoration(
              hintText: 'Düşüncelerinizi yazın…',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _sending ? null : _sendComment,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.topicTeal,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: _sending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: Text(
            _sending ? 'Gönderiliyor…' : 'Gönder',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

