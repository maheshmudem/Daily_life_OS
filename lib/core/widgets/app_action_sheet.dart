import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';

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
      backgroundColor: Colors.transparent,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    // Separate normal actions and destructive actions
    final normalActions = actions.where((a) => !a.isDestructive).toList();
    final destructiveActions = actions.where((a) => a.isDestructive).toList();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
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
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
            ),

            // Header Section
            if (title != null || subtitle != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  children: [
                    if (headerLeading != null) ...[
                      headerLeading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkTextHeading
                                    : AppColors.textHeading,
                              ),
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextCaption
                                    : AppColors.textCaption,
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
                      color: isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(color: dividerColor, height: 1),
            ],

            // Action Items Group
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: [
                  ...normalActions.map((action) => _buildActionTile(context, action, isDark)),
                  if (destructiveActions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Divider(color: dividerColor, height: 1),
                    ),
                    ...destructiveActions
                        .map((action) => _buildActionTile(context, action, isDark)),
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
      BuildContext context, AppActionItem action, bool isDark) {
    final effectiveColor = action.isDestructive
        ? AppColors.error
        : (action.tintColor ??
            (isDark ? AppColors.darkTextHeading : AppColors.textHeading));

    final iconBgColor = action.isDestructive
        ? AppColors.error.withValues(alpha: 0.12)
        : (action.tintColor != null
            ? action.tintColor!.withValues(alpha: 0.12)
            : (isDark
                ? AppColors.darkSurfaceSecondary
                : AppColors.surfaceSecondary));

    return Material(
      color: Colors.transparent,
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  action.icon,
                  size: 19,
                  color: effectiveColor,
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: effectiveColor,
                      ),
                    ),
                    if (action.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        action.subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark
                    ? AppColors.darkTextCaption.withValues(alpha: 0.4)
                    : AppColors.textCaption.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
