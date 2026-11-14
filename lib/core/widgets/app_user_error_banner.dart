import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';
import '../constants/string_constants.dart';
import '../monitoring/app_monitor.dart';
import 'app_text.dart';

/// Global wrapper placed inside `MaterialApp.router(builder: ...)` that listens
/// to [AppMonitor.activeUserAlert] and shows a calm, plain-language recovery
/// card whenever an unexpected error occurs — without any technical words.
class AppMonitorUserErrorHost extends StatelessWidget {
  final Widget child;
  final AppMonitor? monitor;

  const AppMonitorUserErrorHost({super.key, required this.child, this.monitor});

  @override
  Widget build(BuildContext context) {
    final activeMonitor = monitor ?? AppMonitor.instance;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        ValueListenableBuilder<UserFriendlyError?>(
          valueListenable: activeMonitor.activeUserAlert,
          builder: (context, alert, _) {
            return IgnorePointer(
              ignoring: alert == null,
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (bannerChild, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0, -0.2),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slide,
                          child: bannerChild,
                        ),
                      );
                    },
                    child: alert == null
                        ? const SizedBox.shrink()
                        : Padding(
                            key: ValueKey<String>(
                              '${alert.category.name}_${alert.title}',
                            ),
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.pageGutter,
                              AppSpacing.sm,
                              AppSpacing.pageGutter,
                              0,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: AppUserErrorBanner(
                                error: alert,
                                onDismiss: activeMonitor.dismissUserAlert,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Calm, reassuring card presenting a [UserFriendlyError] strictly from the
/// user's perspective, with zero technical terminology.
class AppUserErrorBanner extends StatelessWidget {
  final UserFriendlyError error;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const AppUserErrorBanner({
    super.key,
    required this.error,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Material(
      key: const ValueKey('app_user_error_banner'),
      color: AppColors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: error.accentColor.withValues(
              alpha: palette.isDark ? 0.45 : 0.35,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: error.accentColor.withValues(
                      alpha: palette.isDark ? 0.22 : 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(error.icon, size: 19, color: error.accentColor),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        error.title,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.heading,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AppText(
                        error.message,
                        style: text.bodySmall?.copyWith(
                          color: palette.body,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  InkWell(
                    key: const ValueKey('close_user_error_banner_icon'),
                    borderRadius: AppRadius.radiusSm,
                    onTap: onDismiss,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: palette.caption,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: AppText.caption(
                    error.reassurance,
                    color: palette.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  TextButton(
                    key: const ValueKey('retry_user_error_banner_btn'),
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: AppText.captionBold(
                      error.actionLabel,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                if (onDismiss != null) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    key: const ValueKey('dismiss_user_error_banner_btn'),
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: palette.surfaceMuted.withValues(
                        alpha: palette.isDark ? 0.55 : 0.8,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusSm,
                      ),
                    ),
                    child: AppText.captionBold(
                      StringConstants.gotIt,
                      color: palette.heading,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
