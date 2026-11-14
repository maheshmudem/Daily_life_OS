import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/services/tts/tts_service.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../../../core/widgets/staggered_fade_slide.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/countdown_item_entity.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../../domain/entities/pomodoro_entities.dart';
import '../../../../core/widgets/app_dropdown_menu.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../today_hub/domain/entities/timeline_item_entity.dart';
import '../../../today_hub/domain/usecases/manage_habits_usecase.dart';
import '../../data/models/countdown_item_model.dart';
import '../bloc/planner_bloc.dart';

// Custom Planner Widgets
import '../widgets/countdown_card.dart';
import '../widgets/countdown_sheet.dart';
import '../widgets/countdown_spotlight_card.dart';
import '../widgets/planner_hero_card.dart';
import '../widgets/planner_item_card.dart';
import '../widgets/planner_matrix_view.dart';
import '../widgets/planner_snooze_sheet.dart';
import '../widgets/planner_timeline_view.dart';
import '../widgets/planner_week_strip.dart';
import '../widgets/pomodoro_analytics_card.dart';
import '../widgets/pomodoro_custom_duration_sheet.dart';
import '../widgets/pomodoro_focus_card.dart';
import '../widgets/pomodoro_linked_task_sheet.dart';
import '../widgets/pomodoro_mode_selector.dart';
import '../widgets/pomodoro_zen_screen.dart';
import '../widgets/set_reminder_card.dart';
import '../widgets/set_reminder_sheet.dart';

enum PlannerSortOption { timeAsc, timeDesc, priority, title }

enum PlannerViewMode { agenda, timeline, matrix }

