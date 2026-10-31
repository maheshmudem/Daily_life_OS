import 'package:drift/drift.dart';
import 'package:flutter/material.dart' hide Table;
import '../database/app_database.dart';
import '../../config/theme/app_colors.dart';

/// Seeds the database with demo data on first launch and ensures upgraded
/// installations have default Money v3/v4 tables populated.
class DatabaseSeeder {
  static Future<void> seedIfEmpty(AppDatabase db) async {
    final habits = await db.select(db.habits).get();
    if (habits.isNotEmpty) {
      await _ensureMoneyDefaults(db);
      return;
    }

    final now = DateTime.now().toIso8601String();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // ── Habits ──────────────────────────────────────────────────────────────
    await db.batch((batch) {
      batch.insertAll(db.habits, [
        HabitsCompanion.insert(
          title: 'Drink 3L Water',
          iconCodePoint: Icons.water_drop_rounded.codePoint,
          colorValue: AppColors.secondary.toARGB32(),
          streakDays: const Value(14),
          isDoneToday: const Value(true),
          lastCompletedDate: Value(today),
          createdAt: now,
        ),
        HabitsCompanion.insert(
          title: 'Daily Vitamins',
          iconCodePoint: Icons.medication_rounded.codePoint,
          colorValue: AppColors.moduleMoney.toARGB32(),
          streakDays: const Value(22),
          isDoneToday: const Value(true),
          lastCompletedDate: Value(today),
          createdAt: now,
        ),
        HabitsCompanion.insert(
          title: 'Read 15 mins',
          iconCodePoint: Icons.auto_stories_rounded.codePoint,
          colorValue: AppColors.primary.toARGB32(),
          streakDays: const Value(9),
          isDoneToday: const Value(false),
          createdAt: now,
        ),
        HabitsCompanion.insert(
          title: 'Meditation (10m)',
          iconCodePoint: Icons.self_improvement_rounded.codePoint,
          colorValue: AppColors.moduleVault.toARGB32(),
          streakDays: const Value(5),
          isDoneToday: const Value(false),
          createdAt: now,
        ),
      ]);
    });

    // ── Timeline Items ───────────────────────────────────────────────────────
    await db.batch((batch) {
      batch.insertAll(db.timelineItems, [
        TimelineItemsCompanion.insert(
          time: '09:00 AM',
          title: 'Morning Standup & Deep Focus',
          category: 'Time',
          colorValue: AppColors.moduleTime.toARGB32(),
          iconCodePoint: Icons.laptop_chromebook_rounded.codePoint,
          isDone: const Value(true),
          action: 'Done',
          date: today,
        ),
        TimelineItemsCompanion.insert(
          time: '01:30 PM',
          title: 'Electricity Bill Due (₹450)',
          category: 'Money',
          colorValue: AppColors.moduleMoney.toARGB32(),
          iconCodePoint: Icons.bolt_rounded.codePoint,
          isDone: const Value(false),
          action: 'Log Payment',
          date: today,
        ),
        TimelineItemsCompanion.insert(
          time: '04:00 PM',
          title: 'Call Bank re: Card Upgrade',
          category: 'Talking Reminder',
          colorValue: AppColors.primary.toARGB32(),
          iconCodePoint: Icons.record_voice_over_rounded.codePoint,
          isDone: const Value(false),
          action: 'Snooze',
          date: today,
        ),
        TimelineItemsCompanion.insert(
          time: '07:30 PM',
          title: "Sarah's Birthday Gift Planning",
          category: 'Notes Link',
          colorValue: AppColors.moduleNotes.toARGB32(),
          iconCodePoint: Icons.cake_rounded.codePoint,
          isDone: const Value(false),
          action: 'View Note',
          date: today,
        ),
      ]);
    });

    // ── Budget Settings ──────────────────────────────────────────────────────
    await db
        .into(db.budgetSettings)
        .insertOnConflictUpdate(
          const BudgetSettingsCompanion(
            id: Value(1),
            monthlyBudget: Value(40000),
            fixedBills: Value(8000),
          ),
        );

    // ── Transactions ─────────────────────────────────────────────────────────
    await db.batch((batch) {
      batch.insertAll(db.transactions, [
        TransactionsCompanion.insert(
          title: 'Organic Grocery & Supermarket',
          category: 'Food & Groceries',
          amount: 840,
          mode: 'UPI',
          iconCodePoint: Icons.shopping_basket_rounded.codePoint,
          date: now,
          type: const Value('expense'),
        ),
        TransactionsCompanion.insert(
          title: 'Metro Rail Smart Card Recharge',
          category: 'Travel',
          amount: 300,
          mode: 'Card',
          iconCodePoint: Icons.train_rounded.codePoint,
          date: DateTime.now()
              .subtract(const Duration(hours: 5))
              .toIso8601String(),
          type: const Value('expense'),
        ),
        TransactionsCompanion.insert(
          title: 'High-Speed Fiber Internet Bill',
          category: 'Bills',
          amount: 999,
          mode: 'UPI',
          iconCodePoint: Icons.wifi_rounded.codePoint,
          date: DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          type: const Value('expense'),
        ),
      ]);
    });

    // ── Money v3: income + history (keys from MoneyCategory catalog) ─────────
    final nowDt = DateTime.now();
    String daysAgo(int d, {int hour = 12}) => DateTime(
      nowDt.year,
      nowDt.month,
      nowDt.day,
      hour,
    ).subtract(Duration(days: d)).toIso8601String();
    String monthsAgo(int m, int day, {int hour = 10}) => DateTime(
      nowDt.year,
      nowDt.month - m,
      m == 0 && day > nowDt.day ? nowDt.day : day, // never seed future dates
      hour,
    ).toIso8601String();

    await db.batch((batch) {
      batch.insertAll(db.transactions, [
        // Income
        TransactionsCompanion.insert(
          title: 'Salary Credit',
          category: 'salary',
          amount: 65000,
          mode: 'Bank',
          iconCodePoint: Icons.account_balance_rounded.codePoint,
          date: monthsAgo(0, 1, hour: 9),
          type: const Value('income'),
        ),
        TransactionsCompanion.insert(
          title: 'Salary Credit',
          category: 'salary',
          amount: 65000,
          mode: 'Bank',
          iconCodePoint: Icons.account_balance_rounded.codePoint,
          date: monthsAgo(1, 1, hour: 9),
          type: const Value('income'),
        ),
        TransactionsCompanion.insert(
          title: 'Freelance Design Project',
          category: 'business',
          amount: 12000,
          mode: 'UPI',
          iconCodePoint: Icons.work_rounded.codePoint,
          date: monthsAgo(1, 18, hour: 17),
          type: const Value('income'),
        ),
        // Previous month expenses
        TransactionsCompanion.insert(
          title: 'Monthly Rent',
          category: 'bills',
          amount: 18000,
          mode: 'Bank',
          iconCodePoint: Icons.receipt_long_rounded.codePoint,
          date: monthsAgo(1, 3),
          type: const Value('expense'),
        ),
        TransactionsCompanion.insert(
          title: 'Weekend Groceries',
          category: 'food',
          amount: 2350,
          mode: 'Card',
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          date: monthsAgo(1, 9),
          type: const Value('expense'),
        ),
        TransactionsCompanion.insert(
          title: 'Cab to Airport',
          category: 'transport',
          amount: 780,
          mode: 'UPI',
          iconCodePoint: Icons.directions_car_rounded.codePoint,
          date: monthsAgo(1, 15),
          type: const Value('expense'),
        ),
        TransactionsCompanion.insert(
          title: 'New Sneakers',
          category: 'shopping',
          amount: 4200,
          mode: 'Card',
          iconCodePoint: Icons.shopping_bag_rounded.codePoint,
          date: monthsAgo(1, 22),
          type: const Value('expense'),
        ),
        // This month expenses
        TransactionsCompanion.insert(
          title: 'Monthly Rent',
          category: 'bills',
          amount: 18000,
          mode: 'Bank',
          iconCodePoint: Icons.receipt_long_rounded.codePoint,
          date: monthsAgo(0, 2),
          type: const Value('expense'),
        ),
        TransactionsCompanion.insert(
          title: 'Pharmacy',
          category: 'health',
          amount: 640,
          mode: 'Cash',
          iconCodePoint: Icons.local_pharmacy_rounded.codePoint,
          date: daysAgo(2, hour: 18),
          type: const Value('expense'),
        ),
        TransactionsCompanion.insert(
          title: 'Movie Night',
          category: 'entertainment',
          amount: 950,
          mode: 'UPI',
          iconCodePoint: Icons.play_circle_rounded.codePoint,
          date: daysAgo(3, hour: 21),
          type: const Value('expense'),
        ),
        TransactionsCompanion.insert(
          title: 'Coffee & Snacks',
          category: 'food',
          amount: 320,
          mode: 'UPI',
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          date: daysAgo(4, hour: 11),
          type: const Value('expense'),
        ),
      ]);
    });

    // ── Money v3: category limits & asset accounts ───────────────────────────
    await _ensureMoneyDefaults(db);

    // ── Subscriptions ────────────────────────────────────────────────────────
    final inFourDays = DateTime.now()
        .add(const Duration(days: 4))
        .toIso8601String();
    final inFourteen = DateTime.now()
        .add(const Duration(days: 14))
        .toIso8601String();
    final inTwentyTwo = DateTime.now()
        .add(const Duration(days: 22))
        .toIso8601String();

    await db.batch((batch) {
      batch.insertAll(db.subscriptions, [
        SubscriptionsCompanion.insert(
          name: 'Netflix 4K Premium',
          amount: 649,
          renewalDate: inFourDays,
          autoKillEnabled: const Value(true),
          iconCodePoint: Icons.movie_filter_rounded.codePoint,
        ),
        SubscriptionsCompanion.insert(
          name: 'Spotify Individual',
          amount: 119,
          renewalDate: inFourteen,
          autoKillEnabled: const Value(false),
          iconCodePoint: Icons.music_note_rounded.codePoint,
        ),
        SubscriptionsCompanion.insert(
          name: 'GitHub Copilot',
          amount: 820,
          renewalDate: inTwentyTwo,
          autoKillEnabled: const Value(true),
          iconCodePoint: Icons.code_rounded.codePoint,
        ),
      ]);
    });

    // ── IOU Entries ──────────────────────────────────────────────────────────
    await db.batch((batch) {
      batch.insertAll(db.iouEntries, [
        IouEntriesCompanion.insert(
          person: 'David Kumar',
          amount: 1500,
          type: 'lent',
          note: 'Dinner split bill',
          date: now,
        ),
        IouEntriesCompanion.insert(
          person: 'Priya Sen',
          amount: 600,
          type: 'borrowed',
          note: 'Concert ticket advance',
          date: now,
        ),
      ]);
    });

    // ── Notes ────────────────────────────────────────────────────────────────
    await db.batch((batch) {
      batch.insertAll(db.notes, [
        NotesCompanion.insert(
          title: "Sarah's Birthday Gift Ideas",
          content:
              '• Kindle Paperwhite\n• Gourmet coffee subscription\n• Weekend spa voucher',
          colorValue: AppColors.moduleNotes.toARGB32(),
          isPinned: const Value(true),
          tags: const Value('gift,planning'),
          createdAt: now,
          updatedAt: now,
        ),
        NotesCompanion.insert(
          title: 'Weekly Goals',
          content:
              '1. Complete project proposal\n2. Call dentist\n3. Car service appointment',
          colorValue: AppColors.primary.toARGB32(),
          isPinned: const Value(false),
          tags: const Value('goals,weekly'),
          createdAt: now,
          updatedAt: now,
        ),
      ]);
    });

    // ── Planner Items ────────────────────────────────────────────────────────
    await db.batch((batch) {
      batch.insertAll(db.plannerItems, [
        PlannerItemsCompanion.insert(
          title: 'Morning Standup',
          date: today,
          startTime: const Value('09:00'),
          endTime: const Value('09:30'),
          category: 'Work',
          colorValue: AppColors.moduleTime.toARGB32(),
          iconCodePoint: Icons.laptop_chromebook_rounded.codePoint,
          isDone: const Value(true),
        ),
        PlannerItemsCompanion.insert(
          title: 'Gym Workout',
          date: today,
          startTime: const Value('06:00'),
          endTime: const Value('07:00'),
          category: 'Health',
          colorValue: AppColors.secondary.toARGB32(),
          iconCodePoint: Icons.fitness_center_rounded.codePoint,
          isDone: const Value(false),
        ),
      ]);
    });
  }

