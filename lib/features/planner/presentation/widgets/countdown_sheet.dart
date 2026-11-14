import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/utils/snackbar_utils.dart';
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
      backgroundColor: AppColors.transparent,
      builder: (ctx) =>
          CountdownSheet(editItem: editItem, isDark: isDark, onSave: onSave),
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
    _titleController = TextEditingController(
      text: widget.editItem?.title ?? '',
    );
    _notesController = TextEditingController(
      text: widget.editItem?.notes ?? '',
    );
    _selectedDate =
        widget.editItem?.date ?? DateTime.now().add(const Duration(days: 7));
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
        return AppColors.chartRose;
      case 'Renewal':
        return AppColors.moduleTime;
      case 'Travel':
        return AppColors.chartCyan;
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
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isDark = palette.isDark;
    final cardBg = palette.card;
    final dividerColor = palette.divider;
    final headingColor = palette.heading;
    final captionColor = palette.caption;
    final surfaceFill = palette.surfaceMuted.withValues(
      alpha: isDark ? 0.45 : 0.65,
    );
    final accentColor = _getCategoryColor(_selectedCategory);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadius.topXl,
              border: Border.all(color: dividerColor),
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
                        color: dividerColor,
                        borderRadius: AppRadius.radiusFull,
                      ),
                    ),
                  ),
                  AppSpacing.gapH12,
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(
                            alpha: isDark ? 0.22 : 0.14,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(_selectedCategory),
                          color: accentColor,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppText.titleMedium(
                          widget.editItem == null
                              ? 'Create Countdown'
                              : 'Edit Countdown',
                          fontWeight: FontWeight.w800,
                          color: headingColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: captionColor,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Event Title
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceFill,
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(color: dividerColor),
                    ),
                    child: TextField(
                      controller: _titleController,
                      autofocus: true,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: headingColor,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        labelText: 'Event Title',
                        labelStyle: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: captionColor,
                        ),
                        hintText: 'e.g., Mom\'s 50th Birthday, Trip to Paris',
                        hintStyle: textTheme.bodySmall?.copyWith(
                          fontSize: 13.5,
                          color: captionColor,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Target Date Picker + Quick Jump Presets
                  AppText.captionBold(
                    'Target Event Date:',
                    color: captionColor,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 10),
                            ),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd,
                          ),
                          side: BorderSide(color: dividerColor),
                        ),
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 15,
                          color: AppColors.moduleTime,
                        ),
                        label: AppText.bodyMedium(
                          _formatDate(_selectedDate),
                          color: headingColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final preset in const [
                                ('+7d', 7),
                                ('+30d', 30),
                                ('+90d', 90),
                                ('+1y', 365),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    borderRadius: AppRadius.radiusFull,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedDate = DateTime.now().add(
                                          Duration(days: preset.$2),
                                        );
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: surfaceFill,
                                        borderRadius: AppRadius.radiusFull,
                                        border: Border.all(color: dividerColor),
                                      ),
                                      child: AppText(
                                        preset.$1,
                                        style: textTheme.labelSmall?.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: captionColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  AppText.captionBold('Category:', color: captionColor),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      final color = _getCategoryColor(cat);

                      return ChoiceChip(
                        label: AppText(cat),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: color.withValues(
                          alpha: isDark ? 0.24 : 0.16,
                        ),
                        backgroundColor: surfaceFill,
                        side: BorderSide(
                          color: isSelected ? color : dividerColor,
                        ),
                        shape: const StadiumBorder(),
                        labelStyle: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? color : captionColor,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Notes / Gift Ideas
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceFill,
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(color: dividerColor),
                    ),
                    child: TextField(
                      controller: _notesController,
                      minLines: 1,
                      maxLines: 3,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 13.5,
                        color: headingColor,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        labelText: 'Notes or Gift Ideas (Optional)',
                        labelStyle: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: captionColor,
                        ),
                        hintText: 'e.g., Hotel booking code, gift wishlist...',
                        hintStyle: textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: captionColor,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Remind advance toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: surfaceFill,
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(color: dividerColor),
                    ),
                    child: Material(
                      color: AppColors.transparent,
                      child: SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: AppText(
                          'Advance Alert Reminders',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: headingColor,
                          ),
                        ),
                        subtitle: AppText(
                          'Notify 7 days & 1 day before event',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: captionColor,
                          ),
                        ),
                        value: _remindAdvance,
                        activeThumbColor: AppColors.moduleTime,
                        onChanged: (val) =>
                            setState(() => _remindAdvance = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.moduleTime,
                        foregroundColor: AppColors.textWhite,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMd,
                        ),
                      ),
                      onPressed: () {
                        final title = _titleController.text.trim();
                        if (title.isEmpty) {
                          SnackbarUtils.showMessage(
                            context,
                            'Please enter an event title.',
                          );
                          return;
                        }

                        final color = _getCategoryColor(_selectedCategory);
                        final icon = _getCategoryIcon(_selectedCategory);

                        final item = CountdownItemEntity(
                          id:
                              widget.editItem?.id ??
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
                      child: AppText.labelLarge(
                        widget.editItem == null
                            ? 'Create Countdown'
                            : 'Update Countdown',
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
      ),
    );
  }
}
