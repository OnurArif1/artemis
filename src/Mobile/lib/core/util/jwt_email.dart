import 'package:jwt_decoder/jwt_decoder.dart';

/// WebApi `getEmailFromToken` ile uyumlu: `email` veya `sub`.
String? emailFromAccessToken(String? token) {
  if (token == null || token.isEmpty) return null;
  try {
    final m = JwtDecoder.decode(token);
    final e = m['email'] ?? m['sub'];
    if (e == null) return null;
    final s = e.toString().trim();
    return s.isEmpty ? null : s;
  } catch (_) {
    return null;
  }
}
