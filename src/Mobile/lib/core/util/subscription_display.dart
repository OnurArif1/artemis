import 'package:flutter/material.dart';

/// Backend `SubscriptionType`: None=0, Silver=1, Gold=2, Platinum=3
int? parseSubscriptionType(Map<String, dynamic> m) {
  final v = m['subscriptionType'] ?? m['SubscriptionType'];
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

String subscriptionTierLabelTr(int? type) {
  return switch (type) {
    null => 'Belirtilmedi',
    0 => 'Üyelik gerektirmez',
    1 => 'Silver',
    2 => 'Gold',
    3 => 'Platinum',
    _ => 'Seviye $type',
  };
}

/// Rozet metni (kısa)
String subscriptionTierShortTr(int? type) {
  return switch (type) {
    null => '—',
    0 => 'Herkes',
    1 => 'Silver+',
    2 => 'Gold+',
    3 => 'Platinum',
    _ => '$type',
  };
}

Color subscriptionTierColor(int? type) {
  return switch (type) {
    null => const Color(0xFF6B7280),
    0 => const Color(0xFF6B7280),
    1 => const Color(0xFF64748B),
    2 => const Color(0xFFD97706),
    3 => const Color(0xFF7C3AED),
    _ => const Color(0xFF6B7280),
  };
}

/// Yakınlaştırılmış haritada oda pin dolgusu (kapı ikonu beyaz).
Color mapRoomMarkerFill(int? subscriptionType) {
  return switch (subscriptionType) {
    null => const Color(0xFF9CA3AF), // API’de yok — belirsiz
    0 => const Color(0xFF6B7280), // herkes
    1 => const Color(0xFF475569), // slate
    2 => const Color(0xFFD97706), // gold
    3 => const Color(0xFF6D28D9), // platinum (konu lavanta pininden ayrı)
    _ => const Color(0xFF6B7280),
  };
}

/// Pin köşesindeki tek harf; `null` API = `?`, 0 = rozet yok.
String? mapRoomMarkerBadgeLetter(int? subscriptionType) {
  return switch (subscriptionType) {
    null => '?',
    0 => null,
    1 => 'S',
    2 => 'G',
    3 => 'P',
    _ => null,
  };
}
