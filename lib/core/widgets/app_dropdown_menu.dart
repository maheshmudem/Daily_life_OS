import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';

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
    final p = context.palette;
    final text = context.text;
    final effectiveColor = isDestructive
        ? AppColors.error
        : (tintColor ?? p.heading);

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
              AppText(
                label,
                style: text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                  letterSpacing: -0.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                AppText(
                  subtitle!,
                  style: text.labelSmall?.copyWith(
                    fontSize: 10,
                    color: p.caption,
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
    final p = context.palette;
    return Container(
      height: widget.height,
      padding: EdgeInsets.symmetric(
        horizontal: widget.indent,
        vertical: (widget.height - 1) / 2,
      ),
      child: Divider(height: 1, thickness: 0.6, color: p.divider),
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
    final p = context.palette;
    final text = context.text;
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
                AppText(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: p.heading,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 1),
                  AppText(
                    widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      fontSize: 10,
                      color: p.caption,
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
    final p = context.palette;

    return showMenu<T>(
      context: context,
      position: position,
      items: items,
      initialValue: initialValue,
      elevation: 8,
      shadowColor: AppColors.black.withValues(alpha: p.isDark ? 0.5 : 0.15),
      surfaceTintColor: AppColors.transparent,
      color: p.card,
      constraints:
          constraints ?? const BoxConstraints(minWidth: 155, maxWidth: 195),
      menuPadding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxs,
        horizontal: 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMd,
        side: BorderSide(color: p.divider, width: 0.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final effectiveChild =
        child ??
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(borderRadius: AppRadius.radiusXs),
          child:
              icon ??
              Icon(Icons.more_horiz_rounded, size: 18, color: p.caption),
        );

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: p.isDark
            ? AppColors.textWhite.withValues(alpha: 0.06)
            : AppColors.black.withValues(alpha: 0.04),
        highlightColor: p.isDark
            ? AppColors.textWhite.withValues(alpha: 0.04)
            : AppColors.black.withValues(alpha: 0.02),
      ),
      child: PopupMenuButton<T>(
        tooltip: tooltip ?? '',
        position: PopupMenuPosition.under,
        offset: offset,
        elevation: 8,
        shadowColor: AppColors.black.withValues(alpha: p.isDark ? 0.5 : 0.15),
        surfaceTintColor: AppColors.transparent,
        color: p.card,
        constraints:
            menuConstraints ??
            const BoxConstraints(minWidth: 155, maxWidth: 195),
        menuPadding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxs,
          horizontal: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
          side: BorderSide(color: p.divider, width: 0.8),
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
