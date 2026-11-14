import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/theme_context.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor,
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final effectiveConfirmColor =
        confirmColor ?? (isDestructive ? AppColors.error : AppColors.primary);

    return AlertDialog(
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      title: AppText(
        title,
        style: text.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.heading,
        ),
      ),
      content: AppText(
        message,
        style: text.bodyMedium?.copyWith(color: p.body),
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: AppText(
            cancelLabel,
            style: text.labelLarge?.copyWith(color: p.caption),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          child: AppText(
            confirmLabel,
            style: text.labelLarge?.copyWith(
              color: effectiveConfirmColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
