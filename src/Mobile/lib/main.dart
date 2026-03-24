import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'services/app_services.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService(prefs);
  final auth = AuthProvider(authService);

  final dioClient = DioClient(
    readToken: () => authService.token,
    onUnauthorized: () => auth.logout(),
  );
  final appServices = AppServices(dioClient.dio);

  final router = GoRouter(
    initialLocation: auth.isAuthenticated ? '/app' : '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final loc = state.matchedLocation;
      if (!loggedIn && loc != '/login') {
        return '/login';
      }
      if (loggedIn && loc == '/login') {
        return '/app';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/app',
        builder: (context, state) => const HomeShell(),
      ),
    ],
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        Provider<AuthService>.value(value: authService),
        Provider<AppServices>.value(value: appServices),
      ],
      child: MaterialApp.router(
        title: 'Ghossip',
        theme: AppTheme.light(),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
}
