import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';

/// Inline "quick add" card at the top of the Reminders tab.
///
/// Three rows on an 8pt grid: a header row (with optional active date target
/// badge + "Full options" link), a 40dp borderless input, and an adaptive
/// 32dp control row (time · category · priority · submit).
class SetReminderCard extends StatelessWidget {
  static const double _controlHeight = 32;

  final TextEditingController controller;
  final TimeOfDay selectedTime;
  final String selectedCategory;
  final Color categoryColor;
  final IconData categoryIcon;
  final String selectedPriority;
  final String? targetDateLabel;
  final bool isDark;
  final VoidCallback onPickTime;
  final VoidCallback onCycleCategory;
  final VoidCallback? onCyclePriority;
  final VoidCallback? onClearTargetDate;
  final VoidCallback onSubmit;
  final VoidCallback onOpenFullOptions;

  const SetReminderCard({
    super.key,
    required this.controller,
    required this.selectedTime,
    required this.selectedCategory,
    required this.categoryColor,
    required this.categoryIcon,
    this.selectedPriority = 'medium',
    this.targetDateLabel,
    required this.isDark,
    required this.onPickTime,
    required this.onCycleCategory,
    this.onCyclePriority,
    this.onClearTargetDate,
    required this.onSubmit,
    required this.onOpenFullOptions,
  });

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  ({String label, Color color}) _priorityVisual(String p) {
    switch (p) {
      case 'urgent':
        return (label: 'Urgent', color: AppColors.error);
      case 'high':
        return (label: 'High', color: AppColors.focusPomodoro);
      case 'low':
        return (label: 'Low', color: AppColors.success);
      case 'medium':
      default:
        return (label: 'Med', color: AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final headingColor = palette.heading;
    final captionColor = palette.caption;
    final borderColor = palette.divider;
    final fieldFill = palette.surfaceMuted;
    final prio = _priorityVisual(selectedPriority);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title · Active Date Pill · Full options ──────────────────────
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: AppText(
                        StringConstants.setReminder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: headingColor,
                        ),
                      ),
                    ),
                    if (targetDateLabel != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: InkWell(
                          borderRadius: AppRadius.radiusFull,
                          onTap: onClearTargetDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.moduleTime.withValues(
                                alpha: palette.isDark ? 0.22 : 0.12,
                              ),
                              borderRadius: AppRadius.radiusFull,
                              border: Border.all(
                                color: AppColors.moduleTime.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.event_rounded,
                                  size: 11,
                                  color: AppColors.moduleTime,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: AppText.captionBold(
                                    targetDateLabel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.moduleTime,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: AppRadius.radiusXs,
                onTap: onOpenFullOptions,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 2, 2, 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppText.captionBold(
                        'Full options',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.moduleTime,
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

          // ── Input ────────────────────────────────────────────────────────
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: fieldFill,
              borderRadius: AppRadius.radiusSm,
              border: Border.all(color: borderColor.withValues(alpha: 0.7)),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: headingColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: StringConstants.reminderHint,
                hintStyle: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: captionColor,
                ),
                prefixIcon: const Icon(
                  Icons.alarm_add_rounded,
                  size: 17,
                  color: AppColors.moduleTime,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 38,
                  minHeight: 38,
                ),
                contentPadding: const EdgeInsets.fromLTRB(0, 9, 12, 9),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(height: 10),

          // ── Time · Category · Priority · Submit (Narrow-Safe) ────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final chipsScroll = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OptionChip(
                      icon: Icons.schedule_rounded,
                      label: _formatTimeOfDay(selectedTime),
                      color: AppColors.moduleTime,
                      isDark: palette.isDark,
                      onTap: onPickTime,
                    ),
                    const SizedBox(width: 8),
                    _OptionChip(
                      icon: categoryIcon,
                      label: selectedCategory,
                      color: categoryColor,
                      isDark: palette.isDark,
                      onTap: onCycleCategory,
                    ),
                    if (onCyclePriority != null) ...[
                      const SizedBox(width: 8),
                      _OptionChip(
                        icon: Icons.flag_rounded,
                        label: prio.label,
                        color: prio.color,
                        isDark: palette.isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onCyclePriority!();
                        },
                      ),
                    ],
                  ],
                ),
              );

              final submitBtn = FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moduleTime,
                  foregroundColor: AppColors.textWhite,
                  elevation: 0,
                  minimumSize: const Size(0, _controlHeight),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  textStyle: context.text.captionBold.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const AppText(StringConstants.setReminder),
              );

              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [chipsScroll, const SizedBox(height: 8), submitBtn],
                );
              }

              return Row(
                children: [
                  Expanded(child: chipsScroll),
                  const SizedBox(width: 8),
                  submitBtn,
                ],
              );
            },
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
              AppText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
