import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

/// Supported timer modes in the Pomodoro Focus engine.
/// 0 = Work Sprint, 1 = Short Break, 2 = Long Break, 3 = Flowtime Stopwatch.
enum PomodoroTimerMode {
  work(0),
  shortBreak(1),
  longBreak(2),
  stopwatch(3);

  final int indexValue;
  const PomodoroTimerMode(this.indexValue);

  static PomodoroTimerMode fromIndex(int index) {
    switch (index) {
      case 1:
        return PomodoroTimerMode.shortBreak;
      case 2:
        return PomodoroTimerMode.longBreak;
      case 3:
        return PomodoroTimerMode.stopwatch;
      case 0:
      default:
        return PomodoroTimerMode.work;
    }
  }
}

/// User-configurable Pomodoro & Flowtime settings persisted in SharedPreferences.
class PomodoroSettingsEntity extends Equatable {
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int totalRounds;
  final int dailyGoalSessions;
  final bool autoStartBreaks;
  final bool autoStartWork;
  final bool strictMode;
  final bool voiceCoach;
  final String selectedAmbience;
  final double ambienceVolume;
  final String focusCategory;
  final int estimatedPomodoros;
  final int completedTaskPomodoros;
  final String linkedTask;
  final int? linkedTaskId;

  const PomodoroSettingsEntity({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.totalRounds = 4,
    this.dailyGoalSessions = 4,
    this.autoStartBreaks = false,
    this.autoStartWork = false,
    this.strictMode = false,
    this.voiceCoach = false,
    this.selectedAmbience = 'Mute',
    this.ambienceVolume = 0.75,
    this.focusCategory = 'Deep Work',
    this.estimatedPomodoros = 4,
    this.completedTaskPomodoros = 2,
    this.linkedTask = 'Finalize Daily Life OS PRD',
    this.linkedTaskId,
  });

