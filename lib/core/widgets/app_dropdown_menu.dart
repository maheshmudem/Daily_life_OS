import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';

/// Compact, pixel-perfect dropdown item for [AppDropdownMenu].
/// Inspired by Apple Notes, Notion, and Linear menus.
class AppDropdownItem<T> extends PopupMenuItem<T> {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? tintColor;
  final bool isDestructive;
  final Widget? trailing;

  AppDropdownItem({
    super.key,
    required super.value,
    super.enabled = true,
    required this.icon,
    required this.label,
    this.subtitle,
    this.tintColor,
    this.isDestructive = false,
    this.trailing,
  }) : super(
         height: subtitle != null ? 44 : 34,
         padding: const EdgeInsets.symmetric(
           horizontal: AppSpacing.sm,
           vertical: 0,
         ),
         child: _AppDropdownItemContent(
           icon: icon,
           label: label,
           subtitle: subtitle,
           tintColor: tintColor,
           isDestructive: isDestructive,
           trailing: trailing,
         ),
       );
}

class _AppDropdownItemContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? tintColor;
  final bool isDestructive;
  final Widget? trailing;

  const _AppDropdownItemContent({
    required this.icon,
    required this.label,
    this.subtitle,
    this.tintColor,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = isDestructive
        ? AppColors.error
        : (tintColor ??
              (isDark ? AppColors.darkTextHeading : AppColors.textHeading));

    return Row(
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        AppSpacing.gapW8,

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                  letterSpacing: -0.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (trailing != null) ...[AppSpacing.gapW8, trailing!],
      ],
    );
  }
}

/// Compact 1px divider for [AppDropdownMenu].
class AppDropdownDivider extends PopupMenuEntry<Never> {
  @override
  final double height;
  final double indent;
  final double endIndent;

  const AppDropdownDivider({
    super.key,
    this.height = 6,
    this.indent = 6,
    this.endIndent = 6,
  });

  @override
  bool represents(dynamic value) => false;

  @override
  State<AppDropdownDivider> createState() => _AppDropdownDividerState();
}

class _AppDropdownDividerState extends State<AppDropdownDivider> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: widget.height,
      padding: EdgeInsets.symmetric(
        horizontal: widget.indent,
        vertical: (widget.height - 1) / 2,
      ),
      child: Divider(
        height: 1,
        thickness: 0.6,
        color: isDark ? AppColors.darkDivider : AppColors.divider,
      ),
    );
  }
}

/// Optional compact header for [AppDropdownMenu].
class AppDropdownHeader extends PopupMenuEntry<Never> {
  final String title;
  final String? subtitle;
  final Widget? leading;

  const AppDropdownHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
  });

  @override
  double get height => subtitle != null ? 38 : 28;

  @override
  bool represents(dynamic value) => false;

  @override
  State<AppDropdownHeader> createState() => _AppDropdownHeaderState();
}

class _AppDropdownHeaderState extends State<AppDropdownHeader> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          if (widget.leading != null) ...[widget.leading!, AppSpacing.gapW8],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionBold.copyWith(
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact, pixel-perfect dropdown popup menu with sleek floating elevation,
/// smooth rounded borders, native iOS/Notion feel, and haptic feedback.
class AppDropdownMenu<T> extends StatelessWidget {
  final Widget? icon;
  final Widget? child;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final Offset offset;
  final String? tooltip;
  final BoxConstraints? menuConstraints;

  const AppDropdownMenu({
    super.key,
    this.icon,
    this.child,
    required this.items,
    required this.onSelected,
    this.offset = const Offset(0, 4),
    this.tooltip,
    this.menuConstraints,
  });

  /// Imperatively display an [AppDropdownMenu] at a given tap or widget position.
  static Future<T?> show<T>(
    BuildContext context, {
    required RelativeRect position,
    required List<PopupMenuEntry<T>> items,
    T? initialValue,
    BoxConstraints? constraints,
  }) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCardBackground : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return showMenu<T>(
      context: context,
      position: position,
      items: items,
      initialValue: initialValue,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
      surfaceTintColor: Colors.transparent,
      color: bgColor,
      constraints:
          constraints ?? const BoxConstraints(minWidth: 155, maxWidth: 195),
      menuPadding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxs,
        horizontal: 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMd,
        side: BorderSide(color: borderColor, width: 0.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCardBackground : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    final effectiveChild =
        child ??
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(borderRadius: AppRadius.radiusXs),
          child:
              icon ??
              Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: isDark
                    ? AppColors.darkTextCaption
                    : AppColors.textCaption,
              ),
        );

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        highlightColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
      ),
      child: PopupMenuButton<T>(
        tooltip: tooltip ?? '',
        position: PopupMenuPosition.under,
        offset: offset,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
        surfaceTintColor: Colors.transparent,
        color: bgColor,
        constraints:
            menuConstraints ??
            const BoxConstraints(minWidth: 155, maxWidth: 195),
        menuPadding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxs,
          horizontal: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
          side: BorderSide(color: borderColor, width: 0.8),
        ),
        onSelected: (val) {
          HapticFeedback.selectionClick();
          onSelected(val);
        },
        itemBuilder: (context) => items,
        child: effectiveChild,
      ),
    );
  }
}
