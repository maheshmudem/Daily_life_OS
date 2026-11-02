import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';

/// Compact inline "quick add" card at the top of the Reminders tab.
/// Follows an 8pt/4pt spatial grid with 12px internal padding and 30px control pills.
class SetReminderCard extends StatelessWidget {
  static const double _controlHeight = 30;

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
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.moduleTime.withValues(alpha: 0.14),
                  borderRadius: AppRadius.radiusXs,
                ),
                child: const Icon(
                  Icons.alarm_add_rounded,
                  color: AppColors.moduleTime,
                  size: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                StringConstants.setReminder.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.moduleTime,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: AppRadius.radiusXs,
                onTap: onOpenFullOptions,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Full Options',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: captionColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: captionColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Compact Input Field
          SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextHeading
                    : AppColors.textHeading,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.surfaceSecondary,
                hintText: StringConstants.reminderHint,
                hintStyle: TextStyle(fontSize: 12.5, color: captionColor),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.moduleTime,
                    width: 1.2,
                  ),
                ),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(height: 8),

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
                    const SizedBox(width: 6),
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
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moduleTime,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, _controlHeight),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: SetReminderCard._controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13.5, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
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
