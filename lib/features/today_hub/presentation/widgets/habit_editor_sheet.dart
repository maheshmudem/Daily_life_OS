import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../domain/entities/habit_entity.dart';

class HabitEditorSheet extends StatefulWidget {
  final HabitEntity? existing;
  final ValueChanged<HabitEntity> onSave;
  final VoidCallback? onDelete;

  const HabitEditorSheet({
    super.key,
    this.existing,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    HabitEntity? existing,
    required ValueChanged<HabitEntity> onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => HabitEditorSheet(
        existing: existing,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<HabitEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _category;
  late String _scheduleType;
  late Set<int> _selectedDays;
  late int _selectedIconCodePoint;
  late int _selectedColorValue;
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;
  String? _titleError;

  static const List<String> _categories = [
    'Morning',
    'Health',
    'Deep Work',
    'Mindfulness',
    'Evening',
    'General',
  ];

  static final List<IconData> _iconOptions = [
    Icons.water_drop_rounded,
    Icons.medication_rounded,
    Icons.auto_stories_rounded,
    Icons.self_improvement_rounded,
    Icons.fitness_center_rounded,
    Icons.directions_run_rounded,
    Icons.laptop_mac_rounded,
    Icons.edit_note_rounded,
    Icons.bedtime_rounded,
    Icons.wb_sunny_rounded,
    Icons.spa_rounded,
    Icons.bolt_rounded,
  ];

  static final List<Color> _colorOptions = [
    AppColors.secondary,
    AppColors.primary,
    AppColors.moduleMoney,
    AppColors.moduleVault,
    AppColors.moduleTime,
    AppColors.moduleNotes,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _category = (e != null && _categories.contains(e.category))
        ? e.category
        : 'Morning';
    _scheduleType = e?.scheduleType ?? 'daily';
    _selectedDays = e != null
        ? Set<int>.from(e.scheduledWeekdays)
        : {1, 2, 3, 4, 5, 6, 7};
    _selectedIconCodePoint =
        e?.iconCodePoint ?? Icons.water_drop_rounded.codePoint;
    _selectedColorValue = e?.colorValue ?? AppColors.secondary.toARGB32();
    _reminderEnabled = e?.reminderEnabled ?? false;
    _reminderTime =
        _parseTimeOfDay(e?.reminderTime) ?? const TimeOfDay(hour: 8, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTimeOfDay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final upper = raw.trim().toUpperCase();
      final isPm = upper.contains('PM');
      final isAm = upper.contains('AM');
      final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = clean.split(':');
      if (parts.length < 2) return null;
      int hour = int.parse(parts[0].trim());
      final int minute = int.parse(parts[1].trim());
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    } catch (_) {
      return null;
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final h = hour12.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    final suffix = tod.period == DayPeriod.pm ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }

  void _onScheduleTypeChanged(String type) {
    setState(() {
      _scheduleType = type;
      if (type == 'daily') {
        _selectedDays = {1, 2, 3, 4, 5, 6, 7};
      } else if (type == 'weekdays') {
        _selectedDays = {1, 2, 3, 4, 5};
      } else if (type == 'weekends') {
        _selectedDays = {6, 7};
      } else if (_selectedDays.isEmpty) {
        _selectedDays = {1, 3, 5};
      }
    });
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && mounted) {
      setState(() {
        _reminderTime = picked;
        _reminderEnabled = true;
      });
    }
  }

  void _handleSubmit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Please enter a habit or routine name');
      return;
    }

    final sortedDays =
        (_selectedDays.isEmpty
              ? <int>[1, 2, 3, 4, 5, 6, 7]
              : _selectedDays.toList())
          ..sort();
    final repeatCsv = sortedDays.join(',');
    final formattedReminder = _reminderEnabled
        ? _formatTimeOfDay(_reminderTime)
        : null;

    final existing = widget.existing;
    final entity = HabitEntity(
      id: existing?.id ?? 0,
      title: title,
      iconCodePoint: _selectedIconCodePoint,
      colorValue: _selectedColorValue,
      streakDays: existing?.streakDays ?? 0,
      isDoneToday: existing?.isDoneToday ?? false,
      lastCompletedDate: existing?.lastCompletedDate,
      createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
      description: _descriptionController.text.trim(),
      category: _category,
      scheduleType: _scheduleType,
      repeatDays: repeatCsv,
      reminderEnabled: _reminderEnabled,
      reminderTime: formattedReminder,
      isSkippedToday: existing?.isSkippedToday ?? false,
      completedDates: existing?.completedDates ?? const [],
      skippedDates: existing?.skippedDates ?? const [],
      bestStreak: existing?.bestStreak ?? 0,
    );

    HapticFeedback.mediumImpact();
    widget.onSave(entity);
    Navigator.of(context).pop();
  }

  Future<void> _handleDelete() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Habit?',
      message:
          'Are you sure you want to delete "${widget.existing?.title}"? Your streak and completion history for this habit will be permanently removed.',
      confirmLabel: 'Delete Habit',
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
      widget.onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final isEditing = widget.existing != null;
    final accentColor = Color(_selectedColorValue);

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: palette.border, width: 0.8)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
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

