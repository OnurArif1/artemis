import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/home_tab_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/onboarding/select_interests_screen.dart';
import 'screens/onboarding/select_purposes_screen.dart';
import 'screens/onboarding/tell_us_about_yourself_screen.dart';
import 'services/app_services.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService(prefs);
  final homeTab = HomeTabController();
  final auth = AuthProvider(
    authService,
    onAuthenticatedSessionStarted: () => homeTab.setIndex(0),
  );

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
      if (!loggedIn) {
        if (loc.startsWith('/onboarding')) {
          return '/login';
        }
        if (loc != '/login') {
          return '/login';
        }
        return null;
      }
      if (loggedIn && loc == '/login') {
        if (auth.pendingPostRegistrationOnboarding) {
          return '/onboarding/interests';
        }
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
        path: '/onboarding/interests',
        builder: (context, state) => const SelectInterestsScreen(),
      ),
      GoRoute(
        path: '/onboarding/about',
        builder: (context, state) => const TellUsAboutYourselfScreen(),
      ),
      GoRoute(
        path: '/onboarding/purposes',
        builder: (context, state) => const SelectPurposesScreen(),
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
        ChangeNotifierProvider<HomeTabController>.value(value: homeTab),
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
