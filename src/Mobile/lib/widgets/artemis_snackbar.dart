import 'package:flutter/material.dart';

void showAppSnackBar(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? const Color(0xFFB3261E) : const Color(0xFF1A1A1D),
    ),
  );
}
