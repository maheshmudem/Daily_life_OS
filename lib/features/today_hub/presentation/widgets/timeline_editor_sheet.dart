import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../domain/entities/timeline_item_entity.dart';

class TimelineEditorSheet extends StatefulWidget {
  final TimelineItemEntity? existing;
  final ValueChanged<TimelineItemEntity> onSave;
  final VoidCallback? onDelete;

  const TimelineEditorSheet({
    super.key,
    this.existing,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    TimelineItemEntity? existing,
    required ValueChanged<TimelineItemEntity> onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => TimelineEditorSheet(
        existing: existing,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<TimelineEditorSheet> createState() => _TimelineEditorSheetState();
}

class _TimelineEditorSheetState extends State<TimelineEditorSheet> {
  late final TextEditingController _titleController;
  late String _category;
  late TimeOfDay _selectedTime;
  String? _titleError;

  static final List<Map<String, dynamic>> _categorySpecs = [
    {
      'name': 'Time',
      'icon': Icons.laptop_chromebook_rounded,
      'color': AppColors.moduleTime,
      'action': 'Done',
    },
    {
      'name': 'Money',
      'icon': Icons.bolt_rounded,
      'color': AppColors.moduleMoney,
      'action': 'Log Payment',
    },
    {
      'name': 'Talking Reminder',
      'icon': Icons.record_voice_over_rounded,
      'color': AppColors.primary,
      'action': 'Snooze',
    },
    {
      'name': 'Notes Link',
      'icon': Icons.lightbulb_outline_rounded,
      'color': AppColors.moduleNotes,
      'action': 'View Note',
    },
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _category = e?.category ?? 'Time';
    if (!_categorySpecs.any((c) => c['name'] == _category)) {
      _category = 'Time';
    }
    _selectedTime = _parseTime(e?.time) ?? TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? raw) {
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

  String _formatTime(TimeOfDay tod) {
    final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final h = hour12.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    final suffix = tod.period == DayPeriod.pm ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }

  Map<String, dynamic> get _currentSpec => _categorySpecs.firstWhere(
    (c) => c['name'] == _category,
    orElse: () => _categorySpecs.first,
  );

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Please enter a task title');
      return;
    }

    final spec = _currentSpec;
    final IconData icon = spec['icon'] as IconData;
    final Color color = spec['color'] as Color;
    final String action = spec['action'] as String;
    final todayIso = DateTime.now().toIso8601String().substring(0, 10);

    final entity = TimelineItemEntity(
      id: widget.existing?.id ?? 0,
      time: _formatTime(_selectedTime),
      title: title,
      category: _category,
      colorValue: color.toARGB32(),
      iconCodePoint: icon.codePoint,
      isDone: widget.existing?.isDone ?? false,
      action: action,
      date: widget.existing?.date ?? todayIso,
    );

    HapticFeedback.mediumImpact();
    widget.onSave(entity);
    Navigator.of(context).pop();
  }

  Future<void> _handleDelete() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Task?',
      message:
          'Are you sure you want to remove "${widget.existing?.title}" from today\'s timeline?',
      confirmLabel: 'Delete Task',
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
    final spec = _currentSpec;
    final Color accent = spec['color'] as Color;
    final IconData icon = spec['icon'] as IconData;

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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: palette.isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        isEditing ? 'Edit Timeline Task' : 'Add Timeline Task',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.heading,
                        ),
                      ),
                      AppText(
                        'Schedule a task or reminder for today\'s feed',
                        style: text.labelSmall?.copyWith(
                          color: palette.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEditing && widget.onDelete != null)
                  IconButton(
                    tooltip: 'Delete Task',
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
            AppText(
              'TASK TITLE',
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
                hintText: 'e.g., Afternoon Deep Work Sprint, Pay Wi-Fi Bill',
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
              ),
            ),
            const SizedBox(height: 14),
            AppText(
              'CATEGORY & MODULE',
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
              children: _categorySpecs.map((item) {
                final name = item['name'] as String;
                final c = item['color'] as Color;
                final ic = item['icon'] as IconData;
                final active = _category == name;
                return GestureDetector(
                  onTap: () => setState(() => _category = name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? c.withValues(alpha: palette.isDark ? 0.24 : 0.14)
                          : palette.surfaceMuted,
                      borderRadius: AppRadius.radiusFull,
                      border: Border.all(
                        color: active ? c : palette.border,
                        width: active ? 1.2 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ic, size: 14, color: active ? c : palette.caption),
                        const SizedBox(width: 6),
                        AppText(
                          name,
                          style: text.labelMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active ? c : palette.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            AppText(
              'SCHEDULED TIME',
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: palette.caption,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null && mounted) {
                  setState(() => _selectedTime = picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
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
                    Icon(Icons.schedule_rounded, size: 18, color: accent),
                    const SizedBox(width: 10),
                    AppText(
                      _formatTime(_selectedTime),
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.heading,
                      ),
                    ),
                    const Spacer(),
                    AppText(
                      'Change Time',
                      style: text.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: _handleSave,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isEditing ? Icons.check_rounded : Icons.add_rounded,
                  size: 18,
                ),
                label: AppText.labelLarge(
                  isEditing ? 'Save Task Changes' : 'Add to Today\'s Timeline',
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
