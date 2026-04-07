import 'package:jwt_decoder/jwt_decoder.dart';

String? _firstString(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return null;
}

/// Party / API aramaları için gerçek e-posta.
/// `sub` çoğu zaman kullanıcı id’si olduğundan yalnızca `@` içeriyorsa kullanılır.
String? emailFromAccessToken(String? token) {
  if (token == null || token.isEmpty) return null;
  try {
    final m = JwtDecoder.decode(token);
    final fromClaim = _firstString(m, [
      'email',
      'Email',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
    ]);
    if (fromClaim != null) return fromClaim;

    final unique = _firstString(m, ['unique_name', 'preferred_username']);
    if (unique != null && unique.contains('@')) return unique;

    final sub = _firstString(m, ['sub']);
    if (sub != null && sub.contains('@')) return sub;

    return null;
  } catch (_) {
    return null;
  }
}
