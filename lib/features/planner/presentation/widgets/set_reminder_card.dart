import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';

/// Inline "quick add" card at the top of the Reminders tab.
class SetReminderCard extends StatelessWidget {
  /// Shared height for the time/category chips and the submit button.
  static const double _controlHeight = 36;

  final TextEditingController controller;
  final TimeOfDay selectedTime;
  final String selectedCategory;
  final Color categoryColor;
  final IconData categoryIcon;
  final bool isDark;
  final VoidCallback onPickTime;
  final VoidCallback onCycleCategory;
  final VoidCallback onSubmit;
  final VoidCallback onOpenFullOptions;

  const SetReminderCard({
    super.key,
    required this.controller,
    required this.selectedTime,
    required this.selectedCategory,
    required this.categoryColor,
    required this.categoryIcon,
    required this.isDark,
    required this.onPickTime,
    required this.onCycleCategory,
    required this.onSubmit,
    required this.onOpenFullOptions,
  });

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final captionColor = isDark
        ? AppColors.darkTextCaption
        : AppColors.textCaption;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.alarm_add_rounded,
                color: AppColors.moduleTime,
                size: 18,
              ),
              AppSpacing.gapW8,
              Text(
                StringConstants.setReminder.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.moduleTime,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: AppRadius.radiusXs,
                onTap: onOpenFullOptions,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Row(
                    children: [
                      Text(
                        'Full Options',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: captionColor,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: captionColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,

          // Input
          TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurfaceSecondary
                  : AppColors.surfaceSecondary,
              hintText: StringConstants.reminderHint,
              hintStyle: TextStyle(fontSize: 15, color: captionColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: const OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide.none,
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide(color: AppColors.moduleTime, width: 1.5),
              ),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          AppSpacing.gapH12,

          // Time · Category · Submit
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _OptionChip(
                      icon: Icons.schedule_rounded,
                      label: _formatTimeOfDay(selectedTime),
                      color: AppColors.moduleTime,
                      onTap: onPickTime,
                    ),
                    AppSpacing.gapW8,
                    Flexible(
                      child: _OptionChip(
                        icon: categoryIcon,
                        label: selectedCategory,
                        color: categoryColor,
                        onTap: onCycleCategory,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapW8,
              FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moduleTime,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, _controlHeight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusSm,
                  ),
                  textStyle: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text(StringConstants.setReminder),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: AppRadius.radiusSm,
      child: InkWell(
        borderRadius: AppRadius.radiusSm,
        onTap: onTap,
        child: Container(
          height: SetReminderCard._controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              AppSpacing.gapW4,
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
