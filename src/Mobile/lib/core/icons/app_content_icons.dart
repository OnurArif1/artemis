import 'package:flutter/material.dart';

/// Oda ve konu için uygulama genelinde kullanılan tutarlı ikonlar.
/// — Oda: tartışma/sohbet alanı (`forum`)
/// — Konu: başlık veya etiket (`tag`)
abstract final class AppContentIcons {
  AppContentIcons._();

  static const IconData room = Icons.forum_rounded;
  static const IconData roomOutlined = Icons.forum_outlined;

  static const IconData topic = Icons.tag_rounded;
  static const IconData topicOutlined = Icons.tag_outlined;
}
