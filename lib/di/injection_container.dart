import 'package:get_it/get_it.dart';
import '../core/database/app_database.dart';
import '../core/notifications/notification_service.dart';

// Today Hub
import '../features/today_hub/data/datasources/today_hub_local_datasource.dart';
import '../features/today_hub/data/repositories/today_hub_repository_impl.dart';
import '../features/today_hub/domain/repositories/today_hub_repository.dart';
import '../features/today_hub/domain/usecases/get_habits_usecase.dart';
import '../features/today_hub/domain/usecases/get_today_timeline_usecase.dart';
import '../features/today_hub/domain/usecases/toggle_habit_usecase.dart';
import '../features/today_hub/domain/usecases/toggle_timeline_item_usecase.dart';
import '../features/today_hub/presentation/bloc/today_hub_bloc.dart';

// Money
import '../features/money/data/datasources/money_local_datasource.dart';
import '../features/money/data/repositories/money_repository_impl.dart';
import '../features/money/domain/repositories/money_repository.dart';
import '../features/money/domain/usecases/get_transactions_and_budget_usecase.dart';
import '../features/money/domain/usecases/manage_transactions_usecase.dart';
import '../features/money/domain/usecases/manage_subscriptions_and_ious_usecase.dart';
import '../features/money/presentation/bloc/money_bloc.dart';

// Notes
import '../features/notes/data/datasources/notes_local_datasource.dart';
import '../features/notes/data/repositories/notes_repository_impl.dart';
import '../features/notes/domain/repositories/notes_repository.dart';
import '../features/notes/domain/usecases/get_notes_usecase.dart';
import '../features/notes/domain/usecases/manage_notes_usecases.dart';
import '../features/notes/presentation/bloc/notes_bloc.dart';

// Planner
import '../features/planner/data/datasources/planner_local_datasource.dart';
import '../features/planner/data/repositories/planner_repository_impl.dart';
import '../features/planner/domain/repositories/planner_repository.dart';
import '../features/planner/domain/usecases/get_planner_items_usecase.dart';
import '../features/planner/domain/usecases/manage_planner_items_usecase.dart';
import '../features/planner/presentation/bloc/planner_bloc.dart';

