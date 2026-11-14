import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/theme_context.dart';

/// Compact section header row matching `docs/expensetracker-main` (`15px w600`
/// title + `13px w600` primary action link).
class MoneySectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const MoneySectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: AppText(
              title,
              softWrap: true,
              style: text.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: p.heading,
              ),
            ),
          ),
          ?trailing,
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: AppText(
                actionLabel!,
                style: text.labelMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
