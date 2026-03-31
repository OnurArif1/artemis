import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/location/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/paged_result.dart';
import '../../services/app_services.dart';
import '../../widgets/artemis_snackbar.dart';

int? _entityId(Map<String, dynamic> m) {
  final v = m['id'] ?? m['Id'];
  if (v is int) return v;
  return int.tryParse('$v');
}

String _entityTitle(Map<String, dynamic> m) {
  return '${m['title'] ?? m['Title'] ?? m['topicTitle'] ?? ''}'.trim();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTopics();
      _fillLocation();
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
      showAppSnackBar(
        context,
        e.response?.data?.toString() ?? e.message ?? 'Oluşturulamadı',
        error: true,
      );
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: _topicId,
              decoration: const InputDecoration(
                labelText: 'Konu *',
                border: OutlineInputBorder(),
              ),
              items: _topics
                  .map((t) {
                    final id = _entityId(t);
                    if (id == null) return null;
                    return DropdownMenuItem(
                      value: id,
                      child: Text(
                        _entityTitle(t).isEmpty ? '#$id' : _entityTitle(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  })
                  .whereType<DropdownMenuItem<int>>()
                  .toList(),
              onChanged: (v) => setState(() => _topicId = v),
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
            DropdownButtonFormField<int?>(
              // ignore: deprecated_member_use
              value: _subscriptionType,
              decoration: const InputDecoration(
                labelText: 'Abonelik tipi',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Seçilmedi')),
                DropdownMenuItem(value: 0, child: Text('Yok')),
                DropdownMenuItem(value: 1, child: Text('Silver')),
                DropdownMenuItem(value: 2, child: Text('Gold')),
                DropdownMenuItem(value: 3, child: Text('Platinum')),
              ],
              onChanged: (v) => setState(() => _subscriptionType = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomRange,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Oda menzili (km)',
                border: OutlineInputBorder(),
              ),
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
