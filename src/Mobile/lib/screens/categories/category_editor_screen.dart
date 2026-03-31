import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../services/app_services.dart';
import '../../widgets/artemis_snackbar.dart';

/// Web `CategoryList.vue` oluştur / düzenle / sil diyalogları.
class CategoryEditorScreen extends StatefulWidget {
  const CategoryEditorScreen({super.key, this.category});

  /// `null` → yeni kategori.
  final Map<String, dynamic>? category;

  @override
  State<CategoryEditorScreen> createState() => _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends State<CategoryEditorScreen> {
  late final TextEditingController _title;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.category != null
        ? entityString(widget.category!, ['title', 'Title', 'name', 'Name'])
        : null;
    _title = TextEditingController(text: t ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.category != null && entityId(widget.category!) != null;

  Future<void> _save() async {
    final name = _title.text.trim();
    if (name.isEmpty) {
      showAppSnackBar(context, 'Başlık gerekli.', error: true);
      return;
    }
    setState(() => _loading = true);
    final app = context.read<AppServices>();
    try {
      if (_isEdit) {
        await app.categories.update({
          'id': entityId(widget.category!),
          'title': name,
        });
        if (mounted) showAppSnackBar(context, 'Kategori güncellendi.');
      } else {
        await app.categories.create({'title': name});
        if (mounted) showAppSnackBar(context, 'Kategori oluşturuldu.');
      }
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (mounted) {
        showAppSnackBar(context, e.message ?? 'Kaydedilemedi', error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.category != null ? entityId(widget.category!) : null;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategoriyi sil'),
        content: const Text('Bu işlem geri alınamaz. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await context.read<AppServices>().categories.delete(id);
      if (mounted) {
        showAppSnackBar(context, 'Silindi.');
        Navigator.of(context).pop(true);
      }
    } on DioException catch (e) {
      if (mounted) {
        showAppSnackBar(context, e.message ?? 'Silinemedi', error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Kategori düzenle' : 'Yeni kategori'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _loading ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Başlık',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _save,
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
                : Text(_isEdit ? 'Kaydet' : 'Oluştur'),
          ),
        ],
      ),
    );
  }
}
