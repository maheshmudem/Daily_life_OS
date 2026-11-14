import 'package:flutter/material.dart';

import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';

/// Standard drag handle displayed at the top of modal bottom sheets.
class AppSheetHandle extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const AppSheetHandle({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final handle = Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: p.border,
          borderRadius: AppRadius.radiusFull,
        ),
      ),
    );
    if (margin == null) return handle;
    return Padding(padding: margin!, child: handle);
  }
}

/// Shared surface container for modal bottom sheets with top-rounded corners,
/// safe bottom padding, and optional drag handle.
class AppBottomSheetContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showHandle;
  final Color? backgroundColor;

  const AppBottomSheetContainer({
    super.key,
    required this.child,
    this.padding,
    this.showHandle = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? p.card,
        borderRadius: AppRadius.topXxl,
      ),
      padding: padding ?? AppSpacing.edgeInsetsAllXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHandle)
            const AppSheetHandle(
              margin: EdgeInsets.only(bottom: AppSpacing.lg),
            ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
