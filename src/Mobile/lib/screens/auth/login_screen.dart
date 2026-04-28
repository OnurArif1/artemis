import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import '../../widgets/auth_breakpoint.dart';
import '../../widgets/gossip_brand.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regPassword2 = TextEditingController();

  bool _registerMode = false;
  bool _loading = false;
  bool _obscure = true;
  bool _obscureReg = true;
  bool _obscureReg2 = true;

  @override
  void initState() {
    super.initState();
    _regEmail.addListener(_regFieldsChanged);
    _regPassword.addListener(_regFieldsChanged);
    _regPassword2.addListener(_regFieldsChanged);
  }

  void _regFieldsChanged() {
    if (mounted && _registerMode) setState(() {});
  }

  @override
  void dispose() {
    _regEmail.removeListener(_regFieldsChanged);
    _regPassword.removeListener(_regFieldsChanged);
    _regPassword2.removeListener(_regFieldsChanged);
    _email.dispose();
    _password.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regPassword2.dispose();
    super.dispose();
  }

  void _setMode(bool register) {
    if (_loading) return;
    setState(() {
      _registerMode = register;
      _formKey.currentState?.reset();
    });
  }

  bool _passwordRulesOk(String p) {
    if (p.length < 6) return false;
    if (!RegExp(r'[A-Z]').hasMatch(p)) return false;
    if (!RegExp(r'[a-z]').hasMatch(p)) return false;
    if (!RegExp(r'[0-9]').hasMatch(p)) return false;
    return p == _regPassword2.text;
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(
            email: _email.text,
            password: _password.text,
          );
    } on AuthException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Bir hata oluştu', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _canSubmitRegister() {
    final e = _regEmail.text.trim();
    final p = _regPassword.text;
    if (e.isEmpty || !e.contains('@')) return false;
    return _passwordRulesOk(p);
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final e = _regEmail.text.trim();
    final p = _regPassword.text;
    if (p != _regPassword2.text) {
      showAppSnackBar(context, 'Şifreler eşleşmiyor.', error: true);
      return;
    }
    if (p.length < 6) {
      showAppSnackBar(context, 'Şifre en az 6 karakter olmalı.', error: true);
      return;
    }
    if (!_passwordRulesOk(p)) {
      showAppSnackBar(
        context,
        'Şifre kurallarını ve eşleşmeyi kontrol edin.',
        error: true,
      );
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final authSvc = context.read<AuthService>();
    auth.setPendingPostRegistrationOnboarding(true);
    try {
      try {
        await authSvc.registerAccount(email: e, password: p);
      } on AuthException catch (err) {
        auth.setPendingPostRegistrationOnboarding(false);
        if (mounted) showAppSnackBar(context, err.message, error: true);
        return;
      }
      try {
        await auth.login(email: e, password: p);
      } on AuthException catch (_) {
        await authSvc.clearSession();
        auth.setPendingPostRegistrationOnboarding(false);
        if (mounted) {
          showAppSnackBar(
            context,
            'Hesabınız oluşturuldu. Lütfen giriş yapın.',
          );
          _email.text = e;
          _setMode(false);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = AuthBreakpoint.isWide(context);
    final form = _registerMode ? _buildRegisterForm(context) : _buildLoginForm(context);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            const Expanded(flex: 11, child: _AuthHero()),
            Expanded(
              flex: 9,
              child: ColoredBox(
                color: AppColors.surfaceLight,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: _AuthChrome(
                        registerMode: _registerMode,
                        onModeChanged: _setMode,
                        loading: _loading,
                        child: form,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackdrop(),
          SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: const GossipBrand(),
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const insets = EdgeInsets.fromLTRB(20, 12, 20, 24);
                    final minH = constraints.maxHeight - insets.vertical;
                    return SingleChildScrollView(
                      padding: insets,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: minH > 0 ? minH : 0,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: _AuthChrome(
                              registerMode: _registerMode,
                              onModeChanged: _setMode,
                              loading: _loading,
                              child: form,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const SizedBox(height: 28),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            inputFormatters: const [_EmailMacLayoutAtFixFormatter()],
            decoration: const InputDecoration(
              labelText: 'E-posta',
              hintText: 'ornek@eposta.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
              if (!v.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              ),
            ),
            onFieldSubmitted: (_) {
              if (!_loading) _submitLogin();
            },
            validator: (v) {
              if (v == null || v.isEmpty) return 'Şifre gerekli';
              return null;
            },
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _loading ? null : _submitLogin,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Giriş yap'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    final theme = Theme.of(context);
    final p = _regPassword.text;
    final rules = <_PwdRule>[
      _PwdRule('En az 6 karakter', p.length >= 6),
      _PwdRule('En az bir büyük harf', RegExp(r'[A-Z]').hasMatch(p)),
      _PwdRule('En az bir küçük harf', RegExp(r'[a-z]').hasMatch(p)),
      _PwdRule('En az bir rakam', RegExp(r'[0-9]').hasMatch(p)),
    ];
    final mismatch =
        _regPassword2.text.isNotEmpty && p != _regPassword2.text;
    final canSubmit = _canSubmitRegister();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aramıza katıl',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kayıt sonrası ilgi alanların, profilin ve amaçların adım adım tamamlanacak.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _regEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: const [_EmailMacLayoutAtFixFormatter()],
            decoration: const InputDecoration(
              labelText: 'E-posta',
              hintText: 'ornek@eposta.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
              if (!v.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.purple50.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.purple100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Şifre kuralları',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                ...rules.map((r) => _PasswordRuleTile(rule: r)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regPassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            obscureText: _obscureReg,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureReg = !_obscureReg),
                icon: Icon(
                  _obscureReg ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Şifre gerekli';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regPassword2,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            obscureText: _obscureReg2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Şifre (tekrar)',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureReg2 = !_obscureReg2),
                icon: Icon(
                  _obscureReg2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Tekrar gerekli';
              return null;
            },
          ),
          if (mismatch)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Şifreler eşleşmiyor',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_loading || !canSubmit) ? null : _submitRegister,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Hesap oluştur'),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _loading ? null : () => _setMode(false),
              child: const Text('Zaten hesabım var, giriş yap'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PwdRule {
  const _PwdRule(this.label, this.ok);
  final String label;
  final bool ok;
}

class _PasswordRuleTile extends StatelessWidget {
  const _PasswordRuleTile({required this.rule});

  final _PwdRule rule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            rule.ok ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 20,
            color: rule.ok ? AppColors.purple600 : theme.colorScheme.outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rule.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: rule.ok ? AppColors.darkCharcoal : theme.colorScheme.onSurfaceVariant,
                fontWeight: rule.ok ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthChrome extends StatelessWidget {
  const _AuthChrome({
    required this.registerMode,
    required this.onModeChanged,
    required this.loading,
    required this.child,
  });

  final bool registerMode;
  final void Function(bool register) onModeChanged;
  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shadowColor: AppColors.purple900.withValues(alpha: 0.12),
      color: AppColors.surfaceCard,
      surfaceTintColor: AppColors.purple100,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthModeToggle(
              registerMode: registerMode,
              onChanged: onModeChanged,
              enabled: !loading,
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<bool>(registerMode),
                child: child,
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom > 0 ? 4 : 0),
          ],
        ),
      ),
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.registerMode,
    required this.onChanged,
    required this.enabled,
  });

  final bool registerMode;
  final void Function(bool register) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Giriş veya kayıt modu',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.purple50.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.purple100),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TogglePill(
                label: 'Giriş',
                icon: Icons.login_rounded,
                selected: !registerMode,
                onTap: enabled ? () => onChanged(false) : null,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _TogglePill(
                label: 'Kayıt',
                icon: Icons.person_add_alt_1_rounded,
                selected: registerMode,
                onTap: enabled ? () => onChanged(true) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceCard : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.purple900.withValues(alpha: 0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.purple600 : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.purple600 : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBackdrop extends StatefulWidget {
  const _LoginBackdrop();

  @override
  State<_LoginBackdrop> createState() => _LoginBackdropState();
}

class _LoginBackdropState extends State<_LoginBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOutSine.transform(_controller.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _BackdropPainter(phase: t),
              child: const SizedBox.expand(),
            ),
            Positioned(
              top: 88 + 8 * math.sin(t * math.pi * 2),
              right: 24,
              child: const _FloatingBadge(
                icon: Icons.bolt_rounded,
                label: 'Canli sohbet',
              ),
            ),
            Positioned(
              top: 146 + 10 * math.cos(t * math.pi * 2),
              left: 22,
              child: const _FloatingBadge(
                icon: Icons.near_me_rounded,
                label: 'Yakindaki odalar',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.55);
    final rgradient = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.5),
        radius: 1.15,
        colors: [
          AppColors.purple100.withValues(alpha: 0.95),
          AppColors.purple50.withValues(alpha: 0.4),
          AppColors.surfaceLight.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = AppColors.surfaceLight);

    final wobbleX = 14 * math.sin(phase * math.pi * 2);
    final wobbleY = 9 * math.cos(phase * math.pi * 2);
    canvas.drawCircle(
      Offset(size.width * 0.84 + wobbleX, size.height * 0.09 + wobbleY),
      size.width * 0.42,
      rgradient,
    );

    final blob = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.purple300.withValues(alpha: 0.28),
          AppColors.purple100.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.17, size.height * 0.2),
        radius: size.width * 0.35,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.17 - wobbleX * 0.6,
        size.height * 0.2 - wobbleY * 0.6,
      ),
      size.width * 0.32,
      blob,
    );

    final topGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.pureWhite.withValues(alpha: 0.9),
          AppColors.surfaceLight,
        ],
        stops: const [0.0, 0.42],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5), topGlow);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.purple200.withValues(alpha: 0.55);
    final arcRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.14),
      width: size.width * 0.92,
      height: size.height * 0.25,
    );
    canvas.drawArc(
      arcRect,
      math.pi * (0.12 + 0.06 * phase),
      math.pi * 0.78,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) => oldDelegate.phase != phase;
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple900.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.purple600),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.purple700,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple800,
            AppColors.purple600,
            AppColors.purple500,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _SoftGridPainter()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.forum_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Ghossip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Yakınındaki sohbetleri keşfet',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Konular, odalar ve topluluk — tek uygulamada.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailMacLayoutAtFixFormatter extends TextInputFormatter {
  const _EmailMacLayoutAtFixFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.text.contains('œ') && !newValue.text.contains('Œ')) {
      return newValue;
    }
    final text = newValue.text.replaceAll('Œ', '@').replaceAll('œ', '@');
    return TextEditingValue(
      text: text,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

class _SoftGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
