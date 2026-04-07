import 'package:jwt_decoder/jwt_decoder.dart';

int? tryParseSubscriptionTypeFromJwt(String? token) {
  if (token == null || token.isEmpty) return null;
  try {
    final m = JwtDecoder.decode(token);
    final v = m['subscription_type'] ??
        m['subscriptionType'] ??
        m['tier'] ??
        m['SubscriptionTier'];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = '$v'.toLowerCase();
    if (s.contains('platinum') || s == '3') return 3;
    if (s.contains('gold') || s == '2') return 2;
    if (s.contains('silver') || s == '1') return 1;
    return int.tryParse('$v');
  } catch (_) {
    return null;
  }
}
