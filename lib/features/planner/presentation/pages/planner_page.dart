import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../bloc/planner_bloc.dart';

class PlannerPage extends StatelessWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PlannerBloc>()
        ..add(LoadPlanner(DateTime.now().toIso8601String().substring(0, 10))),
      child: const _PlannerView(),
    );
  }
}

class _PlannerView extends StatefulWidget {
  const _PlannerView();

  @override
  State<_PlannerView> createState() => _PlannerViewState();
}

class _PlannerViewState extends State<_PlannerView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Pomodoro Focus Timer — stays local (pure UI state, not stored)
  int _secondsRemaining = 25 * 60;
  bool _isTimerRunning = false;
  Timer? _timer;
  bool _isWorkSprint = true;

  // Countdowns (static for now — will be DB in next iteration)
  final List<Map<String, dynamic>> _countdowns = [
    {
      'title': "Sarah's 28th Birthday",
      'date': DateTime.now().add(const Duration(days: 5)),
      'icon': Icons.cake_rounded,
      'color': AppColors.moduleNotes,
    },
    {
      'title': 'Car Insurance Renewal',
      'date': DateTime.now().add(const Duration(days: 24)),
      'icon': Icons.directions_car_rounded,
      'color': AppColors.moduleTime,
    },
  ];

  // Set Reminder state
  final TextEditingController _quickReminderController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedCategory = 'Personal';
  static const List<String> _categories = [
    'Personal',
    'Work',
    'Health',
    'Finance',
    'Important'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _quickReminderController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          setState(() {
            _isTimerRunning = false;
            _isWorkSprint = !_isWorkSprint;
            _secondsRemaining = _isWorkSprint ? (25 * 60) : (5 * 60);
          });
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = _isWorkSprint ? (25 * 60) : (5 * 60);
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          StringConstants.navPlanner,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          BlocBuilder<PlannerBloc, PlannerState>(
            builder: (context, state) {
              if (state is PlannerLoaded) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${state.completedCount}/${state.items.length} done',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.moduleTime,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.moduleTime,
          unselectedLabelColor: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          indicatorColor: AppColors.moduleTime,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Reminders'),
            Tab(text: 'Pomodoro Focus'),
            Tab(text: 'Countdowns'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRemindersTab(context, isDark),
          _buildFocusTimerTab(isDark),
          _buildCountdownsTab(isDark),
        ],
      ),
    );
  }

  // ── Tab 1: Reminders (DB-backed via PlannerBloc) ─────────────────────────
  Widget _buildRemindersTab(BuildContext context, bool isDark) {
    return BlocBuilder<PlannerBloc, PlannerState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
          children: [
            // ── Set Reminder Section (Quick Add Card) ──────────────────────
            _buildSetReminderSection(context, isDark),
            AppSpacing.gapH16,

            // Items from DB
            if (state is PlannerLoading || state is PlannerInitial)
              ...[1, 2, 3].map((_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: AppShimmerLoader.card(height: 100),
                  ))
            else if (state is PlannerLoaded) ...[
              if (state.items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'No tasks today. Tap the mic or type above!',
                      style: TextStyle(color: isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                    ),
                  ),
                )
              else
                ...state.items.map((item) => _buildPlannerItemCard(context, item, isDark)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPlannerItemCard(BuildContext context, PlannerItemEntity item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: item.isDone
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkDivider : AppColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: item.isDone,
                activeColor: AppColors.moduleTime,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                onChanged: (_) => context.read<PlannerBloc>().add(TogglePlannerItem(item.id)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.timeRange.isNotEmpty)
                          Text(
                            item.timeRange,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
                            ),
                          ),
                        if (item.category.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.14),
                              borderRadius: AppRadius.radiusSm,
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: item.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: AppColors.error.withValues(alpha: 0.6), size: 18),
                onPressed: () => context.read<PlannerBloc>().add(DeletePlannerItem(item.id)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Snoozed for 15 minutes.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: const Text('Snooze +15m', style: TextStyle(fontSize: 11)),
              ),
              AppSpacing.gapW8,
              FilledButton.tonal(
                onPressed: () => context.read<PlannerBloc>().add(TogglePlannerItem(item.id)),
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: AppColors.moduleTime.withValues(alpha: 0.15),
                  foregroundColor: AppColors.moduleTime,
                ),
                child: Text(
                  item.isDone ? 'Undo' : 'Mark Done',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Pomodoro Focus Timer (local UI state — no DB needed) ───────────
  Widget _buildFocusTimerTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 90),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppDecorations.heroTimeGradient,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  _isWorkSprint ? '⚡ DEEP WORK SPRINT' : '☕ SHORT BREAK',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _formatTimer(_secondsRemaining),
                style: AppTextStyles.timerHero.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Linked Task: "Finalize Daily Life OS PRD"',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.moduleTimeDark,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
                    ),
                    icon: Icon(_isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(
                      _isTimerRunning ? 'Pause' : 'Start Focus',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: _resetTimer,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Focus Settings & Presets', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPresetChip('25m Work / 5m Break', true, isDark),
            AppSpacing.gapW8,
            _buildPresetChip('50m Deep / 10m Break', false, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, bool isSelected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.moduleTime.withValues(alpha: 0.15)
            : (isDark ? AppColors.darkCardBackground : AppColors.cardBackground),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isSelected ? AppColors.moduleTime : (isDark ? AppColors.darkDivider : AppColors.divider),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.moduleTime : (isDark ? AppColors.darkTextBody : AppColors.textBody),
        ),
      ),
    );
  }

  // ── Tab 3: Countdowns ─────────────────────────────────────────────────────
  Widget _buildCountdownsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
      children: [
        ..._countdowns.map((cd) {
          final color = cd['color'] as Color;
          final targetDate = cd['date'] as DateTime;
          final daysLeft = targetDate.difference(DateTime.now()).inDays;
          final monthAbbr = _monthAbbr(targetDate.month);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
              borderRadius: AppRadius.radiusLg,
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(cd['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cd['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        '$monthAbbr ${targetDate.day} (In $daysLeft days)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Text(
                    '${daysLeft}d left',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _monthAbbr(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  // ── Set Reminder Section (Quick Add Card) ─────────────────────────────────
  Widget _buildSetReminderSection(BuildContext context, bool isDark) {
    final catColor = _getCategoryColor(_selectedCategory);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark
              ? AppColors.darkDivider
              : AppColors.moduleTime.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title & more options button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.alarm_add_rounded,
                    color: AppColors.moduleTime,
                    size: 16,
                  ),
                  AppSpacing.gapW8,
                  Text(
                    StringConstants.setReminder.toUpperCase(),
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.moduleTime,
                      fontSize: 10.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: AppRadius.radiusXs,
                onTap: () => _showSetReminderSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Full Options',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH8,

          // Input field
          TextField(
            controller: _quickReminderController,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: StringConstants.reminderHint,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) => _submitQuickReminder(context),
          ),
          AppSpacing.gapH8,

          // Quick Action Pills Row: Time, Category & Set Reminder button
          Row(
            children: [
              // Time Picker Chip
              GestureDetector(
                onTap: () => _pickQuickTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.moduleTime.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusXs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.moduleTime),
                      AppSpacing.gapW4,
                      Text(
                        _formatTimeOfDay(_selectedTime),
                        style: AppTextStyles.captionBold.copyWith(
                          fontSize: 11,
                          color: AppColors.moduleTime,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapW8,

              // Category Cycle Chip
              GestureDetector(
                onTap: _cycleCategory,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusXs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getCategoryIcon(_selectedCategory),
                          size: 13, color: catColor),
                      AppSpacing.gapW4,
                      Text(
                        _selectedCategory,
                        style: AppTextStyles.captionBold.copyWith(
                          fontSize: 11,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Submit Reminder Button
              FilledButton.icon(
                onPressed: () => _submitQuickReminder(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moduleTime,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusSm,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                label: Text(
                  StringConstants.setReminder,
                  style: AppTextStyles.captionBold.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitQuickReminder(BuildContext context) {
    final title = _quickReminderController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reminder title.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final timeStr = _formatTimeOfDay(_selectedTime);

    context.read<PlannerBloc>().add(
          AddPlannerItem(
            title: title,
            date: today,
            startTime: timeStr,
            category: _selectedCategory,
            colorValue: _getCategoryColor(_selectedCategory).toARGB32(),
            iconCodePoint: _getCategoryIcon(_selectedCategory).codePoint,
          ),
        );

    _quickReminderController.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder "$title" set for $timeStr!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cycleCategory() {
    setState(() {
      final currentIndex = _categories.indexOf(_selectedCategory);
      final nextIndex = (currentIndex + 1) % _categories.length;
      _selectedCategory = _categories[nextIndex];
    });
  }

  Future<void> _pickQuickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _showSetReminderSheet(BuildContext context) {
    final plannerBloc = context.read<PlannerBloc>();
    final titleCtrl =
        TextEditingController(text: _quickReminderController.text.trim());
    TimeOfDay sheetTime = _selectedTime;
    DateTime sheetDate = DateTime.now();
    String sheetCategory = _selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardBg =
                isDark ? AppColors.darkCardBackground : Colors.white;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.topXxl,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.5 : 0.15),
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
                            color: isDark
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
                                  color: AppColors.moduleTime
                                      .withValues(alpha: 0.14),
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
                                  color: isDark
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
                            color: isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      AppSpacing.gapH16,
                      TextField(
                        controller: titleCtrl,
                        autofocus: true,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
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
                          color: isDark
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
                                  initialDate: sheetDate,
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 1)),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setSheetState(() => sheetDate = picked);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.radiusMd),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.darkDivider
                                      : AppColors.divider,
                                ),
                              ),
                              icon: const Icon(Icons.calendar_today_rounded,
                                  size: 16, color: AppColors.moduleTime),
                              label: Text(
                                _formatDateShort(sheetDate),
                                style: AppTextStyles.captionBold.copyWith(
                                  color: isDark
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
                                  initialTime: sheetTime,
                                );
                                if (picked != null) {
                                  setSheetState(() => sheetTime = picked);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.radiusMd),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.darkDivider
                                      : AppColors.divider,
                                ),
                              ),
                              icon: const Icon(Icons.access_time_rounded,
                                  size: 16, color: AppColors.moduleTime),
                              label: Text(
                                _formatTimeOfDay(sheetTime),
                                style: AppTextStyles.captionBold.copyWith(
                                  color: isDark
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
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                      AppSpacing.gapH8,
                      Wrap(
                        spacing: 8,
                        children: _categories.map((cat) {
                          final isSelected = sheetCategory == cat;
                          final catColor = _getCategoryColor(cat);
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: catColor.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? catColor
                                  : (isDark
                                      ? AppColors.darkTextCaption
                                      : AppColors.textCaption),
                            ),
                            onSelected: (val) {
                              if (val) setSheetState(() => sheetCategory = cat);
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
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please enter a reminder title.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            final dateStr = sheetDate
                                .toIso8601String()
                                .substring(0, 10);
                            final timeStr = _formatTimeOfDay(sheetTime);

                            plannerBloc.add(
                              AddPlannerItem(
                                title: title,
                                date: dateStr,
                                startTime: timeStr,
                                category: sheetCategory,
                                colorValue: _getCategoryColor(sheetCategory)
                                    .toARGB32(),
                                iconCodePoint:
                                    _getCategoryIcon(sheetCategory).codePoint,
                              ),
                            );

                            Navigator.of(sheetContext).pop();
                            _quickReminderController.clear();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Reminder "$title" set for $timeStr!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.moduleTime,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMd,
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded,
                              color: Colors.white),
                          label: Text(
                            StringConstants.setReminder,
                            style: AppTextStyles.buttonText
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatDateShort(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Work':
        return Icons.work_rounded;
      case 'Health':
        return Icons.fitness_center_rounded;
      case 'Finance':
        return Icons.account_balance_wallet_rounded;
      case 'Important':
        return Icons.priority_high_rounded;
      case 'Personal':
      default:
        return Icons.alarm_rounded;
    }
  }
}
