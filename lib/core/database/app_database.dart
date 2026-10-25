import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

part 'app_database.g.dart';

// ─── HABITS TABLE ────────────────────────────────────────────────────────────
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorValue => integer()();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  BoolColumn get isDoneToday => boolean().withDefault(const Constant(false))();
  TextColumn get lastCompletedDate => text().nullable()();
  TextColumn get createdAt => text()();
}

// ─── TIMELINE ITEMS TABLE ────────────────────────────────────────────────────
class TimelineItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get time => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  IntColumn get colorValue => integer()();
  IntColumn get iconCodePoint => integer()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  TextColumn get action => text()();
  TextColumn get date => text()(); // ISO8601 date
}

// ─── TRANSACTIONS TABLE ──────────────────────────────────────────────────────
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get mode => text()(); // UPI / Card / Cash
  IntColumn get iconCodePoint => integer()();
  TextColumn get date => text()(); // ISO8601
  TextColumn get type => text().withDefault(const Constant('expense'))(); // expense / income
}

// ─── BUDGET SETTINGS TABLE ───────────────────────────────────────────────────
class BudgetSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  RealColumn get monthlyBudget => real().withDefault(const Constant(40000))();
  RealColumn get fixedBills => real().withDefault(const Constant(8000))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── SUBSCRIPTIONS TABLE ─────────────────────────────────────────────────────
class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get renewalDate => text()(); // ISO8601
  BoolColumn get autoKillEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get iconCodePoint => integer()();
}

// ─── IOU ENTRIES TABLE ───────────────────────────────────────────────────────
class IouEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get person => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'lent' / 'borrowed'
  TextColumn get note => text()();
  TextColumn get date => text()(); // ISO8601
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
}

// ─── NOTES TABLE ─────────────────────────────────────────────────────────────
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  IntColumn get colorValue => integer()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

// ─── PLANNER ITEMS TABLE ─────────────────────────────────────────────────────
class PlannerItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get date => text()(); // ISO8601 date
  TextColumn get startTime => text().nullable()();
  TextColumn get endTime => text().nullable()();
  TextColumn get category => text()();
  IntColumn get colorValue => integer()();
  IntColumn get iconCodePoint => integer()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get repeatType =>
      text().withDefault(const Constant('none'))(); // 'none', 'daily', 'weekdays', 'weekly', 'monthly'
  TextColumn get repeatDays =>
      text().withDefault(const Constant(''))(); // e.g. '1,3,5' for Mon, Wed, Fri
  TextColumn get endDate => text().nullable()(); // ISO8601 date or null (forever)
  TextColumn get priority =>
      text().withDefault(const Constant('medium'))(); // 'low', 'medium', 'high', 'urgent'
  IntColumn get reminderOffsetMinutes =>
      integer().withDefault(const Constant(0))(); // 0, 5, 15, 30, 60, 1440
  TextColumn get checklistJson =>
      text().withDefault(const Constant('[]'))(); // JSON array of subtasks
  TextColumn get completedDates =>
      text().withDefault(const Constant(''))(); // Comma-separated ISO dates
}

// ─── DATABASE ────────────────────────────────────────────────────────────────
@DriftDatabase(tables: [
  Habits,
  TimelineItems,
  Transactions,
  BudgetSettings,
  Subscriptions,
  IouEntries,
  Notes,
  PlannerItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(plannerItems, plannerItems.repeatType);
            await m.addColumn(plannerItems, plannerItems.repeatDays);
            await m.addColumn(plannerItems, plannerItems.endDate);
            await m.addColumn(plannerItems, plannerItems.priority);
            await m.addColumn(plannerItems, plannerItems.reminderOffsetMinutes);
            await m.addColumn(plannerItems, plannerItems.checklistJson);
            await m.addColumn(plannerItems, plannerItems.completedDates);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'daily_life_os',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            debugPrint(
              'Drift Web: Using ${result.chosenImplementation} (missing: ${result.missingFeatures})',
            );
          }
        },
      ),
    );
  }
}
