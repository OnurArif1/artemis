import 'package:flutter/material.dart';

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

Color mapRoomMarkerFill(int? subscriptionType) {
  return switch (subscriptionType) {
    null => const Color(0xFF9CA3AF),
    0 => const Color(0xFF6B7280),
    1 => const Color(0xFF475569),
    2 => const Color(0xFFD97706),
    3 => const Color(0xFF6D28D9),
    _ => const Color(0xFF6B7280),
  };
}

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
