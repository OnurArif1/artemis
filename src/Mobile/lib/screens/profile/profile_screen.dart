import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/jwt_subscription.dart';
import '../../core/util/room_create_policy.dart';
import '../../core/util/subscription_display.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import '../../widgets/gossip_brand.dart';
import '../../widgets/subscription_tier_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _partyTier;
  bool _tierLoading = true;
  bool _savingTier = false;

  String? _emailFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final m = JwtDecoder.decode(token);
      return (m['email'] ?? m['unique_name'] ?? m['sub'])?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTier());
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTier());
  }

  Future<void> _loadTier() async {
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);
    if (email == null || email.isEmpty) {
      if (mounted) {
        setState(() {
          _partyTier = null;
          _tierLoading = false;
        });
      }
      return;
    }
    final app = context.read<AppServices>();
    final t = await resolveMySubscriptionTypeForRoomCreate(app, token, email);
    if (!mounted) return;
    setState(() {
      _partyTier = t;
      _tierLoading = false;
    });
  }

  Future<void> _pickAndSaveTier() async {
    final token = context.read<AuthService>().token;
    if (token == null || token.isEmpty) {
      showAppSnackBar(context, 'Oturum gerekli.', error: true);
      return;
    }

    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Üyelik paketi'),
        children: [1, 2, 3].map((t) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, t),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SubscriptionTierBadge(subscriptionType: t, compact: true),
                  const SizedBox(width: 10),
                  Expanded(child: Text(subscriptionTierLabelTr(t))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (picked == null || !mounted) return;

    final email = emailFromAccessToken(token);
    if (email == null || email.isEmpty) {
      showAppSnackBar(
        context,
        'Token’da e-posta yok. Çıkış yapıp tekrar giriş deneyin.',
        error: true,
      );
      return;
    }

    setState(() => _savingTier = true);
    try {
      await context.read<AppServices>().parties.updateSubscription(
            email: email,
            subscriptionType: picked,
          );
      if (!mounted) return;
      setState(() {
        _partyTier = picked;
        _savingTier = false;
      });
      showAppSnackBar(context, 'Paket güncellendi.');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _savingTier = false);
      final data = e.response?.data;
      String msg = 'Paket güncellenemedi.';
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      } else if (e.message != null && e.message!.isNotEmpty) {
        msg = e.message!;
      }
      showAppSnackBar(context, msg, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingTier = false);
      showAppSnackBar(context, 'Paket güncellenemedi.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token) ?? _emailFromToken(token);
    final jwtTier = tryParseSubscriptionTypeFromJwt(token);
    final displayTier = _partyTier ?? jwtTier;
    final rail = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: !rail,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            surfaceTintColor: AppColors.purple100,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.purple50,
                    AppColors.surfaceCard,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GossipBrand(),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.purple100,
                    foregroundColor: AppColors.purple700,
                    child: Text(
                      (email != null && email.isNotEmpty
                              ? email.substring(0, 1)
                              : '?')
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    email ?? 'Oturum açık',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_tierLoading) ...[
                    const SizedBox(height: 12),
                    const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ] else if (displayTier != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Üyelik: ',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SubscriptionTierBadge(
                          subscriptionType: displayTier,
                          compact: false,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            surfaceTintColor: AppColors.purple50,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    _tierLoading
                        ? Icons.workspace_premium_rounded
                        : switch (displayTier) {
                            3 => Icons.diamond_rounded,
                            2 => Icons.workspace_premium_rounded,
                            1 => Icons.military_tech_rounded,
                            0 => Icons.groups_rounded,
                            _ => Icons.workspace_premium_rounded,
                          },
                    color: _tierLoading
                        ? Colors.grey.shade400
                        : subscriptionTierColor(displayTier),
                  ),
                  title: const Text('Üyelik paketini değiştir'),
                  subtitle: Text(
                    _tierLoading
                        ? 'Yükleniyor…'
                        : (displayTier != null
                            ? subscriptionTierLabelTr(displayTier)
                            : 'Sunucudan okunamadı'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: _savingTier
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _tierLoading || _savingTier ? null : _pickAndSaveTier,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Çıkış yap'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purple700,
              side: const BorderSide(color: AppColors.purple300),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
