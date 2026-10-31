import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/planner_item_entity.dart';

class PomodoroLinkedTaskSheet extends StatefulWidget {
  final String currentTask;
  final List<PlannerItemEntity> todayTasks;
  final bool isDark;
  final ValueChanged<String> onTaskSelected;

  const PomodoroLinkedTaskSheet({
    super.key,
    required this.currentTask,
    required this.todayTasks,
    required this.isDark,
    required this.onTaskSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentTask,
    required List<PlannerItemEntity> todayTasks,
    required bool isDark,
    required ValueChanged<String> onTaskSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PomodoroLinkedTaskSheet(
        currentTask: currentTask,
        todayTasks: todayTasks,
        isDark: isDark,
        onTaskSelected: onTaskSelected,
      ),
    );
  }

  @override
  State<PomodoroLinkedTaskSheet> createState() =>
      _PomodoroLinkedTaskSheetState();
}

class _PomodoroLinkedTaskSheetState extends State<PomodoroLinkedTaskSheet> {
  late TextEditingController _taskController;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController(text: widget.currentTask);
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? AppColors.darkCardBackground : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
              'Change Linked Focus Task',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: widget.isDark
                    ? AppColors.darkTextHeading
                    : AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _taskController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Current Focus Goal',
                hintText: 'e.g., Code API client, Write project brief...',
                prefixIcon: Icon(Icons.track_changes_rounded),
                border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.todayTasks.isNotEmpty) ...[
              Text(
                'Or pick from today\'s planner:',
                style: AppTextStyles.captionBold.copyWith(
                  color: widget.isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.todayTasks
                    .where((it) => !it.isDone)
                    .take(4)
                    .map((task) {
                      return ActionChip(
                        label: Text(task.title),
                        onPressed: () {
                          _taskController.text = task.title;
                        },
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moduleTime,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
                onPressed: () {
                  final text = _taskController.text.trim();
                  if (text.isNotEmpty) {
                    widget.onTaskSelected(text);
                  }
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Update Focus Task',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
