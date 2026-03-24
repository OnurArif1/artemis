import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/gossip_brand.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    final token = context.read<AuthService>().token;
    final email = _emailFromToken(token);
    final rail = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: !rail,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
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
                  const SizedBox(height: 8),
                  Text(
                    'Hesabınız WebApi ile aynı kimlik sunucusu üzerinden doğrulanır.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns_outlined, color: AppColors.purple600),
                  title: const Text('API kök adresi'),
                  subtitle: Text(
                    ApiConfig.origin,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.purple600),
                  title: const Text('Geliştirici notu'),
                  subtitle: Text(
                    'Android emülatör: flutter run --dart-define=API_HOST=10.0.2.2',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
