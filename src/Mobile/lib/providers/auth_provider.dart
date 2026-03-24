import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth);

  final AuthService _auth;

  bool get isAuthenticated => _auth.isTokenValid;

  Future<void> login({required String email, required String password}) async {
    await _auth.login(email: email, password: password);
    notifyListeners();
  }

  Future<void> register({required String email, required String password}) async {
    await _auth.register(email: email, password: password);
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.clearSession();
    notifyListeners();
  }
}
