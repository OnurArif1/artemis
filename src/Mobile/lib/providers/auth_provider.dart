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

  int? _subscriptionType;
  int? get subscriptionType => _subscriptionType;
  int _subscriptionVersion = 0;
  int get subscriptionVersion => _subscriptionVersion;

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
    _subscriptionType = null;
    _subscriptionVersion = 0;
    _onAuthenticatedSessionStarted?.call();
    notifyListeners();
  }

  Future<void> logout() async {
    _pendingPostRegistrationOnboarding = false;
    _subscriptionType = null;
    _subscriptionVersion = 0;
    LocationService.clearCache();
    await _auth.clearSession();
    notifyListeners();
  }

  void setSubscriptionType(int? value, {bool notify = true}) {
    final changed = _subscriptionType != value;
    _subscriptionType = value;
    if (changed) {
      _subscriptionVersion++;
    }
    if (notify) {
      notifyListeners();
    }
  }
}
