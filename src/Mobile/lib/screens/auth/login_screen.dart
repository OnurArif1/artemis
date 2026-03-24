import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import '../../widgets/auth_breakpoint.dart';
import '../../widgets/gossip_brand.dart';
import '../../widgets/responsive_center.dart';

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
  void dispose() {
    _email.dispose();
    _password.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regPassword2.dispose();
    super.dispose();
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
      if (mounted) {
        // go_router redirect
      }
    } on AuthException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Bir hata oluştu', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final p = _regPassword.text;
    if (!_passwordRulesOk(p)) {
      showAppSnackBar(
        context,
        'Şifre kurallarını ve eşleşmeyi kontrol edin.',
        error: true,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().register(
            email: _regEmail.text,
            password: p,
          );
    } on AuthException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Kayıt sırasında hata', error: true);
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
            Expanded(
              flex: 11,
              child: _AuthHero(),
            ),
            Expanded(
              flex: 9,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: form,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Align(alignment: Alignment.centerLeft, child: GossipBrand()),
              const SizedBox(height: 28),
              form,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tekrar hoş geldin',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Hesabınla giriş yap ve sohbetlere katıl.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-posta',
              hintText: 'ornek@eposta.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
              if (!v.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            keyboardType: TextInputType.text,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Şifre gerekli';
              return null;
            },
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _loading ? null : _submitLogin,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Giriş yap'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hesabın yok mu?', style: Theme.of(context).textTheme.bodyMedium),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _registerMode = true;
                          _formKey.currentState?.reset();
                        }),
                child: const Text('Kayıt ol'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    final p = _regPassword.text;
    final rules = {
      'En az 6 karakter': p.length >= 6,
      'Bir büyük harf': RegExp(r'[A-Z]').hasMatch(p),
      'Bir küçük harf': RegExp(r'[a-z]').hasMatch(p),
      'Bir rakam': RegExp(r'[0-9]').hasMatch(p),
      'Şifreler eşleşiyor': p.isNotEmpty && p == _regPassword2.text,
    };

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hesap oluştur',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Dakikalar içinde topluluğa katıl.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _regEmail,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
              if (!v.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _regPassword,
            keyboardType: TextInputType.text,
            obscureText: _obscureReg,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureReg = !_obscureReg),
                icon: Icon(_obscureReg ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Şifre gerekli';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regPassword2,
            keyboardType: TextInputType.text,
            obscureText: _obscureReg2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Şifre tekrar',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureReg2 = !_obscureReg2),
                icon: Icon(_obscureReg2 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Tekrar gerekli';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rules.entries.map((e) {
              final ok = e.value;
              return Chip(
                avatar: Icon(
                  ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  size: 18,
                  color: ok ? AppColors.purple600 : Colors.grey,
                ),
                label: Text(e.key, style: const TextStyle(fontSize: 12)),
                backgroundColor: ok ? AppColors.purple50 : Colors.grey.shade100,
                side: BorderSide(color: ok ? AppColors.purple200 : Colors.grey.shade300),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submitRegister,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Kayıt ol'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _registerMode = false;
                      _formKey.currentState?.reset();
                    }),
            child: const Text('Zaten hesabım var'),
          ),
        ],
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
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