  PomodoroSettingsEntity copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? totalRounds,
    int? dailyGoalSessions,
    bool? autoStartBreaks,
    bool? autoStartWork,
    bool? strictMode,
    bool? voiceCoach,
    String? selectedAmbience,
    double? ambienceVolume,
    String? focusCategory,
    int? estimatedPomodoros,
    int? completedTaskPomodoros,
    String? linkedTask,
    int? linkedTaskId,
    bool clearLinkedTaskId = false,
  }) {
    return PomodoroSettingsEntity(
      workMinutes: workMinutes ?? this.workMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      totalRounds: totalRounds ?? this.totalRounds,
      dailyGoalSessions: dailyGoalSessions ?? this.dailyGoalSessions,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartWork: autoStartWork ?? this.autoStartWork,
      strictMode: strictMode ?? this.strictMode,
      voiceCoach: voiceCoach ?? this.voiceCoach,
      selectedAmbience: selectedAmbience ?? this.selectedAmbience,
      ambienceVolume: ambienceVolume ?? this.ambienceVolume,
      focusCategory: focusCategory ?? this.focusCategory,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedTaskPomodoros:
          completedTaskPomodoros ?? this.completedTaskPomodoros,
      linkedTask: linkedTask ?? this.linkedTask,
      linkedTaskId: clearLinkedTaskId
          ? null
          : (linkedTaskId ?? this.linkedTaskId),
    );
  }

  Map<String, dynamic> toJson() => {
    'workMinutes': workMinutes,
    'shortBreakMinutes': shortBreakMinutes,
    'longBreakMinutes': longBreakMinutes,
    'totalRounds': totalRounds,
    'dailyGoalSessions': dailyGoalSessions,
    'autoStartBreaks': autoStartBreaks,
    'autoStartWork': autoStartWork,
    'strictMode': strictMode,
    'voiceCoach': voiceCoach,
    'selectedAmbience': selectedAmbience,
    'ambienceVolume': ambienceVolume,
    'focusCategory': focusCategory,
    'estimatedPomodoros': estimatedPomodoros,
    'completedTaskPomodoros': completedTaskPomodoros,
    'linkedTask': linkedTask,
    'linkedTaskId': linkedTaskId,
  };

  factory PomodoroSettingsEntity.fromJson(Map<String, dynamic> json) {
    return PomodoroSettingsEntity(
      workMinutes: (json['workMinutes'] as num?)?.toInt() ?? 25,
      shortBreakMinutes: (json['shortBreakMinutes'] as num?)?.toInt() ?? 5,
      longBreakMinutes: (json['longBreakMinutes'] as num?)?.toInt() ?? 15,
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 4,
      dailyGoalSessions: (json['dailyGoalSessions'] as num?)?.toInt() ?? 4,
      autoStartBreaks: json['autoStartBreaks'] as bool? ?? false,
      autoStartWork: json['autoStartWork'] as bool? ?? false,
      strictMode: json['strictMode'] as bool? ?? false,
      voiceCoach: json['voiceCoach'] as bool? ?? false,
      selectedAmbience: json['selectedAmbience'] as String? ?? 'Mute',
      ambienceVolume: (json['ambienceVolume'] as num?)?.toDouble() ?? 0.75,
      focusCategory: json['focusCategory'] as String? ?? 'Deep Work',
      estimatedPomodoros: (json['estimatedPomodoros'] as num?)?.toInt() ?? 4,
      completedTaskPomodoros:
          (json['completedTaskPomodoros'] as num?)?.toInt() ?? 2,
      linkedTask: json['linkedTask'] as String? ?? 'Finalize Daily Life OS PRD',
      linkedTaskId: (json['linkedTaskId'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
    workMinutes,
    shortBreakMinutes,
    longBreakMinutes,
    totalRounds,
    dailyGoalSessions,
    autoStartBreaks,
    autoStartWork,
    strictMode,
    voiceCoach,
    selectedAmbience,
    ambienceVolume,
    focusCategory,
    estimatedPomodoros,
    completedTaskPomodoros,
    linkedTask,
    linkedTaskId,
  ];
}

/// Represents a completed Pomodoro or Flowtime focus session.
class FocusSessionEntity extends Equatable {
  final String id;
  final String taskTitle;
  final int? linkedTaskId;
  final String category;
  final int durationMinutes;
  final DateTime completedAt;
  final bool isStopwatch;
  final String notes;
  final int focusRating; // 1..5

  const FocusSessionEntity({
    required this.id,
    required this.taskTitle,
    this.linkedTaskId,
    this.category = 'Deep Work',
    required this.durationMinutes,
    required this.completedAt,
    this.isStopwatch = false,
    this.notes = '',
    this.focusRating = 5,
  });

  String get isoDate =>
      '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}';

  String get formattedTime {
    final h = completedAt.hour;
    final m = completedAt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '${hour12.toString().padLeft(2, '0')}:$m $period';
  }

  Color get categoryColor => FocusCategoryCatalog.colorFor(category);
  IconData get categoryIcon => FocusCategoryCatalog.iconFor(category);

  FocusSessionEntity copyWith({
    String? id,
    String? taskTitle,
    int? linkedTaskId,
    String? category,
    int? durationMinutes,
    DateTime? completedAt,
    bool? isStopwatch,
    String? notes,
    int? focusRating,
  }) {
    return FocusSessionEntity(
      id: id ?? this.id,
      taskTitle: taskTitle ?? this.taskTitle,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      completedAt: completedAt ?? this.completedAt,
      isStopwatch: isStopwatch ?? this.isStopwatch,
      notes: notes ?? this.notes,
      focusRating: focusRating ?? this.focusRating,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskTitle': taskTitle,
    'linkedTaskId': linkedTaskId,
    'category': category,
    'durationMinutes': durationMinutes,
    'completedAt': completedAt.toIso8601String(),
    'isStopwatch': isStopwatch,
    'notes': notes,
    'focusRating': focusRating,
  };

  factory FocusSessionEntity.fromJson(Map<String, dynamic> json) {
    return FocusSessionEntity(
      id: json['id'] as String? ?? UniqueKey().toString(),
      taskTitle: json['taskTitle'] as String? ?? 'Focus Session',
      linkedTaskId: (json['linkedTaskId'] as num?)?.toInt(),
      category: json['category'] as String? ?? 'Deep Work',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 25,
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      isStopwatch: json['isStopwatch'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      focusRating: (json['focusRating'] as num?)?.toInt() ?? 5,
    );
  }

  /// Provides realistic default sessions across the last 7 days so the
  /// analytics dashboard, 4-day streak, and 3 sessions today are rich on first boot.
  static List<FocusSessionEntity> defaultSeedSessions([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      // Today (3 sessions = 75m)
      FocusSessionEntity(
        id: 'seed_today_1',
        taskTitle: 'Finalize Daily Life OS PRD',
        category: 'Deep Work',
        durationMinutes: 25,
        completedAt: today.add(const Duration(hours: 9, minutes: 30)),
        notes: 'Completed core architecture section and module specs.',
        focusRating: 5,
      ),
      FocusSessionEntity(
        id: 'seed_today_2',
        taskTitle: 'API Client & Drift Schema Review',
        category: 'Coding',
        durationMinutes: 25,
        completedAt: today.add(const Duration(hours: 10, minutes: 15)),
        notes: 'Zero warnings in migration tests.',
        focusRating: 5,
      ),
      FocusSessionEntity(
        id: 'seed_today_3',
        taskTitle: 'UI Design Tokens & Typography Audit',
        category: 'Design',
        durationMinutes: 25,
        completedAt: today.add(const Duration(hours: 11, minutes: 20)),
        notes: 'Aligned 20px page gutter across tabs.',
        focusRating: 4,
      ),
      // Yesterday (3 sessions = 85m)
      FocusSessionEntity(
        id: 'seed_d1_1',
        taskTitle: 'Clean Architecture BLoC Refactoring',
        category: 'Coding',
        durationMinutes: 45,
        completedAt: today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 10)),
        focusRating: 5,
      ),
      FocusSessionEntity(
        id: 'seed_d1_2',
        taskTitle: 'Sprint Planning & Backlog Grooming',
        category: 'Planning',
        durationMinutes: 25,
        completedAt: today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 14)),
        focusRating: 4,
      ),
      FocusSessionEntity(
        id: 'seed_d1_3',
        taskTitle: 'Read System Design Chapter 4',
        category: 'Study',
        durationMinutes: 15,
        completedAt: today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 19)),
        isStopwatch: true,
        focusRating: 5,
      ),
      // 2 days ago (2 sessions = 50m)
      FocusSessionEntity(
        id: 'seed_d2_1',
        taskTitle: 'Security Vault SHA-256 & Biometrics',
        category: 'Coding',
        durationMinutes: 25,
        completedAt: today
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 11)),
        focusRating: 5,
      ),
      FocusSessionEntity(
        id: 'seed_d2_2',
        taskTitle: 'Security Architecture Documentation',
        category: 'Writing',
        durationMinutes: 25,
        completedAt: today
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 15)),
        focusRating: 4,
      ),
      // 3 days ago (4 sessions = 100m) -> 4-day streak!
      FocusSessionEntity(
        id: 'seed_d3_1',
        taskTitle: 'Money Manager Safe-Spend Algorithm',
        category: 'Coding',
        durationMinutes: 50,
        completedAt: today
            .subtract(const Duration(days: 3))
            .add(const Duration(hours: 10)),
        focusRating: 5,
      ),
      FocusSessionEntity(
        id: 'seed_d3_2',
        taskTitle: 'UX Wireframes for Habit Heatmap',
        category: 'Design',
        durationMinutes: 25,
        completedAt: today
            .subtract(const Duration(days: 3))
            .add(const Duration(hours: 14)),
        focusRating: 5,
      ),
      FocusSessionEntity(
        id: 'seed_d3_3',
        taskTitle: 'Evening Technical Reading',
        category: 'Reading',
        durationMinutes: 25,
        completedAt: today
            .subtract(const Duration(days: 3))
            .add(const Duration(hours: 20)),
        focusRating: 4,
      ),
      // 5 days ago (2 sessions = 50m)
      FocusSessionEntity(
        id: 'seed_d5_1',
        taskTitle: 'Database Migration v4 Testing',
        category: 'Coding',
        durationMinutes: 25,
        completedAt: today
            .subtract(const Duration(days: 5))
            .add(const Duration(hours: 11)),
        focusRating: 5,
      ),
      FocusSessionEntity(
        id: 'seed_d5_2',
        taskTitle: 'Weekly Roadmap Review',
        category: 'Planning',
        durationMinutes: 25,
        completedAt: today
            .subtract(const Duration(days: 5))
            .add(const Duration(hours: 16)),
        focusRating: 4,
      ),
    ];
  }

  @override
  List<Object?> get props => [
    id,
    taskTitle,
    linkedTaskId,
    category,
    durationMinutes,
    completedAt,
    isStopwatch,
    notes,
    focusRating,
  ];
}

