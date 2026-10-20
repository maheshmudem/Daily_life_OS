import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';

/// Shimmer loading placeholder for smooth, state-of-the-art loading states.
class AppShimmerLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AppShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  const AppShimmerLoader.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = AppRadius.radiusFull;

  const AppShimmerLoader.card({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = AppRadius.radiusLg,
  });

  @override
  State<AppShimmerLoader> createState() => _AppShimmerLoaderState();
}

class _AppShimmerLoaderState extends State<AppShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary;
    final highlightColor = isDark
        ? AppColors.darkSurfaceMuted.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.85);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppRadius.radiusMd,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}
