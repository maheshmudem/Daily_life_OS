import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../../domain/entities/pomodoro_entities.dart';

class LinkedFocusTaskResult {
  final String title;
  final int? linkedTaskId;
  final String category;
  final int estimatedPomodoros;

  const LinkedFocusTaskResult({
    required this.title,
    this.linkedTaskId,
    required this.category,
    required this.estimatedPomodoros,
  });
}

class PomodoroLinkedTaskSheet extends StatefulWidget {
  final String currentTask;
  final int? currentLinkedTaskId;
  final String currentCategory;
  final int currentEstimatedPomodoros;
  final List<PlannerItemEntity> todayTasks;
  final bool isDark;
  final ValueChanged<String> onTaskSelected;
  final ValueChanged<LinkedFocusTaskResult>? onTaskDetailsSelected;

  const PomodoroLinkedTaskSheet({
    super.key,
    required this.currentTask,
    this.currentLinkedTaskId,
    this.currentCategory = 'Deep Work',
    this.currentEstimatedPomodoros = 4,
    required this.todayTasks,
    required this.isDark,
    required this.onTaskSelected,
    this.onTaskDetailsSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentTask,
    int? currentLinkedTaskId,
    String currentCategory = 'Deep Work',
    int currentEstimatedPomodoros = 4,
    required List<PlannerItemEntity> todayTasks,
    required bool isDark,
    required ValueChanged<String> onTaskSelected,
    ValueChanged<LinkedFocusTaskResult>? onTaskDetailsSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => PomodoroLinkedTaskSheet(
        currentTask: currentTask,
        currentLinkedTaskId: currentLinkedTaskId,
        currentCategory: currentCategory,
        currentEstimatedPomodoros: currentEstimatedPomodoros,
        todayTasks: todayTasks,
        isDark: isDark,
        onTaskSelected: onTaskSelected,
        onTaskDetailsSelected: onTaskDetailsSelected,
      ),
    );
  }

  @override
  State<PomodoroLinkedTaskSheet> createState() =>
      _PomodoroLinkedTaskSheetState();
}

class _PomodoroLinkedTaskSheetState extends State<PomodoroLinkedTaskSheet> {
  late TextEditingController _taskController;
  int? _selectedPlannerTaskId;
  late String _selectedCategory;
  late int _estimatedPomodoros;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController(text: widget.currentTask);
    _selectedPlannerTaskId = widget.currentLinkedTaskId;
    _selectedCategory = widget.currentCategory;
    _estimatedPomodoros = widget.currentEstimatedPomodoros;
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final cardBg = palette.card;
    final headingColor = palette.heading;
    final captionColor = palette.caption;
    final pendingTasks = widget.todayTasks
        .where((it) => !it.isDone)
        .take(6)
        .toList();

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
                      color: palette.divider,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
                AppSpacing.gapH16,
                AppText.titleMedium(
                  'Change Linked Focus Task',
                  fontWeight: FontWeight.w800,
                  color: headingColor,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _taskController,
                  autofocus: true,
                  onChanged: (_) {
                    if (_selectedPlannerTaskId != null) {
                      setState(() => _selectedPlannerTaskId = null);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Current Focus Goal',
                    hintText: 'e.g., Code API client, Write project brief...',
                    prefixIcon: Icon(Icons.track_changes_rounded),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Focus Category Selector
                AppText.captionBold('Focus Category:', color: captionColor),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: FocusCategoryCatalog.categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final catColor = FocusCategoryCatalog.colorFor(cat);
                    final catIcon = FocusCategoryCatalog.iconFor(cat);
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            catIcon,
                            size: 13,
                            color: isSelected ? catColor : captionColor,
                          ),
                          const SizedBox(width: 4),
                          AppText(cat),
                        ],
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      selectedColor: catColor.withValues(alpha: 0.14),
                      backgroundColor: palette.surfaceMuted,
                      side: BorderSide(
                        color: isSelected
                            ? catColor.withValues(alpha: 0.6)
                            : AppColors.transparent,
                      ),
                      labelStyle: textTheme.labelSmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? catColor : headingColor,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Estimated Pomodoros Picker (1..8)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.captionBold(
                      'Estimated Pomodoros (🍅):',
                      color: captionColor,
                    ),
                    Row(
                      children: List.generate(6, (idx) {
                        final count = idx + 1;
                        final selected = _estimatedPomodoros == count;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _estimatedPomodoros = count),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.only(left: 5),
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.moduleTime
                                  : palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: AppText(
                              '$count',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppColors.textWhite
                                    : headingColor,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (pendingTasks.isNotEmpty) ...[
                  AppText.captionBold(
                    'Or pick from today\'s planner (links subtasks):',
                    color: captionColor,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: pendingTasks.map((task) {
                      final isLinked = _selectedPlannerTaskId == task.id;
                      return ActionChip(
                        avatar: Icon(
                          isLinked
                              ? Icons.check_circle_rounded
                              : Icons.link_rounded,
                          size: 14,
                          color: isLinked ? AppColors.moduleTime : captionColor,
                        ),
                        backgroundColor: isLinked
                            ? AppColors.moduleTime.withValues(alpha: 0.14)
                            : null,
                        label: AppText(
                          task.checklist.isNotEmpty
                              ? '${task.title} (${task.checklistDoneCount}/${task.checklist.length})'
                              : task.title,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 11.5,
                            fontWeight: isLinked
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _taskController.text = task.title;
                            _selectedPlannerTaskId = task.id;
                            if (task.category == 'Work') {
                              _selectedCategory = 'Deep Work';
                            } else if (FocusCategoryCatalog.categories.contains(
                              task.category,
                            )) {
                              _selectedCategory = task.category;
                            }
                          });
                        },
                      );
                    }).toList(),
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
                        widget.onTaskDetailsSelected?.call(
                          LinkedFocusTaskResult(
                            title: text,
                            linkedTaskId: _selectedPlannerTaskId,
                            category: _selectedCategory,
                            estimatedPomodoros: _estimatedPomodoros,
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    },
                    child: const AppText.labelLarge(
                      'Update Focus Task',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
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
