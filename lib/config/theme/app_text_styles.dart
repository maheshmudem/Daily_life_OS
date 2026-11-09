import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design tokens for typography in Daily Life OS.
///
/// One type scale for the whole app, built on the DMSans variable font.
/// The scale follows the sizes used by mainstream iOS / Material apps:
///
/// | Token          | Size | Weight | Typical use                         |
/// |----------------|------|--------|-------------------------------------|
/// | headingLarge   | 24   | 700    | Hero numbers, onboarding titles     |
/// | headingMedium  | 20   | 700    | Page titles (FeatureScaffold)       |
/// | headingSmall   | 18   | 600    | Sheet / dialog titles               |
/// | titleLarge     | 17   | 600    | Card hero values                    |
/// | titleMedium    | 15   | 600    | Section headers, card titles        |
/// | titleSmall     | 14   | 600    | List-row titles                     |
/// | bodyLarge      | 16   | 400    | Inputs, long-form reading           |
/// | bodyMedium     | 14   | 400    | Default body copy                   |
/// | bodySmall      | 13   | 400    | Secondary copy, subtitles           |
/// | caption        | 12   | 500    | Metadata, helper text               |
/// | overline/label | 11   | 600    | Eyebrows, tiny tags                 |
///
/// The constants below carry *light-mode* colours for backwards compatibility.
/// New code should prefer `context.text.*` (see `theme_context.dart`), which
/// resolves the same sizes with the correct light/dark colour automatically.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'DMSans';

  // ==========================================
  // HERO & STAT NUMERALS (CURRENCY & TIMERS)
  // ==========================================
  static const TextStyle currencyHero = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.8,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle timerHero = TextStyle(
    fontFamily: fontFamily,
    fontSize: 52,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle monoCode = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: 0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ==========================================
  // DISPLAY & HEADINGS
  // ==========================================
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.6,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // ==========================================
  // TITLES & SUBTITLES
  // ==========================================
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.25,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
    letterSpacing: -0.1,
    height: 1.3,
  );

  // ==========================================
  // BODY & CONTENT
  // ==========================================
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.4,
  );

  // ==========================================
  // CAPTIONS, LABELS & OVERLINES
  // ==========================================
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textCaption,
    height: 1.35,
  );

  static const TextStyle captionBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textCaption,
    height: 1.35,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textCaption,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textCaption,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = label;

  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle linkText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ==========================================
  // THEME-AWARE TEXT THEME
  // ==========================================

  /// Builds the Material [TextTheme] for the given [brightness] so every
  /// Material widget (buttons, inputs, tabs, chips, list tiles, snackbars)
  /// renders DMSans at the same scale in both light and dark mode.
  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final heading = isDark ? AppColors.darkTextHeading : AppColors.textHeading;
    final body = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final muted = isDark ? AppColors.darkTextCaption : AppColors.textCaption;

    return TextTheme(
      displayLarge: displayLarge.copyWith(color: heading),
      displayMedium: displayMedium.copyWith(color: heading),
      displaySmall: headingLarge.copyWith(color: heading),
      headlineLarge: headingLarge.copyWith(color: heading),
      headlineMedium: headingMedium.copyWith(color: heading),
      headlineSmall: headingSmall.copyWith(color: heading),
      titleLarge: titleLarge.copyWith(color: heading),
      titleMedium: titleMedium.copyWith(color: heading),
      titleSmall: titleSmall.copyWith(color: heading),
      bodyLarge: bodyLarge.copyWith(color: body),
      bodyMedium: bodyMedium.copyWith(color: body),
      bodySmall: bodySmall.copyWith(color: muted),
      labelLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ).copyWith(color: heading),
      labelMedium: caption.copyWith(color: muted),
      labelSmall: overline.copyWith(color: muted),
    );
  }
}
