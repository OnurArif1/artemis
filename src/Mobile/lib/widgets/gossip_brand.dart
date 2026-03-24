import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class GossipBrand extends StatelessWidget {
  const GossipBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.darkCharcoal,
          letterSpacing: -0.3,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.purple50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.purple200),
          ),
          child: Icon(
            Icons.location_on_rounded,
            color: AppColors.purple500,
            size: compact ? 22 : 28,
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        Text('Ghossip', style: style?.copyWith(fontSize: compact ? 18 : 22)),
      ],
    );
  }
}
