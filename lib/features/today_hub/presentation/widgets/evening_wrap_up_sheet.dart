import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../di/injection_container.dart';
import '../../../notes/domain/usecases/manage_notes_usecases.dart';
import '../bloc/today_hub_bloc.dart';

class EveningWrapUpSheet extends StatefulWidget {
  final double spentToday;
  final double safeDailyLimit;

  const EveningWrapUpSheet({
    super.key,
    required this.spentToday,
    required this.safeDailyLimit,
  });

  static Future<void> show(
    BuildContext context, {
    required double spentToday,
    required double safeDailyLimit,
  }) {
    final bloc = context.read<TodayHubBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EveningWrapUpSheet(
          spentToday: spentToday,
          safeDailyLimit: safeDailyLimit,
        ),
      ),
    );
  }

  @override
  State<EveningWrapUpSheet> createState() => _EveningWrapUpSheetState();
}

class _EveningWrapUpSheetState extends State<EveningWrapUpSheet> {
  final TextEditingController _reflectionController = TextEditingController();
  String _selectedMood = 'Focused ⚡';
  bool _savingReflection = false;

  static const List<String> _moodOptions = [
    'Focused ⚡',
    'Accomplished 🏆',
    'Calm 🌿',
    'Grateful 🙏',
    'Recharging 🌙',
  ];

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _saveReflection(TodayHubLoaded state) async {
    final reflectionText = _reflectionController.text.trim();
    setState(() => _savingReflection = true);
    try {
      final now = DateTime.now();
      final dateTitle = DateFormat('EEE, d MMM yyyy').format(now);
      final doneHabits = state.completedHabits;
      final totalHabits = state.habits.length;
      final doneTasks = state.timelineItems.where((t) => t.isDone).length;
      final totalTasks = state.timelineItems.length;

      final bodyLines = <String>[
        'Mood: $_selectedMood',
        'Habits Completed: $doneHabits / $totalHabits',
        'Timeline Tasks Done: $doneTasks / $totalTasks',
        'Daily Spend: ₹${widget.spentToday.toStringAsFixed(0)} / ₹${widget.safeDailyLimit.toStringAsFixed(0)}',
        if (reflectionText.isNotEmpty) ...['', 'Reflection:', reflectionText],
      ];

      await sl<AddNoteUseCase>()(
        title: 'Evening Wrap-Up • $dateTitle',
        content: bodyLines.join('\n'),
        colorValue: AppColors.primary.toARGB32(),
        tags: 'reflection,wrap-up',
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evening Wrap-Up & Reflection saved to Notes!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _savingReflection = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: palette.border, width: 0.8)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BlocBuilder<TodayHubBloc, TodayHubState>(
        builder: (context, state) {
          if (state is! TodayHubLoaded) {
            return const SizedBox(height: 220);
          }

          final pendingHabits = state.habits
              .where((h) => !h.isDoneToday && !h.isSkippedToday)
              .toList();
          final pendingTasks = state.timelineItems
              .where((t) => !t.isDone)
              .toList();
          final totalItems = state.habits.length + state.timelineItems.length;
          final doneItems =
              state.completedHabits +
              state.timelineItems.where((t) => t.isDone).length;
          final pct = totalItems == 0
              ? 100
              : ((doneItems / totalItems) * 100).round();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: palette.isDark ? 0.24 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.nights_stay_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Evening Wrap-Up & Daily Review',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.heading,
                            ),
                          ),
                          Text(
                            '$pct% daily completion • Close out remaining items & reflect',
                            style: text.labelSmall?.copyWith(
                              color: palette.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.caption,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Summary Strip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _WrapStatItem(
                          label: 'Habits Done',
                          value:
                              '${state.completedHabits}/${state.habits.length}',
                          color: AppColors.success,
                        ),
                      ),
                      Container(width: 1, height: 26, color: palette.border),
                      Expanded(
                        child: _WrapStatItem(
                          label: 'Tasks Done',
                          value:
                              '${state.timelineItems.where((t) => t.isDone).length}/${state.timelineItems.length}',
                          color: AppColors.primary,
                        ),
                      ),
                      Container(width: 1, height: 26, color: palette.border),
                      Expanded(
                        child: _WrapStatItem(
                          label: 'Spent Today',
                          value: '₹${widget.spentToday.toStringAsFixed(0)}',
                          color: widget.spentToday <= widget.safeDailyLimit
                              ? AppColors.secondary
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),

                // Unfinished Habits Quick Review
                if (pendingHabits.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'PENDING HABITS (${pendingHabits.length})',
                    style: text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: palette.caption,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pendingHabits.map((h) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          Icon(h.icon, size: 16, color: h.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelLarge?.copyWith(
                                fontSize: 12.5,
                                color: palette.heading,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<TodayHubBloc>().add(SkipHabit(h.id));
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(fontSize: 11.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          FilledButton.tonal(
                            onPressed: () {
                              context.read<TodayHubBloc>().add(
                                ToggleHabit(h.id),
                              );
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Complete',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                // Unfinished Tasks Quick Review
                if (pendingTasks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'UNFINISHED TIMELINE TASKS (${pendingTasks.length})',
                    style: text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: palette.caption,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pendingTasks.map((t) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          Icon(t.icon, size: 16, color: t.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${t.time} • ${t.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelLarge?.copyWith(
                                fontSize: 12.5,
                                color: palette.heading,
                              ),
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () {
                              context.read<TodayHubBloc>().add(
                                ToggleTimelineItem(t.id),
                              );
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Mark Done',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),
                Text(
                  'HOW DID TODAY FEEL?',
                  style: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: palette.caption,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _moodOptions.map((mood) {
                    final selected = _selectedMood == mood;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMood = mood),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(
                                  alpha: palette.isDark ? 0.24 : 0.14,
                                )
                              : palette.surfaceMuted,
                          borderRadius: AppRadius.radiusFull,
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : palette.border,
                          ),
                        ),
                        child: Text(
                          mood,
                          style: text.labelSmall?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected ? AppColors.primary : palette.body,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text(
                  'DAILY REFLECTION & WINS (SAVES TO NOTES)',
                  style: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: palette.caption,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _reflectionController,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText:
                        'What went well today? What is your #1 priority for tomorrow?',
                    filled: true,
                    fillColor: palette.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: palette.border),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _savingReflection
                        ? null
                        : () => _saveReflection(state),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                    label: Text(
                      _savingReflection
                          ? 'Saving Reflection...'
                          : 'Complete Wrap-Up & Save Reflection',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WrapStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _WrapStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: text.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: text.labelSmall?.copyWith(
            fontSize: 10.5,
            color: palette.caption,
          ),
        ),
      ],
    );
  }
}
