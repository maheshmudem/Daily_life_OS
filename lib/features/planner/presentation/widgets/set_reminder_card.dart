import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';

class SetReminderCard extends StatelessWidget {
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
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark
              ? AppColors.darkDivider
              : AppColors.moduleTime.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.alarm_add_rounded,
                    color: AppColors.moduleTime,
                    size: 16,
                  ),
                  AppSpacing.gapW8,
                  Text(
                    StringConstants.setReminder.toUpperCase(),
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.moduleTime,
                      fontSize: 10.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: AppRadius.radiusXs,
                onTap: onOpenFullOptions,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Full Options',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH8,

          // Input field
          TextField(
            controller: controller,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: StringConstants.reminderHint,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color:
                    isDark ? AppColors.darkTextCaption : AppColors.textCaption,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          AppSpacing.gapH8,

          // Quick Action Pills Row
          Row(
            children: [
              GestureDetector(
                onTap: onPickTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.moduleTime.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusXs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.moduleTime),
                      AppSpacing.gapW4,
                      Text(
                        _formatTimeOfDay(selectedTime),
                        style: AppTextStyles.captionBold.copyWith(
                          fontSize: 11,
                          color: AppColors.moduleTime,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapW8,
              GestureDetector(
                onTap: onCycleCategory,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusXs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon, size: 13, color: categoryColor),
                      AppSpacing.gapW4,
                      Text(
                        selectedCategory,
                        style: AppTextStyles.captionBold.copyWith(
                          fontSize: 11,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moduleTime,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusSm,
                  ),
                ),
                icon:
                    const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                label: Text(
                  StringConstants.setReminder,
                  style: AppTextStyles.captionBold.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
