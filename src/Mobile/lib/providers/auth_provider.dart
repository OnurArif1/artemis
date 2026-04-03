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

  bool _pendingPostRegistrationOnboarding = false;
  bool get pendingPostRegistrationOnboarding => _pendingPostRegistrationOnboarding;

  void setPendingPostRegistrationOnboarding(bool value) {
    _pendingPostRegistrationOnboarding = value;
  }

  void clearPendingPostRegistrationOnboarding() {
    if (!_pendingPostRegistrationOnboarding) return;
    _pendingPostRegistrationOnboarding = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.login(email: email, password: password);
    LocationService.clearCache();
    _onAuthenticatedSessionStarted?.call();
    notifyListeners();
  }

  Future<void> logout() async {
    _pendingPostRegistrationOnboarding = false;
    LocationService.clearCache();
    await _auth.clearSession();
    notifyListeners();
  }
}
