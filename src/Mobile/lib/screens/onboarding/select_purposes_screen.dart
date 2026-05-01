import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/jwt_email.dart';
import '../../providers/home_tab_controller.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import 'onboarding_scaffold.dart';

class _Purpose {
  const _Purpose({
    required this.id,
    required this.label,
    required this.icon,
  });

  final int id;
  final String label;
  final IconData icon;
}

const _purposes = [
  _Purpose(
    id: 1,
    label: 'Sosyalleşme',
    icon: Icons.celebration_rounded,
  ),
  _Purpose(
    id: 2,
    label: 'Flört',
    icon: Icons.favorite_rounded,
  ),
  _Purpose(
    id: 3,
    label: 'Ağ kurma',
    icon: Icons.hub_rounded,
  ),
  _Purpose(
    id: 4,
    label: 'Arkadaş edinme',
    icon: Icons.group_add_rounded,
  ),
  _Purpose(
    id: 5,
    label: 'Keşfetme',
    icon: Icons.explore_rounded,
  ),
];

class SelectPurposesScreen extends StatefulWidget {
  const SelectPurposesScreen({super.key});

  @override
  State<SelectPurposesScreen> createState() => _SelectPurposesScreenState();
}

class _SelectPurposesScreenState extends State<SelectPurposesScreen> {
  final Set<int> _selected = {};
  bool _saving = false;

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
      showAppSnackBar(context, 'En az bir amaç seçmelisiniz.', error: true);
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
      await context.read<AppServices>().partyPurposes.savePartyPurposes(
            email: email,
            purposeTypes: _selected.toList(),
          );
      if (mounted) {
        showAppSnackBar(context, 'Amaçlarınız kaydedildi.');
        context.read<HomeTabController>().setIndex(HomeTabController.roomsTabIndex);
        context.go('/app');
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Amaçlar kaydedilirken bir hata oluştu.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingScaffold(
      title: 'Seni buraya getiren ne?',
      stepLabel: 'Adım 3 / 3',
      headerIcon: Icons.volunteer_activism_rounded,
      instruction: 'Birden fazla seçebilirsiniz',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._purposes.map((p) {
            final sel = _selected.contains(p.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _toggle(p.id),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        width: 2,
                        color: sel ? AppColors.purple500 : AppColors.outlineMuted,
                      ),
                      color: sel ? AppColors.purple500.withValues(alpha: 0.07) : Colors.white,
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: AppColors.purple500.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: sel
                                  ? [
                                      AppColors.purple500.withValues(alpha: 0.22),
                                      AppColors.purple600.withValues(alpha: 0.28),
                                    ]
                                  : [
                                      AppColors.purple50,
                                      AppColors.purple100.withValues(alpha: 0.65),
                                    ],
                            ),
                            border: Border.all(
                              color: sel
                                  ? AppColors.purple400.withValues(alpha: 0.55)
                                  : AppColors.outlineMuted.withValues(alpha: 0.6),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            p.icon,
                            size: 26,
                            color: sel ? AppColors.purple700 : AppColors.purple600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkCharcoal,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: sel ? AppColors.purple600 : theme.colorScheme.outline,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
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
