import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';

import '../core/database/app_database.dart';
import '../core/notifications/notification_service.dart';
// Command Palette
import '../features/command_palette/data/datasources/command_palette_local_datasource.dart';
import '../features/command_palette/data/repositories/command_palette_repository_impl.dart';
import '../features/command_palette/domain/repositories/command_palette_repository.dart';
import '../features/command_palette/domain/usecases/get_command_palette_entries_usecase.dart';
import '../features/command_palette/presentation/bloc/command_palette_bloc.dart';
// Money
import '../features/money/data/datasources/money_local_datasource.dart';
import '../features/money/data/repositories/money_repository_impl.dart';
import '../features/money/domain/repositories/money_repository.dart';
import '../features/money/domain/usecases/get_transactions_and_budget_usecase.dart';
import '../features/money/domain/usecases/manage_budgets_and_accounts_usecase.dart';
import '../features/money/domain/usecases/manage_subscriptions_and_ious_usecase.dart';
import '../features/money/domain/usecases/manage_transactions_usecase.dart';
import '../features/money/presentation/bloc/money_bloc.dart';
// Navigation
import '../features/navigation/presentation/bloc/navigation_bloc.dart';
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
// Quick Capture
import '../features/quick_capture/data/datasources/quick_capture_local_datasource.dart';
import '../features/quick_capture/data/repositories/quick_capture_repository_impl.dart';
import '../features/quick_capture/domain/repositories/quick_capture_repository.dart';
import '../features/quick_capture/domain/services/quick_capture_intent_parser.dart';
import '../features/quick_capture/domain/usecases/quick_capture_usecases.dart';
import '../features/quick_capture/presentation/bloc/quick_capture_bloc.dart';
// Security
import '../features/security/data/datasources/security_local_datasource.dart';
import '../features/security/data/repositories/security_repository_impl.dart';
import '../features/security/domain/repositories/security_repository.dart';
// Profile
import '../features/profile/data/datasources/profile_local_datasource.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/usecases/profile_usecases.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
// Today Hub
import '../features/today_hub/data/datasources/today_hub_local_datasource.dart';
import '../features/today_hub/data/repositories/today_hub_repository_impl.dart';
import '../features/today_hub/domain/repositories/today_hub_repository.dart';
import '../features/today_hub/domain/usecases/get_habits_usecase.dart';
import '../features/today_hub/domain/usecases/get_today_timeline_usecase.dart';
import '../features/today_hub/domain/usecases/manage_habits_usecase.dart';
import '../features/today_hub/domain/usecases/toggle_habit_usecase.dart';
import '../features/today_hub/domain/usecases/toggle_timeline_item_usecase.dart';
import '../features/today_hub/presentation/bloc/today_hub_bloc.dart';
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
  FlutterSecureStorage? secureStorage,
  LocalAuthentication? localAuth,
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
  sl.registerLazySingleton<SecurityLocalDataSource>(
    () => SecurityLocalDataSourceImpl(
      storage: secureStorage,
      localAuth: localAuth,
    ),
  );
  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(),
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
  sl.registerLazySingleton<SecurityRepository>(
    () => SecurityRepositoryImpl(sl<SecurityLocalDataSource>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileLocalDataSource>()),
  );

  // ── Use Cases ────────────────────────────────────────────────────────────
  // Profile
  sl.registerLazySingleton(
    () => GetUserProfileUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton(
    () => SaveUserProfileUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton(
    () => PickProfileAvatarUseCase(sl<ProfileRepository>()),
  );
  // Today Hub
  sl.registerLazySingleton(() => GetHabitsUseCase(sl<TodayHubRepository>()));
  sl.registerLazySingleton(() => ToggleHabitUseCase(sl<TodayHubRepository>()));
  sl.registerLazySingleton(() => AddHabitUseCase(sl<TodayHubRepository>()));
  sl.registerLazySingleton(() => UpdateHabitUseCase(sl<TodayHubRepository>()));
  sl.registerLazySingleton(() => DeleteHabitUseCase(sl<TodayHubRepository>()));
  sl.registerLazySingleton(() => SkipHabitUseCase(sl<TodayHubRepository>()));
  sl.registerLazySingleton(
    () => ToggleHabitDateUseCase(sl<TodayHubRepository>()),
  );
  sl.registerLazySingleton(
    () => GetTodayTimelineUseCase(sl<TodayHubRepository>()),
  );
  sl.registerLazySingleton(
    () => ToggleTimelineItemUseCase(sl<TodayHubRepository>()),
  );
  sl.registerLazySingleton(
    () => AddTimelineItemUseCase(sl<TodayHubRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateTimelineItemUseCase(sl<TodayHubRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteTimelineItemUseCase(sl<TodayHubRepository>()),
  );

  // Money
  sl.registerLazySingleton(
    () => GetRecentTransactionsUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(() => GetBudgetUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(
    () => GetSubscriptionsUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(() => GetIousUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => AddTransactionUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => ToggleAutoKillUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => SettleIouUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => AddIouUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => UpdateBudgetUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(
    () => GetAllTransactionsUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(
    () => GetTransactionsInRangeUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(
    () => GetDailySpendSnapshotUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateTransactionUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteTransactionUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(
    () => GetCategoryLimitsUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(
    () => SetCategoryLimitUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(() => GetAccountsUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => AddAccountUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => UpdateAccountUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(() => AddSubscriptionUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(
    () => UpdateSubscriptionUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteSubscriptionUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(() => DeleteIouUseCase(sl<MoneyRepository>()));
  sl.registerLazySingleton(
    () => GetMoneySettingsUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateMoneySettingsUseCase(sl<MoneyRepository>()),
  );
  sl.registerLazySingleton(
    () => NotifyBudgetThresholdUseCase(sl<NotificationService>()),
  );

  // Notes
  sl.registerLazySingleton(() => GetNotesUseCase(sl<NotesRepository>()));
  sl.registerLazySingleton(() => AddNoteUseCase(sl<NotesRepository>()));
  sl.registerLazySingleton(() => UpdateNoteUseCase(sl<NotesRepository>()));
  sl.registerLazySingleton(() => DeleteNoteUseCase(sl<NotesRepository>()));
  sl.registerLazySingleton(() => TogglePinNoteUseCase(sl<NotesRepository>()));

  // Planner
  sl.registerLazySingleton(
    () => GetPlannerItemsUseCase(sl<PlannerRepository>()),
  );
  sl.registerLazySingleton(
    () => AddPlannerItemUseCase(sl<PlannerRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdatePlannerItemUseCase(sl<PlannerRepository>()),
  );
  sl.registerLazySingleton(
    () => TogglePlannerItemUseCase(sl<PlannerRepository>()),
  );
  sl.registerLazySingleton(
    () => DeletePlannerItemUseCase(sl<PlannerRepository>()),
  );
  sl.registerLazySingleton(
    () => ClearCompletedPlannerItemsUseCase(sl<PlannerRepository>()),
  );

  // Vault
  sl.registerLazySingleton(
    () => GetVaultPasswordsUseCase(sl<VaultRepository>()),
  );
  sl.registerLazySingleton(
    () => GetVaultDocumentsUseCase(sl<VaultRepository>()),
  );

  // Security (lock-flow use cases are composed by `SecurityBloc.fromRepository`
  // inside `VaultLockScreen`, which receives its repository from the caller.)

  // Command Palette & Cross-Module Spotlight Search
  sl.registerLazySingleton<CommandPaletteLocalDataSource>(
    () => CommandPaletteLocalDataSourceImpl(
      getHabitsUseCase: sl<GetHabitsUseCase>(),
      getTodayTimelineUseCase: sl<GetTodayTimelineUseCase>(),
      getPlannerItemsUseCase: sl<GetPlannerItemsUseCase>(),
      getAllTransactionsUseCase: sl<GetAllTransactionsUseCase>(),
      getSubscriptionsUseCase: sl<GetSubscriptionsUseCase>(),
      getIousUseCase: sl<GetIousUseCase>(),
      getNotesUseCase: sl<GetNotesUseCase>(),
      getVaultPasswordsUseCase: sl<GetVaultPasswordsUseCase>(),
      getVaultDocumentsUseCase: sl<GetVaultDocumentsUseCase>(),
    ),
  );
  sl.registerLazySingleton<CommandPaletteRepository>(
    () => CommandPaletteRepositoryImpl(sl<CommandPaletteLocalDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetCommandPaletteEntriesUseCase(sl<CommandPaletteRepository>()),
  );

  // Quick Capture
  sl.registerLazySingleton(() => const QuickCaptureIntentParser());
  sl.registerLazySingleton<QuickCaptureLocalDataSource>(
    () => QuickCaptureLocalDataSourceImpl(
      database: sl<AppDatabase>(),
      addHabitUseCase: sl<AddHabitUseCase>(),
      notificationService: sl<NotificationService>(),
    ),
  );
  sl.registerLazySingleton<QuickCaptureRepository>(
    () => QuickCaptureRepositoryImpl(sl<QuickCaptureLocalDataSource>()),
  );
  sl.registerLazySingleton(
    () => ParseQuickCaptureIntentUseCase(sl<QuickCaptureIntentParser>()),
  );
  sl.registerLazySingleton(
    () => SubmitQuickCaptureUseCase(sl<QuickCaptureRepository>()),
  );

  // ── BLoCs ─────────────────────────────────────────────────────────────────
  sl.registerFactory<NavigationBloc>(() => NavigationBloc());

  sl.registerFactory<CommandPaletteBloc>(
    () => CommandPaletteBloc(
      getCommandPaletteEntriesUseCase: sl<GetCommandPaletteEntriesUseCase>(),
    ),
  );

  sl.registerFactory<QuickCaptureBloc>(
    () => QuickCaptureBloc(
      parseQuickCaptureIntentUseCase: sl<ParseQuickCaptureIntentUseCase>(),
      submitQuickCaptureUseCase: sl<SubmitQuickCaptureUseCase>(),
    ),
  );

  sl.registerFactory<TodayHubBloc>(
    () => TodayHubBloc(
      getHabitsUseCase: sl<GetHabitsUseCase>(),
      toggleHabitUseCase: sl<ToggleHabitUseCase>(),
      getTodayTimelineUseCase: sl<GetTodayTimelineUseCase>(),
      toggleTimelineItemUseCase: sl<ToggleTimelineItemUseCase>(),
      addHabitUseCase: sl<AddHabitUseCase>(),
      updateHabitUseCase: sl<UpdateHabitUseCase>(),
      deleteHabitUseCase: sl<DeleteHabitUseCase>(),
      skipHabitUseCase: sl<SkipHabitUseCase>(),
      toggleHabitDateUseCase: sl<ToggleHabitDateUseCase>(),
      addTimelineItemUseCase: sl<AddTimelineItemUseCase>(),
      updateTimelineItemUseCase: sl<UpdateTimelineItemUseCase>(),
      deleteTimelineItemUseCase: sl<DeleteTimelineItemUseCase>(),
      notificationService: sl<NotificationService>(),
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
      getAllTransactionsUseCase: sl<GetAllTransactionsUseCase>(),
      updateTransactionUseCase: sl<UpdateTransactionUseCase>(),
      deleteTransactionUseCase: sl<DeleteTransactionUseCase>(),
      getCategoryLimitsUseCase: sl<GetCategoryLimitsUseCase>(),
      setCategoryLimitUseCase: sl<SetCategoryLimitUseCase>(),
      getAccountsUseCase: sl<GetAccountsUseCase>(),
      addAccountUseCase: sl<AddAccountUseCase>(),
      updateAccountUseCase: sl<UpdateAccountUseCase>(),
      deleteAccountUseCase: sl<DeleteAccountUseCase>(),
      addSubscriptionUseCase: sl<AddSubscriptionUseCase>(),
      updateSubscriptionUseCase: sl<UpdateSubscriptionUseCase>(),
      deleteSubscriptionUseCase: sl<DeleteSubscriptionUseCase>(),
      deleteIouUseCase: sl<DeleteIouUseCase>(),
      getMoneySettingsUseCase: sl<GetMoneySettingsUseCase>(),
      updateMoneySettingsUseCase: sl<UpdateMoneySettingsUseCase>(),
      notifyBudgetThresholdUseCase: sl<NotifyBudgetThresholdUseCase>(),
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
      updatePlannerItemUseCase: sl<UpdatePlannerItemUseCase>(),
      clearCompletedPlannerItemsUseCase:
          sl<ClearCompletedPlannerItemsUseCase>(),
    ),
  );

  sl.registerFactory<VaultBloc>(
    () => VaultBloc(
      getVaultPasswordsUseCase: sl<GetVaultPasswordsUseCase>(),
      getVaultDocumentsUseCase: sl<GetVaultDocumentsUseCase>(),
    ),
  );

  sl.registerLazySingleton<ProfileBloc>(
    () => ProfileBloc(
      getUserProfile: sl<GetUserProfileUseCase>(),
      saveUserProfile: sl<SaveUserProfileUseCase>(),
      pickProfileAvatar: sl<PickProfileAvatarUseCase>(),
    )..add(const LoadProfile()),
  );
}
