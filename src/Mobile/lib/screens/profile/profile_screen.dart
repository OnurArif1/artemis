import 'dart:convert';

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
import '../onboarding/interest_cover_image.dart';
import '../onboarding/interest_display.dart';
import '../onboarding/party_purpose_options.dart';

class _InterestCatalogItem {
  const _InterestCatalogItem({required this.id, required this.name});

  final int id;
  final String name;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _partyTier;
  bool _tierLoading = true;
  bool _savingTier = false;

  final PageController _pageController = PageController();
  final TextEditingController _bioController = TextEditingController();
  int _regPageIndex = 0;

  List<_InterestCatalogItem> _interestCatalog = [];
  final Set<int> _selectedInterestIds = {};
  final Set<int> _selectedPurposeIds = {};
  bool _registrationLoading = false;
  bool _savingInterests = false;
  bool _savingBio = false;
  bool _savingPurposes = false;

  /// Üst üste gelen `_loadRegistrationData` çağrılarında eski yanıtın state'i ezmesini engeller.
  int _registrationLoadSeq = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTier();
      _reloadRegistrationIfLoggedIn();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTier();
      _reloadRegistrationIfLoggedIn();
    });
  }

  void _reloadRegistrationIfLoggedIn() {
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token) ?? _emailFromToken(token);
    if (email != null && email.isNotEmpty) {
      _loadRegistrationData();
    }
  }

  int? _parseId(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  dynamic _mapPick(dynamic m, List<String> keys) {
    if (m is! Map) return null;
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k];
    }
    return null;
  }

  int? _interestIdFromEntry(dynamic e) {
    final raw = _mapPick(e, const ['id', 'Id', 'interestId', 'InterestId']);
    return _parseId(raw);
  }

  int? _parsePurposeScalar(dynamic e) {
    final id = _parseId(e);
    if (id != null) return id;
    if (e is String) {
      const byName = {
        'socializing': 1,
        'dating': 2,
        'networking': 3,
        'makingfriends': 4,
        'exploring': 5,
        'notset': 0,
      };
      final k = e.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
      return byName[k];
    }
    return null;
  }

  /// API / gateway farklı gövdeler için amaç tipi id listesini çıkarır.
  Set<int> _extractPurposeTypeIds(dynamic raw) {
    final out = <int>{};

    void ingestList(dynamic list) {
      if (list is! List) return;
      for (final e in list) {
        final v = _parsePurposeScalar(e);
        if (v != null && v >= 1 && v <= 5) out.add(v);
      }
    }

    void walk(dynamic node, [int depth = 0]) {
      if (node == null || depth > 6) return;

      if (node is String) {
        final t = node.trim();
        if ((t.startsWith('{') && t.endsWith('}')) || (t.startsWith('[') && t.endsWith(']'))) {
          try {
            walk(jsonDecode(t), depth + 1);
          } catch (_) {}
        }
        return;
      }

      if (node is List) {
        ingestList(node);
        return;
      }

      if (node is Map) {
        const keys = [
          'purposeTypes',
          'PurposeTypes',
          'purpose_types',
          'items',
          'values',
          'data',
          'result',
        ];
        for (final k in keys) {
          if (!node.containsKey(k)) continue;
          final v = node[k];
          if (v is List) ingestList(v);
          if (v is Map || v is String) walk(v, depth + 1);
        }
      }
    }

    walk(raw);
    return out;
  }

  Future<void> _loadRegistrationData() async {
    if (!mounted) return;
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token) ?? _emailFromToken(token);
    if (email == null || email.isEmpty) {
      if (mounted) setState(() => _registrationLoading = false);
      return;
    }

    final seq = ++_registrationLoadSeq;
    setState(() => _registrationLoading = true);
    final app = context.read<AppServices>();
    try {
      // JWT'de e-posta claim'i API tarafında bazen gelmiyor; query ile de gönder (yedek).
      final rawProfile = await app.parties.getProfile(email: email);
      final rawMine = await app.interests.getMyInterests(email: email);
      final rawPurposes = await app.partyPurposes.getMyPurposes(email: email);
      final rawList = await app.interests.getList();

      if (!mounted || seq != _registrationLoadSeq) return;

      final catalog = <_InterestCatalogItem>[];
      if (rawList is List) {
        for (final e in rawList) {
          if (e is Map) {
            final id = _interestIdFromEntry(e);
            final nameRaw = _mapPick(e, const ['name', 'Name']);
            final name = nameRaw?.toString().trim() ?? '';
            if (id != null && name.isNotEmpty) {
              catalog.add(_InterestCatalogItem(id: id, name: name));
            }
          }
        }
      }

      final selectedInterest = <int>{};
      if (rawMine is List) {
        for (final e in rawMine) {
          final id = _interestIdFromEntry(e);
          if (id != null) selectedInterest.add(id);
        }
      }

      final purposes = _extractPurposeTypeIds(rawPurposes);

      String bioText = '';
      if (rawProfile is Map) {
        final d = _mapPick(rawProfile, const ['description', 'Description']);
        if (d != null) bioText = d.toString();
      }

      if (!mounted || seq != _registrationLoadSeq) return;

      setState(() {
        _interestCatalog = catalog;
        _selectedInterestIds
          ..clear()
          ..addAll(selectedInterest);
        _selectedPurposeIds
          ..clear()
          ..addAll(purposes);
        _bioController.text = bioText;
        _registrationLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted || seq != _registrationLoadSeq) return;
      final data = e.response?.data;
      var msg = 'Kayıt bilgileri yüklenirken bir sorun oluştu.';
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      showAppSnackBar(context, msg, error: true);
      setState(() => _registrationLoading = false);
    } catch (_) {
      if (!mounted || seq != _registrationLoadSeq) return;
      showAppSnackBar(
        context,
        'Kayıt bilgileri yüklenirken bir sorun oluştu.',
        error: true,
      );
      setState(() => _registrationLoading = false);
    }
  }

  void _toggleInterest(int id) {
    setState(() {
      if (_selectedInterestIds.contains(id)) {
        _selectedInterestIds.remove(id);
      } else {
        _selectedInterestIds.add(id);
      }
    });
  }

  void _togglePurpose(int purposeType) {
    setState(() {
      if (_selectedPurposeIds.contains(purposeType)) {
        _selectedPurposeIds.remove(purposeType);
      } else {
        _selectedPurposeIds.add(purposeType);
      }
    });
  }

  int _interestCrossAxisCount(double width) {
    if (width >= 1100) return 6;
    if (width >= 900) return 5;
    if (width >= 720) return 4;
    if (width >= 480) return 3;
    return 2;
  }

  Future<void> _saveInterests(String email) async {
    if (_selectedInterestIds.isEmpty) {
      showAppSnackBar(context, 'En az bir ilgi alanı seçmelisiniz.', error: true);
      return;
    }
    setState(() => _savingInterests = true);
    try {
      await context.read<AppServices>().interests.savePartyInterests(
            email: email,
            interestIds: _selectedInterestIds.toList(),
          );
      if (mounted) showAppSnackBar(context, 'İlgi alanları güncellendi.');
    } on DioException catch (e) {
      if (mounted) _showDioError(e, 'İlgi alanları kaydedilemedi.');
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'İlgi alanları kaydedilemedi.', error: true);
      }
    } finally {
      if (mounted) setState(() => _savingInterests = false);
    }
  }

  Future<void> _saveBio(String email) async {
    setState(() => _savingBio = true);
    try {
      final bio = _bioController.text.trim();
      await context.read<AppServices>().parties.updateProfile(
            email: email,
            description: bio.isEmpty ? null : bio,
          );
      if (mounted) showAppSnackBar(context, 'Bio güncellendi.');
    } on DioException catch (e) {
      if (mounted) _showDioError(e, 'Bio kaydedilemedi.');
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Bio kaydedilemedi.', error: true);
    } finally {
      if (mounted) setState(() => _savingBio = false);
    }
  }

  Future<void> _savePurposes(String email) async {
    if (_selectedPurposeIds.isEmpty) {
      showAppSnackBar(context, 'En az bir amaç seçmelisiniz.', error: true);
      return;
    }
    setState(() => _savingPurposes = true);
    try {
      await context.read<AppServices>().partyPurposes.savePartyPurposes(
            email: email,
            purposeTypes: _selectedPurposeIds.toList(),
          );
      if (mounted) showAppSnackBar(context, 'Amaçlar güncellendi.');
    } on DioException catch (e) {
      if (mounted) _showDioError(e, 'Amaçlar kaydedilemedi.');
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Amaçlar kaydedilemedi.', error: true);
    } finally {
      if (mounted) setState(() => _savingPurposes = false);
    }
  }

  void _showDioError(DioException e, String fallback) {
    final data = e.response?.data;
    String msg = fallback;
    if (data is Map && data['message'] != null) {
      msg = data['message'].toString();
    } else if (e.message != null && e.message!.isNotEmpty) {
      msg = e.message!;
    }
    showAppSnackBar(context, msg, error: true);
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
    context.read<AuthProvider>().setSubscriptionType(t, notify: false);
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
      context.read<AuthProvider>().setSubscriptionType(picked);
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

  static const _regStepTitles = ['İlgi alanları', 'Bio', 'Amaçlar'];

  Widget _buildRegistrationPager(BuildContext context, String email) {
    final theme = Theme.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final cross = _interestCrossAxisCount(w);

    return Card(
      elevation: 0,
      surfaceTintColor: AppColors.purple50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.purple600, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kayıt bilgilerini güncelle',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Kayıt sırasında verdiğiniz bilgileri buradan değiştirebilirsiniz. Noktalara dokunarak veya kaydırarak adımlar arasında gezinin.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.darkCharcoal.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 14),
            if (_registrationLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              Text(
                'Adım ${_regPageIndex + 1} / 3 · ${_regStepTitles[_regPageIndex]}',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _regPageIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      ),
                      borderRadius: BorderRadius.circular(99),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: active ? AppColors.purple500 : AppColors.outlineMuted,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 420,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _regPageIndex = i),
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'En az bir ilgi alanı seçin.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cross,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.78,
                            ),
                            itemCount: _interestCatalog.length,
                            itemBuilder: (context, i) {
                              final it = _interestCatalog[i];
                              final sel = _selectedInterestIds.contains(it.id);
                              final label = interestLabelTr(it.name);
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _toggleInterest(it.id),
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
                                          height: cross >= 4 ? 52 : 58,
                                          selected: sel,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          label,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelMedium?.copyWith(
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
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: (_selectedInterestIds.isEmpty || _savingInterests)
                                ? null
                                : () => _saveInterests(email),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: AppColors.purple500,
                              foregroundColor: Colors.white,
                            ),
                            child: _savingInterests
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Kaydet'),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            controller: _bioController,
                            maxLines: 5,
                            minLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Kendinizden kısaca bahsedin…',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.outlineMuted),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.purple400, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _savingBio ? null : () => _saveBio(email),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: AppColors.purple500,
                              foregroundColor: Colors.white,
                            ),
                            child: _savingBio
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Kaydet'),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Birden fazla seçebilirsiniz.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          ...kPartyPurposeOptions.map((p) {
                            final sel = _selectedPurposeIds.contains(p.purposeType);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _togglePurpose(p.purposeType),
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
                                          width: 42,
                                          height: 42,
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
                                            size: 22,
                                            color: sel ? AppColors.purple700 : AppColors.purple600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            p.label,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.darkCharcoal,
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                                          color: sel ? AppColors.purple600 : theme.colorScheme.outline,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: (_selectedPurposeIds.isEmpty || _savingPurposes)
                                ? null
                                : () => _savePurposes(email),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: AppColors.purple500,
                              foregroundColor: Colors.white,
                            ),
                            child: _savingPurposes
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Kaydet'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTier();
          await _loadRegistrationData();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      (email != null && email.isNotEmpty ? email.substring(0, 1) : '?').toUpperCase(),
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
                    color: _tierLoading ? Colors.grey.shade400 : subscriptionTierColor(displayTier),
                  ),
                  title: const Text('Üyelik paketini değiştir'),
                  subtitle: Text(
                    _tierLoading
                        ? 'Yükleniyor…'
                        : (displayTier != null ? subscriptionTierLabelTr(displayTier) : 'Sunucudan okunamadı'),
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
          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRegistrationPager(context, email),
          ],
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
      ),
    );
  }
}
