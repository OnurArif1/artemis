import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/responsive_center.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.stepLabel,
    required this.headerIcon,
    required this.child,
    this.instruction,
  });

  final String title;
  final String stepLabel;
  final IconData headerIcon;
  final Widget child;
  final String? instruction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF3F0FF),
                  Colors.white,
                  Color(0xFFF3F0FF),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _Blob(
              size: 220,
              color: AppColors.purple500.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _Blob(
              size: 200,
              color: AppColors.purple700.withValues(alpha: 0.18),
            ),
          ),
          SafeArea(
            child: ResponsiveCenter(
              maxWidth: 720,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Material(
                elevation: 8,
                shadowColor: AppColors.purple900.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.purple500.withValues(alpha: 0.08),
                            AppColors.purple500.withValues(alpha: 0.02),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.purple500.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.purple500, AppColors.purple700],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple500.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(headerIcon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stepLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (instruction != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Text(
                          instruction!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
