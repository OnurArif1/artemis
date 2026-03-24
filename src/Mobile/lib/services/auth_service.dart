import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_config.dart';

/// WebApi `Login.vue` ile aynı OAuth2 password grant + kayıt uçları.
class AuthService {
  AuthService(this._prefs);

  final SharedPreferences _prefs;

  static const _keyToken = 'auth.token';
  static const _keyExpires = 'auth.expiresAt';

  String? get token => _prefs.getString(_keyToken);

  int? get expiresAtMs {
    final s = _prefs.getString(_keyExpires);
    if (s == null || s.isEmpty) return null;
    return int.tryParse(s);
  }

  bool get isTokenValid {
    final t = token;
    if (t == null || t.isEmpty) return false;
    final exp = expiresAtMs;
    if (exp == null) return true;
    return DateTime.now().millisecondsSinceEpoch < exp;
  }

  Future<void> hydrate() async {}

  Future<void> saveSession(String accessToken, int? expiresInSeconds) async {
    await _prefs.setString(_keyToken, accessToken);
    if (expiresInSeconds != null) {
      final at = DateTime.now().millisecondsSinceEpoch + expiresInSeconds * 1000;
      await _prefs.setString(_keyExpires, at.toString());
    } else {
      await _prefs.remove(_keyExpires);
    }
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyExpires);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final dio = Dio(
      BaseOptions(
        contentType: Headers.formUrlEncodedContentType,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    final form = {
      'grant_type': 'password',
      'client_id': 'artemis.client',
      'client_secret': 'artemis_secret',
      'username': email.trim(),
      'password': password,
      'scope': 'openid profile email roles artemis.api',
    };
    try {
      final resp = await dio.post<Map<String, dynamic>>(
        '${ApiConfig.identityBaseUrl}/identity/connect/token',
        data: form,
      );
      if (resp.statusCode != 200 || resp.data == null) {
        throw AuthException(_parseTokenError(resp.data, resp.statusMessage));
      }
      final access = resp.data!['access_token'] as String?;
      final expiresIn = resp.data!['expires_in'];
      if (access == null) {
        throw AuthException('Geçersiz giriş yanıtı');
      }
      final exp = expiresIn is int ? expiresIn : int.tryParse('$expiresIn');
      await saveSession(access, exp);
    } on DioException catch (e) {
      throw AuthException(_parseTokenError(e.response?.data, e.message));
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final dio = Dio();
    final body = {
      'Email': email.trim(),
      'Password': password,
      'PartyName': email.trim(),
      'PartyType': 1,
      'DeviceId': null,
      'IsBanned': false,
    };
    try {
      await dio.post<void>(
        '${ApiConfig.identityBaseUrl}/identity/account/register',
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } on DioException catch (e) {
      throw AuthException(_parseRegisterError(e.response?.data));
    }
    try {
      await login(email: email, password: password);
    } on AuthException catch (e) {
      await clearSession();
      throw AuthException(
        'Hesabınız oluşturuldu. Giriş yapmayı deneyin.\n${e.message}',
      );
    }
  }

  String _parseTokenError(dynamic data, String? fallback) {
    if (data is Map) {
      final err = data['error_description'] ?? data['error'];
      if (err != null) return err.toString();
    }
    return fallback ?? 'Giriş başarısız';
  }

  String _parseRegisterError(dynamic data) {
    if (data is Map) {
      final err = data['error'];
      if (err != null) return err.toString();
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }
    if (data is String && data.isNotEmpty) return data;
    return 'Kayıt başarısız';
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
