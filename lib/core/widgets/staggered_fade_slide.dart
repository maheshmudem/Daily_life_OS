import 'package:flutter/material.dart';

/// Test-safe staggered fade + upward slide entrance animation.
///
/// Uses [TweenAnimationBuilder] with an index-scaled duration rather than
/// `Future.delayed` timers so `WidgetTester.pumpAndSettle()` always completes
/// deterministically without pending timer assertions.
class StaggeredFadeSlide extends StatelessWidget {
  final int index;
  final Widget child;
  final double verticalOffset;
  final Duration baseDuration;

  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.verticalOffset = 6.0,
    this.baseDuration = const Duration(milliseconds: 120),
  });

  @override
  Widget build(BuildContext context) {
    final clampedIndex = index.clamp(0, 6);
    final totalMs = baseDuration.inMilliseconds + (clampedIndex * 18);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: totalMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, builtChild) {
        return Transform.translate(
          offset: Offset(0, (1.0 - t) * verticalOffset),
          child: builtChild,
        );
      },
      child: child,
    );
  }
}

/// Subtle tactile spring-scale wrapper for interactive cards, pills, and tiles.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.975,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
