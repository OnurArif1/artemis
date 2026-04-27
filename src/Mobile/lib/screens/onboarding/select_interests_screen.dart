import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/jwt_email.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import 'interest_cover_image.dart';
import 'interest_display.dart';
import 'onboarding_scaffold.dart';

class _InterestItem {
  const _InterestItem({required this.id, required this.name});

  final int id;
  final String name;
}

class SelectInterestsScreen extends StatefulWidget {
  const SelectInterestsScreen({super.key});

  @override
  State<SelectInterestsScreen> createState() => _SelectInterestsState();
}

class _SelectInterestsState extends State<SelectInterestsScreen> {
  final Set<int> _selected = {};
  List<_InterestItem> _items = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().clearPendingPostRegistrationOnboarding();
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await context.read<AppServices>().interests.getList();
      final list = <_InterestItem>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) {
            final id = _parseId(e['id']);
            final name = e['name']?.toString() ?? '';
            if (id != null && name.isNotEmpty) {
              list.add(_InterestItem(id: id, name: name));
            }
          }
        }
      }
      if (mounted) setState(() => _items = list);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'İlgi alanları yüklenirken bir hata oluştu.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _parseId(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      showAppSnackBar(context, 'En az bir ilgi alanı seçmelisiniz.', error: true);
      return;
    }
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);
    if (email == null) {
      showAppSnackBar(context, 'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.', error: true);
      if (mounted) context.go('/login');
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AppServices>().interests.savePartyInterests(
            email: email,
            interestIds: _selected.toList(),
          );
      if (mounted) {
        showAppSnackBar(context, 'İlgi alanlarınız kaydedildi.');
        context.go('/onboarding/about');
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'İlgi alanları kaydedilirken bir hata oluştu.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _crossAxisCount(double width) {
    if (width >= 1100) return 6;
    if (width >= 900) return 5;
    if (width >= 720) return 4;
    if (width >= 480) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final cross = _crossAxisCount(w);
    final gridHeight = (h * 0.52).clamp(260.0, 520.0);

    return OnboardingScaffold(
      title: 'İlgi Alanlarınız',
      stepLabel: 'Adım 1 / 2',
      headerIcon: Icons.favorite_rounded,
      instruction:
          'Benzer düşünen insanlarla eşleşmenize yardımcı olmak için en az 1 ilgi alanı seçin',
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: gridHeight,
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final it = _items[i];
                      final sel = _selected.contains(it.id);
                      final label = interestLabelTr(it.name);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggle(it.id),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                width: 2,
                                color: sel ? AppColors.purple500 : AppColors.outlineMuted,
                              ),
                              color: sel
                                  ? AppColors.purple500.withValues(alpha: 0.08)
                                  : Colors.white,
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: AppColors.purple500.withValues(alpha: 0.18),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InterestCoverPhoto(
                                  nameKey: it.name,
                                  height: cross >= 4 ? 58 : 64,
                                  selected: sel,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: sel ? AppColors.purple600 : AppColors.darkCharcoal,
                                        height: 1.15,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: (_selected.isEmpty || _saving) ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.purple500,
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Devam Et'),
                ),
              ],
            ),
    );
  }
}
