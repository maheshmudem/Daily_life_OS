import 'package:flutter/material.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/theme/theme_context.dart';

/// Semantic typography variants for [AppText] that automatically adapt
/// to the active light/dark theme via [ThemeContextX].
enum AppTextVariant {
  displayLarge,
  displayMedium,
  headingLarge,
  headingMedium,
  headingSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
  caption,
  captionBold,
  overline,
  monoCode,
  statValue,
  currencyHero,
  timerHero,
}

/// Centralized, theme-aware custom text widget for Daily Life OS.
///
/// Wraps Flutter's [Text] and [Text.rich] with `const` constructors so it can
/// be used inside `const` widget subtrees for maximum rendering performance,
/// while supporting semantic [AppTextVariant] constructors and inline style
/// overrides (`color`, `fontSize`, `fontWeight`, `letterSpacing`, `height`,
/// `decoration`, `tabularFigures`) without verbose `.copyWith(...)` boilerplate.
class AppText extends StatelessWidget {
  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  // Optional semantic variant & style overrides
  final AppTextVariant? variant;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final double? letterSpacing;
  final double? height;
  final TextDecoration? decoration;
  final Color? decorationColor;
  final List<FontFeature>? fontFeatures;
  final bool tabularFigures;

  const AppText(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.variant,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null;

  const AppText.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.variant,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : data = null;

  const AppText.displayLarge(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.displayLarge;

  const AppText.displayMedium(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.displayMedium;

  const AppText.headingLarge(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.headingLarge;

  const AppText.headingMedium(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.headingMedium;

  const AppText.headingSmall(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.headingSmall;

  const AppText.titleLarge(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.titleLarge;

  const AppText.titleMedium(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.titleMedium;

  const AppText.titleSmall(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.titleSmall;

  const AppText.bodyLarge(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.bodyLarge;

  const AppText.bodyMedium(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.bodyMedium;

  const AppText.bodySmall(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.bodySmall;

  const AppText.labelLarge(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.labelLarge;

  const AppText.labelMedium(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.labelMedium;

  const AppText.labelSmall(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.labelSmall;

  const AppText.caption(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.caption;

  const AppText.captionBold(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.captionBold;

  const AppText.overline(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = false,
  }) : textSpan = null,
       variant = AppTextVariant.overline;

  const AppText.monoCode(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = true,
  }) : textSpan = null,
       variant = AppTextVariant.monoCode;

  const AppText.statValue(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = true,
  }) : textSpan = null,
       variant = AppTextVariant.statValue;

  const AppText.currencyHero(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = true,
  }) : textSpan = null,
       variant = AppTextVariant.currencyHero;

  const AppText.timerHero(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.fontFeatures,
    this.tabularFigures = true,
  }) : textSpan = null,
       variant = AppTextVariant.timerHero;

  TextStyle? _resolveVariantStyle(BuildContext context) {
    final v = variant;
    if (v == null) return null;
    final textTheme = context.text;
    final palette = context.palette;

    switch (v) {
      case AppTextVariant.displayLarge:
        return textTheme.displayLarge ??
            AppTextStyles.displayLarge.copyWith(color: palette.heading);
      case AppTextVariant.displayMedium:
        return textTheme.displayMedium ??
            AppTextStyles.displayMedium.copyWith(color: palette.heading);
      case AppTextVariant.headingLarge:
        return textTheme.headlineLarge ??
            AppTextStyles.headingLarge.copyWith(color: palette.heading);
      case AppTextVariant.headingMedium:
        return textTheme.headlineMedium ??
            AppTextStyles.headingMedium.copyWith(color: palette.heading);
      case AppTextVariant.headingSmall:
        return textTheme.headlineSmall ??
            AppTextStyles.headingSmall.copyWith(color: palette.heading);
      case AppTextVariant.titleLarge:
        return textTheme.titleLarge ??
            AppTextStyles.titleLarge.copyWith(color: palette.heading);
      case AppTextVariant.titleMedium:
        return textTheme.titleMedium ??
            AppTextStyles.titleMedium.copyWith(color: palette.heading);
      case AppTextVariant.titleSmall:
        return textTheme.titleSmall ??
            AppTextStyles.titleSmall.copyWith(color: palette.heading);
      case AppTextVariant.bodyLarge:
        return textTheme.bodyLarge ??
            AppTextStyles.bodyLarge.copyWith(color: palette.body);
      case AppTextVariant.bodyMedium:
        return textTheme.bodyMedium ??
            AppTextStyles.bodyMedium.copyWith(color: palette.body);
      case AppTextVariant.bodySmall:
        return textTheme.bodySmall ??
            AppTextStyles.bodySmall.copyWith(color: palette.caption);
      case AppTextVariant.labelLarge:
        return textTheme.labelLarge ??
            AppTextStyles.labelLarge.copyWith(color: palette.heading);
      case AppTextVariant.labelMedium:
        return textTheme.labelMedium ??
            AppTextStyles.labelMedium.copyWith(color: palette.caption);
      case AppTextVariant.labelSmall:
        return textTheme.labelSmall ??
            AppTextStyles.labelSmall.copyWith(color: palette.caption);
      case AppTextVariant.caption:
        return textTheme.labelMedium ??
            AppTextStyles.caption.copyWith(color: palette.caption);
      case AppTextVariant.captionBold:
        return (textTheme.labelMedium ?? AppTextStyles.captionBold).copyWith(
          fontWeight: FontWeight.w600,
          color: palette.caption,
        );
      case AppTextVariant.overline:
        return textTheme.labelSmall ??
            AppTextStyles.overline.copyWith(color: palette.caption);
      case AppTextVariant.monoCode:
        return textTheme.monoCode.copyWith(color: palette.heading);
      case AppTextVariant.statValue:
        return textTheme.statValue.copyWith(color: palette.heading);
      case AppTextVariant.currencyHero:
        return textTheme.currencyHero.copyWith(color: palette.heading);
      case AppTextVariant.timerHero:
        return textTheme.timerHero.copyWith(color: palette.heading);
    }
  }

  TextStyle? _resolveEffectiveStyle(BuildContext context) {
    final variantStyle = _resolveVariantStyle(context);
    TextStyle? resolved;
    if (variantStyle != null && style != null) {
      resolved = variantStyle.merge(style);
    } else {
      resolved = style ?? variantStyle;
    }

    final hasOverrides =
        color != null ||
        fontSize != null ||
        fontWeight != null ||
        fontStyle != null ||
        letterSpacing != null ||
        height != null ||
        decoration != null ||
        decorationColor != null ||
        fontFeatures != null ||
        tabularFigures;

    if (!hasOverrides) {
      return resolved;
    }

    final effectiveFeatures =
        fontFeatures ??
        (tabularFigures
            ? const [FontFeature.tabularFigures()]
            : resolved?.fontFeatures);

    // Preserve button/theme DefaultTextStyle inheritance when bare AppText
    // overrides weight or size without specifying a variant or style.
    final base =
        resolved ?? const TextStyle(fontFamily: AppTextStyles.fontFamily);
    return base.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      fontFeatures: effectiveFeatures,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = _resolveEffectiveStyle(context);
    if (textSpan != null) {
      return Text.rich(
        textSpan!,
        style: effectiveStyle,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    return Text(
      data!,
      style: effectiveStyle,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
