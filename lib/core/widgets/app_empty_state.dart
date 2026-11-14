import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final tint = iconColor ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: p.isDark ? 0.18 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: tint),
            ),
            AppSpacing.gapH20,
            AppText(
              title,
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(color: p.heading),
            ),
            AppSpacing.gapH8,
            AppText(
              description,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: p.caption),
            ),
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.gapH24,
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tint,
                  foregroundColor: AppColors.textWhite,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: AppText(
                  actionLabel!,
                  style: text.labelLarge?.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
