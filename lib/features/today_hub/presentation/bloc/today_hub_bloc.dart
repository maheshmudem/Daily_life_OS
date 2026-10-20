import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_habits_usecase.dart';
import '../../domain/usecases/get_today_timeline_usecase.dart';
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

  TodayHubBloc({
    required this.getHabitsUseCase,
    required this.toggleHabitUseCase,
    required this.getTodayTimelineUseCase,
    required this.toggleTimelineItemUseCase,
  }) : super(TodayHubInitial()) {
    on<LoadTodayHub>(_onLoad);
    on<ToggleHabit>(_onToggleHabit);
    on<ToggleTimelineItem>(_onToggleTimeline);
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

  Future<void> _onToggleHabit(ToggleHabit event, Emitter<TodayHubState> emit) async {
    try {
      await toggleHabitUseCase(event.id);
      final habits = await getHabitsUseCase();
      final current = state;
      if (current is TodayHubLoaded) {
        emit(TodayHubLoaded(habits: habits, timelineItems: current.timelineItems));
      }
    } catch (e) {
      emit(TodayHubError(e.toString()));
    }
  }

  Future<void> _onToggleTimeline(ToggleTimelineItem event, Emitter<TodayHubState> emit) async {
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
