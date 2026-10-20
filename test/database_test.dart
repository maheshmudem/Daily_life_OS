import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';

// Data sources
import 'package:daily_life_os/features/today_hub/data/datasources/today_hub_local_datasource.dart';
import 'package:daily_life_os/features/money/data/datasources/money_local_datasource.dart';
import 'package:daily_life_os/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:daily_life_os/features/planner/data/datasources/planner_local_datasource.dart';
import 'package:daily_life_os/features/vault/data/datasources/vault_local_datasource.dart';

// Repositories
import 'package:daily_life_os/features/today_hub/data/repositories/today_hub_repository_impl.dart';
import 'package:daily_life_os/features/money/data/repositories/money_repository_impl.dart';
import 'package:daily_life_os/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:daily_life_os/features/planner/data/repositories/planner_repository_impl.dart';
import 'package:daily_life_os/features/vault/data/repositories/vault_repository_impl.dart';

// Use cases
import 'package:daily_life_os/features/today_hub/domain/usecases/get_habits_usecase.dart';
import 'package:daily_life_os/features/today_hub/domain/usecases/toggle_habit_usecase.dart';
import 'package:daily_life_os/features/today_hub/domain/usecases/get_today_timeline_usecase.dart';
import 'package:daily_life_os/features/today_hub/domain/usecases/toggle_timeline_item_usecase.dart';
import 'package:daily_life_os/features/money/domain/usecases/get_transactions_and_budget_usecase.dart';
import 'package:daily_life_os/features/money/domain/usecases/manage_transactions_usecase.dart';
import 'package:daily_life_os/features/money/domain/usecases/manage_subscriptions_and_ious_usecase.dart';
import 'package:daily_life_os/features/notes/domain/usecases/get_notes_usecase.dart';
import 'package:daily_life_os/features/notes/domain/usecases/manage_notes_usecases.dart';
import 'package:daily_life_os/features/planner/domain/usecases/get_planner_items_usecase.dart';
import 'package:daily_life_os/features/planner/domain/usecases/manage_planner_items_usecase.dart';
import 'package:daily_life_os/features/vault/domain/usecases/get_vault_items_usecase.dart';

