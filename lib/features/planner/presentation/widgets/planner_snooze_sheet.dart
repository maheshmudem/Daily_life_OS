import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/planner_item_entity.dart';

class PlannerSnoozeChoice {
  final Duration duration;
  final String label;
  final bool moveDateToTomorrow;

  const PlannerSnoozeChoice({
    required this.duration,
    required this.label,
    this.moveDateToTomorrow = false,
  });
}

/// Refined Daily Life OS bottom sheet for snoozing a reminder.
class PlannerSnoozeSheet extends StatelessWidget {
  final PlannerItemEntity item;

  const PlannerSnoozeSheet({super.key, required this.item});

  static Future<PlannerSnoozeChoice?> show(
    BuildContext context, {
    required PlannerItemEntity item,
  }) {
    return showModalBottomSheet<PlannerSnoozeChoice>(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (_) => PlannerSnoozeSheet(item: item),
    );
  }

  String _formatTime(DateTime dt) {
    final tod = TimeOfDay.fromDateTime(dt);
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final now = DateTime.now();

    final in15m = now.add(const Duration(minutes: 15));
    final in1h = now.add(const Duration(hours: 1));
    final tonightTarget = DateTime(now.year, now.month, now.day, 20, 0);
    final tonightDiff = tonightTarget.isAfter(now)
        ? tonightTarget.difference(now)
        : const Duration(hours: 3);

    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowMorning = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      9,
      0,
    );
    final tomorrowDiff = tomorrowMorning.difference(now);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.pageGutter,
            AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppRadius.topXl,
            border: Border.all(color: palette.divider),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.divider,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
                AppSpacing.gapH12,
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.moduleTime.withValues(
                          alpha: palette.isDark ? 0.22 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.snooze_rounded,
                        size: 18,
                        color: AppColors.moduleTime,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            'Snooze Reminder',
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: palette.heading,
                            ),
                          ),
                          AppText(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 11.5,
                              color: palette.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: palette.icon,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SnoozeOptionTile(
                  icon: Icons.timer_10_rounded,
                  color: AppColors.moduleTime,
                  title: '15 Minutes',
                  subtitle: 'Alert at ${_formatTime(in15m)}',
                  onTap: () => Navigator.of(context).pop(
                    const PlannerSnoozeChoice(
                      duration: Duration(minutes: 15),
                      label: '15m',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SnoozeOptionTile(
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.primary,
                  title: '1 Hour',
                  subtitle: 'Alert at ${_formatTime(in1h)}',
                  onTap: () => Navigator.of(context).pop(
                    const PlannerSnoozeChoice(
                      duration: Duration(hours: 1),
                      label: '1 hour',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SnoozeOptionTile(
                  icon: Icons.nights_stay_rounded,
                  color: AppColors.moduleVault,
                  title: tonightTarget.isAfter(now) ? 'Tonight' : 'In 3 Hours',
                  subtitle: 'Alert at ${_formatTime(now.add(tonightDiff))}',
                  onTap: () => Navigator.of(context).pop(
                    PlannerSnoozeChoice(
                      duration: tonightDiff,
                      label: tonightTarget.isAfter(now) ? 'Tonight' : '3 hours',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SnoozeOptionTile(
                  icon: Icons.wb_sunny_rounded,
                  color: AppColors.success,
                  title: 'Tomorrow Morning',
                  subtitle: 'Reschedule & alert at 9:00 AM',
                  onTap: () => Navigator.of(context).pop(
                    PlannerSnoozeChoice(
                      duration: tomorrowDiff > Duration.zero
                          ? tomorrowDiff
                          : const Duration(hours: 12),
                      label: 'Tomorrow 9:00 AM',
                      moveDateToTomorrow: !item.isRecurring,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SnoozeOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SnoozeOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Material(
      color: palette.surfaceMuted.withValues(
        alpha: palette.isDark ? 0.42 : 0.62,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMd,
        side: BorderSide(color: palette.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: palette.isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16.5, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: palette.heading,
                      ),
                    ),
                    AppText(
                      subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11.5,
                        color: palette.caption,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: palette.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
