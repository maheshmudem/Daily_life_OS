import 'package:flutter/material.dart';

/// Smoothly rolling numeric / currency text powered by [TweenAnimationBuilder]
/// with tabular figures (`FontFeature.tabularFigures()`), inspired by Copilot
/// Money, Apple Health, and Linear.
class AnimatedCountText extends StatelessWidget {
  final double value;
  final String Function(double value)? formatter;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;
  final TextAlign? textAlign;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 520),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.suffix = '',
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? DefaultTextStyle.of(context).style)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) {
        final formatted = formatter != null
            ? formatter!(animatedValue)
            : animatedValue.toStringAsFixed(0);
        return Text(
          '$prefix$formatted$suffix',
          textAlign: textAlign,
          style: effectiveStyle,
        );
      },
    );
  }
}
