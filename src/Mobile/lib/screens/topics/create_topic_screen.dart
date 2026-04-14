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

String _categoryTitle(Map<String, dynamic> m) {
  return '${m['title'] ?? m['Title'] ?? m['name'] ?? m['Name'] ?? ''}'.trim();
}

class CreateTopicScreen extends StatefulWidget {
  const CreateTopicScreen({super.key});

  @override
  State<CreateTopicScreen> createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends State<CreateTopicScreen> {
  final _title = TextEditingController();
  final _roomTitle = TextEditingController();
  final _roomLifeCycle = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  int? _categoryId;
  int _topicType = 1;
  double? _locationX;
  double? _locationY;

  int _roomType = 1;
  double? _roomLocationX;
  double? _roomLocationY;

  bool _loading = false;
  bool _loadingCategories = true;
  bool _showRoomSection = false;
  int? _createdTopicId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      _fillLocation();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _roomTitle.dispose();
    _roomLifeCycle.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final data = await context.read<AppServices>().categories.getList({
        'pageIndex': 1,
        'pageSize': 1000,
      });
      if (!mounted) return;
      setState(() {
        _categories = asMapList(data);
        _loadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _fillLocation() async {
    final c = LocationService.cached ?? await LocationService.tryCurrentPosition();
    if (c == null || !mounted) return;
    setState(() {
      _locationX = double.parse(c.lng.toStringAsFixed(6));
      _locationY = double.parse(c.lat.toStringAsFixed(6));
      _roomLocationX = _locationX;
      _roomLocationY = _locationY;
    });
  }

  Future<void> _useGpsTopic() async {
    final c = await LocationService.tryCurrentPosition();
    if (c == null) {
      if (mounted) showAppSnackBar(context, 'Konum alınamadı.', error: true);
      return;
    }
    setState(() {
      _locationX = double.parse(c.lng.toStringAsFixed(6));
      _locationY = double.parse(c.lat.toStringAsFixed(6));
    });
  }

  Future<void> _useGpsRoom() async {
    final c = await LocationService.tryCurrentPosition();
    if (c == null) {
      if (mounted) showAppSnackBar(context, 'Konum alınamadı.', error: true);
      return;
    }
    setState(() {
      _roomLocationX = double.parse(c.lng.toStringAsFixed(6));
      _roomLocationY = double.parse(c.lat.toStringAsFixed(6));
    });
  }

  Future<void> _createTopic() async {
    if (_title.text.trim().isEmpty) {
      showAppSnackBar(context, 'Konu başlığı gerekli.', error: true);
      return;
    }

    final app = context.read<AppServices>();
    setState(() => _loading = true);
    try {
      final result = await app.topics.create({
        'title': _title.text.trim(),
        'type': _topicType,
        'locationX': _locationX ?? 0,
        'locationY': _locationY ?? 0,
        'categoryId': _categoryId ?? 0,
      });

      if (result is Map &&
          result['isSuccess'] == false) {
        throw Exception('${result['exceptionMessage'] ?? 'Oluşturulamadı'}');
      }

      final topicTitle = _title.text.trim();
      final list = await app.topics.getList({
        'pageIndex': 1,
        'pageSize': 1000,
      });
      final items = asMapList(list);
      int? tid;
      for (final t in items) {
        if ('${t['title'] ?? t['Title']}' == topicTitle) {
          tid = _entityId(t);
          break;
        }
      }

      if (!mounted) return;
      final keepX = _locationX;
      final keepY = _locationY;
      setState(() {
        _loading = false;
        _createdTopicId = tid;
        _showRoomSection = true;
        _title.clear();
        _topicType = 1;
        _categoryId = null;
        _locationX = null;
        _locationY = null;
        _roomTitle.clear();
        _roomType = 1;
        _roomLocationX = keepX ?? _roomLocationX;
        _roomLocationY = keepY ?? _roomLocationY;
      });
      showAppSnackBar(context, 'Konu oluşturuldu. İsterseniz oda ekleyin.');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(
        context,
        e.response?.data?.toString() ?? e.message ?? 'Hata',
        error: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, '$e', error: true);
    }
  }

  Future<void> _createRoomForTopic() async {
    if (_roomTitle.text.trim().isEmpty) {
      showAppSnackBar(context, 'Oda başlığı gerekli.', error: true);
      return;
    }
    if (_createdTopicId == null) {
      showAppSnackBar(context, 'Konu kimliği bulunamadı.', error: true);
      return;
    }
    final lifeCycle = double.tryParse(_roomLifeCycle.text.trim());
    if (lifeCycle == null) {
      showAppSnackBar(context, 'Yaşam döngüsü gerekli (sayı).', error: true);
      return;
    }

    final app = context.read<AppServices>();
    setState(() => _loading = true);
    try {
      await app.rooms.create({
        'title': _roomTitle.text.trim(),
        'topicId': _createdTopicId,
        'locationX': _roomLocationX ?? 0,
        'locationY': _roomLocationY ?? 0,
        'roomType': _roomType,
        'lifeCycle': lifeCycle,
      });
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, 'Oda oluşturuldu.');
      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(
        context,
        e.message ?? 'Oda oluşturulamadı',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showRoomSection ? 'Konuya oda ekle' : 'Konu oluştur'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_loadingCategories)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (!_showRoomSection) ...[
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Başlık *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              // ignore: deprecated_member_use
              value: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Seçilmedi'),
                ),
                ..._categories.map((c) {
                  final id = _entityId(c);
                  if (id == null) return null;
                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text(
                      _categoryTitle(c).isEmpty ? '#$id' : _categoryTitle(c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).whereType<DropdownMenuItem<int?>>(),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
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
                  onPressed: _useGpsTopic,
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
              selected: {_topicType},
              onSelectionChanged: (s) =>
                  setState(() => _topicType = s.first),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _createTopic,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple600,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Konuyu oluştur'),
            ),
          ] else ...[
            Text(
              'Konu #$_createdTopicId için oda ekleyebilirsiniz.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomTitle,
              decoration: const InputDecoration(
                labelText: 'Oda başlığı *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomLifeCycle,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Yaşam döngüsü *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Konum: ${_roomLocationY?.toStringAsFixed(4) ?? "—"}, ${_roomLocationX?.toStringAsFixed(4) ?? "—"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: _useGpsRoom,
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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _createRoomForTopic,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple600,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Odayı oluştur'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Atla'),
            ),
          ],
        ],
      ),
    );
  }
}
