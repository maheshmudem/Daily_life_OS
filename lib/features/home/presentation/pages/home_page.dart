import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _habits = [
    {
      'title': 'Morning Sunlight & Water',
      'streak': 12,
      'done': true,
      'icon': Icons.wb_sunny_rounded,
      'color': AppColors.routineMorning,
    },
    {
      'title': 'Deep Work Sprint (90m)',
      'streak': 5,
      'done': true,
      'icon': Icons.bolt_rounded,
      'color': AppColors.primary,
    },
    {
      'title': 'Read 15 Pages',
      'streak': 8,
      'done': false,
      'icon': Icons.menu_book_rounded,
      'color': AppColors.secondary,
    },
    {
      'title': 'Mindful Evening Walk',
      'streak': 3,
      'done': false,
      'icon': Icons.directions_walk_rounded,
      'color': AppColors.accent,
    },
  ];

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Finalize Daily Life OS PRD Scope',
      'priority': 'High',
      'done': false,
    },
    {
      'title': 'Review weekly life metrics & habits',
      'priority': 'Medium',
      'done': true,
    },
    {
      'title': 'Plan tomorrow focus priorities',
      'priority': 'Normal',
      'done': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              StringConstants.appName,
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: palette.heading,
              ),
            ),
            AppText(
              StringConstants.appTagline,
              style: text.bodySmall?.copyWith(
                color: palette.caption,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRD Readiness Card
            _buildReadinessBanner(context),
            const SizedBox(height: 20),

            // Today's Focus & Overview Card
            _buildTodayOverviewCard(context),
            const SizedBox(height: 24),

            // Quick Actions
            _buildSectionHeader(context, title: StringConstants.quickActions),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // Active Habits Tracker
            _buildSectionHeader(
              context,
              title: StringConstants.activeHabits,
              actionText: StringConstants.viewAll,
            ),
            const SizedBox(height: 12),
            _buildHabitsList(context),
            const SizedBox(height: 24),

            // Upcoming Tasks
            _buildSectionHeader(
              context,
              title: StringConstants.upcomingTasks,
              actionText: StringConstants.viewAll,
            ),
            const SizedBox(height: 12),
            _buildTasksList(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        icon: const Icon(Icons.add_rounded),
        label: const AppText.labelLarge(
          'New Action',
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
      ),
    );
  }

  Widget _buildReadinessBanner(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.textWhite,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Daily Life OS Architecture Ready',
                  style: text.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.heading,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  'Clean Architecture, DI, Theme, and Routing initialized. Ready for PRD features.',
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    color: palette.body.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOverviewCard(BuildContext context) {
    final text = context.text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: AppColors.textWhite,
                    ),
                    const SizedBox(width: 6),
                    AppText(
                      'Today’s Plan',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AppText(
                '75% Completed',
                style: text.labelLarge?.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppText(
            'Keep building momentum.',
            style: text.headlineSmall?.copyWith(
              color: AppColors.textWhite,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          AppText(
            '3 habits logged • 2 priority tasks finished today',
            style: text.bodySmall?.copyWith(
              color: AppColors.textWhite.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 8,
              backgroundColor: AppColors.textWhite.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? actionText,
  }) {
    final palette = context.palette;
    final text = context.text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          title,
          style: text.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: palette.heading,
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: AppText(
              actionText,
              style: text.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final actions = [
      {
        'title': 'Add Task',
        'icon': Icons.add_task_rounded,
        'color': AppColors.primary,
      },
      {
        'title': 'Habit',
        'icon': Icons.repeat_rounded,
        'color': AppColors.secondary,
      },
      {
        'title': 'Routine',
        'icon': Icons.schedule_rounded,
        'color': AppColors.accent,
      },
      {
        'title': 'Focus Mode',
        'icon': Icons.timer_outlined,
        'color': AppColors.routineMorning,
      },
    ];

    return Row(
      children: actions.map((item) {
        final color = item['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.divider),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(item['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                AppText(
                  item['title'] as String,
                  style: text.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.heading,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHabitsList(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    return Column(
      children: _habits.asMap().entries.map((entry) {
        final index = entry.key;
        final habit = entry.value;
        final isDone = habit['done'] as bool;
        final color = habit['color'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDone ? color.withValues(alpha: 0.3) : palette.divider,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(habit['icon'] as IconData, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      habit['title'] as String,
                      style: text.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.heading,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    AppText(
                      '🔥 ${habit['streak']} days streak',
                      style: text.labelSmall?.copyWith(
                        fontSize: 11,
                        color: palette.caption,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isDone ? color : palette.border,
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    _habits[index]['done'] = !isDone;
                  });
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTasksList(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    return Column(
      children: _tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        final isDone = task['done'] as bool;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.divider),
          ),
          child: Row(
            children: [
              Checkbox(
                value: isDone,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (val) {
                  setState(() {
                    _tasks[index]['done'] = val ?? false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppText(
                  task['title'] as String,
                  style: text.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: isDone ? palette.caption : palette.heading,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: task['priority'] == 'High'
                      ? AppColors.error.withValues(alpha: 0.1)
                      : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AppText(
                  task['priority'] as String,
                  style: text.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: task['priority'] == 'High'
                        ? AppColors.error
                        : palette.caption,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
