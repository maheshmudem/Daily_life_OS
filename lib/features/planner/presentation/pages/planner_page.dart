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
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/countdown_item_entity.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../../../../core/widgets/app_dropdown_menu.dart';
import '../../../../core/utils/snackbar_utils.dart';
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

enum PlannerSortOption { timeAsc, timeDesc, priority, title }

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
  String _selectedReminderCategoryFilter = 'All';
  String _selectedStatusFilter = 'All'; // 'All', 'Pending', 'Completed'
  String _typeFilter = 'all'; // 'all', 'habits', 'one_off', 'overdue'
  PlannerSortOption _sortOption = PlannerSortOption.timeAsc;
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
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
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
          unselectedLabelColor: isDark
              ? AppColors.darkTextCaption
              : AppColors.textCaption,
          indicatorColor: AppColors.moduleTime,
          indicatorWeight: 3,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
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

        // Filter items based on status, category, type filter, and search query
        final filteredItems = allItems.where((item) {
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
              return 4;
            case 'urgent_not_important':
              return 3;
            case 'important_not_urgent':
              return 2;
            case 'neither':
            default:
              return 1;
          }
        }

        // Sort items according to selected option
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

        const gutter = EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter);

        return ListView(
          // Horizontal gutter is applied per section so the templates row can
          // scroll edge-to-edge while everything else stays on the gutter.
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 96),
          children: [
            Padding(
              padding: gutter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Overview stats
                  _buildProductivityMetricsBar(
                    totalCount: totalCount,
                    todayCount: todayCount,
                    overdueCount: overdueCount,
                    completedCount: completedCount,
                    isDark: isDark,
                  ),
                  AppSpacing.gapH16,

                  // 2. Quick add
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
                    onOpenFullOptions: () =>
                        _openFullReminderSheet(context, isDark),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH12,

            // 3. Quick templates (edge-to-edge horizontal scroll)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: gutter,
                itemCount: _quickTemplates.length,
                separatorBuilder: (_, _) => AppSpacing.gapW8,
                itemBuilder: (context, index) {
                  final tmpl = _quickTemplates[index];
                  return _buildTemplateChip(tmpl, isDark);
                },
              ),
            ),
            AppSpacing.gapH24,

            Padding(
              padding: gutter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 4. Search + filter + sort
                  _buildControlsBar(isDark),
                  AppSpacing.gapH12,

                  // 5. Status segments
                  _buildSegmentedStatusBar(
                    totalCount,
                    pendingCount,
                    completedCount,
                    isDark,
                  ),
                  AppSpacing.gapH8,

                  // 6. Items from DB
                  if (state is PlannerLoading || state is PlannerInitial)
                    ...[1, 2, 3].map(
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: AppShimmerLoader.card(height: 100),
                      ),
                    )
                  else if (state is PlannerLoaded) ...[
                    if (filteredItems.isEmpty)
                      AppEmptyState(
                        icon: _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : (_selectedStatusFilter == 'Completed'
                                  ? Icons.task_alt_rounded
                                  : Icons.alarm_add_rounded),
                        title: _searchQuery.isNotEmpty
                            ? 'No matching reminders'
                            : (_selectedStatusFilter == 'Completed'
                                  ? 'No completed tasks yet'
                                  : (_selectedReminderCategoryFilter == 'All'
                                        ? 'No reminders yet'
                                        : 'No $_selectedReminderCategoryFilter reminders')),
                        description: _searchQuery.isNotEmpty
                            ? 'No reminders match "$_searchQuery". Try a different search.'
                            : (_selectedStatusFilter == 'Completed'
                                  ? 'Finish a reminder to see it archived here.'
                                  : 'Tap "Quick Set" above or select a template to create one.'),
                        actionLabel: _searchQuery.isNotEmpty
                            ? 'Clear Search'
                            : (_selectedReminderCategoryFilter != 'All' ||
                                      _typeFilter != 'all'
                                  ? 'Reset Filters'
                                  : null),
                        onAction: () {
                          setState(() {
                            _searchQuery = '';
                            _selectedReminderCategoryFilter = 'All';
                            _typeFilter = 'all';
                          });
                        },
                      )
                    else if (_searchQuery.isNotEmpty ||
                        _selectedStatusFilter != 'All' ||
                        _selectedReminderCategoryFilter != 'All' ||
                        _typeFilter != 'all') ...[
                      _buildSectionHeader(
                        title: _searchQuery.isNotEmpty
                            ? 'Search Results'
                            : (_selectedReminderCategoryFilter != 'All'
                                  ? '$_selectedReminderCategoryFilter Reminders'
                                  : (_typeFilter != 'all'
                                        ? (_typeFilter == 'habits'
                                              ? 'Habits'
                                              : 'One-Off Reminders')
                                        : '$_selectedStatusFilter Reminders')),
                        icon: Icons.filter_list_rounded,
                        color: AppColors.moduleTime,
                        count: filteredItems.length,
                        isDark: isDark,
                      ),
                      ...filteredItems.map(
                        (item) => _buildReminderItemCard(context, item, isDark),
                      ),
                    ] else ...[
                      () {
                        final overdue = filteredItems
                            .where((i) => i.isOverdue)
                            .toList();
                        final todayAndRecurring = filteredItems
                            .where(
                              (i) =>
                                  !i.isDone &&
                                  !i.isOverdue &&
                                  (i.isToday || i.isRecurring),
                            )
                            .toList();
                        final upcoming = filteredItems
                            .where(
                              (i) => !i.isDone && !i.isOverdue && i.isUpcoming,
                            )
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
                        final completed = filteredItems
                            .where((i) => i.isDone)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Overdue Section
                            if (overdue.isNotEmpty) ...[
                              _buildSectionHeader(
                                title: 'Overdue',
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.error,
                                count: overdue.length,
                                isDark: isDark,
                                onMarkAllDone: () => _markAllDone(overdue),
                              ),
                              ...overdue.map(
                                (item) => _buildReminderItemCard(
                                  context,
                                  item,
                                  isDark,
                                ),
                              ),
                            ],

                            // 2. Today & Recurring Routines
                            if (todayAndRecurring.isNotEmpty) ...[
                              _buildSectionHeader(
                                title: 'Today & Routines',
                                icon: Icons.today_rounded,
                                color: AppColors.moduleTime,
                                count: todayAndRecurring.length,
                                isDark: isDark,
                                onMarkAllDone: () =>
                                    _markAllDone(todayAndRecurring),
                              ),
                              ...todayAndRecurring.map(
                                (item) => _buildReminderItemCard(
                                  context,
                                  item,
                                  isDark,
                                ),
                              ),
                            ],

                            // 3. Upcoming Section
                            if (upcoming.isNotEmpty) ...[
                              _buildSectionHeader(
                                title: 'Upcoming',
                                icon: Icons.upcoming_rounded,
                                color: AppColors.primary,
                                count: upcoming.length,
                                isDark: isDark,
                              ),
                              ...upcoming.map(
                                (item) => _buildReminderItemCard(
                                  context,
                                  item,
                                  isDark,
                                ),
                              ),
                            ],

                            // 4. Other Pending Section
                            if (otherPending.isNotEmpty) ...[
                              _buildSectionHeader(
                                title: 'Other Reminders',
                                icon: Icons.checklist_rounded,
                                color: AppColors.textBody,
                                count: otherPending.length,
                                isDark: isDark,
                              ),
                              ...otherPending.map(
                                (item) => _buildReminderItemCard(
                                  context,
                                  item,
                                  isDark,
                                ),
                              ),
                            ],

                            // 5. Completed Section (Collapsible)
                            if (completed.isNotEmpty) ...[
                              _buildSectionHeader(
                                title: 'Completed',
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.success,
                                count: completed.length,
                                isDark: isDark,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildHeaderAction(
                                      label: 'Clear',
                                      color: AppColors.error,
                                      onTap: () =>
                                          _confirmClearCompleted(context),
                                    ),
                                    AppSpacing.gapW8,
                                    _buildHeaderAction(
                                      label: _isCompletedExpanded
                                          ? 'Hide'
                                          : 'Show',
                                      color: isDark
                                          ? AppColors.darkTextCaption
                                          : AppColors.textCaption,
                                      onTap: () => setState(
                                        () => _isCompletedExpanded =
                                            !_isCompletedExpanded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isCompletedExpanded)
                                ...completed.map(
                                  (item) => _buildReminderItemCard(
                                    context,
                                    item,
                                    isDark,
                                  ),
                                ),
                            ],
                          ],
                        );
                      }(),
                    ],
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductivityMetricsBar({
    required int totalCount,
    required int todayCount,
    required int overdueCount,
    required int completedCount,
    required bool isDark,
  }) {
    final completionRate = totalCount > 0
        ? ((completedCount / totalCount) * 100).round()
        : 0;
    final borderCol = isDark ? AppColors.darkDivider : AppColors.divider;

    Widget divider() => Container(width: 1, height: 32, color: borderCol);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: 'Active',
              value: '${totalCount - completedCount}',
              isDark: isDark,
            ),
          ),
          divider(),
          Expanded(
            child: _buildMetricTile(
              label: 'Today',
              value: '$todayCount',
              isDark: isDark,
            ),
          ),
          divider(),
          Expanded(
            child: _buildMetricTile(
              label: 'Overdue',
              value: '$overdueCount',
              valueColor: overdueCount > 0 ? AppColors.error : null,
              isDark: isDark,
            ),
          ),
          divider(),
          Expanded(
            child: _buildMetricTile(
              label: 'Done',
              value: '$completionRate%',
              valueColor: AppColors.moduleTime,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            color:
                valueColor ??
                (isDark ? AppColors.darkTextHeading : AppColors.textHeading),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateChip(Map<String, dynamic> tmpl, bool isDark) {
    final catColor = _getCategoryColor(tmpl['category'] as String);
    return Material(
      color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
      shape: StadiumBorder(
        side: BorderSide(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _applyQuickTemplate(tmpl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tmpl['icon'] as IconData, size: 16, color: catColor),
              const SizedBox(width: 6),
              Text(
                tmpl['title'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Square 48px icon button that matches the search field's height/border.
  Widget _buildControlSquare({
    required IconData icon,
    required bool isDark,
    bool isActive = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.moduleTime.withValues(alpha: 0.12)
            : (isDark ? AppColors.darkSurfaceSecondary : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.moduleTime.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive
                ? AppColors.moduleTime
                : (isDark ? AppColors.darkIconColor : AppColors.iconColor),
          ),
          if (isActive)
            const Positioned(
              top: 10,
              right: 10,
              child: SizedBox(
                width: 7,
                height: 7,
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
    final hasActiveFilter =
        _selectedReminderCategoryFilter != 'All' || _typeFilter != 'all';

    return Row(
      children: [
        Expanded(
          child: SearchBarWidget(
            hintText: 'Search reminders',
            onChanged: (query) => setState(() => _searchQuery = query.trim()),
            onClear: () => setState(() => _searchQuery = ''),
          ),
        ),
        AppSpacing.gapW8,

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
        AppSpacing.gapW8,

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

  Widget _buildSegmentedStatusBar(
    int totalCount,
    int pendingCount,
    int completedCount,
    bool isDark,
  ) {
    final hasActiveFilter =
        _selectedReminderCategoryFilter != 'All' || _typeFilter != 'all';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.all(AppSpacing.xxs),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceSecondary
                : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildSegmentPill('All', totalCount, isDark),
              _buildSegmentPill('Pending', pendingCount, isDark),
              _buildSegmentPill('Completed', completedCount, isDark),
            ],
          ),
        ),

        // Active filter summary with quick clear
        if (hasActiveFilter) ...[
          AppSpacing.gapH12,
          InputChip(
            label: Text(
              _selectedReminderCategoryFilter != 'All'
                  ? _selectedReminderCategoryFilter
                  : (_typeFilter == 'habits'
                        ? 'Recurring only'
                        : (_typeFilter == 'overdue'
                              ? 'Overdue only'
                              : 'One-off only')),
            ),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.moduleTime,
            ),
            avatar: const Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: AppColors.moduleTime,
            ),
            deleteIcon: const Icon(Icons.close_rounded, size: 16),
            deleteIconColor: AppColors.moduleTime,
            onDeleted: () => setState(() {
              _selectedReminderCategoryFilter = 'All';
              _typeFilter = 'all';
            }),
            backgroundColor: AppColors.moduleTime.withValues(alpha: 0.1),
            side: BorderSide.none,
            shape: const StadiumBorder(),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ],
    );
  }

  Widget _buildSegmentPill(String title, int count, bool isDark) {
    final isSelected = _selectedStatusFilter == title;
    final textColor = isSelected
        ? (isDark ? AppColors.darkTextHeading : AppColors.textHeading)
        : (isDark ? AppColors.darkTextCaption : AppColors.textCaption);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedStatusFilter = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkCardBackground : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.moduleTime
                          : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onMarkAllDone,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            AppSpacing.gapW8,
            Text(
              title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextHeading
                    : AppColors.textHeading,
              ),
            ),
            AppSpacing.gapW8,
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextCaption
                    : AppColors.textCaption,
              ),
            ),
            const Spacer(),
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
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13,
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
          'Template "${template['title']}" applied! Tap "Quick Set" or edit details.',
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

  void _showSnoozeOptions(
    BuildContext context,
    PlannerItemEntity item,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topXxl),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
                AppSpacing.gapH16,
                Text(
                  'Snooze "${item.title}"',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                  ),
                ),
                AppSpacing.gapH12,
                ListTile(
                  leading: const Icon(
                    Icons.timer_10_rounded,
                    color: AppColors.moduleTime,
                  ),
                  title: const Text(
                    '15 Minutes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Alert at ${_formatTimeOfDay(TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 15))))}',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _snoozeReminder(
                      context,
                      item,
                      const Duration(minutes: 15),
                      '15m',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    '1 Hour',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Alert at ${_formatTimeOfDay(TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))))}',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _snoozeReminder(
                      context,
                      item,
                      const Duration(hours: 1),
                      '1 hour',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.wb_sunny_rounded,
                    color: AppColors.warning,
                  ),
                  title: const Text(
                    'Tomorrow Morning',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Alert at 9:00 AM'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final tomorrow = DateTime.now().add(
                      const Duration(days: 1),
                    );
                    final target = DateTime(
                      tomorrow.year,
                      tomorrow.month,
                      tomorrow.day,
                      9,
                      0,
                    );
                    final diff = target.difference(DateTime.now());
                    _snoozeReminder(
                      context,
                      item,
                      diff > Duration.zero ? diff : const Duration(hours: 12),
                      'Tomorrow 9:00 AM',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
      initialDate: DateTime.now(),
      initialTime: _selectedTime,
      initialCategory: _selectedCategory,
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

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 96),
      children: [
        Padding(
          padding: gutter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PomodoroModeSelector(
                selectedIndex: _focusModeIndex,
                workMinutes: _workMinutes,
                shortBreakMinutes: _shortBreakMinutes,
                longBreakMinutes: _longBreakMinutes,
                onModeSelected: _switchFocusMode,
                isDark: isDark,
              ),
              AppSpacing.gapH16,
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
              _buildFocusSectionHeader(
                'Focus Presets & Custom Time',
                isDark,
                action: _buildHeaderAction(
                  label: 'Custom',
                  color: AppColors.moduleTime,
                  onTap: () => _openCustomDurationSheet(context, isDark),
                ),
              ),
            ],
          ),
        ),
        _buildChipStrip(
          children: [
            for (final preset in const [
              ('15m Sprint', 15),
              ('25m Classic', 25),
              ('45m Deep Work', 45),
              ('60m Ultra Focus', 60),
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
                    _isTimerRunning = false;
                  });
                },
              ),
          ],
        ),
        Padding(
          padding: gutter,
          child: _buildFocusSectionHeader('Focus Ambience & Sounds', isDark),
        ),
        _buildChipStrip(
          children: _ambienceOptions.map((opt) {
            final name = opt['name'] as String;
            return _buildSelectableChip(
              label: name,
              icon: opt['icon'] as IconData,
              isSelected: _selectedAmbience == name,
              isDark: isDark,
              onTap: () {
                setState(() => _selectedAmbience = name);
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
          }).toList(),
        ),
        AppSpacing.gapH24,
        Padding(padding: gutter, child: _buildDailyFocusCard(isDark)),
      ],
    );
  }

  Widget _buildFocusSectionHeader(String title, bool isDark, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                ),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }

  /// Horizontal chip row that scrolls edge-to-edge but starts on the gutter.
  Widget _buildChipStrip({required List<Widget> children}) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
        itemCount: children.length,
        separatorBuilder: (_, _) => AppSpacing.gapW8,
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
    final fg = isSelected
        ? AppColors.moduleTime
        : (isDark ? AppColors.darkTextHeading : AppColors.textHeading);
    return Material(
      color: isSelected
          ? AppColors.moduleTime.withValues(alpha: 0.12)
          : (isDark ? AppColors.darkCardBackground : AppColors.cardBackground),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected
              ? AppColors.moduleTime.withValues(alpha: 0.6)
              : (isDark ? AppColors.darkDivider : AppColors.divider),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.moduleTime
                      : (isDark
                            ? AppColors.darkIconColor
                            : AppColors.iconColor),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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

  Widget _buildDailyFocusCard(bool isDark) {
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    Widget divider() => Container(width: 1, height: 32, color: dividerColor);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.focusPomodoro,
                size: 18,
              ),
              AppSpacing.gapW8,
              Expanded(
                child: Text(
                  'Daily Focus Activity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                  ),
                ),
              ),
              Text(
                'Goal: 4 sessions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
            ],
          ),
          AppSpacing.gapH16,
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  '$_completedSessionsToday',
                  'Sessions',
                  AppColors.moduleTime,
                  isDark,
                ),
              ),
              divider(),
              Expanded(
                child: _buildStatColumn(
                  '${_completedSessionsToday * _workMinutes}m',
                  'Focused',
                  AppColors.success,
                  isDark,
                ),
              ),
              divider(),
              Expanded(
                child: _buildStatColumn(
                  '4 days',
                  'Streak',
                  AppColors.focusPomodoro,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildStatColumn(
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
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

    const gutter = EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter);

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 96),
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
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_countdowns.length} upcoming events & milestones',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapW12,
              FilledButton.icon(
                onPressed: () => _openCountdownSheet(context, isDark),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moduleTime,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusSm,
                  ),
                  textStyle: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Event'),
              ),
            ],
          ),
        ),
        AppSpacing.gapH16,

        // Category filter strip (edge-to-edge)
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: gutter,
            itemCount: _countdownCategories.length,
            separatorBuilder: (_, _) => AppSpacing.gapW8,
            itemBuilder: (context, index) {
              final cat = _countdownCategories[index];
              final isSelected = _selectedCountdownCategory == cat;
              return FilterChip(
                label: Text(cat),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (_) =>
                    setState(() => _selectedCountdownCategory = cat),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                shape: const StadiumBorder(),
                backgroundColor: isDark
                    ? AppColors.darkCardBackground
                    : AppColors.cardBackground,
                selectedColor: AppColors.moduleTime.withValues(alpha: 0.12),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.moduleTime.withValues(alpha: 0.6)
                      : (isDark ? AppColors.darkDivider : AppColors.divider),
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.moduleTime
                      : (isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading),
                ),
              );
            },
          ),
        ),
        AppSpacing.gapH16,

        Padding(
          padding: gutter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.celebration_rounded,
                          size: 48,
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                        ),
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
          ),
        ),
      ],
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
