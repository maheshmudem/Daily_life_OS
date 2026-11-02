import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Resolved light/dark colour roles for the current [BuildContext].
///
/// Replaces the `isDark ? AppColors.darkX : AppColors.x` ternaries that were
/// repeated across every widget.
@immutable
class AppPalette {
  final bool isDark;
  final Color scaffold;
  final Color card;
  final Color surfaceMuted;
  final Color divider;
  final Color border;
  final Color heading;
  final Color body;
  final Color secondary;
  final Color caption;
  final Color icon;

  const AppPalette._({
    required this.isDark,
    required this.scaffold,
    required this.card,
    required this.surfaceMuted,
    required this.divider,
    required this.border,
    required this.heading,
    required this.body,
    required this.secondary,
    required this.caption,
    required this.icon,
  });

  static const AppPalette light = AppPalette._(
    isDark: false,
    scaffold: AppColors.scaffoldBackground,
    card: AppColors.cardBackground,
    surfaceMuted: AppColors.surfaceSecondary,
    divider: AppColors.divider,
    border: AppColors.border,
    heading: AppColors.textHeading,
    body: AppColors.textBody,
    secondary: AppColors.textSecondary,
    caption: AppColors.textCaption,
    icon: AppColors.iconColor,
  );

  static const AppPalette dark = AppPalette._(
    isDark: true,
    scaffold: AppColors.darkScaffoldBackground,
    card: AppColors.darkCardBackground,
    surfaceMuted: AppColors.darkSurfaceSecondary,
    divider: AppColors.darkDivider,
    border: AppColors.darkBorder,
    heading: AppColors.darkTextHeading,
    body: AppColors.darkTextBody,
    secondary: AppColors.darkTextSecondary,
    caption: AppColors.darkTextCaption,
    icon: AppColors.darkIconColor,
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Short-hands for the theme: `context.text.titleMedium`, `context.palette.card`.
extension ThemeContextX on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
  AppPalette get palette => AppPalette.of(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
