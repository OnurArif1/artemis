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

int? _entityId(Map<String, dynamic> m) {
  final v = m['id'] ?? m['Id'];
  if (v is int) return v;
  return int.tryParse('$v');
}

String _entityTitle(Map<String, dynamic> m) {
  return '${m['title'] ?? m['Title'] ?? m['topicTitle'] ?? ''}'.trim();
}

/// Bottom sheet’ten abonelik seçimi (`null` = Seçilmedi); kapatma ile karışmaması için sarmalayıcı.
class _SubPick {
  const _SubPick(this.value);
  final int? value;
}

/// Web `CreateRoom.vue` ile aynı API alanları.
class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _title = TextEditingController();
  final _roomRange = TextEditingController();
  final _partySearch = TextEditingController();

  List<Map<String, dynamic>> _topics = [];
  int? _topicId;
  int _roomType = 1;
  int? _subscriptionType;
  double? _locationX;
  double? _locationY;

  bool _loading = false;
  bool _loadingTopics = true;
  bool _showInvite = false;
  int? _createdRoomId;
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
    _roomRange.dispose();
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

    final createdTitle = _title.text.trim();
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
        'subscriptionType': _subscriptionType,
        'roomRange': _roomRange.text.trim().isEmpty
            ? null
            : double.tryParse(_roomRange.text.trim()),
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
        _showInvite = true;
        _title.clear();
        _topicId = null;
        _roomRange.clear();
        _roomType = 1;
        _subscriptionType = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showInvite ? 'Kişi davet et' : 'Oda oluştur'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_loadingTopics)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (!_showInvite) ...[
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Başlık *',
              ).applyDefaults(Theme.of(context).inputDecorationTheme),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (_loadingTopics || _topics.isEmpty)
                    ? null
                    : () => _pickTopic(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Konu *',
                    suffixIcon: Icon(
                      _loadingTopics
                          ? Icons.hourglass_empty_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                  child: Text(
                    _topics.isEmpty && !_loadingTopics
                        ? 'Konu listesi boş'
                        : _topicLabelForId(_topicId),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _topicId == null && _topics.isNotEmpty
                          ? Theme.of(context).hintColor
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Konum: ${_locationY?.toStringAsFixed(4) ?? "—"}, ${_locationX?.toStringAsFixed(4) ?? "—"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: _useGpsNow,
                  icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                  label: const Text('GPS'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Herkese açık')),
                ButtonSegment(value: 2, label: Text('Özel')),
              ],
              selected: {_roomType},
              onSelectionChanged: (s) =>
                  setState(() => _roomType = s.first),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _pickSubscription(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Abonelik tipi',
                    suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                  child: Text(
                    _subscriptionLabel(_subscriptionType),
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomRange,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Oda menzili (km)',
              ).applyDefaults(Theme.of(context).inputDecorationTheme),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submitCreate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple600,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Oluştur'),
            ),
          ] else ...[
            Text(
              'İsteğe bağlı olarak kişi arayıp odaya ekleyin.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _partySearch,
              decoration: const InputDecoration(
                labelText: 'Kişi ara (en az 2 harf)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search_rounded),
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
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Seçilenleri odaya ekle'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bitir'),
            ),
          ],
        ],
      ),
    );
  }
}
