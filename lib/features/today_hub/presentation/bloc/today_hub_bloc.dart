import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/usecases/get_habits_usecase.dart';
import '../../domain/usecases/get_today_timeline_usecase.dart';
import '../../domain/usecases/manage_habits_usecase.dart';
import '../../domain/usecases/toggle_habit_usecase.dart';
import '../../domain/usecases/toggle_timeline_item_usecase.dart';
import 'today_hub_event.dart';
import 'today_hub_state.dart';

export 'today_hub_event.dart';
export 'today_hub_state.dart';

class TodayHubBloc extends Bloc<TodayHubEvent, TodayHubState> {
  final GetHabitsUseCase getHabitsUseCase;
  final ToggleHabitUseCase toggleHabitUseCase;
  final GetTodayTimelineUseCase getTodayTimelineUseCase;
  final ToggleTimelineItemUseCase toggleTimelineItemUseCase;

  final AddHabitUseCase? addHabitUseCase;
  final UpdateHabitUseCase? updateHabitUseCase;
  final DeleteHabitUseCase? deleteHabitUseCase;
  final SkipHabitUseCase? skipHabitUseCase;
  final ToggleHabitDateUseCase? toggleHabitDateUseCase;
  final AddTimelineItemUseCase? addTimelineItemUseCase;
  final UpdateTimelineItemUseCase? updateTimelineItemUseCase;
  final DeleteTimelineItemUseCase? deleteTimelineItemUseCase;
  final NotificationService? notificationService;

  TodayHubBloc({
    required this.getHabitsUseCase,
    required this.toggleHabitUseCase,
    required this.getTodayTimelineUseCase,
    required this.toggleTimelineItemUseCase,
    this.addHabitUseCase,
    this.updateHabitUseCase,
    this.deleteHabitUseCase,
    this.skipHabitUseCase,
    this.toggleHabitDateUseCase,
    this.addTimelineItemUseCase,
    this.updateTimelineItemUseCase,
    this.deleteTimelineItemUseCase,
    this.notificationService,
  }) : super(TodayHubInitial()) {
    on<LoadTodayHub>(_onLoad);
    on<ToggleHabit>(_onToggleHabit);
    on<SkipHabit>(_onSkipHabit);
    on<ToggleHabitDate>(_onToggleHabitDate);
    on<AddHabit>(_onAddHabit);
    on<UpdateHabit>(_onUpdateHabit);
    on<DeleteHabit>(_onDeleteHabit);
    on<SelectHabitCategory>(_onSelectHabitCategory);
    on<ToggleTimelineItem>(_onToggleTimeline);
    on<AddTimelineItem>(_onAddTimeline);
    on<UpdateTimelineItem>(_onUpdateTimeline);
    on<DeleteTimelineItem>(_onDeleteTimeline);
  }

  static int habitNotificationId(int habitId) =>
      (habitId + 500000) & 0x7FFFFFFF;

  Future<void> _syncHabitNotification(HabitEntity habit) async {
    final notifier = notificationService;
    if (notifier == null) return;
    final notifId = habitNotificationId(habit.id);
    try {
      await notifier.cancelNotification(notifId);
      if (!habit.reminderEnabled ||
          habit.reminderTime == null ||
          habit.reminderTime!.trim().isEmpty) {
        return;
      }
      final scheduledTime = _parseNextReminderDateTime(habit.reminderTime!);
      if (scheduledTime == null) return;

      await notifier.scheduleNotification(
        id: notifId,
        title: 'Habit Reminder: ${habit.title}',
        body: habit.description.trim().isNotEmpty
            ? habit.description.trim()
            : 'Keep your ${habit.streakDays}-day ${habit.category.toLowerCase()} streak alive!',
        scheduledDate: scheduledTime,
        channelId: NotificationChannels.reminders,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Gracefully ignore notification errors in unsupported/test environments
    }
  }

  DateTime? _parseNextReminderDateTime(String rawTime) {
    try {
      final cleaned = rawTime.trim().toUpperCase();
      final isPm = cleaned.contains('PM');
      final isAm = cleaned.contains('AM');
      final timePart = cleaned.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = timePart.split(':');
      if (parts.length < 2) return null;

      int hour = int.parse(parts[0].trim());
      final int minute = int.parse(parts[1].trim());
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      final now = DateTime.now();
      var candidate = DateTime(now.year, now.month, now.day, hour, minute);
      if (candidate.isBefore(now.add(const Duration(seconds: 15)))) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    } catch (_) {
      return null;
    }
  }

  String get _currentCategoryFilter {
    final s = state;
    return s is TodayHubLoaded ? s.selectedHabitCategory : 'All';
  }

  Future<void> _emitFreshLoaded(
    Emitter<TodayHubState> emit, {
    String? categoryOverride,
  }) async {
    final currentCat = categoryOverride ?? _currentCategoryFilter;
    final habits = await getHabitsUseCase();
    final timeline = await getTodayTimelineUseCase();
    final validCat =
        currentCat == 'All' ||
            habits.any(
              (h) => h.category.toLowerCase() == currentCat.toLowerCase(),
            )
        ? currentCat
        : 'All';
    emit(
      TodayHubLoaded(
        habits: habits,
        timelineItems: timeline,
        selectedHabitCategory: validCat,
      ),
    );
  }

  Future<void> _onLoad(LoadTodayHub event, Emitter<TodayHubState> emit) async {
    final prevCategory = _currentCategoryFilter;
    if (state is! TodayHubLoaded) {
      emit(TodayHubLoading());
    }
    try {
      await _emitFreshLoaded(emit, categoryOverride: prevCategory);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onToggleHabit(
    ToggleHabit event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await toggleHabitUseCase(event.id);
      await _emitFreshLoaded(emit);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onSkipHabit(
    SkipHabit event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await skipHabitUseCase?.call(event.id);
      await _emitFreshLoaded(emit);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onToggleHabitDate(
    ToggleHabitDate event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await toggleHabitDateUseCase?.call(event.id, event.isoDate);
      await _emitFreshLoaded(emit);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onAddHabit(AddHabit event, Emitter<TodayHubState> emit) async {
    try {
      final created = await addHabitUseCase?.call(event.habit);
      if (created != null) {
        await _syncHabitNotification(created);
      }
      await _emitFreshLoaded(emit);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onUpdateHabit(
    UpdateHabit event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await updateHabitUseCase?.call(event.habit);
      await _syncHabitNotification(event.habit);
      await _emitFreshLoaded(emit);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onDeleteHabit(
    DeleteHabit event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await deleteHabitUseCase?.call(event.id);
      try {
        await notificationService?.cancelNotification(
          habitNotificationId(event.id),
        );
      } catch (_) {}
      await _emitFreshLoaded(emit);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  void _onSelectHabitCategory(
    SelectHabitCategory event,
    Emitter<TodayHubState> emit,
  ) {
    final current = state;
    if (current is TodayHubLoaded) {
      emit(current.copyWith(selectedHabitCategory: event.category));
    }
  }

  Future<void> _onToggleTimeline(
    ToggleTimelineItem event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await toggleTimelineItemUseCase(event.id);
      await _emitFreshLoaded(emit);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onAddTimeline(
    AddTimelineItem event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await addTimelineItemUseCase?.call(event.item);
      await _emitFreshLoaded(emit);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onUpdateTimeline(
    UpdateTimelineItem event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await updateTimelineItemUseCase?.call(event.item);
      await _emitFreshLoaded(emit);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onDeleteTimeline(
    DeleteTimelineItem event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await deleteTimelineItemUseCase?.call(event.id);
      await _emitFreshLoaded(emit);
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }
}
