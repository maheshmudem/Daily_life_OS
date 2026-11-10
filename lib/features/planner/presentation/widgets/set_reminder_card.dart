import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';

/// Inline "quick add" card at the top of the Reminders tab.
///
/// Three rows on an 8pt grid: a plain title with a "Full options" link, a
/// 40dp input, and a 32dp control row (time · category · submit).
class SetReminderCard extends StatelessWidget {
  static const double _controlHeight = 32;

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
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final captionColor = isDark
        ? AppColors.darkTextCaption
        : AppColors.textCaption;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final fieldFill = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.surfaceSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title · Full options
          Row(
            children: [
              Expanded(
                child: Text(
                  StringConstants.setReminder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: headingColor,
                  ),
                ),
              ),
              InkWell(
                borderRadius: AppRadius.radiusXs,
                onTap: onOpenFullOptions,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 2, 2, 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Full options',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.moduleTime,
                        ),
                      ),
                      const SizedBox(width: 1),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: AppColors.moduleTime.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Input
          SizedBox(
            height: 40,
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: headingColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: fieldFill,
                hintText: StringConstants.reminderHint,
                hintStyle: TextStyle(fontSize: 13, color: captionColor),
                prefixIcon: const Icon(
                  Icons.alarm_add_rounded,
                  size: 17,
                  color: AppColors.moduleTime,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 38,
                  minHeight: 38,
                ),
                contentPadding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.radiusSm,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.radiusSm,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.radiusSm,
                  borderSide: BorderSide(
                    color: AppColors.moduleTime,
                    width: 1.2,
                  ),
                ),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(height: 10),

          // Time · Category · Submit
          Row(
            children: [
              // The chip group owns the slack width; the category chip keeps
              // its natural width and only truncates when the row is too narrow.
              Expanded(
                child: Row(
                  children: [
                    _OptionChip(
                      icon: Icons.schedule_rounded,
                      label: _formatTimeOfDay(selectedTime),
                      color: AppColors.moduleTime,
                      isDark: isDark,
                      onTap: onPickTime,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _OptionChip(
                        icon: categoryIcon,
                        label: selectedCategory,
                        color: categoryColor,
                        isDark: isDark,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
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
  final bool isDark;
  final VoidCallback onTap;

  const _OptionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: isDark ? 0.2 : 0.11),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          height: SetReminderCard._controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
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