class PlannerPage extends StatelessWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PlannerBloc>()..add(const LoadPlanner('all')),
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

  // ── Pomodoro Focus Timer State (Persisted in SharedPreferences) ──────────
  static const _pomodoroSettingsPrefKey = 'planner_pomodoro_settings_v2';
  static const _pomodoroSessionsPrefKey = 'planner_pomodoro_sessions_v2';
  static const _pomodoroDistractionsPrefKey =
      'planner_pomodoro_distractions_v2';

  int _focusModeIndex =
      0; // 0 = Work, 1 = Short Break, 2 = Long Break, 3 = Stopwatch Flow
  int _workMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _totalRounds = 4;
  int _dailyGoalSessions = 4;
  bool _autoStartBreaks = false;
  bool _autoStartWork = false;
  bool _strictMode = false;
  bool _voiceCoach = false;
  double _ambienceVolume = 0.75;
  String _focusCategory = 'Deep Work';
  int _estimatedPomodoros = 4;
  int _completedTaskPomodoros = 2;
  int? _linkedTaskId;
  late int _secondsRemaining;
  late int _sessionInitialTotalSeconds;
  bool _isTimerRunning = false;
  Timer? _timer;
  int _currentRound = 1;
  String _linkedTask = 'Finalize Daily Life OS PRD';
  String _selectedAmbience = 'Mute';

  late List<FocusSessionEntity> _focusSessions =
      FocusSessionEntity.defaultSeedSessions();
  List<FocusDistractionItem> _distractions = [];

  static const List<Map<String, dynamic>> _ambienceOptions = [
    {'name': 'Mute', 'icon': Icons.volume_off_rounded},
    {'name': 'Rain', 'icon': Icons.water_drop_rounded},
    {'name': 'Cafe', 'icon': Icons.local_cafe_rounded},
    {'name': 'Waves', 'icon': Icons.waves_rounded},
    {'name': 'Forest', 'icon': Icons.forest_rounded},
    {'name': 'White Noise', 'icon': Icons.air_rounded},
    {'name': '40Hz Gamma', 'icon': Icons.graphic_eq_rounded},
    {'name': 'Fireplace', 'icon': Icons.local_fire_department_rounded},
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
        colorValue: AppColors.chartCyan.toARGB32(),
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
  final TextEditingController _searchController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedCategory = 'Personal';
  String _quickPriority = 'medium';
  String? _selectedDateIso;
  int _weekOffset = 0;
  String _selectedReminderCategoryFilter = 'All';
  String _selectedStatusFilter = 'All'; // 'All', 'Pending', 'Completed'
  String _typeFilter = 'all'; // 'all', 'habits', 'one_off', 'overdue'
  PlannerSortOption _sortOption = PlannerSortOption.timeAsc;
  PlannerViewMode _viewMode = PlannerViewMode.agenda;
  String _searchQuery = '';
  bool _isCompletedExpanded = true;

  static const List<Map<String, dynamic>> _quickTemplates = [
    {
      'title': 'Drink Water',
      'category': 'Health',
      'icon': Icons.water_drop_rounded,
      'time': TimeOfDay(hour: 10, minute: 0),
    },
    {
      'title': 'Take Vitamins',
      'category': 'Health',
      'icon': Icons.medication_rounded,
      'time': TimeOfDay(hour: 9, minute: 0),
    },
    {
      'title': 'Team Standup',
      'category': 'Work',
      'icon': Icons.groups_rounded,
      'time': TimeOfDay(hour: 10, minute: 30),
    },
    {
      'title': 'Check Bills',
      'category': 'Finance',
      'icon': Icons.receipt_long_rounded,
      'time': TimeOfDay(hour: 19, minute: 0),
    },
    {
      'title': '30m Workout',
      'category': 'Personal',
      'icon': Icons.fitness_center_rounded,
      'time': TimeOfDay(hour: 18, minute: 0),
    },
    {
      'title': 'Call Family',
      'category': 'Personal',
      'icon': Icons.call_rounded,
      'time': TimeOfDay(hour: 20, minute: 0),
    },
  ];

  String _formatDateToIso(DateTime dt) => dt.toIso8601String().substring(0, 10);

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
    _secondsRemaining = _workMinutes * 60;
    _sessionInitialTotalSeconds = _secondsRemaining;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadCountdowns();
    _loadPomodoroState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _quickReminderController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Pomodoro Persistence (Settings, Sessions, Distractions) ──────────────
  Future<void> _loadPomodoroState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawSettings = prefs.getString(_pomodoroSettingsPrefKey);
      if (rawSettings != null && rawSettings.isNotEmpty) {
        final cfg = PomodoroSettingsEntity.fromJson(
          jsonDecode(rawSettings) as Map<String, dynamic>,
        );
        if (mounted) {
          setState(() {
            _workMinutes = cfg.workMinutes;
            _shortBreakMinutes = cfg.shortBreakMinutes;
            _longBreakMinutes = cfg.longBreakMinutes;
            _totalRounds = cfg.totalRounds;
            _dailyGoalSessions = cfg.dailyGoalSessions;
            _autoStartBreaks = cfg.autoStartBreaks;
            _autoStartWork = cfg.autoStartWork;
            _strictMode = cfg.strictMode;
            _voiceCoach = cfg.voiceCoach;
            _selectedAmbience = cfg.selectedAmbience;
            _ambienceVolume = cfg.ambienceVolume;
            _focusCategory = cfg.focusCategory;
            _estimatedPomodoros = cfg.estimatedPomodoros;
            _completedTaskPomodoros = cfg.completedTaskPomodoros;
            _linkedTask = cfg.linkedTask;
            _linkedTaskId = cfg.linkedTaskId;
            if (!_isTimerRunning && _focusModeIndex != 3) {
              _secondsRemaining = _currentTotalSeconds;
              _sessionInitialTotalSeconds = _secondsRemaining;
            }
          });
        }
      }

      final rawSessions = prefs.getString(_pomodoroSessionsPrefKey);
      if (rawSessions != null && rawSessions.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawSessions);
        if (mounted) {
          setState(() {
            _focusSessions = decoded
                .map(
                  (e) => FocusSessionEntity.fromJson(e as Map<String, dynamic>),
                )
                .toList();
          });
        }
      }

      final rawDistractions = prefs.getString(_pomodoroDistractionsPrefKey);
      if (rawDistractions != null && rawDistractions.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawDistractions);
        if (mounted) {
          setState(() {
            _distractions = decoded
                .map(
                  (e) =>
                      FocusDistractionItem.fromJson(e as Map<String, dynamic>),
                )
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _savePomodoroSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cfg = PomodoroSettingsEntity(
        workMinutes: _workMinutes,
        shortBreakMinutes: _shortBreakMinutes,
        longBreakMinutes: _longBreakMinutes,
        totalRounds: _totalRounds,
        dailyGoalSessions: _dailyGoalSessions,
        autoStartBreaks: _autoStartBreaks,
        autoStartWork: _autoStartWork,
        strictMode: _strictMode,
        voiceCoach: _voiceCoach,
        selectedAmbience: _selectedAmbience,
        ambienceVolume: _ambienceVolume,
        focusCategory: _focusCategory,
        estimatedPomodoros: _estimatedPomodoros,
        completedTaskPomodoros: _completedTaskPomodoros,
        linkedTask: _linkedTask,
        linkedTaskId: _linkedTaskId,
      );
      await prefs.setString(_pomodoroSettingsPrefKey, jsonEncode(cfg.toJson()));
    } catch (_) {}
  }

  Future<void> _saveFocusSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _focusSessions.map((s) => s.toJson()).toList();
      await prefs.setString(_pomodoroSessionsPrefKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _saveDistractions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _distractions.map((d) => d.toJson()).toList();
      await prefs.setString(_pomodoroDistractionsPrefKey, jsonEncode(list));
    } catch (_) {}
  }

  void _speakCoachCue(String message) {
    if (!_voiceCoach) return;
    try {
      getAppTtsService().speak(message);
    } catch (_) {}
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
      final models = _countdowns
          .map((c) => CountdownItemModel.fromEntity(c).toJson())
          .toList();
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
      case 3:
        return 3600; // 60-minute cycle visual ring for Flow Stopwatch
      case 0:
      default:
        return _workMinutes * 60;
    }
  }

  double get _timerProgress {
    if (_focusModeIndex == 3) {
      return (_secondsRemaining % 3600) / 3600.0;
    }
    final total = math.max(1, _sessionInitialTotalSeconds);
    return ((total - _secondsRemaining) / total).clamp(0.0, 1.0);
  }

  Future<void> _switchFocusMode(int modeIndex) async {
    if (_focusModeIndex == modeIndex) return;
    if (_strictMode && _isTimerRunning && _focusModeIndex == 0) {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'Strict Focus Mode Active',
        message:
            'You are in the middle of an active focus sprint. Abandon this sprint and switch modes?',
        confirmLabel: 'Switch Mode',
        isDestructive: true,
      );
      if (confirmed != true) return;
    }
    _timer?.cancel();
    setState(() {
      _focusModeIndex = modeIndex;
      _isTimerRunning = false;
      _secondsRemaining = modeIndex == 3 ? 0 : _currentTotalSeconds;
      _sessionInitialTotalSeconds = _currentTotalSeconds;
    });
  }

  void _startTimerLoop() {
    _timer?.cancel();
    setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_focusModeIndex == 3) {
        setState(() => _secondsRemaining++);
      } else if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _onTimerCompleted();
      }
    });
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      _startTimerLoop();
      _speakCoachCue(
        _focusModeIndex == 0
            ? 'Starting deep work sprint on $_linkedTask.'
            : (_focusModeIndex == 3
                  ? 'Flow stopwatch started.'
                  : 'Break timer started. Relax and recharge.'),
      );
    }
  }

  void _addMinutesToTimer(int minutesToAdd) {
    if (_focusModeIndex == 3) return;
    setState(() {
      _secondsRemaining += minutesToAdd * 60;
      _sessionInitialTotalSeconds = math.max(
        _sessionInitialTotalSeconds,
        _secondsRemaining,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added +${minutesToAdd}m to current timer'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _finishStopwatchSession() {
    _timer?.cancel();
    final elapsedMins = math.max(1, (_secondsRemaining / 60).round());
    final newSession = FocusSessionEntity(
      id: 'flow_${DateTime.now().millisecondsSinceEpoch}',
      taskTitle: _linkedTask,
      linkedTaskId: _linkedTaskId,
      category: _focusCategory,
      durationMinutes: elapsedMins,
      completedAt: DateTime.now(),
      isStopwatch: true,
      notes: 'Flowtime open-ended sprint',
      focusRating: 5,
    );
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = 0;
      _focusSessions.insert(0, newSession);
      _completedTaskPomodoros++;
    });
    _saveFocusSessions();
    _savePomodoroSettings();
    SnackbarUtils.showSuccess(
      context,
      'Logged ${elapsedMins}m Flow session on "$_linkedTask"!',
    );
  }

  void _onTimerCompleted() {
    final completedWorkSprint = _focusModeIndex == 0;
    if (completedWorkSprint) {
      final sprintMinutes = math.max(
        1,
        (_sessionInitialTotalSeconds / 60).round(),
      );
      final newSession = FocusSessionEntity(
        id: 'pomo_${DateTime.now().millisecondsSinceEpoch}',
        taskTitle: _linkedTask,
        linkedTaskId: _linkedTaskId,
        category: _focusCategory,
        durationMinutes: sprintMinutes,
        completedAt: DateTime.now(),
        notes: 'Round $_currentRound/$_totalRounds sprint',
        focusRating: 5,
      );
      _focusSessions.insert(0, newSession);
      _completedTaskPomodoros++;
      _saveFocusSessions();
      _savePomodoroSettings();
    }

    setState(() {
      _isTimerRunning = false;
      if (completedWorkSprint) {
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
      _sessionInitialTotalSeconds = _secondsRemaining;
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

    _speakCoachCue(
      _focusModeIndex == 0
          ? 'Break complete. Ready for your next focus sprint?'
          : 'Focus sprint complete. Great work! Time for a recharge break.',
    );

    // Auto-start next phase if enabled
    if (completedWorkSprint && _autoStartBreaks) {
      _startTimerLoop();
    } else if (!completedWorkSprint && _autoStartWork) {
      _startTimerLoop();
    }

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

  Future<void> _resetTimer() async {
    if (_strictMode && _isTimerRunning && _focusModeIndex == 0) {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'Reset Active Sprint?',
        message:
            'Strict Focus Mode is enabled. Are you sure you want to reset your current progress?',
        confirmLabel: 'Reset Timer',
        isDestructive: true,
      );
      if (confirmed != true) return;
    }
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = _focusModeIndex == 3 ? 0 : _currentTotalSeconds;
      _sessionInitialTotalSeconds = _currentTotalSeconds;
    });
  }

  Future<void> _skipSession() async {
    if (_strictMode && _isTimerRunning && _focusModeIndex == 0) {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'Skip Active Sprint?',
        message:
            'Strict Focus Mode is enabled. Skipping now will not log this session.',
        confirmLabel: 'Skip Anyway',
        isDestructive: true,
      );
      if (confirmed != true) return;
    }
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
      _sessionInitialTotalSeconds = _currentTotalSeconds;
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
    final palette = context.palette;
    final isDark = palette.isDark;

    return FeatureScaffold(
      title: StringConstants.navPlanner,
      accentColor: AppColors.moduleTime,
      titleTrailing: BlocBuilder<PlannerBloc, PlannerState>(
        builder: (context, state) {
          if (state is! PlannerLoaded) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.moduleTime.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusFull,
            ),
            child: Text(
              '${state.completedCount}/${state.items.length} done',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(
                color: AppColors.moduleTimeDark,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          );
        },
      ),
      actionsEndPadding: AppSpacing.pageGutter,
      actions: [_buildAppBarAction(context, isDark)],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Container(
              height: 38,
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                0,
                AppSpacing.pageGutter,
                10,
              ),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(9),
                indicator: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                labelColor: palette.heading,
                unselectedLabelColor: palette.caption,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: context.text.labelLarge?.copyWith(fontSize: 13),
                unselectedLabelStyle: context.text.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    height: 32,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Reminders'),
                    ),
                  ),
                  Tab(
                    height: 32,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Pomodoro Focus'),
                    ),
                  ),
                  Tab(
                    height: 32,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Countdowns'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      builder: (context) => TabBarView(
        controller: _tabController,
        children: [
          _buildRemindersTab(context, isDark),
          _buildFocusTimerTab(context, isDark),
          _buildCountdownsTab(context, isDark),
        ],
      ),
    );
  }

  Widget _buildAppBarAction(BuildContext context, bool isDark) {
    final tabIndex = _tabController.index;
    final IconData icon;
    final String label;
    final VoidCallback onTap;

    if (tabIndex == 1) {
      icon = Icons.tune_rounded;
      label = 'Timer';
      onTap = () => _openCustomDurationSheet(context, isDark);
    } else if (tabIndex == 2) {
      icon = Icons.add_rounded;
      label = 'New Event';
      onTap = () => _openCountdownSheet(context, isDark);
    } else {
      icon = Icons.add_rounded;
      label = 'New Task';
      onTap = () => _openFullReminderSheet(context, isDark);
    }

    return FeatureHeaderButton(
      icon: icon,
      label: label,
      color: AppColors.moduleTime,
      onPressed: onTap,
    );
  }

  // =========================================================================
  // TAB 1: REMINDERS TAB
  // =========================================================================
  Widget _buildRemindersTab(BuildContext context, bool isDark) {
    return BlocBuilder<PlannerBloc, PlannerState>(
      builder: (context, state) {
        final allItems = state is PlannerLoaded
            ? state.items
            : <PlannerItemEntity>[];
        final totalCount = allItems.length;
        final pendingCount = allItems.where((i) => !i.isDone).length;
        final completedCount = allItems.where((i) => i.isDone).length;
        final overdueCount = allItems.where((i) => i.isOverdue).length;
        final todayCount = allItems
            .where((i) => i.isToday || i.isRecurring)
            .length;

        final now = DateTime.now();
        final todayIso = PlannerWeekStrip.toIsoDate(now);
        final selectedDay = _selectedDateIso != null
            ? DateTime.tryParse(_selectedDateIso!)
            : null;
        final targetDateLabel = selectedDay != null
            ? DateFormat('EEE, MMM d').format(selectedDay)
            : null;

        // Filter items based on date horizon, status, category, type, and search
        final filteredItems = allItems.where((item) {
          if (selectedDay != null &&
              !PlannerWeekStrip.itemOccursOnDay(item, selectedDay)) {
            return false;
          }
          if (_selectedStatusFilter == 'Pending' && item.isDone) return false;
          if (_selectedStatusFilter == 'Completed' && !item.isDone) {
            return false;
          }
          if (_selectedReminderCategoryFilter != 'All' &&
              item.category != _selectedReminderCategoryFilter) {
            return false;
          }
          if (_typeFilter == 'habits' && !item.isRecurring) return false;
          if (_typeFilter == 'one_off' && item.isRecurring) return false;
          if (_typeFilter == 'overdue' && !item.isOverdue) return false;

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final titleMatch = item.title.toLowerCase().contains(q);
            final notesMatch = item.notes.toLowerCase().contains(q);
            final checklistMatch = item.checklist.any(
              (c) => c.title.toLowerCase().contains(q),
            );
            final categoryMatch = item.category.toLowerCase().contains(q);
            if (!titleMatch &&
                !notesMatch &&
                !checklistMatch &&
                !categoryMatch) {
              return false;
            }
          }
          return true;
        }).toList();

        int prioScore(String p) {
          switch (p) {
            case 'urgent_important':
            case 'urgent':
              return 4;
            case 'urgent_not_important':
            case 'high':
              return 3;
            case 'important_not_urgent':
            case 'medium':
              return 2;
            case 'neither':
            case 'low':
            default:
              return 1;
          }
        }

        filteredItems.sort((a, b) {
          switch (_sortOption) {
            case PlannerSortOption.timeAsc:
              final dtA =
                  DateTime.tryParse('${a.date} 00:00:00') ?? DateTime(2099);
              final dtB =
                  DateTime.tryParse('${b.date} 00:00:00') ?? DateTime(2099);
              final dateComp = dtA.compareTo(dtB);
              if (dateComp != 0) return dateComp;
              return (a.startTime ?? '').compareTo(b.startTime ?? '');
            case PlannerSortOption.timeDesc:
              final dtA =
                  DateTime.tryParse('${a.date} 00:00:00') ?? DateTime(1970);
              final dtB =
                  DateTime.tryParse('${b.date} 00:00:00') ?? DateTime(1970);
              final dateComp = dtB.compareTo(dtA);
              if (dateComp != 0) return dateComp;
              return (b.startTime ?? '').compareTo(a.startTime ?? '');
            case PlannerSortOption.priority:
              return prioScore(b.priority).compareTo(prioScore(a.priority));
            case PlannerSortOption.title:
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          }
        });

        final nextPendingItem = filteredItems
            .where((i) => !i.isDone)
            .firstOrNull;

        final heroCard = PlannerHeroCard(
          totalCount: totalCount,
          todayCount: todayCount,
          overdueCount: overdueCount,
          completedCount: completedCount,
          todayIso: todayIso,
          selectedDateIso: _selectedDateIso,
          targetDateLabel: targetDateLabel ?? 'All Dates',
          weekOffset: _weekOffset,
          allItems: allItems,
          nextPendingItem: nextPendingItem,
          isActiveMetricSelected: _selectedStatusFilter == 'Pending',
          isTodayMetricSelected: _selectedDateIso == todayIso,
          isOverdueMetricSelected: _typeFilter == 'overdue',
          isDoneMetricSelected: _selectedStatusFilter == 'Completed',
          onTapActiveMetric: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedStatusFilter = _selectedStatusFilter == 'Pending'
                  ? 'All'
                  : 'Pending';
              _typeFilter = 'all';
            });
          },
          onTapTodayMetric: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (_selectedDateIso == todayIso) {
                _selectedDateIso = null;
              } else {
                _selectedDateIso = todayIso;
                _weekOffset = 0;
              }
            });
          },
          onTapOverdueMetric: () {
            HapticFeedback.selectionClick();
            setState(() {
              _typeFilter = _typeFilter == 'overdue' ? 'all' : 'overdue';
              if (_typeFilter == 'overdue') {
                _selectedStatusFilter = 'All';
                _selectedDateIso = null;
              }
            });
          },
          onTapDoneMetric: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedStatusFilter = _selectedStatusFilter == 'Completed'
                  ? 'All'
                  : 'Completed';
              _typeFilter = 'all';
            });
          },
          onSelectDate: (iso) => setState(() => _selectedDateIso = iso),
          onChangeWeekOffset: (offset) => setState(() => _weekOffset = offset),
          onFocusNext: _startFocusOnTask,
        );

        final quickAddCard = SetReminderCard(
          controller: _quickReminderController,
          selectedTime: _selectedTime,
          selectedCategory: _selectedCategory,
          categoryColor: _getCategoryColor(_selectedCategory),
          categoryIcon: _getCategoryIcon(_selectedCategory),
          selectedPriority: _quickPriority,
          targetDateLabel: targetDateLabel,
          isDark: isDark,
          onPickTime: () => _pickQuickTime(context),
          onCycleCategory: _cycleCategory,
          onCyclePriority: _cycleQuickPriority,
          onClearTargetDate: () => setState(() => _selectedDateIso = null),
          onSubmit: () => _submitQuickReminder(context),
          onOpenFullOptions: () => _openFullReminderSheet(context, isDark),
        );

        Widget buildWorkspaceContent() {
          if (state is PlannerLoading || state is PlannerInitial) {
            return Column(
              children: [
                for (var i = 0; i < 3; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: AppShimmerLoader.card(height: 84),
                  ),
              ],
            );
          }
          if (state is! PlannerLoaded) return const SizedBox.shrink();

          // In Matrix mode without active search, always render the 4 priority
          // quadrants so users can quick-add directly into any quadrant.
          if (_viewMode == PlannerViewMode.matrix &&
              (filteredItems.isNotEmpty || _searchQuery.isEmpty)) {
            return PlannerMatrixView(
              items: filteredItems,
              isDark: isDark,
              onToggle: (item) => context.read<PlannerBloc>().add(
                TogglePlannerItem(item.id, targetDate: 'all'),
              ),
              onEdit: (item) => _openEditReminderSheet(context, item, isDark),
              onStartFocus: _startFocusOnTask,
              onQuickAddWithPriority: (prio) => _openFullReminderSheet(
                context,
                isDark,
                overridePriority: prio,
              ),
            );
          }

          if (filteredItems.isEmpty) {
            return AppEmptyState(
              icon: _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : (_selectedStatusFilter == 'Completed'
                        ? Icons.task_alt_rounded
                        : Icons.alarm_add_rounded),
              title: _searchQuery.isNotEmpty
                  ? 'No matching reminders'
                  : (selectedDay != null
                        ? 'No tasks on $targetDateLabel'
                        : (_selectedStatusFilter == 'Completed'
                              ? 'No completed tasks yet'
                              : (_selectedReminderCategoryFilter == 'All'
                                    ? 'No reminders yet'
                                    : 'No $_selectedReminderCategoryFilter reminders'))),
              description: _searchQuery.isNotEmpty
                  ? 'No reminders match "$_searchQuery". Try a different search.'
                  : (selectedDay != null
                        ? 'Use Set Reminder above to schedule a task for $targetDateLabel, or switch back to All Dates.'
                        : (_selectedStatusFilter == 'Completed'
                              ? 'Finish a reminder to see it archived here.'
                              : 'Tap "Set Reminder" above or select a template to create one.')),
              actionLabel: _searchQuery.isNotEmpty
                  ? 'Clear Search'
                  : (_selectedDateIso != null ||
                            _selectedReminderCategoryFilter != 'All' ||
                            _typeFilter != 'all' ||
                            _selectedStatusFilter != 'All'
                        ? 'Reset Filters'
                        : null),
              onAction: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedDateIso = null;
                  _selectedReminderCategoryFilter = 'All';
                  _typeFilter = 'all';
                  _selectedStatusFilter = 'All';
                });
              },
            );
          }

          if (_viewMode == PlannerViewMode.timeline) {
            return PlannerTimelineView(
              items: filteredItems,
              isDark: isDark,
              onToggle: (item) => context.read<PlannerBloc>().add(
                TogglePlannerItem(item.id, targetDate: 'all'),
              ),
              onEdit: (item) => _openEditReminderSheet(context, item, isDark),
              onStartFocus: _startFocusOnTask,
              onSnooze: (item) => _showSnoozeOptions(context, item, isDark),
            );
          }

          if (_searchQuery.isNotEmpty ||
              _selectedStatusFilter != 'All' ||
              _selectedReminderCategoryFilter != 'All' ||
              _typeFilter != 'all' ||
              selectedDay != null) {
            final headerTitle = _searchQuery.isNotEmpty
                ? 'Search Results'
                : (selectedDay != null
                      ? 'Agenda · $targetDateLabel'
                      : (_selectedReminderCategoryFilter != 'All'
                            ? '$_selectedReminderCategoryFilter Reminders'
                            : (_typeFilter != 'all'
                                  ? (_typeFilter == 'habits'
                                        ? 'Habits'
                                        : (_typeFilter == 'overdue'
                                              ? 'Overdue Reminders'
                                              : 'One-Off Reminders'))
                                  : '$_selectedStatusFilter Reminders')));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  title: headerTitle,
                  color: _typeFilter == 'overdue'
                      ? AppColors.error
                      : AppColors.moduleTime,
                  count: filteredItems.length,
                  isDark: isDark,
                ),
                for (var i = 0; i < filteredItems.length; i++)
                  StaggeredFadeSlide(
                    index: i,
                    child: _buildReminderItemCard(
                      context,
                      filteredItems[i],
                      isDark,
                    ),
                  ),
              ],
            );
          }

          final overdue = filteredItems.where((i) => i.isOverdue).toList();
          final todayAndRecurring = filteredItems
              .where(
                (i) =>
                    !i.isDone && !i.isOverdue && (i.isToday || i.isRecurring),
              )
              .toList();
          final upcoming = filteredItems
              .where((i) => !i.isDone && !i.isOverdue && i.isUpcoming)
              .toList();
          final otherPending = filteredItems
              .where(
                (i) =>
                    !i.isDone &&
                    !i.isOverdue &&
                    !i.isToday &&
                    !i.isRecurring &&
                    !i.isUpcoming,
              )
              .toList();
          final completed = filteredItems.where((i) => i.isDone).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overdue.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Overdue',
                  color: AppColors.error,
                  count: overdue.length,
                  isDark: isDark,
                  onMarkAllDone: () => _markAllDone(overdue),
                ),
                for (var i = 0; i < overdue.length; i++)
                  StaggeredFadeSlide(
                    index: i,
                    child: _buildReminderItemCard(context, overdue[i], isDark),
                  ),
              ],
              if (todayAndRecurring.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Today & Routines',
                  color: AppColors.moduleTime,
                  count: todayAndRecurring.length,
                  isDark: isDark,
                  onMarkAllDone: () => _markAllDone(todayAndRecurring),
                ),
                for (var i = 0; i < todayAndRecurring.length; i++)
                  StaggeredFadeSlide(
                    index: i,
                    child: _buildReminderItemCard(
                      context,
                      todayAndRecurring[i],
                      isDark,
                    ),
                  ),
              ],
              if (upcoming.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Upcoming',
                  color: AppColors.primary,
                  count: upcoming.length,
                  isDark: isDark,
                ),
                for (var i = 0; i < upcoming.length; i++)
                  StaggeredFadeSlide(
                    index: i,
                    child: _buildReminderItemCard(context, upcoming[i], isDark),
                  ),
              ],
              if (otherPending.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Other Reminders',
                  color: context.palette.body,
                  count: otherPending.length,
                  isDark: isDark,
                ),
                for (var i = 0; i < otherPending.length; i++)
                  StaggeredFadeSlide(
                    index: i,
                    child: _buildReminderItemCard(
                      context,
                      otherPending[i],
                      isDark,
                    ),
                  ),
              ],
              if (completed.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Completed',
                  color: AppColors.success,
                  count: completed.length,
                  isDark: isDark,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeaderAction(
                        label: 'Clear',
                        color: AppColors.error,
                        onTap: () => _confirmClearCompleted(context),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderAction(
                        label: _isCompletedExpanded ? 'Hide' : 'Show',
                        color: context.palette.caption,
                        onTap: () => setState(
                          () => _isCompletedExpanded = !_isCompletedExpanded,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isCompletedExpanded)
                  for (var i = 0; i < completed.length; i++)
                    StaggeredFadeSlide(
                      index: i,
                      child: _buildReminderItemCard(
                        context,
                        completed[i],
                        isDark,
                      ),
                    ),
              ],
            ],
          );
        }

        const gutter = EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter);

        return RefreshIndicator(
          color: AppColors.moduleTime,
          onRefresh: () async {
            context.read<PlannerBloc>().add(const LoadPlanner('all'));
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideDesktop = constraints.maxWidth >= 940;

              if (isWideDesktop) {
                return ListView(
                  padding: const EdgeInsets.only(top: 6, bottom: 88),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: Padding(
                          padding: gutter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              heroCard,
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 360,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        quickAddCard,
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _quickTemplates
                                              .map(
                                                (tmpl) => SizedBox(
                                                  height: 32,
                                                  child: _buildTemplateChip(
                                                    tmpl,
                                                    isDark,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildWorkspaceToolbar(
                                          totalCount: totalCount,
                                          pendingCount: pendingCount,
                                          completedCount: completedCount,
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        _buildControlsBar(isDark),
                                        const SizedBox(height: 6),
                                        buildWorkspaceContent(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 88),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: gutter,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                heroCard,
                                const SizedBox(height: AppSpacing.sm),
                                quickAddCard,
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SizedBox(
                            height: 32,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: gutter,
                              itemCount: _quickTemplates.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: AppSpacing.xs),
                              itemBuilder: (context, index) {
                                final tmpl = _quickTemplates[index];
                                return _buildTemplateChip(tmpl, isDark);
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: gutter,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildWorkspaceToolbar(
                                  totalCount: totalCount,
                                  pendingCount: pendingCount,
                                  completedCount: completedCount,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _buildControlsBar(isDark),
                                const SizedBox(height: 6),
                                buildWorkspaceContent(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Responsive toolbar combining the 3-mode view switcher (`Agenda` · `Day Flow` ·
  /// `Priority Matrix`) and status filter (`All` · `Pending` · `Completed`).
  /// Renders side-by-side on viewports `>= 580px` and stacks compactly on mobile.
  Widget _buildWorkspaceToolbar({
    required int totalCount,
    required int pendingCount,
    required int completedCount,
    required bool isDark,
  }) {
    final hasActiveFilter =
        _selectedReminderCategoryFilter != 'All' || _typeFilter != 'all';

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 580;
        final statusTrack = _buildStatusTrack(
          totalCount,
          pendingCount,
          completedCount,
          isDark,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sideBySide)
              Row(
                children: [
                  Expanded(flex: 6, child: _buildWorkspaceViewSwitcher(isDark)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(flex: 5, child: statusTrack),
                ],
              )
            else ...[
              _buildWorkspaceViewSwitcher(isDark),
              const SizedBox(height: AppSpacing.xs),
              statusTrack,
            ],
            if (hasActiveFilter) ...[
              const SizedBox(height: AppSpacing.xs),
              _buildActiveFilterChip(),
            ],
          ],
        );
      },
    );
  }

  /// 3-mode workspace lens switcher (`Agenda` · `Day Flow` · `Priority Matrix`)
  /// styled with the Daily Life OS `surfaceMuted` + `card` segmented token system.
  Widget _buildWorkspaceViewSwitcher(bool isDark) {
    final palette = context.palette;

    Widget buildModePill({
      required Key key,
      required PlannerViewMode mode,
      required IconData icon,
      required String label,
    }) {
      final isSelected = _viewMode == mode;
      return Expanded(
        child: GestureDetector(
          key: key,
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _viewMode = mode);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected ? palette.card : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              boxShadow: isSelected && !palette.isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13.5,
                    color: isSelected ? AppColors.moduleTime : palette.caption,
                  ),
                  const SizedBox(width: 4.5),
                  Text(
                    label,
                    style: context.text.labelMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? palette.heading : palette.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.radiusSm,
      ),
      child: Row(
        children: [
          buildModePill(
            key: const ValueKey('planner_view_agenda'),
            mode: PlannerViewMode.agenda,
            icon: Icons.view_agenda_outlined,
            label: 'Agenda',
          ),
          buildModePill(
            key: const ValueKey('planner_view_timeline'),
            mode: PlannerViewMode.timeline,
            icon: Icons.timeline_rounded,
            label: 'Day Flow',
          ),
          buildModePill(
            key: const ValueKey('planner_view_matrix'),
            mode: PlannerViewMode.matrix,
            icon: Icons.grid_view_rounded,
            label: 'Priority Matrix',
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(Map<String, dynamic> tmpl, bool isDark) {
    final palette = context.palette;
    final catColor = _getCategoryColor(tmpl['category'] as String);
    return Material(
      color: palette.card,
      shape: StadiumBorder(side: BorderSide(color: palette.divider)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _applyQuickTemplate(tmpl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tmpl['icon'] as IconData, size: 14, color: catColor),
              const SizedBox(width: 5),
              Text(
                tmpl['title'] as String,
                style: context.text.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.heading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Square 40px icon button that matches the search field's height/border.
  Widget _buildControlSquare({
    required IconData icon,
    required bool isDark,
    bool isActive = false,
  }) {
    final palette = context.palette;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.moduleTime.withValues(alpha: 0.12)
            : palette.card,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(
          color: isActive
              ? AppColors.moduleTime.withValues(alpha: 0.5)
              : palette.divider,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            size: 17,
            color: isActive ? AppColors.moduleTime : palette.icon,
          ),
          if (isActive)
            const Positioned(
              top: 7,
              right: 7,
              child: SizedBox(
                width: 6,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.moduleTime,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsBar(bool isDark) {
    final palette = context.palette;
    final hasActiveFilter =
        _selectedReminderCategoryFilter != 'All' || _typeFilter != 'all';

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: AppRadius.radiusSm,
                border: Border.all(color: palette.divider),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (query) =>
                    setState(() => _searchQuery = query.trim()),
                style: context.text.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: palette.heading,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: 'Search reminders, checklists, notes...',
                  hintStyle: context.text.bodyMedium?.copyWith(
                    color: palette.caption,
                    fontSize: 12.5,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: palette.icon,
                    size: 17,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 38,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: palette.caption,
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),

        // 1. Filter Dropdown Menu
        AppDropdownMenu<String>(
          tooltip: 'Filter Reminders',
          onSelected: (val) {
            setState(() {
              if (val.startsWith('cat:')) {
                _selectedReminderCategoryFilter = val.substring(4);
              } else if (val.startsWith('type:')) {
                _typeFilter = val.substring(5);
              } else if (val == 'clear_all') {
                _selectedReminderCategoryFilter = 'All';
                _typeFilter = 'all';
              }
            });
          },
          items: [
            const AppDropdownHeader(
              title: 'FILTER BY CATEGORY',
              subtitle: 'Select category focus',
            ),
            AppDropdownItem(
              value: 'cat:All',
              icon: Icons.grid_view_rounded,
              label: 'All Categories',
              trailing: _selectedReminderCategoryFilter == 'All'
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.moduleTime,
                    )
                  : null,
            ),
            ..._categories.map(
              (cat) => AppDropdownItem(
                value: 'cat:$cat',
                icon: _getCategoryIcon(cat),
                label: cat,
                tintColor: _getCategoryColor(cat),
                trailing: _selectedReminderCategoryFilter == cat
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: _getCategoryColor(cat),
                      )
                    : null,
              ),
            ),
            const AppDropdownDivider(),
            const AppDropdownHeader(
              title: 'FILTER BY TYPE',
              subtitle: 'Filter habits vs one-offs',
            ),
            AppDropdownItem(
              value: 'type:all',
              icon: Icons.all_inclusive_rounded,
              label: 'All Types',
              trailing: _typeFilter == 'all'
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.moduleTime,
                    )
                  : null,
            ),
            AppDropdownItem(
              value: 'type:habits',
              icon: Icons.repeat_rounded,
              label: 'Recurring Habits Only',
              tintColor: AppColors.moduleTime,
              trailing: _typeFilter == 'habits'
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.moduleTime,
                    )
                  : null,
            ),
            AppDropdownItem(
              value: 'type:one_off',
              icon: Icons.event_note_rounded,
              label: 'One-off Reminders Only',
              trailing: _typeFilter == 'one_off'
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.moduleTime,
                    )
                  : null,
            ),
            AppDropdownItem(
              value: 'type:overdue',
              icon: Icons.warning_amber_rounded,
              label: 'Overdue Only',
              tintColor: AppColors.error,
              trailing: _typeFilter == 'overdue'
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.error,
                    )
                  : null,
            ),
            if (hasActiveFilter) ...[
              const AppDropdownDivider(),
              AppDropdownItem(
                value: 'clear_all',
                icon: Icons.refresh_rounded,
                label: 'Reset Filters',
                isDestructive: true,
              ),
            ],
          ],
          child: _buildControlSquare(
            icon: Icons.tune_rounded,
            isDark: isDark,
            isActive: hasActiveFilter,
          ),
        ),
        const SizedBox(width: 8),

        // 2. Sort Dropdown Menu
        AppDropdownMenu<PlannerSortOption>(
          tooltip: 'Sort Reminders',
          onSelected: (option) => setState(() => _sortOption = option),
          items: [
            const AppDropdownHeader(
              title: 'SORT REMINDERS',
              subtitle: 'Select order preference',
            ),
            AppDropdownItem(
              value: PlannerSortOption.timeAsc,
              icon: Icons.access_time_rounded,
              label: 'Time (Earliest First)',
              trailing: _sortOption == PlannerSortOption.timeAsc
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.moduleTime,
                    )
                  : null,
            ),
            AppDropdownItem(
              value: PlannerSortOption.timeDesc,
              icon: Icons.history_toggle_off_rounded,
              label: 'Time (Latest First)',
              trailing: _sortOption == PlannerSortOption.timeDesc
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.moduleTime,
                    )
                  : null,
            ),
            AppDropdownItem(
              value: PlannerSortOption.priority,
              icon: Icons.flag_rounded,
              label: 'Priority (Urgent First)',
              trailing: _sortOption == PlannerSortOption.priority
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.moduleTime,
                    )
                  : null,
            ),
            AppDropdownItem(
              value: PlannerSortOption.title,
              icon: Icons.sort_by_alpha_rounded,
              label: 'Title (A to Z)',
              trailing: _sortOption == PlannerSortOption.title
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.moduleTime,
                    )
                  : null,
            ),
          ],
          child: _buildControlSquare(
            icon: Icons.swap_vert_rounded,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTrack(
    int totalCount,
    int pendingCount,
    int completedCount,
    bool isDark,
  ) {
    final palette = context.palette;
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.radiusSm,
      ),
      child: Row(
        children: [
          _buildSegmentPill('All', totalCount, isDark),
          _buildSegmentPill('Pending', pendingCount, isDark),
          _buildSegmentPill('Completed', completedCount, isDark),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip() {
    return InputChip(
      label: Text(
        _selectedReminderCategoryFilter != 'All'
            ? _selectedReminderCategoryFilter
            : (_typeFilter == 'habits'
                  ? 'Recurring only'
                  : (_typeFilter == 'overdue'
                        ? 'Overdue only'
                        : 'One-off only')),
      ),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: AppColors.moduleTimeDark,
      ),
      avatar: const Icon(
        Icons.filter_list_rounded,
        size: 14,
        color: AppColors.moduleTime,
      ),
      deleteIcon: const Icon(Icons.close_rounded, size: 14),
      deleteIconColor: AppColors.moduleTime,
      onDeleted: () => setState(() {
        _selectedReminderCategoryFilter = 'All';
        _typeFilter = 'all';
      }),
      backgroundColor: AppColors.moduleTime.withValues(alpha: 0.12),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSegmentPill(String title, int count, bool isDark) {
    final palette = context.palette;
    final isSelected = _selectedStatusFilter == title;
    final textColor = isSelected ? palette.heading : palette.caption;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedStatusFilter = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? palette.card : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected && !palette.isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: title),
                  TextSpan(
                    text: '  $count',
                    style: context.text.labelMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.moduleTime
                          : palette.caption,
                    ),
                  ),
                ],
              ),
              style: context.text.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Plain section title (same 17px style as the Today tab) with a tinted
  /// count pill and right-aligned text actions. The title owns the slack
  /// width, so it never wraps while the actions still sit on the gutter.
  Widget _buildSectionHeader({
    required String title,
    required Color color,
    required int count,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onMarkAllDone,
  }) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: palette.heading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: context.text.labelSmall?.copyWith(
                        fontSize: 11.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (onMarkAllDone != null)
              _buildHeaderAction(
                label: 'Mark All Done',
                color: color,
                onTap: onMarkAllDone,
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  /// Text action used in section headers; right edge sits on the gutter.
  Widget _buildHeaderAction({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.only(left: 8),
        minimumSize: const Size(0, 24),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: AppTextStyles.labelMedium.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }

  void _duplicateReminder(PlannerItemEntity item) {
    context.read<PlannerBloc>().add(
      AddPlannerItem(
        title: '${item.title} (Copy)',
        date: item.date,
        startTime: item.startTime,
        endTime: item.endTime,
        category: item.category,
        colorValue: item.colorValue,
        iconCodePoint: item.iconCodePoint,
        repeatType: item.repeatType,
        repeatDays: item.repeatDays,
        endDate: item.endDate,
        priority: item.priority,
        reminderOffsetMinutes: item.reminderOffsetMinutes,
        checklist: item.checklist,
        notes: item.notes,
      ),
    );
    SnackbarUtils.showSuccess(context, 'Duplicated "${item.title}"');
  }

  void _pushToTomorrow(PlannerItemEntity item) {
    final current = DateTime.tryParse(item.date) ?? DateTime.now();
    final tomorrow = current.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    context.read<PlannerBloc>().add(
      UpdatePlannerItem(
        id: item.id,
        title: item.title,
        date: tomorrowStr,
        startTime: item.startTime,
        endTime: item.endTime,
        category: item.category,
        colorValue: item.colorValue,
        iconCodePoint: item.iconCodePoint,
        repeatType: item.repeatType,
        repeatDays: item.repeatDays,
        endDate: item.endDate,
        priority: item.priority,
        reminderOffsetMinutes: item.reminderOffsetMinutes,
        checklist: item.checklist,
        notes: item.notes,
      ),
    );
    SnackbarUtils.showSuccess(context, 'Rescheduled to tomorrow');
  }

  Future<void> _pushToTodayTimeline(
    BuildContext context,
    PlannerItemEntity item,
  ) async {
    try {
      if (sl.isRegistered<AddTimelineItemUseCase>()) {
        final todayStr = DateTime.now().toIso8601String().split('T').first;
        await sl<AddTimelineItemUseCase>()(
          TimelineItemEntity(
            id: 0,
            time: (item.startTime != null && item.startTime!.isNotEmpty)
                ? item.startTime!
                : '09:00 AM',
            title: item.title,
            category: item.category.isNotEmpty ? item.category : 'Planner',
            colorValue: item.colorValue,
            iconCodePoint: item.iconCodePoint,
            isDone: item.isDone,
            action: 'Mark Done',
            date: todayStr,
          ),
        );
      }
      if (context.mounted) {
        SnackbarUtils.showSuccess(
          context,
          '${StringConstants.pushedToTimelineMessage}: "${item.title}"',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, '$e');
      }
    }
  }

  void _markAllDone(List<PlannerItemEntity> items) {
    final pending = items.where((i) => !i.isDone).toList();
    for (final item in pending) {
      context.read<PlannerBloc>().add(
        TogglePlannerItem(item.id, targetDate: 'all'),
      );
    }
    SnackbarUtils.showSuccess(
      context,
      'Marked ${pending.length} reminders as done',
    );
  }

  void _startFocusOnTask(PlannerItemEntity item) {
    final mappedCategory = switch (item.category) {
      'Work' => 'Deep Work',
      'Personal' => 'Personal',
      'Health' => 'Reading',
      'Finance' => 'Planning',
      _ => 'Deep Work',
    };
    setState(() {
      if (_linkedTaskId != item.id) {
        _completedTaskPomodoros = 0;
      }
      _linkedTask = item.title;
      _linkedTaskId = item.id;
      _focusCategory = mappedCategory;
      if (!_isTimerRunning && _focusModeIndex != 0) {
        _focusModeIndex = 0;
        _secondsRemaining = _workMinutes * 60;
        _sessionInitialTotalSeconds = _secondsRemaining;
      }
    });
    _savePomodoroSettings();
    _tabController.animateTo(1);
    SnackbarUtils.showSuccess(context, 'Linked "${item.title}" to Focus Timer');
  }

  Widget _buildReminderItemCard(
    BuildContext context,
    PlannerItemEntity item,
    bool isDark,
  ) {
    return PlannerItemCard(
      item: item,
      isDark: isDark,
      onToggle: (_) => context.read<PlannerBloc>().add(
        TogglePlannerItem(item.id, targetDate: 'all'),
      ),
      onEdit: () => _openEditReminderSheet(context, item, isDark),
      onDuplicate: () => _duplicateReminder(item),
      onPushTomorrow: () => _pushToTomorrow(item),
      onPushToTimeline: () => _pushToTodayTimeline(context, item),
      onStartFocus: () => _startFocusOnTask(item),
      onChecklistChanged: (updatedChecklist) {
        context.read<PlannerBloc>().add(
          UpdatePlannerItem(
            id: item.id,
            title: item.title,
            date: item.date,
            startTime: item.startTime,
            endTime: item.endTime,
            category: item.category,
            colorValue: item.colorValue,
            iconCodePoint: item.iconCodePoint,
            repeatType: item.repeatType,
            repeatDays: item.repeatDays,
            endDate: item.endDate,
            priority: item.priority,
            reminderOffsetMinutes: item.reminderOffsetMinutes,
            checklist: updatedChecklist,
            notes: item.notes,
          ),
        );
      },
      onDelete: () {
        final notifId =
            ('${item.title}${item.date}${item.startTime}').hashCode &
            0x7FFFFFFF;
        try {
          sl<NotificationService>().cancelNotification(notifId);
        } catch (_) {}
        context.read<PlannerBloc>().add(DeletePlannerItem(item.id));
      },
      onSnooze: () => _showSnoozeOptions(context, item, isDark),
    );
  }

  void _applyQuickTemplate(Map<String, dynamic> template) {
    setState(() {
      _quickReminderController.text = template['title'] as String;
      _selectedCategory = template['category'] as String;
      _selectedTime = template['time'] as TimeOfDay;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Template "${template['title']}" applied! Tap "Set Reminder" or edit details.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmClearCompleted(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Clear Completed Reminders?',
      message: 'This will permanently remove all completed one-off reminders.',
      confirmLabel: 'Clear All',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<PlannerBloc>().add(const ClearCompletedPlannerItems());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed reminders cleared.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showSnoozeOptions(
    BuildContext context,
    PlannerItemEntity item,
    bool isDark,
  ) async {
    final choice = await PlannerSnoozeSheet.show(context, item: item);
    if (choice == null || !context.mounted) return;
    if (choice.moveDateToTomorrow) {
      _pushToTomorrow(item);
    }
    _snoozeReminder(context, item, choice.duration, choice.label);
  }

  void _snoozeReminder(
    BuildContext context,
    PlannerItemEntity item,
    Duration duration,
    String label,
  ) {
    final snoozeTime = DateTime.now().add(duration);
    final snoozeId = (item.id.hashCode + duration.inMinutes) & 0x7FFFFFFF;
    try {
      sl<NotificationService>().scheduleNotification(
        id: snoozeId,
        title: 'Snoozed: ${item.title}',
        body: 'Reminder snoozed ($label)',
        scheduledDate: snoozeTime,
        channelId: NotificationChannels.reminders,
        payload: 'planner_snooze_${item.id}',
      );
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.title}" snoozed ($label). Alert set!'),
        behavior: SnackBarBehavior.floating,
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

    final targetDateIso =
        _selectedDateIso ?? DateTime.now().toIso8601String().substring(0, 10);
    final timeStr = _formatTimeOfDay(_selectedTime);

    context.read<PlannerBloc>().add(
      AddPlannerItem(
        title: title,
        date: targetDateIso,
        startTime: timeStr,
        category: _selectedCategory,
        priority: _quickPriority,
        colorValue: _getCategoryColor(_selectedCategory).toARGB32(),
        iconCodePoint: _getCategoryIcon(_selectedCategory).codePoint,
      ),
    );

    final parsedDate = DateTime.tryParse(targetDateIso) ?? DateTime.now();
    final scheduledDate = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final notifId = ('$title$targetDateIso$timeStr').hashCode & 0x7FFFFFFF;
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

  void _cycleQuickPriority() {
    const priorities = ['low', 'medium', 'high', 'urgent'];
    setState(() {
      final idx = priorities.indexOf(_quickPriority);
      _quickPriority = priorities[(idx + 1) % priorities.length];
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

  void _openFullReminderSheet(
    BuildContext context,
    bool isDark, {
    String? overridePriority,
  }) {
    final plannerBloc = context.read<PlannerBloc>();
    final defaultDate = _selectedDateIso != null
        ? (DateTime.tryParse(_selectedDateIso!) ?? DateTime.now())
        : DateTime.now();

    SetReminderSheet.show(
      context,
      initialTitle: _quickReminderController.text.trim(),
      initialDate: defaultDate,
      initialTime: _selectedTime,
      initialCategory: _selectedCategory,
      initialPriority: overridePriority ?? _quickPriority,
      isDark: isDark,
      onSubmit:
          ({
            required title,
            required date,
            required time,
            required category,
            required repeatType,
            required repeatDays,
            required endDate,
            required priority,
            required reminderOffsetMinutes,
            required checklist,
            required notes,
          }) {
            final dateStr = _formatDateToIso(date);
            final endDateStr = endDate != null
                ? _formatDateToIso(endDate)
                : null;
            final timeStr = _formatTimeOfDay(time);

            plannerBloc.add(
              AddPlannerItem(
                title: title,
                date: dateStr,
                startTime: timeStr,
                category: category,
                colorValue: _getCategoryColor(category).toARGB32(),
                iconCodePoint: _getCategoryIcon(category).codePoint,
                repeatType: repeatType,
                repeatDays: repeatDays,
                endDate: endDateStr,
                priority: priority,
                reminderOffsetMinutes: reminderOffsetMinutes,
                checklist: checklist,
                notes: notes,
              ),
            );

            _scheduleReminderNotification(
              title: title,
              date: date,
              time: time,
              category: category,
              repeatType: repeatType,
              offsetMinutes: reminderOffsetMinutes,
            );

            _quickReminderController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reminder "$title" saved!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
    );
  }

  void _openEditReminderSheet(
    BuildContext context,
    PlannerItemEntity item,
    bool isDark,
  ) {
    final plannerBloc = context.read<PlannerBloc>();

    DateTime initialDate = DateTime.now();
    if (item.date.isNotEmpty) {
      try {
        initialDate = DateTime.parse(item.date);
      } catch (_) {}
    }

    DateTime? initialEndDate;
    if (item.endDate != null && item.endDate!.isNotEmpty) {
      try {
        initialEndDate = DateTime.parse(item.endDate!);
      } catch (_) {}
    }

    final initialTime = _parseTimeString(item.startTime) ?? _selectedTime;
    final category = item.category.isNotEmpty
        ? item.category
        : _selectedCategory;

    SetReminderSheet.show(
      context,
      sheetTitle: 'Edit Reminder',
      submitButtonText: 'Update Reminder',
      initialTitle: item.title,
      initialDate: initialDate,
      initialTime: initialTime,
      initialCategory: category,
      initialRepeatType: item.repeatType,
      initialRepeatDays: item.repeatDays,
      initialEndDate: initialEndDate,
      initialPriority: item.priority,
      initialReminderOffsetMinutes: item.reminderOffsetMinutes,
      initialChecklist: item.checklist,
      initialNotes: item.notes,
      isDark: isDark,
      onSubmit:
          ({
            required title,
            required date,
            required time,
            required category,
            required repeatType,
            required repeatDays,
            required endDate,
            required priority,
            required reminderOffsetMinutes,
            required checklist,
            required notes,
          }) {
            final dateStr = _formatDateToIso(date);
            final endDateStr = endDate != null
                ? _formatDateToIso(endDate)
                : null;
            final timeStr = _formatTimeOfDay(time);

            // Cancel previous notification
            final oldNotifId =
                ('${item.title}${item.date}${item.startTime}').hashCode &
                0x7FFFFFFF;
            try {
              sl<NotificationService>().cancelNotification(oldNotifId);
            } catch (_) {}

            // Dispatch update
            plannerBloc.add(
              UpdatePlannerItem(
                id: item.id,
                title: title,
                date: dateStr,
                startTime: timeStr,
                category: category,
                colorValue: _getCategoryColor(category).toARGB32(),
                iconCodePoint: _getCategoryIcon(category).codePoint,
                repeatType: repeatType,
                repeatDays: repeatDays,
                endDate: endDateStr,
                priority: priority,
                reminderOffsetMinutes: reminderOffsetMinutes,
                checklist: checklist,
                notes: notes,
              ),
            );

            // Reschedule updated notification
            _scheduleReminderNotification(
              title: title,
              date: date,
              time: time,
              category: category,
              repeatType: repeatType,
              offsetMinutes: reminderOffsetMinutes,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reminder "$title" updated!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
    );
  }

  void _scheduleReminderNotification({
    required String title,
    required DateTime date,
    required TimeOfDay time,
    required String category,
    required String repeatType,
    required int offsetMinutes,
  }) {
    final rawDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final alertDate = rawDate.subtract(Duration(minutes: offsetMinutes));
    final notifId = ('$title$date$time$repeatType').hashCode & 0x7FFFFFFF;

    DateTimeComponents? matchComponents;
    if (repeatType == 'daily' || repeatType == 'weekdays') {
      matchComponents = DateTimeComponents.time;
    } else if (repeatType == 'weekly') {
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    }

    try {
      sl<NotificationService>().scheduleNotification(
        id: notifId,
        title: 'Reminder: $title',
        body: offsetMinutes > 0
            ? 'Starting in $offsetMinutes min • Category: $category'
            : 'Scheduled for ${_formatTimeOfDay(time)} • Category: $category',
        scheduledDate: alertDate,
        channelId: NotificationChannels.reminders,
        payload: 'planner_reminder_$notifId',
        matchDateTimeComponents: matchComponents,
      );
    } catch (_) {}
  }

  // =========================================================================
  // TAB 2: POMODORO FOCUS TAB
  // =========================================================================
  Widget _buildFocusTimerTab(BuildContext context, bool isDark) {
    const gutter = EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter);

    return BlocBuilder<PlannerBloc, PlannerState>(
      builder: (context, state) {
        final allItems = state is PlannerLoaded
            ? state.items
            : <PlannerItemEntity>[];
        PlannerItemEntity? linkedItem;
        if (_linkedTaskId != null) {
          for (final it in allItems) {
            if (it.id == _linkedTaskId) {
              linkedItem = it;
              break;
            }
          }
        }
        if (linkedItem == null) {
          for (final it in allItems) {
            if (it.title.toLowerCase() == _linkedTask.toLowerCase()) {
              linkedItem = it;
              break;
            }
          }
        }

        final modeSelector = PomodoroModeSelector(
          selectedIndex: _focusModeIndex,
          workMinutes: _workMinutes,
          shortBreakMinutes: _shortBreakMinutes,
          longBreakMinutes: _longBreakMinutes,
          onModeSelected: _switchFocusMode,
          isDark: isDark,
        );

        final focusCard = PomodoroFocusCard(
          focusModeIndex: _focusModeIndex,
          currentRound: _currentRound,
          totalRounds: _totalRounds,
          timerProgress: _timerProgress,
          formattedTime: _formatTimer(_secondsRemaining),
          isTimerRunning: _isTimerRunning,
          linkedTask: _linkedTask,
          focusCategory: _focusCategory,
          estimatedPomodoros: _estimatedPomodoros,
          completedTaskPomodoros: _completedTaskPomodoros,
          strictMode: _strictMode,
          selectedAmbience: _selectedAmbience,
          linkedPlannerItem: linkedItem,
          onToggleTimer: _toggleTimer,
          onResetTimer: _resetTimer,
          onSkipSession: _skipSession,
          onChangeTask: () => _openLinkedTaskSheet(context, isDark),
          onAddMinutes: _addMinutesToTimer,
          onFinishStopwatch: _finishStopwatchSession,
          onOpenZenMode: () => _openZenFocusScreen(context, linkedItem),
          onToggleSubtask: linkedItem == null
              ? null
              : (sub) => _toggleLinkedSubtask(linkedItem!, sub),
          onMarkTaskDone: linkedItem == null
              ? null
              : () => _markLinkedTaskDone(linkedItem!),
        );

        final presetChips = [
          for (final preset in const [
            ('15m Sprint', 15),
            ('25m Classic', 25),
            ('45m Deep Work', 45),
            ('60m Ultra Focus', 60),
            ('90m Flow Block', 90),
          ])
            _buildSelectableChip(
              label: preset.$1,
              isSelected: _focusModeIndex == 0 && _workMinutes == preset.$2,
              isDark: isDark,
              onTap: () {
                _timer?.cancel();
                setState(() {
                  _workMinutes = preset.$2;
                  _focusModeIndex = 0;
                  _secondsRemaining = preset.$2 * 60;
                  _sessionInitialTotalSeconds = _secondsRemaining;
                  _isTimerRunning = false;
                });
                _savePomodoroSettings();
              },
            ),
        ];

        final ambienceChips = _ambienceOptions.map((opt) {
          final name = opt['name'] as String;
          return _buildSelectableChip(
            label: name,
            icon: opt['icon'] as IconData,
            isSelected: _selectedAmbience == name,
            isDark: isDark,
            onTap: () {
              setState(() => _selectedAmbience = name);
              _savePomodoroSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    name == 'Mute'
                        ? 'Ambience sound muted'
                        : 'Ambience set to $name',
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
        }).toList();

        Widget buildVolumeStrip() {
          final palette = context.palette;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: AppRadius.radiusSm,
              border: Border.all(color: palette.divider, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.graphic_eq_rounded,
                  size: 16,
                  color: AppColors.moduleTime,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedAmbience,
                  style: context.text.labelMedium?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: palette.heading,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.moduleTime,
                      inactiveTrackColor: AppColors.moduleTime.withValues(
                        alpha: 0.2,
                      ),
                      thumbColor: AppColors.moduleTime,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _ambienceVolume,
                      onChanged: (val) {
                        setState(() => _ambienceVolume = val);
                        _savePomodoroSettings();
                      },
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _selectedAmbience = 'Mute');
                    _savePomodoroSettings();
                  },
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: 'Mute Ambience',
                  icon: Icon(
                    Icons.volume_off_rounded,
                    size: 15,
                    color: palette.caption,
                  ),
                ),
              ],
            ),
          );
        }

        final analyticsSection = BlocBuilder<ProfileBloc, ProfileState>(
          bloc: sl.isRegistered<ProfileBloc>() ? sl<ProfileBloc>() : null,
          builder: (context, profileState) {
            final effectiveGoalSessions = sl.isRegistered<ProfileBloc>()
                ? (profileState.profile.dailyFocusGoalMinutes /
                          (_workMinutes > 0 ? _workMinutes : 25))
                      .ceil()
                      .clamp(1, 16)
                : _dailyGoalSessions;
            return PomodoroAnalyticsDashboard(
              sessions: _focusSessions,
              distractions: _distractions,
              dailyGoalSessions: effectiveGoalSessions,
              workMinutes: _workMinutes,
              isDark: isDark,
              onOpenManualLog: () => _openManualSessionSheet(context, isDark),
              onDeleteSession: (id) {
                setState(() {
                  _focusSessions.removeWhere((s) => s.id == id);
                });
                _saveFocusSessions();
              },
              onAddDistraction: _addDistractionNote,
              onConvertDistractionToTask: (item) =>
                  _convertDistractionToPlanner(context, item),
              onDeleteDistraction: (id) {
                setState(() {
                  _distractions.removeWhere((d) => d.id == id);
                });
                _saveDistractions();
              },
            );
          },
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideDesktop = constraints.maxWidth >= 940;

            if (isWideDesktop) {
              return ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 88),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Padding(
                        padding: gutter,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 11,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  modeSelector,
                                  const SizedBox(height: 12),
                                  focusCard,
                                  _buildFocusSectionHeader(
                                    'Focus Presets & Custom Time',
                                    isDark,
                                    action: _buildHeaderAction(
                                      label: 'Custom',
                                      color: AppColors.moduleTime,
                                      onTap: () => _openCustomDurationSheet(
                                        context,
                                        isDark,
                                      ),
                                    ),
                                  ),
                                  _buildChipStrip(
                                    padding: EdgeInsets.zero,
                                    children: presetChips,
                                  ),
                                  _buildFocusSectionHeader(
                                    'Focus Ambience & Sounds',
                                    isDark,
                                    action: _selectedAmbience != 'Mute'
                                        ? Text(
                                            '${(_ambienceVolume * 100).round()}% Vol',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.moduleTime,
                                                ),
                                          )
                                        : null,
                                  ),
                                  _buildChipStrip(
                                    padding: EdgeInsets.zero,
                                    children: ambienceChips,
                                  ),
                                  if (_selectedAmbience != 'Mute') ...[
                                    const SizedBox(height: 6),
                                    buildVolumeStrip(),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(flex: 10, child: analyticsSection),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.only(top: 6, bottom: 88),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: gutter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              modeSelector,
                              const SizedBox(height: 12),
                              focusCard,
                              _buildFocusSectionHeader(
                                'Focus Presets & Custom Time',
                                isDark,
                                action: _buildHeaderAction(
                                  label: 'Custom',
                                  color: AppColors.moduleTime,
                                  onTap: () =>
                                      _openCustomDurationSheet(context, isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildChipStrip(children: presetChips),
                        Padding(
                          padding: gutter,
                          child: _buildFocusSectionHeader(
                            'Focus Ambience & Sounds',
                            isDark,
                            action: _selectedAmbience != 'Mute'
                                ? Text(
                                    '${(_ambienceVolume * 100).round()}% Vol',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.moduleTime,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        _buildChipStrip(children: ambienceChips),
                        if (_selectedAmbience != 'Mute')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.pageGutter,
                              6,
                              AppSpacing.pageGutter,
                              0,
                            ),
                            child: buildVolumeStrip(),
                          ),
                        const SizedBox(height: 12),
                        Padding(padding: gutter, child: analyticsSection),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleLinkedSubtask(PlannerItemEntity item, ChecklistItem target) {
    final updated = item.checklist
        .map((c) => c.id == target.id ? c.copyWith(isDone: !c.isDone) : c)
        .toList();
    context.read<PlannerBloc>().add(
      UpdatePlannerItem(
        id: item.id,
        title: item.title,
        date: item.date,
        startTime: item.startTime,
        endTime: item.endTime,
        category: item.category,
        colorValue: item.colorValue,
        iconCodePoint: item.iconCodePoint,
        repeatType: item.repeatType,
        repeatDays: item.repeatDays,
        endDate: item.endDate,
        priority: item.priority,
        reminderOffsetMinutes: item.reminderOffsetMinutes,
        checklist: updated,
        notes: item.notes,
      ),
    );
  }

  void _markLinkedTaskDone(PlannerItemEntity item) {
    context.read<PlannerBloc>().add(
      TogglePlannerItem(item.id, targetDate: 'all'),
    );
    SnackbarUtils.showSuccess(
      context,
      'Completed linked task "${item.title}"! 🎯',
    );
  }

  void _addDistractionNote(String text) {
    final item = FocusDistractionItem(
      id: 'dist_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _distractions.insert(0, item);
    });
    _saveDistractions();
  }

  void _convertDistractionToPlanner(
    BuildContext context,
    FocusDistractionItem item,
  ) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    context.read<PlannerBloc>().add(
      AddPlannerItem(
        title: item.text,
        date: today,
        startTime: '05:00 PM',
        category: 'Personal',
        colorValue: AppColors.moduleTime.toARGB32(),
        iconCodePoint: Icons.lightbulb_outline_rounded.codePoint,
        notes: 'Captured from Pomodoro Distraction Pad',
      ),
    );
    setState(() {
      final idx = _distractions.indexWhere((d) => d.id == item.id);
      if (idx != -1) {
        _distractions[idx] = item.copyWith(addedToPlanner: true);
      }
    });
    _saveDistractions();
    SnackbarUtils.showSuccess(
      context,
      'Added "${item.text}" to today\'s Planner!',
    );
  }

  void _openManualSessionSheet(BuildContext context, bool isDark) {
    PomodoroManualSessionSheet.show(
      context,
      initialTask: _linkedTask,
      initialCategory: _focusCategory,
      initialDuration: _workMinutes,
      isDark: isDark,
      onSave: (newSession) {
        setState(() {
          _focusSessions.insert(0, newSession);
          _completedTaskPomodoros++;
        });
        _saveFocusSessions();
        _savePomodoroSettings();
        SnackbarUtils.showSuccess(
          context,
          'Logged ${newSession.durationMinutes}m focus session!',
        );
      },
    );
  }

  void _openZenFocusScreen(
    BuildContext context,
    PlannerItemEntity? linkedItem,
  ) {
    _timer?.cancel();
    PomodoroZenScreen.show(
      context,
      focusModeIndex: _focusModeIndex,
      currentRound: _currentRound,
      totalRounds: _totalRounds,
      secondsRemaining: _secondsRemaining,
      totalModeSeconds: _sessionInitialTotalSeconds,
      isRunning: _isTimerRunning,
      linkedTask: _linkedTask,
      focusCategory: _focusCategory,
      selectedAmbience: _selectedAmbience,
      ambienceVolume: _ambienceVolume,
      linkedPlannerItem: linkedItem,
      ambienceOptions: _ambienceOptions,
      onToggleSubtask: linkedItem == null
          ? null
          : (sub) => _toggleLinkedSubtask(linkedItem, sub),
      onCaptureDistraction: _addDistractionNote,
      onAmbienceChanged: (amb) {
        setState(() => _selectedAmbience = amb);
        _savePomodoroSettings();
      },
      onVolumeChanged: (vol) {
        setState(() => _ambienceVolume = vol);
        _savePomodoroSettings();
      },
      onSyncBack: (remaining, running) {
        if (!mounted) return;
        setState(() {
          _secondsRemaining = remaining;
          _isTimerRunning = running;
        });
        if (running) {
          _startTimerLoop();
        }
      },
    );
  }

  Widget _buildFocusSectionHeader(String title, bool isDark, {Widget? action}) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: SizedBox(
        height: 26,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium?.copyWith(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: palette.heading,
                ),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }

  /// Horizontal chip row that scrolls edge-to-edge (or flush inside a column).
  Widget _buildChipStrip({
    required List<Widget> children,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.pageGutter,
    ),
  }) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final palette = context.palette;
    final fg = isSelected ? AppColors.moduleTime : palette.heading;
    return Material(
      color: isSelected
          ? AppColors.moduleTime.withValues(alpha: 0.12)
          : palette.card,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected
              ? AppColors.moduleTime.withValues(alpha: 0.5)
              : palette.divider,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? AppColors.moduleTime : palette.icon,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCustomDurationSheet(BuildContext context, bool isDark) {
    PomodoroCustomDurationSheet.show(
      context,
      workMinutes: _workMinutes,
      shortBreakMinutes: _shortBreakMinutes,
      longBreakMinutes: _longBreakMinutes,
      totalRounds: _totalRounds,
      dailyGoalSessions: _dailyGoalSessions,
      autoStartBreaks: _autoStartBreaks,
      autoStartWork: _autoStartWork,
      strictMode: _strictMode,
      voiceCoach: _voiceCoach,
      isDark: isDark,
      onSave: (w, s, l) {
        _timer?.cancel();
        setState(() {
          _workMinutes = w;
          _shortBreakMinutes = s;
          _longBreakMinutes = l;
          _isTimerRunning = false;
          if (_focusModeIndex != 3) {
            _secondsRemaining = _currentTotalSeconds;
            _sessionInitialTotalSeconds = _secondsRemaining;
          }
        });
        _savePomodoroSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pomodoro durations updated!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onSaveAdvanced: (cfg) {
        setState(() {
          _totalRounds = cfg.totalRounds;
          if (_currentRound > _totalRounds) _currentRound = 1;
          _dailyGoalSessions = cfg.dailyGoalSessions;
          _autoStartBreaks = cfg.autoStartBreaks;
          _autoStartWork = cfg.autoStartWork;
          _strictMode = cfg.strictMode;
          _voiceCoach = cfg.voiceCoach;
        });
        _savePomodoroSettings();
      },
    );
  }

  void _openLinkedTaskSheet(BuildContext context, bool isDark) {
    final state = context.read<PlannerBloc>().state;
    final items = state is PlannerLoaded ? state.items : <PlannerItemEntity>[];

    PomodoroLinkedTaskSheet.show(
      context,
      currentTask: _linkedTask,
      currentLinkedTaskId: _linkedTaskId,
      currentCategory: _focusCategory,
      currentEstimatedPomodoros: _estimatedPomodoros,
      todayTasks: items,
      isDark: isDark,
      onTaskSelected: (task) => setState(() => _linkedTask = task),
      onTaskDetailsSelected: (details) {
        setState(() {
          if (details.title != _linkedTask) {
            _completedTaskPomodoros = 0;
          }
          _linkedTask = details.title;
          _linkedTaskId = details.linkedTaskId;
          _focusCategory = details.category;
          _estimatedPomodoros = details.estimatedPomodoros;
        });
        _savePomodoroSettings();
      },
    );
  }

  // =========================================================================
  // TAB 3: COUNTDOWNS TAB
  // =========================================================================
  Widget _buildCountdownsTab(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = _selectedCountdownCategory == 'All'
        ? List<CountdownItemEntity>.from(_countdowns)
        : _countdowns
              .where((c) => c.category == _selectedCountdownCategory)
              .toList();

    final upcoming = <CountdownItemEntity>[];
    final past = <CountdownItemEntity>[];
    for (final cd in filtered) {
      final target = DateTime(cd.date.year, cd.date.month, cd.date.day);
      if (target.isBefore(today)) {
        past.add(cd);
      } else {
        upcoming.add(cd);
      }
    }
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    past.sort((a, b) => b.date.compareTo(a.date));

    final nearest = upcoming.isNotEmpty ? upcoming.first : null;

    Widget buildCountdownGrid(List<CountdownItemEntity> items, bool twoColumn) {
      if (!twoColumn) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++)
              StaggeredFadeSlide(
                index: i,
                child: CountdownCard(
                  item: items[i],
                  isDark: isDark,
                  onAddToPlanner: () =>
                      _addCountdownToPlanner(context, items[i]),
                  onEdit: () =>
                      _openCountdownSheet(context, isDark, editItem: items[i]),
                  onDelete: () => _deleteCountdown(context, items[i]),
                ),
              ),
          ],
        );
      }

      final rows = <Widget>[];
      for (var i = 0; i < items.length; i += 2) {
        final first = items[i];
        final second = (i + 1 < items.length) ? items[i + 1] : null;
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CountdownCard(
                  item: first,
                  isDark: isDark,
                  onAddToPlanner: () => _addCountdownToPlanner(context, first),
                  onEdit: () =>
                      _openCountdownSheet(context, isDark, editItem: first),
                  onDelete: () => _deleteCountdown(context, first),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: second != null
                    ? CountdownCard(
                        item: second,
                        isDark: isDark,
                        onAddToPlanner: () =>
                            _addCountdownToPlanner(context, second),
                        onEdit: () => _openCountdownSheet(
                          context,
                          isDark,
                          editItem: second,
                        ),
                        onDelete: () => _deleteCountdown(context, second),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      );
    }

    const gutter = EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter);
    final palette = context.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth >= 880;

        return ListView(
          padding: const EdgeInsets.only(top: 6, bottom: 88),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: gutter,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Important Countdowns',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.titleMedium?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: palette.heading,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_countdowns.length} upcoming events & milestones',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.bodySmall?.copyWith(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: palette.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () =>
                                _openCountdownSheet(context, isDark),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.moduleTime.withValues(
                                alpha: palette.isDark ? 0.22 : 0.14,
                              ),
                              foregroundColor: palette.isDark
                                  ? AppColors.moduleTimeLight
                                  : AppColors.moduleTime,
                              elevation: 0,
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              textStyle: AppTextStyles.labelMedium.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add Event'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Milestone Overview & Nearest-Event Spotlight
                    if (_countdowns.isNotEmpty) ...[
                      Padding(
                        padding: gutter,
                        child: CountdownSpotlightCard(
                          countdowns: filtered,
                          onTapNearest: nearest != null
                              ? () => _openCountdownSheet(
                                  context,
                                  isDark,
                                  editItem: nearest,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Category filter strip
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: gutter,
                        itemCount: _countdownCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _countdownCategories[index];
                          final isSelected = _selectedCountdownCategory == cat;
                          return FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => setState(
                              () => _selectedCountdownCategory = cat,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: const StadiumBorder(),
                            backgroundColor: palette.card,
                            selectedColor: AppColors.moduleTime.withValues(
                              alpha: 0.12,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.moduleTime.withValues(alpha: 0.5)
                                  : palette.divider,
                            ),
                            labelStyle: context.text.labelMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.moduleTime
                                  : palette.heading,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: gutter,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (filtered.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.celebration_rounded,
                                      size: 36,
                                      color: palette.divider,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No countdowns in $_selectedCountdownCategory',
                                      style: context.text.bodySmall?.copyWith(
                                        fontSize: 12.5,
                                        color: palette.caption,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _openCountdownSheet(context, isDark),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 30),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 15,
                                      ),
                                      label: Text(
                                        'Create a Countdown',
                                        style: context.text.labelSmall
                                            ?.copyWith(fontSize: 11.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            if (upcoming.isNotEmpty)
                              buildCountdownGrid(upcoming, isTwoColumn),
                            if (past.isNotEmpty) ...[
                              _buildSectionHeader(
                                title: 'Past Events',
                                color: palette.caption,
                                count: past.length,
                                isDark: isDark,
                              ),
                              buildCountdownGrid(past, isTwoColumn),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openCountdownSheet(
    BuildContext context,
    bool isDark, {
    CountdownItemEntity? editItem,
  }) {
    CountdownSheet.show(
      context,
      editItem: editItem,
      isDark: isDark,
      onSave: (savedItem) async {
        if (editItem != null) {
          final index = _countdowns.indexWhere(
            (item) => item.id == editItem.id,
          );
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
    final scheduledDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      9,
      0,
    );
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
    BuildContext context,
    CountdownItemEntity cd,
  ) async {
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
        final dayOf = DateTime(
          item.date.year,
          item.date.month,
          item.date.day,
          9,
          0,
        );
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
            body: '1 day remaining until "${item.title}" (${item.category})!',
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
            body: '7 days remaining until "${item.title}" (${item.category})!',
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
      await sl<NotificationService>().cancelNotification(
        (baseId + 1) & 0x7FFFFFFF,
      );
      await sl<NotificationService>().cancelNotification(
        (baseId + 7) & 0x7FFFFFFF,
      );
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

  TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final clean = timeStr.trim();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)?.toUpperCase();
      if (period != null) {
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
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