/// Quick thought / distraction captured mid-session so the user stays in flow.
class FocusDistractionItem extends Equatable {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool addedToPlanner;

  const FocusDistractionItem({
    required this.id,
    required this.text,
    required this.createdAt,
    this.addedToPlanner = false,
  });

  FocusDistractionItem copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    bool? addedToPlanner,
  }) {
    return FocusDistractionItem(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      addedToPlanner: addedToPlanner ?? this.addedToPlanner,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'addedToPlanner': addedToPlanner,
  };

  factory FocusDistractionItem.fromJson(Map<String, dynamic> json) {
    return FocusDistractionItem(
      id: json['id'] as String? ?? UniqueKey().toString(),
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      addedToPlanner: json['addedToPlanner'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, text, createdAt, addedToPlanner];
}

/// Focus categories with semantic colors and icons.
class FocusCategoryCatalog {
  FocusCategoryCatalog._();

  static const List<String> categories = [
    'Deep Work',
    'Coding',
    'Study',
    'Writing',
    'Design',
    'Reading',
    'Planning',
    'Personal',
  ];

  static Color colorFor(String category) {
    switch (category) {
      case 'Coding':
        return AppColors.primary;
      case 'Study':
        return AppColors.moduleVault;
      case 'Writing':
        return AppColors.moduleNotes;
      case 'Design':
        return const Color(0xFFEC4899);
      case 'Reading':
        return AppColors.success;
      case 'Planning':
        return const Color(0xFF14B8A6);
      case 'Personal':
        return AppColors.warning;
      case 'Deep Work':
      default:
        return AppColors.focusPomodoro;
    }
  }

  static IconData iconFor(String category) {
    switch (category) {
      case 'Coding':
        return Icons.code_rounded;
      case 'Study':
        return Icons.school_rounded;
      case 'Writing':
        return Icons.edit_note_rounded;
      case 'Design':
        return Icons.palette_rounded;
      case 'Reading':
        return Icons.menu_book_rounded;
      case 'Planning':
        return Icons.architecture_rounded;
      case 'Personal':
        return Icons.person_rounded;
      case 'Deep Work':
      default:
        return Icons.bolt_rounded;
    }
  }
}
