import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/expandable_text_widget.dart';
import '../../domain/entities/pomodoro_entities.dart';

/// Comprehensive Focus Analytics, 7-Day Trend Bar Chart, Category Breakdown,
/// Distraction Brain-Dump Pad, and Recent Focus Sessions Log.
class PomodoroAnalyticsDashboard extends StatefulWidget {
  final List<FocusSessionEntity> sessions;
  final List<FocusDistractionItem> distractions;
  final int dailyGoalSessions;
  final int workMinutes;
  final bool isDark;
  final VoidCallback onOpenManualLog;
  final ValueChanged<String> onDeleteSession;
  final ValueChanged<String> onAddDistraction;
  final ValueChanged<FocusDistractionItem> onConvertDistractionToTask;
  final ValueChanged<String> onDeleteDistraction;

  const PomodoroAnalyticsDashboard({
    super.key,
    required this.sessions,
    required this.distractions,
    required this.dailyGoalSessions,
    required this.workMinutes,
    required this.isDark,
    required this.onOpenManualLog,
    required this.onDeleteSession,
    required this.onAddDistraction,
    required this.onConvertDistractionToTask,
    required this.onDeleteDistraction,
  });

  @override
  State<PomodoroAnalyticsDashboard> createState() =>
      _PomodoroAnalyticsDashboardState();
}

