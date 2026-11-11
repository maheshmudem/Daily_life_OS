import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../domain/entities/habit_entity.dart';
import '../bloc/today_hub_bloc.dart';

/// Quick template item for fast 1-tap habit creation.
class _HabitTemplate {
  final String title;
  final IconData icon;
  final Color color;

  const _HabitTemplate({
    required this.title,
    required this.icon,
    required this.color,
  });
}

const List<_HabitTemplate> _kHabitTemplates = [
  _HabitTemplate(
    title: 'Drink 3L Water',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF0EA5E9),
  ),
  _HabitTemplate(
    title: 'Daily Vitamins',
    icon: Icons.medication_rounded,
    color: Color(0xFF10B981),
  ),
  _HabitTemplate(
    title: 'Workout / Gym',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFFF5200),
  ),
  _HabitTemplate(
    title: 'Read 20 Mins',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF8B5CF6),
  ),
  _HabitTemplate(
    title: 'Meditation',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF14B8A6),
  ),
  _HabitTemplate(
    title: 'Healthy Meal',
    icon: Icons.restaurant_rounded,
    color: Color(0xFF10B981),
  ),
  _HabitTemplate(
    title: '8h Sleep',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF6366F1),
  ),
  _HabitTemplate(
    title: 'Code & Learn',
    icon: Icons.code_rounded,
    color: Color(0xFFF59E0B),
  ),
  _HabitTemplate(
    title: 'Morning Walk',
    icon: Icons.directions_walk_rounded,
    color: Color(0xFF06B6D4),
  ),
  _HabitTemplate(
    title: 'Journaling',
    icon: Icons.edit_note_rounded,
    color: Color(0xFFEC4899),
  ),
];

const List<IconData> _kHabitIcons = [
  Icons.water_drop_rounded,
  Icons.medication_rounded,
  Icons.fitness_center_rounded,
  Icons.menu_book_rounded,
  Icons.self_improvement_rounded,
  Icons.directions_run_rounded,
  Icons.directions_walk_rounded,
  Icons.bedtime_rounded,
  Icons.restaurant_rounded,
  Icons.code_rounded,
  Icons.brush_rounded,
  Icons.wb_sunny_rounded,
  Icons.nature_people_rounded,
  Icons.edit_note_rounded,
  Icons.spa_rounded,
  Icons.favorite_rounded,
];

const List<Color> _kHabitColors = [
  Color(0xFF0EA5E9), // Sky Blue
  Color(0xFF10B981), // Emerald
  Color(0xFF6366F1), // Indigo
  Color(0xFFFF5200), // Flame Orange
  Color(0xFFF59E0B), // Amber
  Color(0xFF8B5CF6), // Violet
  Color(0xFFEC4899), // Pink
  Color(0xFF14B8A6), // Teal
];

/// Bottom sheet dialog to Create, Edit, and Delete Habits & Micro-Routines.
class HabitFormSheet extends StatefulWidget {
  final HabitEntity? habit;

  const HabitFormSheet({super.key, this.habit});

