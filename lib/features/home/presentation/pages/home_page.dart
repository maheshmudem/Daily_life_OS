import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              StringConstants.appName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              StringConstants.appTagline,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textCaption,
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
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Action',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildReadinessBanner(BuildContext context) {
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
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Life OS Architecture Ready',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Clean Architecture, DI, Theme, and Routing initialized. Ready for PRD features.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textBody.withValues(alpha: 0.8),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF4338CA)],
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Today’s Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '75% Completed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Keep building momentum.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '3 habits logged • 2 priority tasks finished today',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeading,
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
            child: Text(
              actionText,
              style: const TextStyle(
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
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
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDone ? color.withValues(alpha: 0.3) : AppColors.divider,
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
                    Text(
                      habit['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      '🔥 ${habit['streak']} days streak',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textCaption,
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
                  color: isDone ? color : AppColors.border,
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
    return Column(
      children: _tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        final isDone = task['done'] as bool;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
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
                child: Text(
                  task['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDone
                        ? AppColors.textCaption
                        : AppColors.textHeading,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: task['priority'] == 'High'
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task['priority'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: task['priority'] == 'High'
                        ? AppColors.error
                        : AppColors.textCaption,
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
