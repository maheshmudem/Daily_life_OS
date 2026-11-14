import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/planner_item_entity.dart';

/// Theme-adaptive Pomodoro & Flow Stopwatch studio card.
///
/// Harmonizes with Light & Dark themes via `context.palette` and Daily Life OS
/// focus tokens (`AppColors.moduleTime`, `AppColors.focusBreak`,
/// `AppColors.moduleNotes`, `AppColors.moduleVault`).
class PomodoroFocusCard extends StatefulWidget {
  final int focusModeIndex;
  final int currentRound;
  final int totalRounds;
  final double timerProgress;
  final String formattedTime;
  final bool isTimerRunning;
  final String linkedTask;
  final VoidCallback onToggleTimer;
  final VoidCallback onResetTimer;
  final VoidCallback onSkipSession;
  final VoidCallback onChangeTask;

  // Extended Focus 2.0 optional props
  final String focusCategory;
  final int estimatedPomodoros;
  final int completedTaskPomodoros;
  final bool strictMode;
  final String selectedAmbience;
  final PlannerItemEntity? linkedPlannerItem;
  final ValueChanged<ChecklistItem>? onToggleSubtask;
  final VoidCallback? onMarkTaskDone;
  final ValueChanged<int>? onAddMinutes;
  final VoidCallback? onFinishStopwatch;
  final VoidCallback? onOpenZenMode;

  const PomodoroFocusCard({
    super.key,
    required this.focusModeIndex,
    required this.currentRound,
    required this.totalRounds,
    required this.timerProgress,
    required this.formattedTime,
    required this.isTimerRunning,
    required this.linkedTask,
    required this.onToggleTimer,
    required this.onResetTimer,
    required this.onSkipSession,
    required this.onChangeTask,
    this.focusCategory = 'Deep Work',
    this.estimatedPomodoros = 4,
    this.completedTaskPomodoros = 2,
    this.strictMode = false,
    this.selectedAmbience = 'Mute',
    this.linkedPlannerItem,
    this.onToggleSubtask,
    this.onMarkTaskDone,
    this.onAddMinutes,
    this.onFinishStopwatch,
    this.onOpenZenMode,
  });

  @override
  State<PomodoroFocusCard> createState() => _PomodoroFocusCardState();
}

