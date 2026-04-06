import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import 'jwt_subscription.dart';
import 'paged_result.dart';

/// Oda oluşturma: yalnızca Gold (2) ve Platinum (3).
bool canCreateRoom(int? subscriptionType) {
  return subscriptionType == 2 || subscriptionType == 3;
}

/// Konu oluşturma: oda ile aynı kural (Gold / Platinum).
bool canCreateTopic(int? subscriptionType) => canCreateRoom(subscriptionType);

/// Kategori oluşturma: oda / konu ile aynı kural (Gold / Platinum).
bool canCreateCategory(int? subscriptionType) => canCreateRoom(subscriptionType);

/// JWT’de claim varsa onu kullan; yoksa party lookup (e-posta) ile doldurur.
Future<int?> resolveMySubscriptionTypeForRoomCreate(
  AppServices app,
  String? token,
  String? email,
) async {
  final jwt = tryParseSubscriptionTypeFromJwt(token);
  if (jwt != null) return jwt;
  if (email == null || email.trim().isEmpty) return null;
  try {
    final data = await app.parties.getLookup({
      'searchText': email.trim(),
      'partyLookupSearchType': 3,
    });
    final list = asMapList(data);
    if (list.isEmpty) return null;
    final m = list.first;
    final v = m['subscriptionType'] ?? m['SubscriptionType'];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  } catch (_) {
    return null;
  }
}

Future<void> showRoomCreateNotAllowedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Oda oluşturamazsınız'),
      content: const Text(
        'Oda oluşturma yalnızca Gold ve Platinum üyeler içindir. '
        'Silver ile oda açamazsınız; paketinizi Gold veya Platinum’a yükseltebilirsiniz.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
}

Future<void> showTopicCreateNotAllowedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Konu oluşturamazsınız'),
      content: const Text(
        'Konu oluşturma yalnızca Gold ve Platinum üyeler içindir. '
        'Silver ile konu açamazsınız; paketinizi Gold veya Platinum’a yükseltebilirsiniz.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
}

Future<void> showCategoryCreateNotAllowedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Kategori oluşturamazsınız'),
      content: const Text(
        'Kategori oluşturma yalnızca Gold ve Platinum üyeler içindir. '
        'Silver ile kategori açamazsınız; paketinizi Gold veya Platinum’a yükseltebilirsiniz.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
}
