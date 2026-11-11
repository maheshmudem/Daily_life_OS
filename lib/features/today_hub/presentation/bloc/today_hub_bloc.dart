import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/add_habit_usecase.dart';
import '../../domain/usecases/delete_habit_usecase.dart';
import '../../domain/usecases/get_habits_usecase.dart';
import '../../domain/usecases/get_today_timeline_usecase.dart';
import '../../domain/usecases/toggle_habit_usecase.dart';
import '../../domain/usecases/toggle_timeline_item_usecase.dart';
import '../../domain/usecases/update_habit_usecase.dart';
import 'today_hub_event.dart';
import 'today_hub_state.dart';

export 'today_hub_event.dart';
export 'today_hub_state.dart';

class TodayHubBloc extends Bloc<TodayHubEvent, TodayHubState> {
  final GetHabitsUseCase getHabitsUseCase;
  final ToggleHabitUseCase toggleHabitUseCase;
  final GetTodayTimelineUseCase getTodayTimelineUseCase;
  final ToggleTimelineItemUseCase toggleTimelineItemUseCase;
  final AddHabitUseCase addHabitUseCase;
  final UpdateHabitUseCase updateHabitUseCase;
  final DeleteHabitUseCase deleteHabitUseCase;

  TodayHubBloc({
    required this.getHabitsUseCase,
    required this.toggleHabitUseCase,
    required this.getTodayTimelineUseCase,
    required this.toggleTimelineItemUseCase,
    required this.addHabitUseCase,
    required this.updateHabitUseCase,
    required this.deleteHabitUseCase,
  }) : super(TodayHubInitial()) {
    on<LoadTodayHub>(_onLoad);
    on<ToggleHabit>(_onToggleHabit);
    on<ToggleTimelineItem>(_onToggleTimeline);
    on<AddHabit>(_onAddHabit);
    on<UpdateHabit>(_onUpdateHabit);
    on<DeleteHabit>(_onDeleteHabit);
  }

  Future<void> _onLoad(LoadTodayHub event, Emitter<TodayHubState> emit) async {
    emit(TodayHubLoading());
    try {
      final habits = await getHabitsUseCase();
      final timeline = await getTodayTimelineUseCase();
      emit(TodayHubLoaded(habits: habits, timelineItems: timeline));
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
      final habits = await getHabitsUseCase();
      final current = state;
      if (current is TodayHubLoaded) {
        emit(
          TodayHubLoaded(habits: habits, timelineItems: current.timelineItems),
        );
      }
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onAddHabit(
    AddHabit event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await addHabitUseCase(event.habit);
      final habits = await getHabitsUseCase();
      final current = state;
      if (current is TodayHubLoaded) {
        emit(
          TodayHubLoaded(habits: habits, timelineItems: current.timelineItems),
        );
      } else {
        final timeline = await getTodayTimelineUseCase();
        emit(TodayHubLoaded(habits: habits, timelineItems: timeline));
      }
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onUpdateHabit(
    UpdateHabit event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await updateHabitUseCase(event.habit);
      final habits = await getHabitsUseCase();
      final current = state;
      if (current is TodayHubLoaded) {
        emit(
          TodayHubLoaded(habits: habits, timelineItems: current.timelineItems),
        );
      }
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onDeleteHabit(
    DeleteHabit event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await deleteHabitUseCase(event.id);
      final habits = await getHabitsUseCase();
      final current = state;
      if (current is TodayHubLoaded) {
        emit(
          TodayHubLoaded(habits: habits, timelineItems: current.timelineItems),
        );
      }
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onToggleTimeline(
    ToggleTimelineItem event,
    Emitter<TodayHubState> emit,
  ) async {
    try {
      await toggleTimelineItemUseCase(event.id);
      final timeline = await getTodayTimelineUseCase();
      final current = state;
      if (current is TodayHubLoaded) {
        emit(TodayHubLoaded(habits: current.habits, timelineItems: timeline));
      }
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }
}