  static Future<void> show(
    BuildContext context, {
    HabitEntity? habit,
  }) {
    HapticFeedback.lightImpact();
    final bloc = context.read<TodayHubBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: HabitFormSheet(habit: habit),
      ),
    );
  }

  @override
  State<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<HabitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  late int _streakDays;

  bool get isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final h = widget.habit!;
      _titleController = TextEditingController(text: h.title);
      _selectedIcon = h.icon;
      _selectedColor = h.color;
      _streakDays = h.streakDays;
    } else {
      _titleController = TextEditingController();
      _selectedIcon = Icons.water_drop_rounded;
      _selectedColor = const Color(0xFF0EA5E9);
      _streakDays = 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _applyTemplate(_HabitTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _selectedIcon = template.icon;
      _selectedColor = template.color;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _handleDelete() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Habit?',
      message:
          'Are you sure you want to delete "${widget.habit!.title}"? Your streak and history for this habit will be removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      context.read<TodayHubBloc>().add(DeleteHabit(widget.habit!.id));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Habit "${widget.habit!.title}" deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();

    if (isEditing) {
      final updated = widget.habit!.copyWith(
        title: title,
        iconCodePoint: _selectedIcon.codePoint,
        colorValue: _selectedColor.toARGB32(),
        streakDays: _streakDays,
      );
      context.read<TodayHubBloc>().add(UpdateHabit(updated));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Habit "$title" updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final newHabit = HabitEntity(
        id: 0,
        title: title,
        iconCodePoint: _selectedIcon.codePoint,
        colorValue: _selectedColor.toARGB32(),
        streakDays: 0,
        isDoneToday: false,
        createdAt: DateTime.now().toIso8601String(),
      );
      context.read<TodayHubBloc>().add(AddHabit(newHabit));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Habit "$title" created'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: AppRadius.topXxl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Habit' : 'Add New Habit',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEditing
                            ? 'Adjust streak, icon, or remove habit'
                            : 'Create a micro-routine for daily momentum',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                    ],
                  ),
                  // Live Preview Bubble
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.16),
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(
                        color: _selectedColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _selectedIcon,
                      color: _selectedColor,
                      size: 24,
                    ),
                  ),
                ],
              ),

              // Quick Templates (when creating)
              if (!isEditing) ...[
                const SizedBox(height: 16),
                Text(
                  'QUICK TEMPLATES',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _kHabitTemplates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tmpl = _kHabitTemplates[index];
                      final isSelected = _titleController.text == tmpl.title;
                      return ActionChip(
                        avatar: Icon(tmpl.icon, size: 16, color: tmpl.color),
                        label: Text(tmpl.title),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextBody
                                  : AppColors.textBody),
                        ),
                        backgroundColor: isSelected
                            ? tmpl.color
                            : (isDark
                                ? AppColors.darkSurfaceSecondary
                                : AppColors.surfaceSecondary),
                        side: BorderSide(
                          color: isSelected
                              ? tmpl.color
                              : (isDark
                                  ? AppColors.darkDivider
                                  : AppColors.divider),
                        ),
                        onPressed: () => _applyTemplate(tmpl),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Title Field
              Text(
                'HABIT NAME',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 10 Mins Meditation, Drink 3L Water',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.surfaceSecondary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                    borderSide: BorderSide(
                      color: _selectedColor,
                      width: 1.8,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a habit title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Choose Icon
              Text(
                'CHOOSE ICON',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _kHabitIcons.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final icon = _kHabitIcons[index];
                    final isSelected = _selectedIcon.codePoint == icon.codePoint;
                    return InkWell(
                      borderRadius: AppRadius.radiusMd,
                      onTap: () {
                        setState(() => _selectedIcon = icon);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withValues(alpha: 0.2)
                              : (isDark
                                  ? AppColors.darkSurfaceSecondary
                                  : AppColors.surfaceSecondary),
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(
                            color: isSelected
                                ? _selectedColor
                                : (isDark
                                    ? AppColors.darkDivider
                                    : AppColors.divider),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? _selectedColor
                              : (isDark
                                  ? AppColors.darkTextBody
                                  : AppColors.textBody),
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Choose Color
              Text(
                'COLOR ACCENT',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _kHabitColors.map((color) {
                  final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = color);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),

              // If Editing: Streak Adjuster
              if (isEditing) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSecondary
                        : AppColors.surfaceSecondary,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Streak',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextHeading
                                      : AppColors.textHeading,
                                ),
                              ),
                              Text(
                                '$_streakDays days in a row',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextCaption
                                      : AppColors.textCaption,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            color: isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
                            onPressed: _streakDays > 0
                                ? () => setState(() => _streakDays--)
                                : null,
                          ),
                          Text(
                            '$_streakDays',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: AppColors.primary,
                            onPressed: () => setState(() => _streakDays++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Bottom Actions
              Row(
                children: [
                  if (isEditing) ...[
                    // Delete Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd,
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: _handleDelete,
                      ),
                    ),
                    AppSpacing.gapW12,
                  ],
                  // Save Button
                  Expanded(
                    flex: 3,
                    child: AppButton(
                      label: isEditing ? 'Save Changes' : 'Create Habit',
                      icon: isEditing
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      onPressed: _handleSave,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
