import 'package:flutter/material.dart';

import '../core/util/subscription_display.dart';

class SubscriptionTierBadge extends StatelessWidget {
  const SubscriptionTierBadge({
    super.key,
    required this.subscriptionType,
    this.compact = true,
  });

  final int? subscriptionType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = subscriptionType;
    if (t == null) return const SizedBox.shrink();
    final c = subscriptionTierColor(t);
    final label = subscriptionTierShortTr(t);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: compact ? 14 : 15, color: c),
          SizedBox(width: compact ? 4 : 5),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
