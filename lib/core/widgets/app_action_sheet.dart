import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_bottom_sheet.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';

class AppActionItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? tintColor;
  final bool isDestructive;
  final VoidCallback onTap;

  const AppActionItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.tintColor,
    this.isDestructive = false,
    required this.onTap,
  });
}

class AppActionSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? headerLeading;
  final List<AppActionItem> actions;

  const AppActionSheet({
    super.key,
    this.title,
    this.subtitle,
    this.headerLeading,
    required this.actions,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? subtitle,
    Widget? headerLeading,
    required List<AppActionItem> actions,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => AppActionSheet(
        title: title,
        subtitle: subtitle,
        headerLeading: headerLeading,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;

    // Separate normal actions and destructive actions
    final normalActions = actions.where((a) => !a.isDestructive).toList();
    final destructiveActions = actions.where((a) => a.isDestructive).toList();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: AppRadius.radiusXxl,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: p.isDark ? 0.45 : 0.15),
              blurRadius: 32,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle Indicator
            const AppSheetHandle(
              margin: EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
            ),

            // Header Section
            if (title != null || subtitle != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    if (headerLeading != null) ...[
                      headerLeading!,
                      AppSpacing.gapW12,
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            AppText(
                              title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: p.heading,
                              ),
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            AppText(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall?.copyWith(
                                fontSize: 12,
                                color: p.caption,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: p.caption,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(color: p.divider, height: 1),
            ],

            // Action Items Group
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  ...normalActions.map(
                    (action) => _buildActionTile(context, action, p, text),
                  ),
                  if (destructiveActions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: AppSpacing.sm,
                      ),
                      child: Divider(color: p.divider, height: 1),
                    ),
                    ...destructiveActions.map(
                      (action) => _buildActionTile(context, action, p, text),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    AppActionItem action,
    AppPalette p,
    TextTheme text,
  ) {
    final effectiveColor = action.isDestructive
        ? AppColors.error
        : (action.tintColor ?? p.heading);

    final iconBgColor = action.isDestructive
        ? AppColors.error.withValues(alpha: 0.12)
        : (action.tintColor != null
              ? action.tintColor!.withValues(alpha: 0.12)
              : p.surfaceMuted);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop();
          action.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              // Icon Badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Icon(action.icon, size: 19, color: effectiveColor),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      action.title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: effectiveColor,
                      ),
                    ),
                    if (action.subtitle != null) ...[
                      const SizedBox(height: 2),
                      AppText(
                        action.subtitle!,
                        style: text.labelSmall?.copyWith(color: p.caption),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: p.caption.withValues(alpha: p.isDark ? 0.4 : 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
