import 'package:flutter/material.dart';

class AuthBreakpoint {
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;
}
