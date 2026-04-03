import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/jwt_email.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import 'onboarding_scaffold.dart';

/// WebApi `TellUsAboutYourself.vue`
class TellUsAboutYourselfScreen extends StatefulWidget {
  const TellUsAboutYourselfScreen({super.key});

  @override
  State<TellUsAboutYourselfScreen> createState() => _TellUsAboutYourselfScreenState();
}

class _TellUsAboutYourselfScreenState extends State<TellUsAboutYourselfScreen> {
  final _bio = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);
    if (email == null) {
      showAppSnackBar(
        context,
        'Kullanıcı bilgileri bulunamadı. Lütfen tekrar giriş yapın.',
        error: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final bio = _bio.text.trim();
      await context.read<AppServices>().parties.updateProfile(
            email: email,
            partyName: email,
            description: bio.isEmpty ? null : bio,
          );
      if (mounted) {
        showAppSnackBar(context, 'Profil bilgileriniz kaydedildi.');
        context.go('/onboarding/purposes');
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Profil bilgileri kaydedilirken bir hata oluştu.',
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
      title: 'Bize kendinizden bahsedin',
      stepLabel: 'Adım 2 / 2',
      headerIcon: Icons.person_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bio',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bio,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Kendiniz hakkında bir şeyler yazın...',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineMuted),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineMuted),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.purple500, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
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
