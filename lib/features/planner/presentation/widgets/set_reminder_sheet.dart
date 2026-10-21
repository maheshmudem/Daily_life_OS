import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';

class SetReminderSheet extends StatefulWidget {
  final String initialTitle;
  final TimeOfDay initialTime;
  final String initialCategory;
  final bool isDark;
  final void Function(
    String title,
    DateTime date,
    TimeOfDay time,
    String category,
  ) onSubmit;

  const SetReminderSheet({
    super.key,
    required this.initialTitle,
    required this.initialTime,
    required this.initialCategory,
    required this.isDark,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialTitle,
    required TimeOfDay initialTime,
    required String initialCategory,
    required bool isDark,
    required void Function(
      String title,
      DateTime date,
      TimeOfDay time,
      String category,
    ) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetReminderSheet(
        initialTitle: initialTitle,
        initialTime: initialTime,
        initialCategory: initialCategory,
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
  late TimeOfDay _time;
  late DateTime _date;
  late String _category;

  static const List<String> _categories = [
    'Personal',
    'Work',
    'Health',
    'Finance',
    'Important',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _time = widget.initialTime;
    _date = DateTime.now();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
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
                        child: const Icon(
                          Icons.alarm_add_rounded,
                          size: 18,
                          color: AppColors.moduleTime,
                        ),
                      ),
                      AppSpacing.gapW12,
                      Text(
                        StringConstants.setReminder,
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
              TextField(
                controller: _titleController,
                autofocus: true,
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
                          initialDate: _date,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _date = picked);
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
                        _formatDateShort(_date),
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
              AppSpacing.gapH24,
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

                    widget.onSubmit(title, _date, _time, _category);
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
                    StringConstants.setReminder,
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
