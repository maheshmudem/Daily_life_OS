import 'package:drift/drift.dart';
import 'package:flutter/material.dart' hide Table;
import '../database/app_database.dart';
import '../../config/theme/app_colors.dart';

/// Seeds the database with demo data on first launch
class DatabaseSeeder {
  static Future<void> seedIfEmpty(AppDatabase db) async {
    // Check if already seeded
    final habits = await db.select(db.habits).get();
    if (habits.isNotEmpty) return;

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
    await db.into(db.budgetSettings).insertOnConflictUpdate(
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

    // ── Subscriptions ────────────────────────────────────────────────────────
    final inFourDays =
        DateTime.now().add(const Duration(days: 4)).toIso8601String();
    final inFourteen =
        DateTime.now().add(const Duration(days: 14)).toIso8601String();
    final inTwentyTwo =
        DateTime.now().add(const Duration(days: 22)).toIso8601String();

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
}
