import 'package:flutter/material.dart';

import '../core/icons/app_content_icons.dart';
import '../core/theme/app_colors.dart';

enum ContentKind { room, topic }

class ContentKindBadge extends StatelessWidget {
  const ContentKindBadge({
    super.key,
    required this.kind,
    this.compact = false,
  });

  final ContentKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isRoom = kind == ContentKind.room;
    final label = isRoom ? 'Oda' : 'Konu';
    final icon = isRoom ? AppContentIcons.room : AppContentIcons.topic;
    final bg = isRoom
        ? AppColors.purple600.withValues(alpha: 0.12)
        : const Color(0xFF0D9488).withValues(alpha: 0.14);
    final fg = isRoom ? AppColors.purple700 : const Color(0xFF0F766E);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: fg.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: fg),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 11 : 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
