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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {},
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
