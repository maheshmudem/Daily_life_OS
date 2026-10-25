import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/features/planner/data/datasources/planner_local_datasource.dart';
import 'package:daily_life_os/features/planner/data/repositories/planner_repository_impl.dart';
import 'package:daily_life_os/features/planner/domain/usecases/get_planner_items_usecase.dart';
import 'package:daily_life_os/features/planner/domain/usecases/manage_planner_items_usecase.dart';
import 'package:daily_life_os/features/planner/presentation/bloc/planner_bloc.dart';

void main() {
  late AppDatabase db;
  late PlannerLocalDataSource dataSource;
  late PlannerRepositoryImpl repository;
  late GetPlannerItemsUseCase getUseCase;
  late TogglePlannerItemUseCase toggleUseCase;
  late DeletePlannerItemUseCase deleteUseCase;
  late AddPlannerItemUseCase addUseCase;
  late UpdatePlannerItemUseCase updateUseCase;
  late ClearCompletedPlannerItemsUseCase clearCompletedUseCase;
  late PlannerBloc bloc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = PlannerLocalDataSourceImpl(db);
    repository = PlannerRepositoryImpl(dataSource);
    getUseCase = GetPlannerItemsUseCase(repository);
    toggleUseCase = TogglePlannerItemUseCase(repository);
    deleteUseCase = DeletePlannerItemUseCase(repository);
    addUseCase = AddPlannerItemUseCase(repository);
    updateUseCase = UpdatePlannerItemUseCase(repository);
    clearCompletedUseCase = ClearCompletedPlannerItemsUseCase(repository);

    bloc = PlannerBloc(
      getPlannerItemsUseCase: getUseCase,
      togglePlannerItemUseCase: toggleUseCase,
      deletePlannerItemUseCase: deleteUseCase,
      addPlannerItemUseCase: addUseCase,
      updatePlannerItemUseCase: updateUseCase,
      clearCompletedPlannerItemsUseCase: clearCompletedUseCase,
    );
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  test('PlannerBloc can load, add, update, toggle, and delete items', () async {
    const testDate = '2026-10-24';

    // 1. Initial state
    expect(bloc.state, isA<PlannerInitial>());

    // 2. Load
    bloc.add(const LoadPlanner(testDate));
    await pumpEventQueue();
    expect(bloc.state, isA<PlannerLoaded>());
    expect((bloc.state as PlannerLoaded).items, isEmpty);

    // 3. Add item
    bloc.add(const AddPlannerItem(
      title: 'Original Reminder',
      date: testDate,
      startTime: '09:00 AM',
      category: 'Work',
      colorValue: 0xFF3B82F6,
      iconCodePoint: 100,
    ));
    await pumpEventQueue();

    expect(bloc.state, isA<PlannerLoaded>());
    final loadedState = bloc.state as PlannerLoaded;
    expect(loadedState.items.length, 1);
    final createdId = loadedState.items.first.id;
    expect(loadedState.items.first.title, 'Original Reminder');

    // 4. Update item
    bloc.add(UpdatePlannerItem(
      id: createdId,
      title: 'Edited Reminder Title',
      date: testDate,
      startTime: '11:30 AM',
      category: 'Important',
      colorValue: 0xFFEF4444,
      iconCodePoint: 200,
    ));
    await pumpEventQueue();

    expect(bloc.state, isA<PlannerLoaded>());
    final updatedState = bloc.state as PlannerLoaded;
    final item = updatedState.items.first;
    expect(item.title, 'Edited Reminder Title');
    expect(item.startTime, '11:30 AM');
    expect(item.category, 'Important');

    // 5. Toggle item
    bloc.add(TogglePlannerItem(createdId));
    await pumpEventQueue();

    expect(bloc.state, isA<PlannerLoaded>());
    expect((bloc.state as PlannerLoaded).items.first.isDone, isTrue);

    // 6. Delete item
    bloc.add(DeletePlannerItem(createdId));
    await pumpEventQueue();

    expect(bloc.state, isA<PlannerLoaded>());
    expect((bloc.state as PlannerLoaded).items, isEmpty);
  });

  test('PlannerBloc ClearCompletedPlannerItems removes completed one-off items',
      () async {
    const testDate = 'all';

    bloc.add(const LoadPlanner(testDate));
    await pumpEventQueue();

    // Add first item (to be completed)
    bloc.add(const AddPlannerItem(
      title: 'Task to finish',
      date: '2026-10-25',
      category: 'Work',
      colorValue: 0xFF3B82F6,
      iconCodePoint: 100,
    ));
    await pumpEventQueue();

    // Add second item (remains pending)
    bloc.add(const AddPlannerItem(
      title: 'Task to keep',
      date: '2026-10-25',
      category: 'Work',
      colorValue: 0xFF10B981,
      iconCodePoint: 101,
    ));
    await pumpEventQueue();

    final state = bloc.state as PlannerLoaded;
    final itemToDone = state.items.firstWhere((i) => i.title == 'Task to finish');

    // Toggle to done
    bloc.add(TogglePlannerItem(itemToDone.id));
    await pumpEventQueue();

    // Clear completed items
    bloc.add(const ClearCompletedPlannerItems());
    await pumpEventQueue();

    final finalState = bloc.state as PlannerLoaded;
    expect(finalState.items.any((i) => i.title == 'Task to finish'), isFalse);
    expect(finalState.items.any((i) => i.title == 'Task to keep'), isTrue);
  });
}

