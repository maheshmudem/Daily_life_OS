import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/countdown_item_entity.dart';

/// Theme-adaptive Milestone Spotlight & 4-Stat Overview for Countdowns.
///
/// Uses `AppDecorations.card(context)` + `context.palette` so Light & Dark
/// themes look cohesive across the entire Daily Life OS application, while
/// tinting the top radial wash to the nearest milestone's category color.
class CountdownSpotlightCard extends StatelessWidget {
  final List<CountdownItemEntity> countdowns;
  final VoidCallback? onTapNearest;

  const CountdownSpotlightCard({
    super.key,
    required this.countdowns,
    this.onTapNearest,
  });

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Birthday':
        return Icons.cake_rounded;
      case 'Anniversary':
        return Icons.favorite_rounded;
      case 'Renewal':
        return Icons.directions_car_rounded;
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Milestone':
        return Icons.flag_rounded;
      case 'Event':
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = palette.isDark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = <CountdownItemEntity>[];
    var within30Days = 0;
    var alertsEnabled = 0;

    for (final item in countdowns) {
      final target = DateTime(item.date.year, item.date.month, item.date.day);
      final diff = target.difference(today).inDays;
      if (diff >= 0) {
        upcoming.add(item);
        if (diff <= 30) within30Days++;
      }
      if (item.remindAdvance) alertsEnabled++;
    }

    upcoming.sort((a, b) => a.date.compareTo(b.date));
    final nearest = upcoming.isNotEmpty ? upcoming.first : null;
    final accent = nearest != null
        ? Color(nearest.colorValue)
        : AppColors.moduleTime;

    final int? nearestDays;
    var remHours = 0;
    var remMinutes = 0;

    if (nearest != null) {
      final targetMidnight = DateTime(
        nearest.date.year,
        nearest.date.month,
        nearest.date.day,
      );
      nearestDays = targetMidnight.difference(today).inDays;

      // Target 9:00 AM on the milestone date for live hours/minutes readout
      final targetMoment = DateTime(
        nearest.date.year,
        nearest.date.month,
        nearest.date.day,
        9,
      );
      final rawDiff = targetMoment.difference(now);
      if (!rawDiff.isNegative) {
        remHours = rawDiff.inHours % 24;
        remMinutes = rawDiff.inMinutes % 60;
      }
    } else {
      nearestDays = null;
    }

    final nextStatValue = nearestDays == null
        ? '—'
        : (nearestDays == 0
              ? 'Today'
              : (nearestDays == 1 ? '1d' : '${nearestDays}d'));

    Widget vDivider() => Container(
      width: 1,
      height: 22,
      color: palette.divider,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );

    return Container(
      decoration: AppDecorations.card(context).copyWith(
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.34 : 0.24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -24,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: isDark ? 0.18 : 0.11),
                      accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Nearest Milestone Digital Spotlight ───────────────────
                if (nearest != null) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTapNearest,
                      borderRadius: AppRadius.radiusSm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(
                                        alpha: isDark ? 0.20 : 0.12,
                                      ),
                                      borderRadius: AppRadius.radiusSm,
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.32),
                                      ),
                                    ),
                                    child: Icon(
                                      _iconForCategory(nearest.category),
                                      size: 19,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'MILESTONE SPOTLIGHT · ${DateFormat('MMM d, yyyy').format(nearest.date).toUpperCase()}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.overline
                                              .copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                color: isDark
                                                    ? AppColors.moduleTimeLight
                                                    : AppColors.moduleTimeDark,
                                              ),
                                        ),
                                        const SizedBox(height: 2.5),
                                        Text(
                                          'Next Up · ${nearest.title}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.text.titleSmall
                                              ?.copyWith(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.3,
                                                color: palette.heading,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Digital Tabular Countdown Readout
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _DigitalTile(
                                    value: '${nearestDays ?? 0}'.padLeft(
                                      2,
                                      '0',
                                    ),
                                    unit: 'DAYS',
                                    palette: palette,
                                    accent: accent,
                                  ),
                                  const SizedBox(width: 5),
                                  _DigitalTile(
                                    value: '$remHours'.padLeft(2, '0'),
                                    unit: 'HRS',
                                    palette: palette,
                                    accent: accent,
                                  ),
                                  const SizedBox(width: 5),
                                  _DigitalTile(
                                    value: '$remMinutes'.padLeft(2, '0'),
                                    unit: 'MIN',
                                    palette: palette,
                                    accent: accent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // ── 2. Theme-Adaptive 4-Stat Milestone Overview Strip ────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(color: palette.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SpotlightStat(
                          value: '${upcoming.length}',
                          label: 'Upcoming',
                          color: AppColors.moduleTime,
                          palette: palette,
                        ),
                      ),
                      vDivider(),
                      Expanded(
                        child: _SpotlightStat(
                          value: '$within30Days',
                          label: 'Next 30d',
                          color: AppColors.primary,
                          palette: palette,
                        ),
                      ),
                      vDivider(),
                      Expanded(
                        child: _SpotlightStat(
                          value: '$alertsEnabled',
                          label: 'Alerts On',
                          color: AppColors.success,
                          palette: palette,
                        ),
                      ),
                      vDivider(),
                      Expanded(
                        child: _SpotlightStat(
                          value: nextStatValue,
                          label: 'Next In',
                          color: AppColors.moduleNotes,
                          palette: palette,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitalTile extends StatelessWidget {
  final String value;
  final String unit;
  final AppPalette palette;
  final Color accent;

  const _DigitalTile({
    required this.value,
    required this.unit,
    required this.palette,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    return Container(
      constraints: const BoxConstraints(minWidth: 44),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontSize: 15,
              height: 1.05,
              fontWeight: FontWeight.w800,
              color: palette.heading,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: AppTextStyles.overline.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: palette.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final AppPalette palette;

  const _SpotlightStat({
    required this.value,
    required this.label,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: textTheme.titleSmall?.copyWith(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: palette.heading,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: palette.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
