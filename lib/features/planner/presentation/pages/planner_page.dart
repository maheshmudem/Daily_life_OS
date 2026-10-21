import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/countdown_item_entity.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../../data/models/countdown_item_model.dart';
import '../bloc/planner_bloc.dart';

// Custom Planner Widgets
import '../widgets/countdown_card.dart';
import '../widgets/countdown_sheet.dart';
import '../widgets/planner_item_card.dart';
import '../widgets/pomodoro_custom_duration_sheet.dart';
import '../widgets/pomodoro_focus_card.dart';
import '../widgets/pomodoro_linked_task_sheet.dart';
import '../widgets/pomodoro_mode_selector.dart';
import '../widgets/set_reminder_card.dart';
import '../widgets/set_reminder_sheet.dart';

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

class _PlannerViewState extends State<_PlannerView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Pomodoro Focus Timer State ───────────────────────────────────────────
  int _focusModeIndex = 0; // 0 = Work, 1 = Short Break, 2 = Long Break
  int _workMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  late int _secondsRemaining;
  bool _isTimerRunning = false;
  Timer? _timer;
  int _currentRound = 1;
  static const int _totalRounds = 4;
  int _completedSessionsToday = 3;
  String _linkedTask = 'Finalize Daily Life OS PRD';
  String _selectedAmbience = 'Mute';

  static const List<Map<String, dynamic>> _ambienceOptions = [
    {'name': 'Mute', 'icon': Icons.volume_off_rounded},
    {'name': 'Rain', 'icon': Icons.water_drop_rounded},
    {'name': 'Cafe', 'icon': Icons.local_cafe_rounded},
    {'name': 'Waves', 'icon': Icons.waves_rounded},
    {'name': 'Forest', 'icon': Icons.forest_rounded},
    {'name': 'White Noise', 'icon': Icons.air_rounded},
  ];

  // ── Countdowns State (Persisted in SharedPreferences) ─────────────────────
  static const _countdownsPrefKey = 'planner_saved_countdowns';
  late List<CountdownItemEntity> _countdowns = _defaultCountdowns;
  String _selectedCountdownCategory = 'All';

  static List<CountdownItemEntity> get _defaultCountdowns {
    final now = DateTime.now();
    return [
      CountdownItemModel(
        id: 'cd_1',
        title: "Sarah's 28th Birthday",
        date: now.add(const Duration(days: 5)),
        category: 'Birthday',
        colorValue: AppColors.moduleNotes.toARGB32(),
        iconCodePoint: Icons.cake_rounded.codePoint,
        notes: 'Noise-cancelling headphones or gift voucher',
        remindAdvance: true,
      ),
      CountdownItemModel(
        id: 'cd_2',
        title: 'Car Insurance Renewal',
        date: now.add(const Duration(days: 24)),
        category: 'Renewal',
        colorValue: AppColors.moduleTime.toARGB32(),
        iconCodePoint: Icons.directions_car_rounded.codePoint,
        notes: 'Check policy documents in Vault',
        remindAdvance: true,
      ),
      CountdownItemModel(
        id: 'cd_3',
        title: 'Trip to Tokyo',
        date: now.add(const Duration(days: 45)),
        category: 'Travel',
        colorValue: const Color(0xFF06B6D4).toARGB32(),
        iconCodePoint: Icons.flight_takeoff_rounded.codePoint,
        notes: 'Book JR Rail Pass and pack universal adapter',
        remindAdvance: true,
      ),
    ];
  }

  static const List<String> _countdownCategories = [
    'All',
    'Birthday',
    'Renewal',
    'Travel',
    'Milestone',
    'Anniversary',
    'Event',
  ];

  // ── Set Reminder State ────────────────────────────────────────────────────
  final TextEditingController _quickReminderController =
      TextEditingController();
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
    _secondsRemaining = _workMinutes * 60;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadCountdowns();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _quickReminderController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Countdowns Persistence ───────────────────────────────────────────────
  Future<void> _loadCountdowns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_countdownsPrefKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        if (mounted) {
          setState(() {
            _countdowns = decoded
                .map((item) => CountdownItemModel.fromJson(item))
                .toList();
          });
        }
        return;
      }
    } catch (_) {}
  }

  Future<void> _saveCountdowns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final models = _countdowns.map((c) => CountdownItemModel.fromEntity(c).toJson()).toList();
      await prefs.setString(_countdownsPrefKey, jsonEncode(models));
    } catch (_) {}
  }

  // ── Pomodoro Timer Logic ──────────────────────────────────────────────────
  int get _currentTotalSeconds {
    switch (_focusModeIndex) {
      case 1:
        return _shortBreakMinutes * 60;
      case 2:
        return _longBreakMinutes * 60;
      case 0:
      default:
        return _workMinutes * 60;
    }
  }

  double get _timerProgress {
    final total = _currentTotalSeconds;
    if (total <= 0) return 0.0;
    return (total - _secondsRemaining) / total;
  }

  void _switchFocusMode(int modeIndex) {
    if (_focusModeIndex == modeIndex) return;
    _timer?.cancel();
    setState(() {
      _focusModeIndex = modeIndex;
      _isTimerRunning = false;
      _secondsRemaining = _currentTotalSeconds;
    });
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
          _onTimerCompleted();
        }
      });
    }
  }

  void _onTimerCompleted() {
    setState(() {
      _isTimerRunning = false;
      if (_focusModeIndex == 0) {
        _completedSessionsToday++;
        if (_currentRound >= _totalRounds) {
          _currentRound = 1;
          _focusModeIndex = 2; // Long Break
          _secondsRemaining = _longBreakMinutes * 60;
        } else {
          _currentRound++;
          _focusModeIndex = 1; // Short Break
          _secondsRemaining = _shortBreakMinutes * 60;
        }
      } else {
        _focusModeIndex = 0; // Back to Work
        _secondsRemaining = _workMinutes * 60;
      }
    });

    // Trigger local mobile notification for focus transition
    try {
      sl<NotificationService>().showInstantNotification(
        id: 9901,
        title: _focusModeIndex == 0
            ? 'Break Over! ⚡'
            : 'Focus Sprint Complete! 🎯',
        body: _focusModeIndex == 0
            ? 'Ready to dive back into your next focus sprint?'
            : 'Well done! Time for your scheduled recharge break.',
        channelId: NotificationChannels.focus,
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _focusModeIndex == 0
                ? 'Break complete! Ready to start next sprint?'
                : 'Focus sprint finished! Take a well-earned break.',
          ),
          backgroundColor: AppColors.moduleTime,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = _currentTotalSeconds;
    });
  }

  void _skipSession() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      if (_focusModeIndex == 0) {
        _focusModeIndex = (_currentRound >= _totalRounds) ? 2 : 1;
      } else {
        if (_focusModeIndex == 2) _currentRound = 1;
        _focusModeIndex = 0;
      }
      _secondsRemaining = _currentTotalSeconds;
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ── Main Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.scaffoldBackground,
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
          unselectedLabelColor:
              isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          indicatorColor: AppColors.moduleTime,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
          _buildFocusTimerTab(context, isDark),
          _buildCountdownsTab(context, isDark),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: REMINDERS TAB
  // =========================================================================
  Widget _buildRemindersTab(BuildContext context, bool isDark) {
    return BlocBuilder<PlannerBloc, PlannerState>(
      builder: (context, state) {
        return ListView(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
          children: [
            // Custom Set Reminder Card
            SetReminderCard(
              controller: _quickReminderController,
              selectedTime: _selectedTime,
              selectedCategory: _selectedCategory,
              categoryColor: _getCategoryColor(_selectedCategory),
              categoryIcon: _getCategoryIcon(_selectedCategory),
              isDark: isDark,
              onPickTime: () => _pickQuickTime(context),
              onCycleCategory: _cycleCategory,
              onSubmit: () => _submitQuickReminder(context),
              onOpenFullOptions: () => _openFullReminderSheet(context, isDark),
            ),
            AppSpacing.gapH16,

            // Items from DB
            if (state is PlannerLoading || state is PlannerInitial)
              ...[1, 2, 3].map(
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: AppShimmerLoader.card(height: 100),
                ),
              )
            else if (state is PlannerLoaded) ...[
              if (state.items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'No tasks today. Tap the mic or type above!',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ),
                  ),
                )
              else
                ...state.items.map(
                  (item) => PlannerItemCard(
                    item: item,
                    isDark: isDark,
                    onToggle: (_) => context
                        .read<PlannerBloc>()
                        .add(TogglePlannerItem(item.id)),
                    onDelete: () {
                      final notifId =
                          ('${item.title}${item.date}${item.startTime}')
                                  .hashCode &
                              0x7FFFFFFF;
                      try {
                        sl<NotificationService>().cancelNotification(notifId);
                      } catch (_) {}
                      context
                          .read<PlannerBloc>()
                          .add(DeletePlannerItem(item.id));
                    },
                    onSnooze: () {
                      final snoozeTime =
                          DateTime.now().add(const Duration(minutes: 15));
                      final snoozeId =
                          (item.id.hashCode + 999) & 0x7FFFFFFF;
                      try {
                        sl<NotificationService>().scheduleNotification(
                          id: snoozeId,
                          title: 'Snoozed: ${item.title}',
                          body: 'Reminder snoozed for 15 minutes',
                          scheduledDate: snoozeTime,
                          channelId: NotificationChannels.reminders,
                          payload: 'planner_snooze_${item.id}',
                        );
                      } catch (_) {}
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Snoozed for 15 minutes. Notification scheduled!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
        );
      },
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

    // Schedule local mobile notification
    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final notifId = ('$title$today$timeStr').hashCode & 0x7FFFFFFF;
    try {
      sl<NotificationService>().scheduleNotification(
        id: notifId,
        title: 'Reminder: $title',
        body: 'Scheduled for $timeStr • Category: $_selectedCategory',
        scheduledDate: scheduledDate,
        channelId: NotificationChannels.reminders,
        payload: 'planner_reminder_$notifId',
      );
    } catch (_) {}

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

  void _openFullReminderSheet(BuildContext context, bool isDark) {
    final plannerBloc = context.read<PlannerBloc>();

    SetReminderSheet.show(
      context,
      initialTitle: _quickReminderController.text.trim(),
      initialTime: _selectedTime,
      initialCategory: _selectedCategory,
      isDark: isDark,
      onSubmit: (title, date, time, category) {
        final dateStr = date.toIso8601String().substring(0, 10);
        final timeStr = _formatTimeOfDay(time);

        plannerBloc.add(
          AddPlannerItem(
            title: title,
            date: dateStr,
            startTime: timeStr,
            category: category,
            colorValue: _getCategoryColor(category).toARGB32(),
            iconCodePoint: _getCategoryIcon(category).codePoint,
          ),
        );

        // Schedule local mobile notification
        final scheduledDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        final notifId = ('$title$dateStr$timeStr').hashCode & 0x7FFFFFFF;
        try {
          sl<NotificationService>().scheduleNotification(
            id: notifId,
            title: 'Reminder: $title',
            body: 'Scheduled for $timeStr • Category: $category',
            scheduledDate: scheduledDate,
            channelId: NotificationChannels.reminders,
            payload: 'planner_reminder_$notifId',
          );
        } catch (_) {}

        _quickReminderController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder "$title" set for $timeStr!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  // =========================================================================
  // TAB 2: POMODORO FOCUS TAB
  // =========================================================================
  Widget _buildFocusTimerTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
      children: [
        // Mode Selector Pills
        PomodoroModeSelector(
          selectedIndex: _focusModeIndex,
          workMinutes: _workMinutes,
          shortBreakMinutes: _shortBreakMinutes,
          longBreakMinutes: _longBreakMinutes,
          onModeSelected: _switchFocusMode,
          isDark: isDark,
        ),
        AppSpacing.gapH16,

        // Hero Pomodoro Focus Card
        PomodoroFocusCard(
          focusModeIndex: _focusModeIndex,
          currentRound: _currentRound,
          totalRounds: _totalRounds,
          timerProgress: _timerProgress,
          formattedTime: _formatTimer(_secondsRemaining),
          isTimerRunning: _isTimerRunning,
          linkedTask: _linkedTask,
          onToggleTimer: _toggleTimer,
          onResetTimer: _resetTimer,
          onSkipSession: _skipSession,
          onChangeTask: () => _openLinkedTaskSheet(context, isDark),
        ),
        AppSpacing.gapH20,

        // Presets & Custom
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Focus Presets & Custom Time',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color:
                    isDark ? AppColors.darkTextHeading : AppColors.textHeading,
              ),
            ),
            InkWell(
              borderRadius: AppRadius.radiusSm,
              onTap: () => _openCustomDurationSheet(context, isDark),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded,
                        size: 14, color: AppColors.moduleTime),
                    const SizedBox(width: 4),
                    Text(
                      'Custom...',
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.moduleTime,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapH12,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildPresetChip('15m Sprint', 15, isDark),
              AppSpacing.gapW8,
              _buildPresetChip('25m Classic', 25, isDark),
              AppSpacing.gapW8,
              _buildPresetChip('45m Deep Work', 45, isDark),
              AppSpacing.gapW8,
              _buildPresetChip('60m Ultra Focus', 60, isDark),
            ],
          ),
        ),
        AppSpacing.gapH20,

        // Ambient Sound Bar
        Text(
          'Focus Ambience & Sounds',
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
          ),
        ),
        AppSpacing.gapH12,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _ambienceOptions.map((opt) {
              final name = opt['name'] as String;
              final icon = opt['icon'] as IconData;
              final isSelected = _selectedAmbience == name;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(
                    icon,
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption),
                  ),
                  label: Text(name),
                  selected: isSelected,
                  selectedColor: AppColors.moduleTime,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedAmbience = name);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(name == 'Mute'
                              ? 'Ambience sound muted'
                              : 'Ambience set to $name'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        AppSpacing.gapH20,

        // Daily Activity Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: AppColors.focusPomodoro, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Daily Focus Activity',
                        style: AppTextStyles.captionBold.copyWith(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '🎯 4 Sessions Goal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('$_completedSessionsToday', 'Sessions Done',
                      AppColors.moduleTime),
                  Container(
                      width: 1,
                      height: 32,
                      color:
                          isDark ? AppColors.darkDivider : AppColors.divider),
                  _buildStatColumn('${_completedSessionsToday * _workMinutes}m',
                      'Time Focused', AppColors.success),
                  Container(
                      width: 1,
                      height: 32,
                      color:
                          isDark ? AppColors.darkDivider : AppColors.divider),
                  _buildStatColumn(
                      '4 Days', 'Focus Streak', AppColors.focusPomodoro),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openCustomDurationSheet(BuildContext context, bool isDark) {
    PomodoroCustomDurationSheet.show(
      context,
      workMinutes: _workMinutes,
      shortBreakMinutes: _shortBreakMinutes,
      longBreakMinutes: _longBreakMinutes,
      isDark: isDark,
      onSave: (w, s, l) {
        _timer?.cancel();
        setState(() {
          _workMinutes = w;
          _shortBreakMinutes = s;
          _longBreakMinutes = l;
          _isTimerRunning = false;
          _secondsRemaining = _currentTotalSeconds;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pomodoro durations updated!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _openLinkedTaskSheet(BuildContext context, bool isDark) {
    final state = context.read<PlannerBloc>().state;
    final items = state is PlannerLoaded ? state.items : <PlannerItemEntity>[];

    PomodoroLinkedTaskSheet.show(
      context,
      currentTask: _linkedTask,
      todayTasks: items,
      isDark: isDark,
      onTaskSelected: (task) => setState(() => _linkedTask = task),
    );
  }

  Widget _buildPresetChip(String label, int minutes, bool isDark) {
    final isSelected = _focusModeIndex == 0 && _workMinutes == minutes;

    return GestureDetector(
      onTap: () {
        _timer?.cancel();
        setState(() {
          _workMinutes = minutes;
          _focusModeIndex = 0;
          _secondsRemaining = minutes * 60;
          _isTimerRunning = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.moduleTime.withValues(alpha: 0.15)
              : (isDark
                  ? AppColors.darkCardBackground
                  : AppColors.cardBackground),
          borderRadius: AppRadius.radiusMd,
          border: Border.all(
            color: isSelected
                ? AppColors.moduleTime
                : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.moduleTime
                : (isDark ? AppColors.darkTextBody : AppColors.textBody),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textCaption,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 3: COUNTDOWNS TAB
  // =========================================================================
  Widget _buildCountdownsTab(BuildContext context, bool isDark) {
    final filtered = _selectedCountdownCategory == 'All'
        ? _countdowns
        : _countdowns
            .where((c) => c.category == _selectedCountdownCategory)
            .toList();

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Countdowns',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                  ),
                ),
                Text(
                  '${_countdowns.length} upcoming events & milestones',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: () => _openCountdownSheet(context, isDark),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.moduleTime,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Add Event',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
        AppSpacing.gapH12,

        // Filter Strip
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _countdownCategories.map((cat) {
              final isSelected = _selectedCountdownCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.moduleTime.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.moduleTime,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.moduleTime
                        : (isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption),
                  ),
                  onSelected: (val) {
                    setState(() => _selectedCountdownCategory = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        AppSpacing.gapH16,

        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.celebration_rounded,
                      size: 48,
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.divider),
                  const SizedBox(height: 12),
                  Text(
                    'No countdowns in $_selectedCountdownCategory',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _openCountdownSheet(context, isDark),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Create a Countdown'),
                  ),
                ],
              ),
            ),
          )
        else
          ...filtered.map(
            (cd) => CountdownCard(
              item: cd,
              isDark: isDark,
              onAddToPlanner: () => _addCountdownToPlanner(context, cd),
              onEdit: () =>
                  _openCountdownSheet(context, isDark, editItem: cd),
              onDelete: () => _deleteCountdown(context, cd),
            ),
          ),
      ],
    );
  }

  void _openCountdownSheet(BuildContext context, bool isDark,
      {CountdownItemEntity? editItem}) {
    CountdownSheet.show(
      context,
      editItem: editItem,
      isDark: isDark,
      onSave: (savedItem) async {
        if (editItem != null) {
          final index =
              _countdowns.indexWhere((item) => item.id == editItem.id);
          if (index != -1) {
            setState(() => _countdowns[index] = savedItem);
          }
        } else {
          setState(() => _countdowns.add(savedItem));
        }

        await _saveCountdowns();
        await _syncCountdownNotifications(savedItem);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Countdown "${savedItem.title}" saved!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _addCountdownToPlanner(BuildContext context, CountdownItemEntity cd) {
    final dateStr = cd.date.toIso8601String().substring(0, 10);
    context.read<PlannerBloc>().add(
          AddPlannerItem(
            title: '${_getCategoryEmoji(cd.category)} ${cd.title}',
            date: dateStr,
            startTime: '09:00 AM',
            category: 'Important',
            colorValue: cd.colorValue,
            iconCodePoint: cd.iconCodePoint,
          ),
        );

    final eventDate = cd.date;
    final scheduledDate =
        DateTime(eventDate.year, eventDate.month, eventDate.day, 9, 0);
    final notifId = ('${cd.title}$dateStr').hashCode & 0x7FFFFFFF;
    try {
      sl<NotificationService>().scheduleNotification(
        id: notifId,
        title: '${_getCategoryEmoji(cd.category)} Milestone: ${cd.title}',
        body: 'Scheduled on your Planner for today at 09:00 AM',
        scheduledDate: scheduledDate,
        channelId: NotificationChannels.countdowns,
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${cd.title}" to Planner on $dateStr!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteCountdown(
      BuildContext context, CountdownItemEntity cd) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Countdown?',
      message: 'Are you sure you want to delete "${cd.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      setState(() {
        _countdowns.removeWhere((item) => item.id == cd.id);
      });
      await _saveCountdowns();
      await _cancelCountdownNotifications(cd.id);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Countdown "${cd.title}" deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncCountdownNotifications(CountdownItemEntity item) async {
    final baseId = item.id.hashCode & 0x7FFFFFFF;
    try {
      if (item.remindAdvance) {
        final now = DateTime.now();
        // Day of event (at 9:00 AM)
        final dayOf =
            DateTime(item.date.year, item.date.month, item.date.day, 9, 0);
        await sl<NotificationService>().scheduleNotification(
          id: baseId,
          title: 'Today: ${item.title}',
          body: 'Milestone event "${item.title}" (${item.category}) is today!',
          scheduledDate: dayOf,
          channelId: NotificationChannels.countdowns,
          payload: 'countdown_${item.id}_day',
        );

        // 1 day before (at 9:00 AM)
        final oneDayBefore = dayOf.subtract(const Duration(days: 1));
        if (oneDayBefore.isAfter(now)) {
          await sl<NotificationService>().scheduleNotification(
            id: (baseId + 1) & 0x7FFFFFFF,
            title: 'Tomorrow: ${item.title}',
            body:
                '1 day remaining until "${item.title}" (${item.category})!',
            scheduledDate: oneDayBefore,
            channelId: NotificationChannels.countdowns,
            payload: 'countdown_${item.id}_1d',
          );
        }

        // 7 days before (at 9:00 AM)
        final sevenDaysBefore = dayOf.subtract(const Duration(days: 7));
        if (sevenDaysBefore.isAfter(now)) {
          await sl<NotificationService>().scheduleNotification(
            id: (baseId + 7) & 0x7FFFFFFF,
            title: 'Upcoming in 7 Days: ${item.title}',
            body:
                '7 days remaining until "${item.title}" (${item.category})!',
            scheduledDate: sevenDaysBefore,
            channelId: NotificationChannels.countdowns,
            payload: 'countdown_${item.id}_7d',
          );
        }
      } else {
        await _cancelCountdownNotifications(item.id);
      }
    } catch (e) {
      debugPrint('Error syncing countdown notifications: $e');
    }
  }

  Future<void> _cancelCountdownNotifications(String countdownId) async {
    final baseId = countdownId.hashCode & 0x7FFFFFFF;
    try {
      await sl<NotificationService>().cancelNotification(baseId);
      await sl<NotificationService>().cancelNotification((baseId + 1) & 0x7FFFFFFF);
      await sl<NotificationService>().cancelNotification((baseId + 7) & 0x7FFFFFFF);
    } catch (e) {
      debugPrint('Error canceling countdown notifications: $e');
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Birthday':
        return '🎂';
      case 'Anniversary':
        return '💍';
      case 'Renewal':
        return '🚗';
      case 'Travel':
        return '✈️';
      case 'Milestone':
        return '🎯';
      case 'Event':
      default:
        return '⭐';
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
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
