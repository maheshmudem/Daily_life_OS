import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../../domain/usecases/get_planner_items_usecase.dart';
import '../../domain/usecases/manage_planner_items_usecase.dart';
import 'planner_event.dart';
import 'planner_state.dart';

export 'planner_event.dart';
export 'planner_state.dart';

class PlannerBloc extends Bloc<PlannerEvent, PlannerState> {
  final GetPlannerItemsUseCase getPlannerItemsUseCase;
  final TogglePlannerItemUseCase togglePlannerItemUseCase;
  final DeletePlannerItemUseCase deletePlannerItemUseCase;
  final AddPlannerItemUseCase addPlannerItemUseCase;
  final UpdatePlannerItemUseCase updatePlannerItemUseCase;
  final ClearCompletedPlannerItemsUseCase? clearCompletedPlannerItemsUseCase;

  String _currentDate = 'all';

  PlannerBloc({
    required this.getPlannerItemsUseCase,
    required this.togglePlannerItemUseCase,
    required this.deletePlannerItemUseCase,
    required this.addPlannerItemUseCase,
    required this.updatePlannerItemUseCase,
    this.clearCompletedPlannerItemsUseCase,
  }) : super(PlannerInitial()) {
    on<LoadPlanner>(_onLoad);
    on<TogglePlannerItem>(_onToggle);
    on<DeletePlannerItem>(_onDelete);
    on<ClearCompletedPlannerItems>(_onClearCompleted);
    on<AddPlannerItem>(_onAdd);
    on<UpdatePlannerItem>(_onUpdate);
  }

  Future<void> _onLoad(LoadPlanner event, Emitter<PlannerState> emit) async {
    _currentDate = event.date;
    if (state is! PlannerLoaded) {
      emit(PlannerLoading());
    }
    try {
      final items = await getPlannerItemsUseCase(event.date);
      emit(PlannerLoaded(items: items, date: event.date));
    } catch (e) {
      emit(PlannerError(e.toString()));
    }
  }

  Future<void> _reload(Emitter<PlannerState> emit) async {
    final items = await getPlannerItemsUseCase(_currentDate);
    emit(PlannerLoaded(items: items, date: _currentDate));
  }

  Future<void> _onToggle(
    TogglePlannerItem event,
    Emitter<PlannerState> emit,
  ) async {
    final current = state;
    if (current is PlannerLoaded) {
      final optimisticItems = current.items.map((item) {
        if (item.id != event.id) return item;
        return PlannerItemEntity(
          id: item.id,
          title: item.title,
          date: item.date,
          startTime: item.startTime,
          endTime: item.endTime,
          category: item.category,
          colorValue: item.colorValue,
          iconCodePoint: item.iconCodePoint,
          isDone: !item.isDone,
          notes: item.notes,
          repeatType: item.repeatType,
          repeatDays: item.repeatDays,
          endDate: item.endDate,
          priority: item.priority,
          reminderOffsetMinutes: item.reminderOffsetMinutes,
          checklist: item.checklist,
          completedDates: item.completedDates,
        );
      }).toList();
      emit(PlannerLoaded(items: optimisticItems, date: current.date));
    }
    await togglePlannerItemUseCase(
      event.id,
      targetDate: event.targetDate ?? _currentDate,
    );
    await _reload(emit);
  }

  Future<void> _onDelete(
    DeletePlannerItem event,
    Emitter<PlannerState> emit,
  ) async {
    await deletePlannerItemUseCase(event.id);
    await _reload(emit);
  }

  Future<void> _onClearCompleted(
    ClearCompletedPlannerItems event,
    Emitter<PlannerState> emit,
  ) async {
    if (clearCompletedPlannerItemsUseCase != null) {
      await clearCompletedPlannerItemsUseCase!();
    }
    await _reload(emit);
  }

  Future<void> _onAdd(AddPlannerItem event, Emitter<PlannerState> emit) async {
    await addPlannerItemUseCase(
      title: event.title,
      date: event.date,
      startTime: event.startTime,
      endTime: event.endTime,
      category: event.category,
      colorValue: event.colorValue,
      iconCodePoint: event.iconCodePoint,
      repeatType: event.repeatType,
      repeatDays: event.repeatDays,
      endDate: event.endDate,
      priority: event.priority,
      reminderOffsetMinutes: event.reminderOffsetMinutes,
      checklist: event.checklist,
      notes: event.notes,
    );
    await _reload(emit);
  }

  Future<void> _onUpdate(
    UpdatePlannerItem event,
    Emitter<PlannerState> emit,
  ) async {
    await updatePlannerItemUseCase(
      id: event.id,
      title: event.title,
      date: event.date,
      startTime: event.startTime,
      endTime: event.endTime,
      category: event.category,
      colorValue: event.colorValue,
      iconCodePoint: event.iconCodePoint,
      repeatType: event.repeatType,
      repeatDays: event.repeatDays,
      endDate: event.endDate,
      priority: event.priority,
      reminderOffsetMinutes: event.reminderOffsetMinutes,
      checklist: event.checklist,
      notes: event.notes,
    );
    await _reload(emit);
  }
}
