import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/countdown_item_entity.dart';

class CountdownSheet extends StatefulWidget {
  final CountdownItemEntity? editItem;
  final bool isDark;
  final ValueChanged<CountdownItemEntity> onSave;

  const CountdownSheet({
    super.key,
    this.editItem,
    required this.isDark,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    CountdownItemEntity? editItem,
    required bool isDark,
    required ValueChanged<CountdownItemEntity> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CountdownSheet(
        editItem: editItem,
        isDark: isDark,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CountdownSheet> createState() => _CountdownSheetState();
}

class _CountdownSheetState extends State<CountdownSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late bool _remindAdvance;

  static const List<String> _categories = [
    'Birthday',
    'Renewal',
    'Travel',
    'Milestone',
    'Anniversary',
    'Event',
  ];

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.editItem?.title ?? '');
    _notesController =
        TextEditingController(text: widget.editItem?.notes ?? '');
    _selectedDate = widget.editItem?.date ??
        DateTime.now().add(const Duration(days: 7));
    _selectedCategory = widget.editItem?.category ?? 'Birthday';
    _remindAdvance = widget.editItem?.remindAdvance ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Anniversary':
        return const Color(0xFFEC4899);
      case 'Renewal':
        return AppColors.moduleTime;
      case 'Travel':
        return const Color(0xFF06B6D4);
      case 'Milestone':
        return AppColors.success;
      case 'Event':
        return AppColors.primary;
      case 'Birthday':
      default:
        return AppColors.moduleNotes;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Anniversary':
        return Icons.favorite_rounded;
      case 'Renewal':
        return Icons.directions_car_rounded;
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Milestone':
        return Icons.emoji_events_rounded;
      case 'Event':
        return Icons.event_available_rounded;
      case 'Birthday':
      default:
        return Icons.cake_rounded;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadius.topXxl,
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
                  Text(
                    widget.editItem == null
                        ? 'Create Countdown'
                        : 'Edit Countdown',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: widget.isDark
                          ? AppColors.darkTextHeading
                          : AppColors.textHeading,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Event Title
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'e.g., Mom\'s 50th Birthday, Trip to Paris',
                  prefixIcon: Icon(Icons.event_note_rounded),
                  border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                ),
              ),
              const SizedBox(height: 14),

              // Target Date Picker
              Text(
                'Target Event Date:',
                style: AppTextStyles.captionBold.copyWith(
                  color: widget.isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd),
                  side: BorderSide(
                      color: widget.isDark
                          ? AppColors.darkDivider
                          : AppColors.divider),
                ),
                icon: const Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.moduleTime),
                label: Text(
                  _formatDate(_selectedDate),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: widget.isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Category Selector
              Text(
                'Category:',
                style: AppTextStyles.captionBold.copyWith(
                  color: widget.isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final color = _getCategoryColor(cat);

                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: color.withValues(alpha: 0.2),
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
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Notes / Gift Ideas
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes or Gift Ideas (Optional)',
                  hintText: 'e.g., Hotel booking code, gift wishlist...',
                  prefixIcon: Icon(Icons.card_giftcard_rounded),
                  border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                ),
              ),
              const SizedBox(height: 10),

              // Remind advance toggle (wrapped in Material to avoid ink splash warning)
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Advance Alert Reminders',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Notify 7 days & 1 day before event',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textCaption)),
                  value: _remindAdvance,
                  activeThumbColor: AppColors.moduleTime,
                  onChanged: (val) => setState(() => _remindAdvance = val),
                ),
              ),
              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.moduleTime,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusMd),
                  ),
                  onPressed: () {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an event title.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final color = _getCategoryColor(_selectedCategory);
                    final icon = _getCategoryIcon(_selectedCategory);

                    final item = CountdownItemEntity(
                      id: widget.editItem?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      date: _selectedDate,
                      category: _selectedCategory,
                      colorValue: color.toARGB32(),
                      iconCodePoint: icon.codePoint,
                      notes: _notesController.text.trim(),
                      remindAdvance: _remindAdvance,
                    );

                    widget.onSave(item);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    widget.editItem == null
                        ? 'Create Countdown'
                        : 'Update Countdown',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