            // Header Row
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(
                      alpha: palette.isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    IconData(
                      // ignore: non_const_argument_for_const_parameter
                      _selectedIconCodePoint,
                      fontFamily: 'MaterialIcons',
                    ),
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        isEditing
                            ? 'Edit Habit & Routine'
                            : 'New Habit or Micro-Routine',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.heading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        'Configure schedule, category & daily reminder',
                        style: text.labelSmall?.copyWith(
                          color: palette.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEditing && widget.onDelete != null)
                  IconButton(
                    tooltip: 'Delete Habit',
                    onPressed: _handleDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: palette.caption,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Title Input
            AppText(
              'HABIT NAME',
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: palette.caption,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() => _titleError = null);
                }
              },
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.heading,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., Drink 3L Water, Read 15 mins, Deep Breathing',
                errorText: _titleError,
                filled: true,
                fillColor: palette.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Micro-Routine Cue / Description Input
            AppText(
              'MICRO-ROUTINE CUE OR NOTE (OPTIONAL)',
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: palette.caption,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              minLines: 1,
              style: text.bodySmall?.copyWith(color: palette.body),
              decoration: InputDecoration(
                hintText:
                    'e.g., Right after morning coffee • Keep water bottle on desk',
                filled: true,
                fillColor: palette.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
            const SizedBox(height: 14),

            // 3. Category Pills
            AppText(
              'CATEGORY',
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: palette.caption,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? accentColor.withValues(
                              alpha: palette.isDark ? 0.24 : 0.14,
                            )
                          : palette.surfaceMuted,
                      borderRadius: AppRadius.radiusFull,
                      border: Border.all(
                        color: selected ? accentColor : palette.border,
                        width: selected ? 1.2 : 0.8,
                      ),
                    ),
                    child: AppText(
                      cat,
                      style: text.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? accentColor : palette.body,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 4. Schedule & Repetition Frequency
            AppText(
              'SCHEDULE & FREQUENCY',
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: palette.caption,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ScheduleChip(
                  label: 'Every Day',
                  selected: _scheduleType == 'daily',
                  accentColor: accentColor,
                  onTap: () => _onScheduleTypeChanged('daily'),
                ),
                const SizedBox(width: 6),
                _ScheduleChip(
                  label: 'Weekdays',
                  selected: _scheduleType == 'weekdays',
                  accentColor: accentColor,
                  onTap: () => _onScheduleTypeChanged('weekdays'),
                ),
                const SizedBox(width: 6),
                _ScheduleChip(
                  label: 'Weekends',
                  selected: _scheduleType == 'weekends',
                  accentColor: accentColor,
                  onTap: () => _onScheduleTypeChanged('weekends'),
                ),
                const SizedBox(width: 6),
                _ScheduleChip(
                  label: 'Custom',
                  selected: _scheduleType == 'custom',
                  accentColor: accentColor,
                  onTap: () => _onScheduleTypeChanged('custom'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Day of Week Selector Row (M T W T F S S)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final dayNum = index + 1;
                const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final active = _selectedDays.contains(dayNum);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _scheduleType = 'custom';
                      if (active && _selectedDays.length > 1) {
                        _selectedDays.remove(dayNum);
                      } else {
                        _selectedDays.add(dayNum);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? accentColor : palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? accentColor : palette.border,
                      ),
                    ),
                    child: AppText(
                      labels[index],
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: active ? AppColors.textWhite : palette.body,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // 5. Icon & Accent Color Picker
            AppText(
              'ICON & ACCENT COLOR',
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: palette.caption,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _colorOptions.map((c) {
                final cVal = c.toARGB32();
                final isSelected = _selectedColorValue == cVal;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColorValue = cVal),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: palette.heading, width: 2.2)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: AppColors.textWhite,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _iconOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final ic = _iconOptions[index];
                  final selected = _selectedIconCodePoint == ic.codePoint;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedIconCodePoint = ic.codePoint),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? accentColor.withValues(
                                alpha: palette.isDark ? 0.25 : 0.14,
                              )
                            : palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? accentColor : palette.border,
                          width: selected ? 1.4 : 0.8,
                        ),
                      ),
                      child: Icon(
                        ic,
                        size: 19,
                        color: selected ? accentColor : palette.body,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 6. Reminder & Local Notification Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Icon(
                    _reminderEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: _reminderEnabled ? accentColor : palette.caption,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Daily Reminder Notification',
                          style: text.labelLarge?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.heading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: _pickReminderTime,
                          child: AppText(
                            _reminderEnabled
                                ? 'Scheduled for ${_formatTimeOfDay(_reminderTime)} (Tap to change)'
                                : 'Enable push alert at a specific time',
                            style: text.labelSmall?.copyWith(
                              color: _reminderEnabled
                                  ? accentColor
                                  : palette.caption,
                              fontWeight: _reminderEnabled
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_reminderEnabled)
                    TextButton(
                      onPressed: _pickReminderTime,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: AppText(
                        _formatTimeOfDay(_reminderTime),
                        style: text.labelMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Switch.adaptive(
                    value: _reminderEnabled,
                    activeTrackColor: accentColor,
                    onChanged: (val) async {
                      setState(() => _reminderEnabled = val);
                      if (val) {
                        await _pickReminderTime();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 7. Primary Save Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: _handleSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isEditing ? Icons.check_rounded : Icons.add_task_rounded,
                  size: 18,
                ),
                label: AppText.labelLarge(
                  isEditing ? 'Save Changes' : 'Create Habit',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ScheduleChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: palette.isDark ? 0.24 : 0.14)
                : palette.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? accentColor : palette.border,
              width: selected ? 1.2 : 0.8,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AppText(
                label,
                maxLines: 1,
                style: context.text.labelSmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? accentColor : palette.body,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
