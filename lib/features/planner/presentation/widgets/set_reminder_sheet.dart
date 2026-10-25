import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../domain/entities/planner_item_entity.dart';

class SetReminderSheet extends StatefulWidget {
  final String initialTitle;
  final DateTime? initialDate;
  final TimeOfDay initialTime;
  final String initialCategory;
  final String initialRepeatType;
  final String initialRepeatDays;
  final DateTime? initialEndDate;
  final String initialPriority;
  final int initialReminderOffsetMinutes;
  final List<ChecklistItem> initialChecklist;
  final String initialNotes;
  final String? sheetTitle;
  final String? submitButtonText;
  final bool isDark;
  final void Function({
    required String title,
    required DateTime date,
    required TimeOfDay time,
    required String category,
    required String repeatType,
    required String repeatDays,
    required DateTime? endDate,
    required String priority,
    required int reminderOffsetMinutes,
    required List<ChecklistItem> checklist,
    required String notes,
  }) onSubmit;

  const SetReminderSheet({
    super.key,
    required this.initialTitle,
    this.initialDate,
    required this.initialTime,
    required this.initialCategory,
    this.initialRepeatType = 'none',
    this.initialRepeatDays = '',
    this.initialEndDate,
    this.initialPriority = 'medium',
    this.initialReminderOffsetMinutes = 0,
    this.initialChecklist = const [],
    this.initialNotes = '',
    this.sheetTitle,
    this.submitButtonText,
    required this.isDark,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialTitle,
    DateTime? initialDate,
    required TimeOfDay initialTime,
    required String initialCategory,
    String initialRepeatType = 'none',
    String initialRepeatDays = '',
    DateTime? initialEndDate,
    String initialPriority = 'medium',
    int initialReminderOffsetMinutes = 0,
    List<ChecklistItem> initialChecklist = const [],
    String initialNotes = '',
    String? sheetTitle,
    String? submitButtonText,
    required bool isDark,
    required void Function({
      required String title,
      required DateTime date,
      required TimeOfDay time,
      required String category,
      required String repeatType,
      required String repeatDays,
      required DateTime? endDate,
      required String priority,
      required int reminderOffsetMinutes,
      required List<ChecklistItem> checklist,
      required String notes,
    }) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetReminderSheet(
        initialTitle: initialTitle,
        initialDate: initialDate,
        initialTime: initialTime,
        initialCategory: initialCategory,
        initialRepeatType: initialRepeatType,
        initialRepeatDays: initialRepeatDays,
        initialEndDate: initialEndDate,
        initialPriority: initialPriority,
        initialReminderOffsetMinutes: initialReminderOffsetMinutes,
        initialChecklist: initialChecklist,
        initialNotes: initialNotes,
        sheetTitle: sheetTitle,
        submitButtonText: submitButtonText,
        isDark: isDark,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<SetReminderSheet> createState() => _SetReminderSheetState();
}

class _SetReminderSheetState extends State<SetReminderSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _newChecklistController;

  late TimeOfDay _time;
  late DateTime _startDate;
  late String _category;
  late String _repeatType; // 'none', 'daily', 'weekdays', 'weekly', 'monthly'
  late Set<int> _selectedWeekdays; // 1=Mon .. 7=Sun
  late bool _hasEndDate;
  DateTime? _endDate;
  late String _priority; // 'low', 'medium', 'high', 'urgent'
  late int _reminderOffsetMinutes; // 0, 5, 15, 30, 60, 1440
  late List<ChecklistItem> _checklist;

  static const List<String> _categories = [
    'Personal',
    'Work',
    'Health',
    'Finance',
    'Important',
  ];

  static const List<Map<String, dynamic>> _repeatOptions = [
    {'type': 'none', 'label': 'Once'},
    {'type': 'daily', 'label': 'Daily'},
    {'type': 'weekdays', 'label': 'Weekdays'},
    {'type': 'weekly', 'label': 'Weekly'},
    {'type': 'monthly', 'label': 'Monthly'},
  ];

  static const List<Map<String, dynamic>> _priorityOptions = [
    {'level': 'low', 'label': 'Low', 'color': Color(0xFF10B981)},
    {'level': 'medium', 'label': 'Medium', 'color': Color(0xFF6366F1)},
    {'level': 'high', 'label': 'High', 'color': Color(0xFFF97316)},
    {'level': 'urgent', 'label': 'Urgent', 'color': Color(0xFFDC2626)},
  ];

  static const List<Map<String, dynamic>> _leadTimeOptions = [
    {'offset': 0, 'label': 'At time'},
    {'offset': 5, 'label': '5m before'},
    {'offset': 15, 'label': '15m before'},
    {'offset': 30, 'label': '30m before'},
    {'offset': 60, 'label': '1h before'},
    {'offset': 1440, 'label': '1 day before'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _notesController = TextEditingController(text: widget.initialNotes);
    _newChecklistController = TextEditingController();

    _time = widget.initialTime;
    _startDate = widget.initialDate ?? DateTime.now();
    _category = widget.initialCategory;
    _repeatType = widget.initialRepeatType;

    _selectedWeekdays = widget.initialRepeatDays.isNotEmpty
        ? widget.initialRepeatDays
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toSet()
        : {_startDate.weekday};

    _hasEndDate = widget.initialEndDate != null;
    _endDate = widget.initialEndDate;
    _priority = widget.initialPriority;
    _reminderOffsetMinutes = widget.initialReminderOffsetMinutes;
    _checklist = List.from(widget.initialChecklist);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _newChecklistController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return AppColors.primary;
      case 'Health':
        return AppColors.success;
      case 'Finance':
        return AppColors.moduleMoney;
      case 'Important':
        return AppColors.error;
      case 'Personal':
      default:
        return AppColors.moduleTime;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatDateShort(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _addChecklistItem() {
    final text = _newChecklistController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklist.add(ChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text,
      ));
      _newChecklistController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardBg =
        widget.isDark ? AppColors.darkCardBackground : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadius.topXxl,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.5 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.moduleTime.withValues(alpha: 0.14),
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: Icon(
                          widget.sheetTitle != null
                              ? Icons.edit_calendar_rounded
                              : Icons.alarm_add_rounded,
                          size: 18,
                          color: AppColors.moduleTime,
                        ),
                      ),
                      AppSpacing.gapW12,
                      Text(
                        widget.sheetTitle ?? StringConstants.setReminder,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: widget.isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: widget.isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              AppSpacing.gapH16,

              // ── Title Input ────────────────────────────────────────────────
              TextField(
                controller: _titleController,
                autofocus: widget.initialTitle.isEmpty,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: widget.isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Reminder Title',
                  hintText: StringConstants.reminderHint,
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
              ),
              AppSpacing.gapH16,

              // ── Schedule: Start Date & Time ────────────────────────────────
              Text(
                'Schedule:',
                style: AppTextStyles.captionBold.copyWith(
                  color: widget.isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              AppSpacing.gapH8,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            if (_repeatType == 'weekly' && _selectedWeekdays.isEmpty) {
                              _selectedWeekdays = {picked.weekday};
                            }
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd),
                        side: BorderSide(
                          color: widget.isDark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppColors.moduleTime),
                      label: Text(
                        _formatDateShort(_startDate),
                        style: AppTextStyles.captionBold.copyWith(
                          color: widget.isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapW8,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (picked != null) {
                          setState(() => _time = picked);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd),
                        side: BorderSide(
                          color: widget.isDark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                        ),
                      ),
                      icon: const Icon(Icons.access_time_rounded,
                          size: 16, color: AppColors.moduleTime),
                      label: Text(
                        _formatTimeOfDay(_time),
                        style: AppTextStyles.captionBold.copyWith(
                          color: widget.isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,

              // ── Recurrence Frequency ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repeat Frequency:',
                    style: AppTextStyles.captionBold.copyWith(
                      color: widget.isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                    ),
                  ),
                  if (_repeatType != 'none')
                    Text(
                      'Recurring',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.moduleTime,
                      ),
                    ),
                ],
              ),
              AppSpacing.gapH8,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _repeatOptions.map((opt) {
                    final type = opt['type'] as String;
                    final label = opt['label'] as String;
                    final isSelected = _repeatType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppColors.moduleTime.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.moduleTime
                              : (widget.isDark
                                  ? AppColors.darkTextCaption
                                  : AppColors.textCaption),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _repeatType = type);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Weekly Day Selector (if Weekly chosen) ──────────────────────
              if (_repeatType == 'weekly') ...[
                AppSpacing.gapH12,
                Text(
                  'Repeat on days:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
                AppSpacing.gapH8,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    {'d': 1, 'name': 'M'},
                    {'d': 2, 'name': 'T'},
                    {'d': 3, 'name': 'W'},
                    {'d': 4, 'name': 'T'},
                    {'d': 5, 'name': 'F'},
                    {'d': 6, 'name': 'S'},
                    {'d': 7, 'name': 'S'},
                  ].map((entry) {
                    final dayNum = entry['d'] as int;
                    final dayLabel = entry['name'] as String;
                    final isPicked = _selectedWeekdays.contains(dayNum);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isPicked) {
                            if (_selectedWeekdays.length > 1) {
                              _selectedWeekdays.remove(dayNum);
                            }
                          } else {
                            _selectedWeekdays.add(dayNum);
                          }
                        });
                      },
                      borderRadius: AppRadius.radiusFull,
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPicked
                              ? AppColors.moduleTime
                              : (widget.isDark
                                  ? AppColors.darkSurfaceSecondary
                                  : AppColors.surfaceSecondary),
                          border: Border.all(
                            color: isPicked
                                ? AppColors.moduleTime
                                : (widget.isDark
                                    ? AppColors.darkDivider
                                    : AppColors.divider),
                          ),
                        ),
                        child: Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isPicked
                                ? Colors.white
                                : (widget.isDark
                                    ? AppColors.darkTextHeading
                                    : AppColors.textHeading),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // ── Date Range End Condition (if Recurring) ───────────────────
              if (_repeatType != 'none') ...[
                AppSpacing.gapH12,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'End Repeat:',
                      style: AppTextStyles.captionBold.copyWith(
                        color: widget.isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _hasEndDate ? 'Until Date' : 'Forever',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
                          ),
                        ),
                        Switch(
                          value: _hasEndDate,
                          activeThumbColor: AppColors.moduleTime,
                          onChanged: (val) {
                            setState(() {
                              _hasEndDate = val;
                              if (val && _endDate == null) {
                                _endDate = _startDate.add(const Duration(days: 30));
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                if (_hasEndDate)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                        firstDate: _startDate,
                        lastDate: _startDate.add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMd),
                      side: BorderSide(
                        color: widget.isDark
                            ? AppColors.darkDivider
                            : AppColors.divider,
                      ),
                    ),
                    icon: const Icon(Icons.event_busy_rounded,
                        size: 16, color: AppColors.moduleTime),
                    label: Text(
                      _endDate != null
                          ? 'Repeat until: ${_formatDateShort(_endDate!)}'
                          : 'Set End Date',
                      style: AppTextStyles.captionBold.copyWith(
                        color: widget.isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading,
                      ),
                    ),
                  ),
              ],
              AppSpacing.gapH16,

              // ── Priority Matrix ───────────────────────────────────────────
              Text(
                'Priority Level:',
                style: AppTextStyles.captionBold.copyWith(
                  color: widget.isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              AppSpacing.gapH8,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _priorityOptions.map((opt) {
                    final level = opt['level'] as String;
                    final label = opt['label'] as String;
                    final color = opt['color'] as Color;
                    final isSelected = _priority == level;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: CircleAvatar(
                          radius: 5,
                          backgroundColor: color,
                        ),
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: color.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? color
                              : (widget.isDark
                                  ? AppColors.darkTextCaption
                                  : AppColors.textCaption),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _priority = level);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              AppSpacing.gapH16,

              // ── Early Alert Lead Time ─────────────────────────────────────
              Text(
                'Advance Alert Notice:',
                style: AppTextStyles.captionBold.copyWith(
                  color: widget.isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              AppSpacing.gapH8,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _leadTimeOptions.map((opt) {
                    final offset = opt['offset'] as int;
                    final label = opt['label'] as String;
                    final isSelected = _reminderOffsetMinutes == offset;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : (widget.isDark
                                  ? AppColors.darkTextCaption
                                  : AppColors.textCaption),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _reminderOffsetMinutes = offset);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              AppSpacing.gapH16,

              // ── Category ──────────────────────────────────────────────────
              Text(
                'Category:',
                style: AppTextStyles.captionBold.copyWith(
                  color: widget.isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              AppSpacing.gapH8,
              Wrap(
                spacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _category == cat;
                  final catColor = _getCategoryColor(cat);
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: catColor.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? catColor
                          : (widget.isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              AppSpacing.gapH16,

              // ── Subtasks / Checklist Builder ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Checklist Subtasks (${_checklist.length}):',
                    style: AppTextStyles.captionBold.copyWith(
                      color: widget.isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH8,
              ..._checklist.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: item.isDone,
                        activeColor: AppColors.moduleTime,
                        onChanged: (val) {
                          setState(() {
                            final idx = _checklist.indexWhere((c) => c.id == item.id);
                            if (idx != -1) {
                              _checklist[idx] = item.copyWith(isDone: val ?? false);
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.isDark
                                ? AppColors.darkTextHeading
                                : AppColors.textHeading,
                            decoration:
                                item.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        color: AppColors.error.withValues(alpha: 0.6),
                        onPressed: () {
                          setState(() {
                            _checklist.removeWhere((c) => c.id == item.id);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newChecklistController,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a subtask...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.radiusMd,
                          borderSide: BorderSide(
                            color: widget.isDark
                                ? AppColors.darkDivider
                                : AppColors.divider,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _addChecklistItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _addChecklistItem,
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                ],
              ),
              AppSpacing.gapH16,

              // ── Notes / Description ────────────────────────────────────────
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                ),
                decoration: InputDecoration(
                  labelText: 'Notes / Details (Optional)',
                  hintText: 'Add extra details or reminders here...',
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
              ),
              AppSpacing.gapH24,

              // ── Submit Button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a reminder title.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final repeatDaysStr = _repeatType == 'weekly'
                        ? (_selectedWeekdays.toList()..sort()).join(',')
                        : '';

                    final finalEndDate = _hasEndDate ? _endDate : null;

                    widget.onSubmit(
                      title: title,
                      date: _startDate,
                      time: _time,
                      category: _category,
                      repeatType: _repeatType,
                      repeatDays: repeatDaysStr,
                      endDate: finalEndDate,
                      priority: _priority,
                      reminderOffsetMinutes: _reminderOffsetMinutes,
                      checklist: _checklist,
                      notes: _notesController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.moduleTime,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: Text(
                    widget.submitButtonText ?? StringConstants.setReminder,
                    style:
                        AppTextStyles.buttonText.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