class _PomodoroFocusCardState extends State<PomodoroFocusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _showSubtasks = false;
  bool _expandLinkedTaskText = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isTimerRunning) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PomodoroFocusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTimerRunning != oldWidget.isTimerRunning) {
      if (widget.isTimerRunning) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _resolveAccentColor(int mode) {
    switch (mode) {
      case 1:
        return AppColors.focusBreak; // Emerald (#10B981)
      case 2:
        return AppColors.moduleNotes; // Sky (#0EA5E9)
      case 3:
        return AppColors.moduleVault; // Violet (#8B5CF6)
      case 0:
      default:
        return AppColors.moduleTime; // Sunrise Amber (#F59E0B)
    }
  }

  Color _resolveTextAccent(int mode, bool isDark) {
    switch (mode) {
      case 1:
        return isDark ? AppColors.moduleTasksLight : AppColors.moduleTasksDark;
      case 2:
        return isDark ? AppColors.moduleNotesLight : AppColors.moduleNotesDark;
      case 3:
        return isDark ? AppColors.moduleVaultLight : AppColors.moduleVault;
      case 0:
      default:
        return isDark ? AppColors.moduleTimeLight : AppColors.moduleTimeDark;
    }
  }

  String _resolveModeLabel(int mode) {
    switch (mode) {
      case 1:
        return '☕ SHORT BREAK';
      case 2:
        return '🌴 LONG BREAK';
      case 3:
        return '♾️ FLOW STOPWATCH';
      case 0:
      default:
        return '⚡ DEEP WORK SPRINT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isDark = palette.isDark;
    final mode = widget.focusModeIndex;
    final accentColor = _resolveAccentColor(mode);
    final textAccent = _resolveTextAccent(mode, isDark);
    final modeLabel = _resolveModeLabel(mode);
    final isStopwatch = mode == 3;
    final linkedItem = widget.linkedPlannerItem;
    final hasChecklist = linkedItem != null && linkedItem.checklist.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.36 : 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : accentColor).withValues(
              alpha: isDark ? 0.35 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Soft Theme-Adaptive Mode Wash at Top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 110,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
                      accentColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // 1. Top Bar: Mode Badge, Strict Lock, Round Indicators & Zen Mode Button
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: 6,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(
                                  alpha: isDark ? 0.18 : 0.12,
                                ),
                                borderRadius: AppRadius.radiusFull,
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.32),
                                ),
                              ),
                              child: Text(
                                modeLabel,
                                style: AppTextStyles.overline.copyWith(
                                  color: textAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            if (widget.strictMode) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceMuted,
                                  borderRadius: AppRadius.radiusFull,
                                  border: Border.all(color: palette.divider),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 10,
                                      color: palette.heading,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'STRICT',
                                      style: AppTextStyles.overline.copyWith(
                                        color: palette.heading,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Round ${widget.currentRound}/${widget.totalRounds}',
                              style: textTheme.labelSmall?.copyWith(
                                color: palette.heading,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                widget.totalRounds,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1.5,
                                  ),
                                  width: i + 1 == widget.currentRound ? 12 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: AppRadius.radiusFull,
                                    color: i < widget.currentRound
                                        ? accentColor
                                        : palette.divider,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.onOpenZenMode != null) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: widget.onOpenZenMode,
                                borderRadius: AppRadius.radiusFull,
                                child: Tooltip(
                                  message: 'Full-Screen Zen Focus',
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: palette.surfaceMuted,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: palette.divider,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.fullscreen_rounded,
                                      size: 16,
                                      color: palette.heading,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 2. Precision CustomPainter Radial Progress Dial + Breathing Pulse
                SizedBox(
                  width: 168,
                  height: 168,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulseVal = widget.isTimerRunning
                          ? _pulseController.value
                          : 0.0;
                      return CustomPaint(
                        painter: _FocusDialPainter(
                          progress: widget.timerProgress.clamp(0.0, 1.0),
                          pulseValue: pulseVal,
                          isRunning: widget.isTimerRunning,
                          accentColor: accentColor,
                          trackColor: palette.divider,
                          cardColor: palette.card,
                        ),
                        child: child,
                      );
                    },
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(
                                alpha: isDark ? 0.16 : 0.10,
                              ),
                              borderRadius: AppRadius.radiusFull,
                            ),
                            child: Text(
                              widget.focusCategory.toUpperCase(),
                              style: AppTextStyles.overline.copyWith(
                                color: textAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.formattedTime,
                            style: AppTextStyles.timerHero.copyWith(
                              color: palette.heading,
                              fontSize: 36,
                              letterSpacing: -1,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.isTimerRunning
                                ? (isStopwatch
                                      ? 'Flow state active...'
                                      : (mode == 0
                                            ? 'Stay in the zone...'
                                            : 'Breathe and relax...'))
                                : 'Ready to start',
                            style: textTheme.labelSmall?.copyWith(
                              color: palette.caption,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.selectedAmbience != 'Mute') ...[
                            const SizedBox(height: 5),
                            _buildMiniEqualizerBadge(
                              palette,
                              accentColor,
                              textAccent,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 3. Quick Time Boosts (+1m / +5m) or Finish Flow Session
                if (!isStopwatch && widget.onAddMinutes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: 6,
                      children: [
                        _buildQuickAdjustPill(
                          palette: palette,
                          label: '+1m',
                          tooltip: 'Add 1 minute',
                          onTap: () => widget.onAddMinutes!(1),
                        ),
                        _buildQuickAdjustPill(
                          palette: palette,
                          label: '+5m',
                          tooltip: 'Add 5 minutes',
                          onTap: () => widget.onAddMinutes!(5),
                        ),
                        if (widget.onOpenZenMode != null)
                          _buildQuickAdjustPill(
                            palette: palette,
                            label: 'Zen Mode',
                            icon: Icons.self_improvement_rounded,
                            tooltip: 'Enter Full-Screen Zen Mode',
                            onTap: widget.onOpenZenMode!,
                          ),
                      ],
                    ),
                  )
                else if (isStopwatch && widget.onFinishStopwatch != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: 6,
                      children: [
                        _buildQuickAdjustPill(
                          palette: palette,
                          label: 'Finish & Log Flow',
                          icon: Icons.check_circle_outline_rounded,
                          tooltip: 'Save elapsed stopwatch session',
                          onTap: widget.onFinishStopwatch!,
                        ),
                        if (widget.onOpenZenMode != null)
                          _buildQuickAdjustPill(
                            palette: palette,
                            label: 'Zen Mode',
                            icon: Icons.self_improvement_rounded,
                            tooltip: 'Enter Full-Screen Zen Mode',
                            onTap: widget.onOpenZenMode!,
                          ),
                      ],
                    ),
                  ),

                // 4. Linked Task Capsule + Pomodoro Target Progress
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: widget.onChangeTask,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceMuted,
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(color: palette.divider),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.track_changes_rounded,
                                    size: 13.5,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Focusing on: "${widget.linkedTask}"',
                                      maxLines: _expandLinkedTaskText
                                          ? null
                                          : 2,
                                      overflow: _expandLinkedTaskText
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: palette.heading,
                                        fontSize: 12,
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                        alpha: isDark ? 0.18 : 0.12,
                                      ),
                                      borderRadius: AppRadius.radiusFull,
                                    ),
                                    child: Text(
                                      '🍅 ${widget.completedTaskPomodoros}/${widget.estimatedPomodoros}',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: textAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 12,
                                    color: palette.caption,
                                  ),
                                ],
                              ),
                              if (_expandLinkedTaskText &&
                                  linkedItem != null &&
                                  linkedItem.notes.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  linkedItem.notes,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: palette.body,
                                    fontSize: 11.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (widget.linkedTask.length > 48 ||
                          (linkedItem != null && linkedItem.notes.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: InkWell(
                            onTap: () => setState(
                              () => _expandLinkedTaskText =
                                  !_expandLinkedTaskText,
                            ),
                            borderRadius: AppRadius.radiusFull,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _expandLinkedTaskText
                                        ? 'Show less'
                                        : 'Show more details',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: textAccent,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    _expandLinkedTaskText
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: textAccent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Optional Linked Planner Task Subtasks & Quick Complete Bar
                if (linkedItem != null && !linkedItem.isDone) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      if (hasChecklist)
                        InkWell(
                          onTap: () =>
                              setState(() => _showSubtasks = !_showSubtasks),
                          borderRadius: AppRadius.radiusFull,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceMuted,
                              borderRadius: AppRadius.radiusFull,
                              border: Border.all(color: palette.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.checklist_rounded,
                                  size: 12,
                                  color: textAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Subtasks ${linkedItem.checklistDoneCount}/${linkedItem.checklist.length}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: palette.heading,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  _showSubtasks
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: palette.caption,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (widget.onMarkTaskDone != null)
                        InkWell(
                          onTap: widget.onMarkTaskDone,
                          borderRadius: AppRadius.radiusFull,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(
                                alpha: isDark ? 0.18 : 0.12,
                              ),
                              borderRadius: AppRadius.radiusFull,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.task_alt_rounded,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Complete Task',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: isDark
                                        ? AppColors.moduleTasksLight
                                        : AppColors.moduleTasksDark,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: (_showSubtasks && hasChecklist)
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: palette.surfaceMuted,
                                borderRadius: AppRadius.radiusMd,
                                border: Border.all(color: palette.divider),
                              ),
                              child: Column(
                                children: linkedItem.checklist.map((sub) {
                                  return InkWell(
                                    onTap: widget.onToggleSubtask != null
                                        ? () => widget.onToggleSubtask!(sub)
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            sub.isDone
                                                ? Icons.check_box_rounded
                                                : Icons
                                                      .check_box_outline_blank_rounded,
                                            size: 15,
                                            color: sub.isDone
                                                ? accentColor
                                                : palette.caption,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              sub.title,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: sub.isDone
                                                        ? palette.caption
                                                        : palette.heading,
                                                    fontSize: 11.5,
                                                    decoration: sub.isDone
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : null,
                                                    decorationColor:
                                                        palette.caption,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),

                // 5. Primary Timer Action Controls
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset Button
                      IconButton.filledTonal(
                        onPressed: widget.onResetTimer,
                        tooltip: 'Reset Timer',
                        style: IconButton.styleFrom(
                          backgroundColor: palette.surfaceMuted,
                          foregroundColor: palette.heading,
                          side: BorderSide(color: palette.divider),
                          fixedSize: const Size.square(38),
                          minimumSize: const Size.square(38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Main Start/Pause Button
                      ElevatedButton.icon(
                        onPressed: widget.onToggleTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusFull,
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          widget.isTimerRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                        label: Text(
                          widget.isTimerRunning ? 'Pause' : 'Start Focus',
                          style: AppTextStyles.buttonLabel.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Skip Session Button
                      IconButton.filledTonal(
                        onPressed: widget.onSkipSession,
                        tooltip: 'Skip Session',
                        style: IconButton.styleFrom(
                          backgroundColor: palette.surfaceMuted,
                          foregroundColor: palette.heading,
                          side: BorderSide(color: palette.divider),
                          fixedSize: const Size.square(38),
                          minimumSize: const Size.square(38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.skip_next_rounded, size: 18),
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

  Widget _buildQuickAdjustPill({
    required AppPalette palette,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.surfaceMuted,
        shape: StadiumBorder(side: BorderSide(color: palette.divider)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12, color: palette.heading),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: palette.heading,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniEqualizerBadge(
    AppPalette palette,
    Color accentColor,
    Color textAccent,
  ) {
    final v = widget.isTimerRunning ? _pulseController.value : 0.3;
    final heights = [
      4.0 + 6.0 * v,
      9.0 - 4.0 * v,
      5.0 + 5.0 * (1 - v),
      8.0 * v + 3.0,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: palette.isDark ? 0.16 : 0.10),
        borderRadius: AppRadius.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final h in heights)
            Container(
              width: 2,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          const SizedBox(width: 4),
          Text(
            widget.selectedAmbience,
            style: context.text.labelSmall?.copyWith(
              color: textAccent,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom dial painter with 60 precision radial tick marks, breathing halo,
/// rounded progress arc, and glowing progress orb tip.
class _FocusDialPainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final bool isRunning;
  final Color accentColor;
  final Color trackColor;
  final Color cardColor;

  const _FocusDialPainter({
    required this.progress,
    required this.pulseValue,
    required this.isRunning,
    required this.accentColor,
    required this.trackColor,
    required this.cardColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final dialRadius = outerRadius - 8;

    // 1. Breathing halo when running
    if (isRunning) {
      final haloPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.10 + (0.14 * pulseValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 + (6 * pulseValue);
      canvas.drawCircle(center, dialRadius, haloPaint);
    }

    // 2. 60 Radial Tick Marks around the dial
    const int tickCount = 60;
    final activeTicks = (progress * tickCount).round();
    final tickPaintActive = Paint()
      ..color = accentColor.withValues(alpha: 0.90)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final tickPaintInactive = Paint()
      ..color = trackColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < tickCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / tickCount);
      final isMajor = i % 5 == 0;
      final innerR = dialRadius - (isMajor ? 12.5 : 10.0);
      final outerR = dialRadius - 7.5;
      final p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      canvas.drawLine(
        p1,
        p2,
        i <= activeTicks ? tickPaintActive : tickPaintInactive,
      );
    }

    // 3. Track Ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawCircle(center, dialRadius, trackPaint);

    // 4. Active Progress Arc
    if (progress > 0.001) {
      final sweepAngle = 2 * math.pi * progress;
      final arcPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: dialRadius),
        -math.pi / 2,
        sweepAngle,
        false,
        arcPaint,
      );

      // 5. Glowing Orb at the leading edge of the progress arc
      final endAngle = -math.pi / 2 + sweepAngle;
      final tipCenter = Offset(
        center.dx + dialRadius * math.cos(endAngle),
        center.dy + dialRadius * math.sin(endAngle),
      );
      final glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipCenter, 7.5, glowPaint);

      final dotPaint = Paint()
        ..color = cardColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipCenter, 3.5, dotPaint);

      final dotBorderPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(tipCenter, 3.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FocusDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.trackColor != trackColor;
  }
}
