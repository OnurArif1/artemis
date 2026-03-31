import 'package:flutter/foundation.dart';

import '../core/location/location_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(
    this._auth, {
    void Function()? onAuthenticatedSessionStarted,
  }) : _onAuthenticatedSessionStarted = onAuthenticatedSessionStarted;

  final AuthService _auth;
  final void Function()? _onAuthenticatedSessionStarted;

  bool get isAuthenticated => _auth.isTokenValid;

  Future<void> login({required String email, required String password}) async {
    await _auth.login(email: email, password: password);
    LocationService.clearCache();
    _onAuthenticatedSessionStarted?.call();
    notifyListeners();
  }

  Future<void> register({required String email, required String password}) async {
    await _auth.register(email: email, password: password);
    LocationService.clearCache();
    _onAuthenticatedSessionStarted?.call();
    notifyListeners();
  }

  Future<void> logout() async {
    LocationService.clearCache();
    await _auth.clearSession();
    notifyListeners();
  }
}
