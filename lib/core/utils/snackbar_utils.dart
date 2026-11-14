import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';

class SnackbarUtils {
  SnackbarUtils._();

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    EdgeInsetsGeometry? margin,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.success,
      duration: duration,
      margin: margin,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    EdgeInsetsGeometry? margin,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.error,
      duration: duration,
      margin: margin,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    EdgeInsetsGeometry? margin,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.warning,
      duration: duration,
      margin: margin,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    EdgeInsetsGeometry? margin,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.info,
      duration: duration,
      margin: margin,
    );
  }

  /// Displays a themed status message, optionally overriding [backgroundColor],
  /// [duration], or [margin] while using [AppText.bodyMedium] inside.
  static void showMessage(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    EdgeInsetsGeometry? margin,
  }) {
    showMessengerMessage(
      ScaffoldMessenger.of(context),
      message,
      backgroundColor: backgroundColor,
      duration: duration,
      margin: margin,
    );
  }

  /// Displays a themed status message using a pre-captured [ScaffoldMessengerState]
  /// (safe to invoke after async gaps without passing a stale [BuildContext]).
  static void showMessengerMessage(
    ScaffoldMessengerState messenger,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    EdgeInsetsGeometry? margin,
  }) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: AppText.bodyMedium(
          message,
          color: AppColors.textWhite,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        margin: margin ?? AppSpacing.edgeInsetsAllMd,
      ),
    );
  }

  static void showAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Color actionTextColor = AppColors.voiceWaveform,
    EdgeInsetsGeometry? margin,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: AppText.bodyMedium(
          message,
          color: AppColors.textWhite,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        margin:
            margin ??
            const EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              0,
              AppSpacing.pageGutter,
              AppSpacing.huge + AppSpacing.xl,
            ),
        duration: duration,
        action: SnackBarAction(
          label: actionLabel,
          textColor: actionTextColor,
          onPressed: onAction,
        ),
      ),
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
    EdgeInsetsGeometry? margin,
  }) {
    showMessengerMessage(
      ScaffoldMessenger.of(context),
      message,
      backgroundColor: backgroundColor,
      duration: duration,
      margin: margin,
    );
  }
}