void main() {
  late AppDatabase db;
  late TodayHubRepositoryImpl todayRepo;
  late MoneyRepositoryImpl moneyRepo;
  late NotesRepositoryImpl notesRepo;
  late PlannerRepositoryImpl plannerRepo;
  late VaultRepositoryImpl vaultRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await DatabaseSeeder.seedIfEmpty(db);

    todayRepo = TodayHubRepositoryImpl(TodayHubLocalDataSourceImpl(db));
    moneyRepo = MoneyRepositoryImpl(MoneyLocalDataSourceImpl(db));
    notesRepo = NotesRepositoryImpl(NotesLocalDataSourceImpl(db));
    plannerRepo = PlannerRepositoryImpl(PlannerLocalDataSourceImpl(db));
    vaultRepo = VaultRepositoryImpl(VaultLocalDataSourceImpl());
  });

  tearDown(() async {
    await db.close();
  });

  group('TodayHub Clean Architecture (DataSource -> Repository -> UseCases)', () {
    test('GetHabitsUseCase retrieves seeded habits', () async {
      final useCase = GetHabitsUseCase(todayRepo);
      final habits = await useCase();
      expect(habits.length, greaterThanOrEqualTo(4));
      expect(habits.any((h) => h.title == 'Drink 3L Water'), isTrue);
    });

    test('ToggleHabitUseCase updates streak & status', () async {
      final getHabits = GetHabitsUseCase(todayRepo);
      final toggleHabit = ToggleHabitUseCase(todayRepo);

      final habits = await getHabits();
      final target = habits.firstWhere((h) => h.title == 'Read 15 mins');
      expect(target.isDoneToday, isFalse);
      final initialStreak = target.streakDays;

      await toggleHabit(target.id);

      final updatedHabits = await getHabits();
      final updated = updatedHabits.firstWhere((h) => h.id == target.id);
      expect(updated.isDoneToday, isTrue);
      expect(updated.streakDays, equals(initialStreak + 1));
    });

    test('Timeline use cases toggle completion state', () async {
      final getTimeline = GetTodayTimelineUseCase(todayRepo);
      final toggleItem = ToggleTimelineItemUseCase(todayRepo);

      final timeline = await getTimeline();
      expect(timeline.isNotEmpty, isTrue);
      final item = timeline.first;

      await toggleItem(item.id);

      final updatedTimeline = await getTimeline();
      final updatedItem = updatedTimeline.firstWhere((t) => t.id == item.id);
      expect(updatedItem.isDone, equals(!item.isDone));
    });
  });

  group('Money Manager Clean Architecture (DataSource -> Repository -> UseCases)', () {
    test('GetBudgetUseCase calculates budget and daily safe spend dynamically', () async {
      final getBudget = GetBudgetUseCase(moneyRepo);
      final budget = await getBudget();
      expect(budget.monthlyBudget, equals(40000.0));
      expect(budget.fixedBills, equals(8000.0));
      expect(budget.dailySafeSpend, greaterThan(0));
    });

    test('AddTransactionUseCase persists and retrieves new transaction', () async {
      final getTx = GetRecentTransactionsUseCase(moneyRepo);
      final addTx = AddTransactionUseCase(moneyRepo);

      final initialTx = await getTx();

      await addTx(
        title: 'Coffee at Blue Tokai',
        category: 'Food',
        amount: 280.0,
        mode: 'UPI',
        iconCodePoint: 0xe532,
      );

      final updatedTx = await getTx();
      expect(updatedTx.length, equals(initialTx.length + 1));
      expect(updatedTx.first.title, equals('Coffee at Blue Tokai'));
    });

    test('Subscription & IOU Use Cases toggle auto-kill and settle debts', () async {
      final getSubs = GetSubscriptionsUseCase(moneyRepo);
      final toggleAutoKill = ToggleAutoKillUseCase(moneyRepo);
      final getIous = GetIousUseCase(moneyRepo);
      final settleIou = SettleIouUseCase(moneyRepo);

      final subs = await getSubs();
      final sub = subs.first;
      final initialAutoKill = sub.autoKillEnabled;

      await toggleAutoKill(sub.id);
      final updatedSubs = await getSubs();
      expect(updatedSubs.firstWhere((s) => s.id == sub.id).autoKillEnabled, equals(!initialAutoKill));

      final ious = await getIous();
      final iou = ious.firstWhere((i) => !i.isSettled);

      await settleIou(iou.id);
      final activeIous = await getIous();
      expect(activeIous.any((i) => i.id == iou.id), isFalse);
    });
  });

  group('Notes Clean Architecture (DataSource -> Repository -> UseCases)', () {
    test('Notes use cases create, pin, and delete notes', () async {
      final getNotes = GetNotesUseCase(notesRepo);
      final addNote = AddNoteUseCase(notesRepo);
      final togglePin = TogglePinNoteUseCase(notesRepo);
      final deleteNote = DeleteNoteUseCase(notesRepo);

      final initialNotes = await getNotes();

      await addNote(
        title: 'Project Ideas 2026',
        content: 'AI-first personal operating system',
        colorValue: 0xFF2563EB,
        tags: 'ideas,tech',
      );

      final notesAfterAdd = await getNotes();
      expect(notesAfterAdd.length, equals(initialNotes.length + 1));

      final created = notesAfterAdd.firstWhere((n) => n.title == 'Project Ideas 2026');
      expect(created.isPinned, isFalse);

      await togglePin(created.id);
      final pinnedNotes = await getNotes();
      expect(pinnedNotes.firstWhere((n) => n.id == created.id).isPinned, isTrue);

      await deleteNote(created.id);
      final notesAfterDelete = await getNotes();
      expect(notesAfterDelete.any((n) => n.id == created.id), isFalse);
    });
  });

  group('Planner Clean Architecture (DataSource -> Repository -> UseCases)', () {
    test('Planner use cases add and toggle planner tasks', () async {
      final getPlanner = GetPlannerItemsUseCase(plannerRepo);
      final addPlanner = AddPlannerItemUseCase(plannerRepo);
      final togglePlanner = TogglePlannerItemUseCase(plannerRepo);

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final initialItems = await getPlanner(today);

      await addPlanner(
        title: 'Review Architecture Diagram',
        date: today,
        category: 'Architecture',
        colorValue: 0xFF0D9488,
        iconCodePoint: 0xe532,
        startTime: '11:00',
        endTime: '12:00',
      );

      final updatedItems = await getPlanner(today);
      expect(updatedItems.length, equals(initialItems.length + 1));

      final added = updatedItems.firstWhere((i) => i.title == 'Review Architecture Diagram');
      expect(added.isDone, isFalse);

      await togglePlanner(added.id);
      final toggledItems = await getPlanner(today);
      expect(toggledItems.firstWhere((i) => i.id == added.id).isDone, isTrue);
    });
  });

  group('Vault Clean Architecture (DataSource -> Repository -> UseCases)', () {
    test('Vault use cases fetch passwords and warranties', () async {
      final getPasswords = GetVaultPasswordsUseCase(vaultRepo);
      final getDocs = GetVaultDocumentsUseCase(vaultRepo);

      final passwords = await getPasswords();
      final docs = await getDocs();

      expect(passwords.isNotEmpty, isTrue);
      expect(docs.isNotEmpty, isTrue);
      expect(passwords.any((p) => p.title.contains('NetBanking')), isTrue);
      expect(docs.any((d) => d.title.contains('Warranty')), isTrue);
    });
  });
}
