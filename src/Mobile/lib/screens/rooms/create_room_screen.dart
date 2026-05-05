import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/location/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/room_create_policy.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import '../chat/room_chat_screen.dart';

int? _entityId(Map<String, dynamic> m) {
  final v = m['id'] ?? m['Id'];
  if (v is int) return v;
  return int.tryParse('$v');
}

String _entityTitle(Map<String, dynamic> m) {
  return '${m['title'] ?? m['Title'] ?? m['topicTitle'] ?? ''}'.trim();
}

class _SubPick {
  const _SubPick(this.value);
  final int? value;
}

enum _LifeCyclePreset {
  hourly,
  daily,
  weekly;

  String get labelTr => switch (this) {
        hourly => 'Saatlik',
        daily => 'Günlük',
        weekly => 'Haftalık',
      };

  Duration get duration => switch (this) {
        hourly => const Duration(hours: 1),
        daily => const Duration(days: 1),
        weekly => const Duration(days: 7),
      };
}

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _title = TextEditingController();
  final _partySearch = TextEditingController();

  List<Map<String, dynamic>> _topics = [];
  int? _topicId;
  int _roomType = 1;
  int? _subscriptionType;
  double? _locationX;
  double? _locationY;
  _LifeCyclePreset? _lifeCyclePreset;
  double _roomRangeKm = 10;

  bool _loading = false;
  bool _loadingTopics = true;
  bool _showInvite = false;
  int? _createdRoomId;
  String? _createdRoomTitle;
  String? _createdTopicTitle;
  final List<Map<String, dynamic>> _selectedParties = [];
  List<Map<String, dynamic>> _partyResults = [];
  bool _loadingParties = false;
  Timer? _partyDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = context.read<AppServices>();
      final token = context.read<AuthService>().token;
      final email = emailFromAccessToken(token);
      final t = await resolveMySubscriptionTypeForRoomCreate(app, token, email);
      if (!mounted) return;
      if (!canCreateRoom(t)) {
        await showRoomCreateNotAllowedDialog(context);
        if (mounted) Navigator.of(context).pop();
        return;
      }
      await _loadTopics();
      await _fillLocation();
    });
  }

  @override
  void dispose() {
    _partyDebounce?.cancel();
    _title.dispose();
    _partySearch.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    setState(() => _loadingTopics = true);
    try {
      final data = await context.read<AppServices>().topics.getList({
        'pageIndex': 1,
        'pageSize': 1000,
      });
      if (!mounted) return;
      setState(() {
        _topics = asMapList(data);
        _loadingTopics = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingTopics = false);
    }
  }

  Future<void> _fillLocation() async {
    final c = LocationService.cached ?? await LocationService.tryCurrentPosition();
    if (c == null || !mounted) return;
    setState(() {
      _locationX = double.parse(c.lng.toStringAsFixed(6));
      _locationY = double.parse(c.lat.toStringAsFixed(6));
    });
  }

  Future<void> _useGpsNow() async {
    final c = await LocationService.tryCurrentPosition();
    if (c == null) {
      if (mounted) {
        showAppSnackBar(context, 'Konum alınamadı.', error: true);
      }
      return;
    }
    setState(() {
      _locationX = double.parse(c.lng.toStringAsFixed(6));
      _locationY = double.parse(c.lat.toStringAsFixed(6));
    });
  }

  Future<void> _submitCreate() async {
    if (_title.text.trim().isEmpty) {
      showAppSnackBar(context, 'Oda başlığı gerekli.', error: true);
      return;
    }
    if (_topicId == null) {
      showAppSnackBar(context, 'Konu seçin.', error: true);
      return;
    }
    final resolved = _resolveLifeCycleFromPreset();
    if (resolved == null) {
      showAppSnackBar(context, 'Yaşam döngüsü süresini seçin.', error: true);
      return;
    }
    final lifeCycle = resolved.minutes;

    final createdTitle = _title.text.trim();
    final topicSnap = _snapshotTopicTitleForChat(_topicId);
    final app = context.read<AppServices>();
    final email = emailFromAccessToken(context.read<AuthService>().token);
    setState(() => _loading = true);
    try {
      await app.rooms.create({
        'title': createdTitle,
        'topicId': _topicId,
        'locationX': _locationX ?? 0,
        'locationY': _locationY ?? 0,
        'roomType': _roomType,
        'lifeCycle': lifeCycle,
        'subscriptionType': _subscriptionType,
        'roomRange': _roomRangeKm,
        if (email != null && email.isNotEmpty) 'userEmail': email,
      });

      final list = await app.rooms.getList({
        'pageIndex': 1,
        'pageSize': 1000,
      });
      final rooms = asMapList(list);
      int? newId;
      for (final r in rooms) {
        if ('${r['title'] ?? r['Title']}' == createdTitle) {
          newId = _entityId(r);
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _createdRoomId = newId;
        _createdRoomTitle = createdTitle;
        _createdTopicTitle = topicSnap;
        _showInvite = true;
        _title.clear();
        _topicId = null;
        _roomRangeKm = 10;
        _roomType = 1;
        _subscriptionType = null;
        _lifeCyclePreset = null;
      });
      showAppSnackBar(context, 'Oda oluşturuldu.');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      var msg = e.message ?? 'Oluşturulamadı';
      final d = e.response?.data;
      if (d is Map && d['message'] != null) {
        msg = '${d['message']}';
      }
      showAppSnackBar(context, msg, error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, 'Oluşturulamadı', error: true);
    }
  }

  /// Seçilen preset için bitiş anı ve `lifeCycle` (dakika, backend ile uyumlu).
  ({double minutes, DateTime endsAtUtc})? _resolveLifeCycleFromPreset() {
    final preset = _lifeCyclePreset;
    if (preset == null) return null;
    final nowUtc = DateTime.now().toUtc();
    final dur = preset.duration;
    final endsAtUtc = nowUtc.add(dur);
    final minutes = dur.inSeconds / 60.0;
    if (minutes <= 0) return null;
    return (minutes: minutes, endsAtUtc: endsAtUtc);
  }

  String _lifeCycleSummary(BuildContext context) {
    final preset = _lifeCyclePreset;
    if (preset == null) return 'Süre seçin';
    final loc = MaterialLocalizations.of(context);
    final r = _resolveLifeCycleFromPreset();
    if (r == null) return preset.labelTr;
    final endLocal = r.endsAtUtc.toLocal();
    final d = loc.formatCompactDate(endLocal);
    final t = loc.formatTimeOfDay(
      TimeOfDay.fromDateTime(endLocal),
      alwaysUse24HourFormat: true,
    );
    return '${preset.labelTr} · bitiş yaklaşık $d $t';
  }

  void _onPartySearchChanged(String q) {
    _partyDebounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _partyResults = []);
      return;
    }
    _partyDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchParties(q.trim());
    });
  }

  Future<void> _searchParties(String text) async {
    final app = context.read<AppServices>();
    setState(() => _loadingParties = true);
    try {
      final data = await app.parties.getLookup({
        'SearchText': text,
        'PartyLookupSearchType': 1,
      });
      if (!mounted) return;
      final vm = data is Map ? (data['ViewModels'] ?? data['viewModels']) : null;
      final out = <Map<String, dynamic>>[];
      if (vm is List) {
        for (final e in vm) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final id = m['PartyId'] ?? m['partyId'] ?? m['id'] ?? m['Id'];
          final name = m['PartyName'] ?? m['partyName'] ?? '';
          final pid = id is int ? id : int.tryParse('$id');
          if (pid != null && '$name'.isNotEmpty) {
            out.add({'id': pid, 'partyName': '$name'});
          }
        }
      }
      setState(() {
        _partyResults = out;
        _loadingParties = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _partyResults = [];
          _loadingParties = false;
        });
      }
    }
  }

  /// Sohbet başlığında gösterilecek konu adı; listeden çözümlenemezse null.
  String? _snapshotTopicTitleForChat(int? topicId) {
    if (topicId == null) return null;
    for (final t in _topics) {
      if (_entityId(t) == topicId) {
        final title = _entityTitle(t).trim();
        return title.isEmpty ? null : title;
      }
    }
    return null;
  }

  String _topicLabelForId(int? id) {
    if (id == null) return 'Konu seçin';
    for (final t in _topics) {
      if (_entityId(t) == id) {
        final title = _entityTitle(t);
        return title.isEmpty ? '#$id' : title;
      }
    }
    return '#$id';
  }

  String _subscriptionLabel(int? v) {
    return switch (v) {
      null => 'Seçilmedi',
      0 => 'Yok',
      1 => 'Silver',
      2 => 'Gold',
      3 => 'Platinum',
      _ => 'Seçilmedi',
    };
  }

  Future<void> _pickTopic(BuildContext context) async {
    if (_loadingTopics || _topics.isEmpty) return;
    final theme = Theme.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SizedBox(
            height: (h * 0.52).clamp(260.0, 420.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    'Konu seçin',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    itemCount: _topics.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (c, i) {
                      final t = _topics[i];
                      final id = _entityId(t);
                      if (id == null) return const SizedBox.shrink();
                      final title = _entityTitle(t).isEmpty ? '#$id' : _entityTitle(t);
                      final selected = id == _topicId;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        selected: selected,
                        selectedTileColor: AppColors.purple50,
                        title: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: selected
                            ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                            : null,
                        onTap: () => Navigator.pop(c, id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && mounted) setState(() => _topicId = picked);
  }

  Future<void> _pickSubscription(BuildContext context) async {
    final theme = Theme.of(context);
    const options = <({int? value, String label})>[
      (value: null, label: 'Seçilmedi'),
      (value: 0, label: 'Yok'),
      (value: 1, label: 'Silver'),
      (value: 2, label: 'Gold'),
      (value: 3, label: 'Platinum'),
    ];
    final result = await showModalBottomSheet<_SubPick?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom + 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'Abonelik tipi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...options.map((o) {
                final sel = _subscriptionType == o.value;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  selected: sel,
                  selectedTileColor: AppColors.purple50,
                  title: Text(o.label),
                  trailing: sel
                      ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, _SubPick(o.value)),
                );
              }),
            ],
          ),
        );
      },
    );
    if (result != null && mounted) {
      setState(() => _subscriptionType = result.value);
    }
  }

  Future<void> _addPartiesToRoom() async {
    if (_createdRoomId == null) {
      showAppSnackBar(context, 'Oda kimliği yok.', error: true);
      return;
    }
    if (_selectedParties.isEmpty) {
      showAppSnackBar(context, 'Kişi seçin.', error: true);
      return;
    }
    final app = context.read<AppServices>();
    setState(() => _loading = true);
    try {
      final ids = _selectedParties.map((p) => p['id'] as int).toList();
      await app.rooms.addPartiesToRoom(
            _createdRoomId!,
            ids,
          );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _selectedParties.clear();
        _partySearch.clear();
        _partyResults = [];
      });
      showAppSnackBar(context, 'Davetler gönderildi.');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(
        context,
        e.message ?? 'Davet başarısız',
        error: true,
      );
    }
  }

  Widget _stepChip(String step, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineMuted.withValues(alpha: 0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.purple100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.purple700,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineMuted.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.purple600),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    InputDecoration fieldDecoration({
      required String label,
      String? hint,
      Widget? suffixIcon,
      Widget? prefixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300.withValues(alpha: 0.5)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.purple500, width: 1.6),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.darkCharcoal,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _showInvite ? 'Kişi davet et' : 'Oda oluştur',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.darkCharcoal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (_loadingTopics)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (!_showInvite) ...[
            Row(
              children: [
                _stepChip('1', 'Temel bilgiler'),
                const SizedBox(width: 8),
                _stepChip('2', 'Ayarlar'),
                const SizedBox(width: 8),
                _stepChip('3', 'Onay'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.purple50, AppColors.surfaceCard],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.purple200.withValues(alpha: 0.55)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.purple600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Önce oda bilgilerini girin, sonra yaşam döngüsü ve menzili belirleyin.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.purple700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Temel bilgiler',
              icon: Icons.info_outline_rounded,
              children: [
                TextField(
                  controller: _title,
                  decoration: fieldDecoration(
                    label: 'Başlık *',
                    hint: 'Oda başlığını yazın',
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (_loadingTopics || _topics.isEmpty)
                        ? null
                        : () => _pickTopic(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: fieldDecoration(
                        label: 'Konu *',
                        suffixIcon: Icon(
                          _loadingTopics
                              ? Icons.hourglass_empty_rounded
                              : Icons.keyboard_arrow_down_rounded,
                        ),
                      ),
                      child: Text(
                        _topics.isEmpty && !_loadingTopics
                            ? 'Konu listesi boş'
                            : _topicLabelForId(_topicId),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _topicId == null && _topics.isNotEmpty
                              ? theme.hintColor
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineMuted.withValues(alpha: 0.9)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Konum: ${_locationY?.toStringAsFixed(4) ?? "—"}, ${_locationX?.toStringAsFixed(4) ?? "—"}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _useGpsNow,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.purple600,
                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                        label: const Text('GPS'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Oda ayarları',
              icon: Icons.tune_rounded,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Herkese açık')),
                    ButtonSegment(value: 2, label: Text('Özel')),
                  ],
                  selected: {_roomType},
                  onSelectionChanged: (s) => setState(() => _roomType = s.first),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _pickSubscription(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: fieldDecoration(
                        label: 'Abonelik tipi',
                        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      child: Text(
                        _subscriptionLabel(_subscriptionType),
                        style: theme.textTheme.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Yaşam döngüsü ve menzil',
              icon: Icons.timer_outlined,
              children: [
                Text(
                  'Yaşam döngüsü *',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<_LifeCyclePreset>(
                  segments: [
                    ButtonSegment(
                      value: _LifeCyclePreset.hourly,
                      label: Text(_LifeCyclePreset.hourly.labelTr),
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: _LifeCyclePreset.daily,
                      label: Text(_LifeCyclePreset.daily.labelTr),
                      icon: const Icon(Icons.today_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: _LifeCyclePreset.weekly,
                      label: Text(_LifeCyclePreset.weekly.labelTr),
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                    ),
                  ],
                  emptySelectionAllowed: true,
                  selected: _lifeCyclePreset == null
                      ? const <_LifeCyclePreset>{}
                      : {_lifeCyclePreset!},
                  onSelectionChanged: (s) => setState(() {
                    _lifeCyclePreset = s.isEmpty ? null : s.first;
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _lifeCycleSummary(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _lifeCyclePreset == null
                        ? theme.hintColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: fieldDecoration(label: 'Oda menzili (km)'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Slider(
                        min: 1,
                        max: 100,
                        divisions: 99,
                        value: _roomRangeKm,
                        label: '${_roomRangeKm.round()} km',
                        onChanged: (v) => setState(() => _roomRangeKm = v),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_roomRangeKm.round()} km',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submitCreate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple600,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Odayı oluştur'),
            ),
          ] else ...[
            Text(
              'İsteğe bağlı olarak kişi arayıp odaya ekleyin.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _partySearch,
              decoration: fieldDecoration(
                label: 'Kişi ara (en az 2 harf)',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: _onPartySearchChanged,
            ),
            if (_loadingParties)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_partyResults.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _partyResults.length,
                  itemBuilder: (ctx, i) {
                    final p = _partyResults[i];
                    final id = p['id'] as int;
                    return ListTile(
                      title: Text('${p['partyName']}'),
                      onTap: () {
                        if (_selectedParties.any((x) => x['id'] == id)) {
                          return;
                        }
                        setState(() {
                          _selectedParties.add(p);
                          _partySearch.clear();
                          _partyResults = [];
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedParties
                  .map(
                    (p) => Chip(
                      label: Text('${p['partyName']}'),
                      onDeleted: () => setState(() {
                        _selectedParties.remove(p);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _addPartiesToRoom,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple600,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Seçilenleri odaya ekle'),
            ),
            TextButton(
              onPressed: () {
                final id = _createdRoomId;
                if (id == null) {
                  Navigator.of(context).pop();
                  return;
                }
                final roomTitle =
                    (_createdRoomTitle != null && _createdRoomTitle!.trim().isNotEmpty)
                        ? _createdRoomTitle!.trim()
                        : 'Oda #$id';
                Navigator.of(context).pushReplacement<void, void>(
                  MaterialPageRoute<void>(
                    builder: (_) => RoomChatScreen(
                      roomId: id,
                      roomTitle: roomTitle,
                      topicTitle: _createdTopicTitle,
                    ),
                  ),
                );
              },
              child: const Text('Bitir'),
            ),
          ],
        ],
      ),
    );
  }
}
