import 'package:flutter/material.dart';

/// İki sütunlu büyük ekran düzeni (giriş sayfası).
class AuthBreakpoint {
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;
}
