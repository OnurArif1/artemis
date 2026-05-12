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

  Widget _stepChip({
    required String step,
    required String label,
    required bool active,
    /// Aktifken oda adımı (2) için mor palet; konu adımı (1) için teal.
    bool roomAccent = false,
  }) {
    late final Color chipBg;
    late final Color borderColor;
    late final Color circleBg;
    late final Color numberColor;
    late final Color labelColor;

    if (active) {
      if (roomAccent) {
        chipBg = AppColors.purple50;
        borderColor = AppColors.purple200.withValues(alpha: 0.55);
        circleBg = AppColors.purple600.withValues(alpha: 0.14);
        numberColor = AppColors.purple600;
        labelColor = AppColors.purple700;
      } else {
        chipBg = AppColors.topicMint;
        borderColor = AppColors.topicTeal.withValues(alpha: 0.22);
        circleBg = AppColors.topicTeal.withValues(alpha: 0.18);
        numberColor = AppColors.topicTeal;
        labelColor = AppColors.topicTeal;
      }
    } else {
      chipBg = AppColors.surfaceCard;
      borderColor = AppColors.outlineMuted.withValues(alpha: 0.9);
      circleBg = Colors.grey.shade200;
      numberColor = Colors.grey.shade600;
      labelColor = AppColors.darkCharcoal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: circleBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: numberColor,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: labelColor,
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
    bool topicStyle = true,
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
              Icon(
                icon,
                size: 18,
                color: topicStyle ? AppColors.topicTeal : AppColors.purple600,
              ),
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
      bool topicFocus = true,
    }) {
      final accentColor =
          topicFocus ? AppColors.topicTeal : AppColors.purple500;
      return InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: AppColors.surfaceCard,
        floatingLabelStyle: TextStyle(
          color: accentColor,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(
            color: accentColor,
            width: 1.6,
          ),
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
          _showRoomSection ? 'Konuya oda ekle' : 'Konu oluştur',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.darkCharcoal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (_loadingCategories)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.topicTeal),
              ),
            )
          else if (!_showRoomSection) ...[
            Row(
              children: [
                _stepChip(step: '1', label: 'Konu bilgisi', active: true),
                const SizedBox(width: 8),
                _stepChip(step: '2', label: 'İsteğe bağlı oda', active: false),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.topicMint, AppColors.surfaceCard],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.topicTeal.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded, color: AppColors.topicTeal, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Konu bilgilerini doldurun. İsterseniz ikinci adımda odaya geçebilirsiniz.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.topicTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Konu bilgileri',
              icon: Icons.tag_rounded,
              children: [
                TextField(
                  controller: _title,
                  cursorColor: AppColors.topicTeal,
                  decoration: fieldDecoration(
                    label: 'Başlık *',
                    hint: 'Konu başlığını yazın',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  decoration: fieldDecoration(
                    label: 'Kategori',
                    topicFocus: true,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.outlineMuted.withValues(alpha: 0.9),
                    ),
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
                        onPressed: _useGpsTopic,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.topicTeal,
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _createTopic,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.topicTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Konuyu oluştur'),
            ),
          ] else ...[
            Row(
              children: [
                _stepChip(step: '1', label: 'Konu bilgisi', active: false),
                const SizedBox(width: 8),
                _stepChip(
                  step: '2',
                  label: 'İsteğe bağlı oda',
                  active: true,
                  roomAccent: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.purple50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.purple200.withValues(alpha: 0.55)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room_outlined, color: AppColors.purple600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Konu #$_createdTopicId için bir oda oluşturabilirsiniz (isteğe bağlı).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.purple700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Oda ayarları',
              icon: Icons.tune_rounded,
              topicStyle: false,
              children: [
                TextField(
                  controller: _roomTitle,
                  cursorColor: AppColors.purple500,
                  decoration: fieldDecoration(
                    label: 'Oda başlığı *',
                    hint: 'Oda için başlık yazın',
                    topicFocus: false,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _roomLifeCycle,
                  cursorColor: AppColors.purple500,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: fieldDecoration(
                    label: 'Yaşam döngüsü *',
                    hint: 'Dakika cinsinden (örn: 60)',
                    topicFocus: false,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.outlineMuted.withValues(alpha: 0.9),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Konum: ${_roomLocationY?.toStringAsFixed(4) ?? "—"}, ${_roomLocationX?.toStringAsFixed(4) ?? "—"}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _useGpsRoom,
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
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _createRoomForTopic,
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
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