// Vault
import '../features/vault/data/datasources/vault_local_datasource.dart';
import '../features/vault/data/repositories/vault_repository_impl.dart';
import '../features/vault/domain/repositories/vault_repository.dart';
import '../features/vault/domain/usecases/get_vault_items_usecase.dart';
import '../features/vault/presentation/bloc/vault_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies({
  AppDatabase? database,
  NotificationService? notificationService,
}) async {
  if (sl.isRegistered<AppDatabase>()) {
    await sl.reset();
  }

  // ── Core Services ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<NotificationService>(
    () => notificationService ?? NotificationServiceImpl(),
  );

  // ── Database ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AppDatabase>(() => database ?? AppDatabase());

  // ── Data Sources ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<TodayHubLocalDataSource>(
    () => TodayHubLocalDataSourceImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<MoneyLocalDataSource>(
    () => MoneyLocalDataSourceImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<NotesLocalDataSource>(
    () => NotesLocalDataSourceImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<PlannerLocalDataSource>(
    () => PlannerLocalDataSourceImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<VaultLocalDataSource>(
    () => VaultLocalDataSourceImpl(),
  );

  // ── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<TodayHubRepository>(
    () => TodayHubRepositoryImpl(sl<TodayHubLocalDataSource>()),
  );
  sl.registerLazySingleton<MoneyRepository>(
    () => MoneyRepositoryImpl(sl<MoneyLocalDataSource>()),
  );
  sl.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(sl<NotesLocalDataSource>()),
  );
  sl.registerLazySingleton<PlannerRepository>(
    () => PlannerRepositoryImpl(sl<PlannerLocalDataSource>()),
  );
  sl.registerLazySingleton<VaultRepository>(
    () => VaultRepositoryImpl(sl<VaultLocalDataSource>()),
  );

  // ── Use Cases ────────────────────────────────────────────────────────────
  // Today Hub
  sl.registerLazySingleton(() => GetHabitsUseCase(sl<TodayHubRepository>()));
  sl.registerLazySingleton(() => ToggleHabitUseCase(sl<TodayHubRepository>()));
  sl.registerLazySingleton(() => GetTodayTimelineUseCase(sl<TodayHubRepository>()));
  sl.registerLazySingleton(() => ToggleTimelineItemUseCase(sl<TodayHubRepository>()));

  // Money
  sl.registerLazySingleton(() => GetRecentTransactionsUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => GetBudgetUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => GetSubscriptionsUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => GetIousUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => AddTransactionUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => ToggleAutoKillUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => SettleIouUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => AddIouUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => UpdateBudgetUseCase(sl<MoneyRepository>()));

  // Notes
  sl.registerLazySingleton(() => GetNotesUseCase(sl<NotesRepository>()));
  sl.registerLazySingleton(() => AddNoteUseCase(sl<NotesRepository>()));
  sl.registerLazySingleton(() => UpdateNoteUseCase(sl<NotesRepository>()));
  sl.registerLazySingleton(() => DeleteNoteUseCase(sl<NotesRepository>()));
  sl.registerLazySingleton(() => TogglePinNoteUseCase(sl<NotesRepository>()));

  // Planner
  sl.registerLazySingleton(() => GetPlannerItemsUseCase(sl<PlannerRepository>()));
  sl.registerLazySingleton(() => AddPlannerItemUseCase(sl<PlannerRepository>()));
  sl.registerLazySingleton(() => TogglePlannerItemUseCase(sl<PlannerRepository>()));
  sl.registerLazySingleton(() => DeletePlannerItemUseCase(sl<PlannerRepository>()));

  // Vault
  sl.registerLazySingleton(() => GetVaultPasswordsUseCase(sl<VaultRepository>()));
  sl.registerLazySingleton(() => GetVaultDocumentsUseCase(sl<VaultRepository>()));

  // ── BLoCs ─────────────────────────────────────────────────────────────────
  sl.registerFactory<TodayHubBloc>(
    () => TodayHubBloc(
      getHabitsUseCase: sl<GetHabitsUseCase>(),
      toggleHabitUseCase: sl<ToggleHabitUseCase>(),
      getTodayTimelineUseCase: sl<GetTodayTimelineUseCase>(),
      toggleTimelineItemUseCase: sl<ToggleTimelineItemUseCase>(),
    ),
  );

  sl.registerFactory<MoneyBloc>(
    () => MoneyBloc(
      getRecentTransactionsUseCase: sl<GetRecentTransactionsUseCase>(),
      getBudgetUseCase: sl<GetBudgetUseCase>(),
      getSubscriptionsUseCase: sl<GetSubscriptionsUseCase>(),
      getIousUseCase: sl<GetIousUseCase>(),
      addTransactionUseCase: sl<AddTransactionUseCase>(),
      toggleAutoKillUseCase: sl<ToggleAutoKillUseCase>(),
      settleIouUseCase: sl<SettleIouUseCase>(),
      addIouUseCase: sl<AddIouUseCase>(),
      updateBudgetUseCase: sl<UpdateBudgetUseCase>(),
    ),
  );

  sl.registerFactory<NotesBloc>(
    () => NotesBloc(
      getNotesUseCase: sl<GetNotesUseCase>(),
      addNoteUseCase: sl<AddNoteUseCase>(),
      updateNoteUseCase: sl<UpdateNoteUseCase>(),
      deleteNoteUseCase: sl<DeleteNoteUseCase>(),
      togglePinNoteUseCase: sl<TogglePinNoteUseCase>(),
    ),
  );

  sl.registerFactory<PlannerBloc>(
    () => PlannerBloc(
      getPlannerItemsUseCase: sl<GetPlannerItemsUseCase>(),
      togglePlannerItemUseCase: sl<TogglePlannerItemUseCase>(),
      deletePlannerItemUseCase: sl<DeletePlannerItemUseCase>(),
      addPlannerItemUseCase: sl<AddPlannerItemUseCase>(),
    ),
  );

  sl.registerFactory<VaultBloc>(
    () => VaultBloc(
      getVaultPasswordsUseCase: sl<GetVaultPasswordsUseCase>(),
      getVaultDocumentsUseCase: sl<GetVaultDocumentsUseCase>(),
    ),
  );
}