class _PomodoroAnalyticsDashboardState
    extends State<PomodoroAnalyticsDashboard> {
  int _selectedDayOffset = 0; // 0 = Today, 1 = Yesterday, ..., 6 = 6 days ago
  bool _showAllSessions = false;
  bool _showAllDistractions = false;
  bool _showAllCategories = false;
  final TextEditingController _distractionController = TextEditingController();

  @override
  void dispose() {
    _distractionController.dispose();
    super.dispose();
  }

  String _isoForDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
      default:
        return 'Sun';
    }
  }

  int _computeCurrentStreak(DateTime today) {
    final activeDates = widget.sessions.map((s) => s.isoDate).toSet();
    int streak = 0;
    for (int i = 0; i < 60; i++) {
      final dateKey = _isoForDate(today.subtract(Duration(days: i)));
      if (activeDates.contains(dateKey)) {
        streak++;
      } else if (i == 0) {
        // If today has no session yet, check from yesterday
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  int _computeBestStreak(DateTime today) {
    final activeDates = widget.sessions.map((s) => s.isoDate).toSet();
    int best = 0;
    int current = 0;
    for (int i = 0; i < 90; i++) {
      final dateKey = _isoForDate(today.subtract(Duration(days: i)));
      if (activeDates.contains(dateKey)) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return math.max(best, _computeCurrentStreak(today));
  }

  String _formatDurationCompact(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hrs = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return mins == 0 ? '${hrs}h' : '${hrs}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final cardBg = isDark
        ? AppColors.darkCardBackground
        : AppColors.cardBackground;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final captionColor = isDark
        ? AppColors.darkTextCaption
        : AppColors.textCaption;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayIso = _isoForDate(today);

    final todaySessions = widget.sessions
        .where((s) => s.isoDate == todayIso)
        .toList();
    final completedTodayCount = todaySessions.length;
    final focusedMinutesToday = todaySessions.fold<int>(
      0,
      (sum, s) => sum + s.durationMinutes,
    );
    final totalAllMinutes = widget.sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationMinutes,
    );
    final avgSessionMins = widget.sessions.isEmpty
        ? widget.workMinutes
        : (totalAllMinutes / widget.sessions.length).round();

    final streakDays = _computeCurrentStreak(today);
    final bestStreak = _computeBestStreak(today);
    final avgRating = widget.sessions.isEmpty
        ? 5.0
        : widget.sessions.fold<int>(0, (sum, s) => sum + s.focusRating) /
              widget.sessions.length;
    final goalProgress = widget.dailyGoalSessions > 0
        ? (completedTodayCount / widget.dailyGoalSessions).clamp(0.0, 1.0)
        : 0.0;

    // Determine top focus category for the coach insight
    final Map<String, int> catTotals = {};
    for (final s in widget.sessions) {
      catTotals[s.category] = (catTotals[s.category] ?? 0) + s.durationMinutes;
    }
    String topCategory = 'Deep Work';
    int topCatMins = 0;
    catTotals.forEach((cat, mins) {
      if (mins > topCatMins) {
        topCatMins = mins;
        topCategory = cat;
      }
    });

    final remainingSessions = math.max(
      0,
      widget.dailyGoalSessions - completedTodayCount,
    );
    final String coachHeadline = completedTodayCount >= widget.dailyGoalSessions
        ? 'Daily Focus Target Achieved!'
        : (completedTodayCount > 0
              ? '$remainingSessions more ${remainingSessions == 1 ? 'session' : 'sessions'} to hit today\'s target'
              : 'Ready for your first deep work sprint today');
    final String coachDetail = widget.sessions.isEmpty
        ? 'Start a ${widget.workMinutes}m Pomodoro sprint or use "+ Log" to record deep work sessions and unlock personalized flow insights.'
        : 'Peak category: $topCategory (${_formatDurationCompact(topCatMins)}) • Average sprint: ${avgSessionMins}m across ${widget.sessions.length} logged sessions (${_formatDurationCompact(totalAllMinutes)} total focus). Consistent daily sprints compound your cognitive stamina.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Daily Focus Activity, Animated Goal Ring & 2x2 Bento Metric Grid
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: dividerColor, width: 0.85),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.focusPomodoro.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.focusPomodoro,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Daily Focus Activity',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                        color: headingColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkScaffoldBackground
                          : AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: dividerColor, width: 0.8),
                    ),
                    child: Text(
                      'Goal: ${widget.dailyGoalSessions} sessions',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: captionColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: widget.onOpenManualLog,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.moduleTime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 12,
                            color: AppColors.moduleTime,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Log',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.moduleTime,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Animated Goal Progress & Focus Coach Insight Banner
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.surfaceSecondary,
                  borderRadius: AppRadius.radiusSm,
                  border: Border.all(
                    color: AppColors.moduleTime.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: goalProgress),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, animVal, _) {
                        return SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: animVal,
                                strokeWidth: 5,
                                strokeCap: StrokeCap.round,
                                backgroundColor: AppColors.moduleTime
                                    .withValues(alpha: 0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.moduleTime,
                                ),
                              ),
                              Center(
                                child: Text(
                                  '${(animVal * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: headingColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coachHeadline,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: headingColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          ExpandableTextWidget(
                            text: coachDetail,
                            collapsedMaxLines: 2,
                            characterThreshold: 75,
                            toggleColor: AppColors.moduleTime,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: captionColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 2x2 Bento Metric Grid (No cramped columns or clipped labels)
              Row(
                children: [
                  Expanded(
                    child: _buildBentoMetricTile(
                      value: '$completedTodayCount',
                      label: 'Sessions',
                      subtitle: 'Target: ${widget.dailyGoalSessions}/day',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.moduleTime,
                      isDark: isDark,
                      dividerColor: dividerColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBentoMetricTile(
                      value: '${focusedMinutesToday}m',
                      label: 'Focused',
                      subtitle:
                          'Total: ${_formatDurationCompact(totalAllMinutes)}',
                      icon: Icons.timer_outlined,
                      color: AppColors.success,
                      isDark: isDark,
                      dividerColor: dividerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildBentoMetricTile(
                      value: '$streakDays days',
                      label: 'Streak',
                      subtitle: 'Best: $bestStreak days',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.focusPomodoro,
                      isDark: isDark,
                      dividerColor: dividerColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBentoMetricTile(
                      value: '${avgRating.toStringAsFixed(1)}★',
                      label: 'Flow',
                      subtitle: 'Avg: ${avgSessionMins}m / sprint',
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      isDark: isDark,
                      dividerColor: dividerColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. 7-Day Focus Trend & Category Breakdown Card
        _buildWeeklyTrendAndCategoryCard(
          today: today,
          cardBg: cardBg,
          dividerColor: dividerColor,
          headingColor: headingColor,
          captionColor: captionColor,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // 3. Mid-Session Distraction Brain-Dump Pad
        _buildDistractionPadCard(
          cardBg: cardBg,
          dividerColor: dividerColor,
          headingColor: headingColor,
          captionColor: captionColor,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // 4. Recent Focus Sessions Log
        _buildRecentSessionsCard(
          cardBg: cardBg,
          dividerColor: dividerColor,
          headingColor: headingColor,
          captionColor: captionColor,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBentoMetricTile({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color dividerColor,
  }) {
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final captionColor = isDark
        ? AppColors.darkTextCaption
        : AppColors.textCaption;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.surfaceSecondary,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: dividerColor.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: headingColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: captionColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendAndCategoryCard({
    required DateTime today,
    required Color cardBg,
    required Color dividerColor,
    required Color headingColor,
    required Color captionColor,
    required bool isDark,
  }) {
    // Compute 7 days (oldest to today: offset 6 down to 0)
    final days = List.generate(7, (idx) {
      final offset = 6 - idx;
      final dt = today.subtract(Duration(days: offset));
      final iso = _isoForDate(dt);
      final daySessions = widget.sessions
          .where((s) => s.isoDate == iso)
          .toList();
      final mins = daySessions.fold<int>(
        0,
        (sum, s) => sum + s.durationMinutes,
      );
      return (
        offset: offset,
        date: dt,
        label: offset == 0 ? 'Today' : _weekdayShort(dt.weekday),
        minutes: mins,
        count: daySessions.length,
      );
    });

    final maxMins = math.max(
      widget.dailyGoalSessions * widget.workMinutes,
      days.fold<int>(60, (m, d) => math.max(m, d.minutes)),
    );

    final selectedDay = days.firstWhere(
      (d) => d.offset == _selectedDayOffset,
      orElse: () => days.last,
    );

    // Category breakdown across all sessions
    final Map<String, int> categoryMinutes = {};
    int totalAllMinutes = 0;
    for (final s in widget.sessions) {
      categoryMinutes[s.category] =
          (categoryMinutes[s.category] ?? 0) + s.durationMinutes;
      totalAllMinutes += s.durationMinutes;
    }
    final sortedCategories = categoryMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final visibleCategories = _showAllCategories
        ? sortedCategories
        : sortedCategories.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: dividerColor, width: 0.85),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '7-Day Focus Trend & Categories',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: headingColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.moduleTime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${selectedDay.label}: ${selectedDay.minutes}m (${selectedDay.count}x)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.moduleTime,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 7-Day Interactive Bars with Smooth Entrance & Selection Animation
          SizedBox(
            height: 102,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final isSelected = day.offset == _selectedDayOffset;
                final ratio = maxMins > 0
                    ? (day.minutes / maxMins).clamp(0.0, 1.0)
                    : 0.0;
                final barHeight = math.max(6.0, ratio * 52.0);
                final metGoal =
                    day.minutes >=
                    (widget.dailyGoalSessions * widget.workMinutes);

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _selectedDayOffset = day.offset),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          day.minutes > 0 ? '${day.minutes}m' : '—',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.moduleTime
                                : captionColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 6.0, end: barHeight),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedH, _) {
                            return Container(
                              width: isSelected ? 22 : 18,
                              height: animatedH,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: day.minutes == 0
                                    ? null
                                    : LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: isSelected
                                            ? const [
                                                Color(0xFFF59E0B),
                                                Color(0xFFD97706),
                                              ]
                                            : (metGoal
                                                  ? [
                                                      AppColors.success,
                                                      AppColors.success
                                                          .withValues(
                                                            alpha: 0.75,
                                                          ),
                                                    ]
                                                  : [
                                                      AppColors.moduleTime
                                                          .withValues(
                                                            alpha: 0.65,
                                                          ),
                                                      AppColors.moduleTime
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                    ]),
                                      ),
                                color: day.minutes == 0
                                    ? (isDark
                                          ? AppColors.darkSurfaceSecondary
                                          : AppColors.surfaceSecondary)
                                    : null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        Text(
                          day.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected ? headingColor : captionColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (sortedCategories.isNotEmpty && totalAllMinutes > 0) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 10),
            // Stacked Category Bar
            ClipRRect(
              borderRadius: AppRadius.radiusFull,
              child: SizedBox(
                height: 7,
                child: Row(
                  children: sortedCategories.map((entry) {
                    final flex = math.max(
                      1,
                      ((entry.value / totalAllMinutes) * 100).round(),
                    );
                    return Expanded(
                      flex: flex,
                      child: Container(
                        color: FocusCategoryCatalog.colorFor(entry.key),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: visibleCategories.map((entry) {
                  final color = FocusCategoryCatalog.colorFor(entry.key);
                  final pct = ((entry.value / totalAllMinutes) * 100).round();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.key} ${entry.value}m ($pct%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: captionColor,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            if (sortedCategories.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InkWell(
                  onTap: () =>
                      setState(() => _showAllCategories = !_showAllCategories),
                  borderRadius: AppRadius.radiusXs,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showAllCategories
                            ? 'Show less categories'
                            : 'Show all ${sortedCategories.length} categories',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _showAllCategories
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDistractionPadCard({
    required Color cardBg,
    required Color dividerColor,
    required Color headingColor,
    required Color captionColor,
    required bool isDark,
  }) {
    final visibleDistractions = _showAllDistractions
        ? widget.distractions
        : widget.distractions.take(3).toList();
    final hiddenCount = widget.distractions.length - 3;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: dividerColor, width: 0.85),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.moduleVault.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.moduleVault,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distraction Blocker & Brain Dump',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: headingColor,
                      ),
                    ),
                    Text(
                      'Park random thoughts mid-sprint and convert them to tasks later',
                      style: TextStyle(fontSize: 10.5, color: captionColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.surfaceSecondary,
                      borderRadius: AppRadius.radiusSm,
                      border: Border.all(color: dividerColor, width: 0.8),
                    ),
                    child: TextField(
                      controller: _distractionController,
                      style: TextStyle(fontSize: 12.5, color: headingColor),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        hintText:
                            'Jot a distracting thought (e.g., Call dentist)...',
                        hintStyle: TextStyle(color: captionColor, fontSize: 12),
                        prefixIcon: const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15,
                          color: AppColors.moduleVault,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _submitDistraction(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _submitDistraction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moduleVault,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Park',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (widget.distractions.isNotEmpty) ...[
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                children: visibleDistractions.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceSecondary
                            : AppColors.surfaceSecondary,
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              item.addedToPlanner
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 14,
                              color: item.addedToPlanner
                                  ? AppColors.success
                                  : AppColors.moduleVault,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ExpandableTextWidget(
                              text: item.text,
                              collapsedMaxLines: 2,
                              characterThreshold: 60,
                              toggleColor: AppColors.moduleVault,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: item.addedToPlanner
                                    ? captionColor
                                    : headingColor,
                                decoration: item.addedToPlanner
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (!item.addedToPlanner)
                            TextButton.icon(
                              onPressed: () =>
                                  widget.onConvertDistractionToTask(item),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.moduleTime,
                                minimumSize: const Size(0, 24),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(
                                Icons.add_task_rounded,
                                size: 13,
                              ),
                              label: const Text(
                                'To Planner',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          IconButton(
                            onPressed: () =>
                                widget.onDeleteDistraction(item.id),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: captionColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (widget.distractions.length > 3)
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _showAllDistractions = !_showAllDistractions,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.moduleVault,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    _showAllDistractions
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _showAllDistractions
                        ? 'Show less'
                        : 'Show more ($hiddenCount more)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _submitDistraction() {
    final text = _distractionController.text.trim();
    if (text.isEmpty) return;
    widget.onAddDistraction(text);
    _distractionController.clear();
  }

  Widget _buildRecentSessionsCard({
    required Color cardBg,
    required Color dividerColor,
    required Color headingColor,
    required Color captionColor,
    required bool isDark,
  }) {
    final visibleSessions = _showAllSessions
        ? widget.sessions
        : widget.sessions.take(3).toList();
    final hiddenSessionsCount = widget.sessions.length - 3;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: dividerColor, width: 0.85),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppColors.success,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Focus Sessions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: headingColor,
                    ),
                  ),
                ],
              ),
              Text(
                '${widget.sessions.length} logged',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: captionColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (visibleSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No focus sessions logged yet. Start a sprint or tap "+ Log" above!',
                style: TextStyle(fontSize: 12, color: captionColor),
              ),
            )
          else ...[
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                children: visibleSessions.map((session) {
                  final catColor = session.categoryColor;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceSecondary
                            : AppColors.surfaceSecondary,
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              session.categoryIcon,
                              size: 16,
                              color: catColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExpandableTextWidget(
                                  text: session.taskTitle,
                                  collapsedMaxLines: 2,
                                  characterThreshold: 55,
                                  toggleColor: catColor,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    color: headingColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 3,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '${session.category} • ${session.isoDate} at ${session.formattedTime}${session.isStopwatch ? " • Flow ⏱" : ""}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: captionColor,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.moduleTime.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${session.focusRating}★',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.moduleTime,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (session.notes.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  ExpandableTextWidget(
                                    text: session.notes,
                                    collapsedMaxLines: 2,
                                    characterThreshold: 55,
                                    toggleColor: AppColors.moduleTime,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.35,
                                      fontStyle: FontStyle.italic,
                                      color: captionColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${session.durationMinutes}m',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: catColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () => widget.onDeleteSession(session.id),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: 'Delete session',
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 15,
                              color: captionColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (widget.sessions.length > 3)
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _showAllSessions = !_showAllSessions),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.moduleTime,
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    _showAllSessions
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _showAllSessions
                        ? 'Show less sessions'
                        : 'Show more ($hiddenSessionsCount more sessions)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Modal Bottom Sheet to log a manual focus session or rate a completed session.
class PomodoroManualSessionSheet extends StatefulWidget {
  final String initialTask;
  final String initialCategory;
  final int initialDuration;
  final bool isDark;
  final ValueChanged<FocusSessionEntity> onSave;

  const PomodoroManualSessionSheet({
    super.key,
    required this.initialTask,
    required this.initialCategory,
    this.initialDuration = 25,
    required this.isDark,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialTask,
    required String initialCategory,
    int initialDuration = 25,
    required bool isDark,
    required ValueChanged<FocusSessionEntity> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PomodoroManualSessionSheet(
        initialTask: initialTask,
        initialCategory: initialCategory,
        initialDuration: initialDuration,
        isDark: isDark,
        onSave: onSave,
      ),
    );
  }

  @override
  State<PomodoroManualSessionSheet> createState() =>
      _PomodoroManualSessionSheetState();
}

class _PomodoroManualSessionSheetState
    extends State<PomodoroManualSessionSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late String _category;
  late int _duration;
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTask);
    _notesController = TextEditingController();
    _category = widget.initialCategory;
    _duration = widget.initialDuration;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? AppColors.darkCardBackground : Colors.white;
    final headingColor = widget.isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final captionColor = widget.isDark
        ? AppColors.darkTextCaption
        : AppColors.textCaption;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadius.topXxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? AppColors.darkDivider
                          : AppColors.divider,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
                AppSpacing.gapH16,
                Text(
                  'Log Focus Session',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'What did you focus on?',
                    prefixIcon: Icon(Icons.bolt_rounded),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Duration: $_duration mins',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: headingColor,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [15, 25, 45, 60, 90].map((m) {
                        final selected = _duration == m;
                        return ChoiceChip(
                          label: Text('${m}m'),
                          selected: selected,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onSelected: (_) => setState(() => _duration = m),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Category:',
                  style: AppTextStyles.captionBold.copyWith(
                    color: captionColor,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: FocusCategoryCatalog.categories.map((cat) {
                    final selected = _category == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: selected,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (_) => setState(() => _category = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Flow State Rating:',
                      style: AppTextStyles.captionBold.copyWith(
                        color: captionColor,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => _rating = star),
                          icon: Icon(
                            star <= _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppColors.moduleTime,
                            size: 22,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Session Note / Reflection (Optional)',
                    hintText: 'Key takeaways or progress made...',
                    prefixIcon: Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.moduleTime,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusMd,
                      ),
                    ),
                    onPressed: () {
                      final title = _titleController.text.trim().isEmpty
                          ? 'Deep Work Session'
                          : _titleController.text.trim();
                      widget.onSave(
                        FocusSessionEntity(
                          id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                          taskTitle: title,
                          category: _category,
                          durationMinutes: _duration,
                          completedAt: DateTime.now(),
                          notes: _notesController.text.trim(),
                          focusRating: _rating,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Save Focus Session',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