  /// Ensures `budgetSettings`, `categoryBudgets`, and `moneyAccounts` have
  /// baseline records even when upgrading from an older schema version.
  static Future<void> _ensureMoneyDefaults(AppDatabase db) async {
    final settings = await db.select(db.budgetSettings).get();
    if (settings.isEmpty) {
      await db
          .into(db.budgetSettings)
          .insertOnConflictUpdate(
            const BudgetSettingsCompanion(
              id: Value(1),
              monthlyBudget: Value(40000),
              fixedBills: Value(8000),
            ),
          );
    }

    final existingCategoryBudgets = await db.select(db.categoryBudgets).get();
    if (existingCategoryBudgets.isEmpty) {
      await db.batch((batch) {
        batch.insertAll(db.categoryBudgets, [
          CategoryBudgetsCompanion.insert(
            category: 'food',
            monthlyLimit: const Value(6000),
          ),
          CategoryBudgetsCompanion.insert(
            category: 'transport',
            monthlyLimit: const Value(2500),
          ),
          CategoryBudgetsCompanion.insert(
            category: 'shopping',
            monthlyLimit: const Value(5000),
          ),
          CategoryBudgetsCompanion.insert(
            category: 'health',
            monthlyLimit: const Value(2000),
          ),
          CategoryBudgetsCompanion.insert(
            category: 'entertainment',
            monthlyLimit: const Value(1500),
          ),
          CategoryBudgetsCompanion.insert(
            category: 'bills',
            monthlyLimit: const Value(20000),
          ),
          CategoryBudgetsCompanion.insert(
            category: 'travel',
            monthlyLimit: const Value(3000),
          ),
          CategoryBudgetsCompanion.insert(
            category: 'other',
            monthlyLimit: const Value(1000),
          ),
        ], mode: InsertMode.insertOrIgnore);
      });
    }

    final existingAccounts = await db.select(db.moneyAccounts).get();
    if (existingAccounts.isEmpty) {
      await db.batch((batch) {
        batch.insertAll(db.moneyAccounts, [
          MoneyAccountsCompanion.insert(
            name: 'Wallet Cash',
            type: 'cash',
            balance: const Value(4500),
            colorValue: AppColors.moneyAssetCash.toARGB32(),
            iconCodePoint: Icons.payments_rounded.codePoint,
          ),
          MoneyAccountsCompanion.insert(
            name: 'Savings Account',
            type: 'savings',
            balance: const Value(125000),
            colorValue: AppColors.moneyAssetSavings.toARGB32(),
            iconCodePoint: Icons.savings_rounded.codePoint,
          ),
          MoneyAccountsCompanion.insert(
            name: 'Mutual Funds',
            type: 'investment',
            balance: const Value(68000),
            colorValue: AppColors.moneyAssetInvest.toARGB32(),
            iconCodePoint: Icons.trending_up_rounded.codePoint,
          ),
        ]);
      });
    }
  }
}
