import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/location/location_service.dart';
import '../../core/icons/app_content_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/map_helpers.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/room_create_policy.dart';
import '../../core/util/subscription_display.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import 'room_chat_screen.dart';
import 'topic_chat_screen.dart';

/// WhatsApp’taki «yeni sohbet» benzeri: pakete uygun odalar + tüm konular; seçimde sohbet ekranı.
class StartChatPickerScreen extends StatefulWidget {
  const StartChatPickerScreen({super.key});

  @override
  State<StartChatPickerScreen> createState() => _StartChatPickerScreenState();
}

class _StartChatPickerScreenState extends State<StartChatPickerScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late final TabController _tabController;

  int? _myTier;
  bool _tierLoading = true;
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
      final tier = await resolveMySubscriptionTypeForRoomCreate(app, token, email);
      if (!mounted) return;

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

      // Üyelik süzmesi sunucuda (StartChatPickerMode); burada tekrar filtrelemek
      // JWT / API tier uyumsuzluğunda listeyi 1 öğeye düşürebiliyordu.
      setState(() {
        _myTier = tier;
        _tierLoading = false;
        _allRooms = roomMaps;
        _allTopics = topicMaps;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _tierLoading = false;
        _error = e.message ?? 'Yüklenemedi';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _tierLoading = false;
        _error = 'Yüklenemedi';
      });
    }
  }

  String _q() => _search.text.trim().toLowerCase();

  List<Map<String, dynamic>> _visibleRooms() {
    final q = _q();
    if (q.isEmpty) return _allRooms;
    return _allRooms.where((m) => mapTitle(m).toLowerCase().contains(q)).toList();
  }

  List<Map<String, dynamic>> _visibleTopics() {
    final q = _q();
    if (q.isEmpty) return _allTopics;
    return _allTopics.where((m) => mapTitle(m).toLowerCase().contains(q)).toList();
  }

  void _openRoom(Map<String, dynamic> m) {
    final id = entityId(m);
    if (id == null) return;
    final title = mapTitle(m);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RoomChatScreen(
          roomId: id,
          roomTitle: title,
        ),
      ),
    );
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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Sohbet başlat'),
        bottom: _loading || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppColors.purple700,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: AppColors.purple600,
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
                    if (_tierLoading)
                      const LinearProgressIndicator(minHeight: 2)
                    else if (_myTier != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                        child: Text(
                          'Üyeliğiniz: ${subscriptionTierLabelTr(_myTier)} — odalar buna göre listelenir.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Ara…',
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
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
      itemBuilder: (context, i) {
        final m = items[i];
        final st = parseSubscriptionType(Map<String, dynamic>.from(m));
        final title = mapTitle(m);
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.purple100,
            foregroundColor: AppColors.purple700,
            child: Icon(AppContentIcons.room),
          ),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            st != null && st > 0
                ? 'Konuşmak için: ${subscriptionTierLabelTr(st)}'
                : 'Herkes katılabilir',
            style: theme.textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openRoom(m),
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
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
      itemBuilder: (context, i) {
        final m = items[i];
        final title = mapTitle(m);
        final sub = mapSubtitle(m);
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFCCFBF1),
            foregroundColor: Color(0xFF0F766E),
            child: Icon(AppContentIcons.topic),
          ),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            sub ?? 'Konu sohbeti',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openTopic(m),
        );
      },
    );
  }
}
