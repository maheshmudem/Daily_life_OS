import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/features/planner/data/datasources/planner_local_datasource.dart';

void main() {
  late AppDatabase db;
  late PlannerLocalDataSource dataSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = PlannerLocalDataSourceImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('PlannerLocalDataSource can insert, query, toggle, and delete items',
      () async {
    const today = '2026-10-21';

    // 1. Initial items should be empty
    final initial = await dataSource.getItemsForDate(today);
    expect(initial, isEmpty);

    // 2. Add item
    await dataSource.addItem(
      title: 'Review PR & Deploy',
      date: today,
      startTime: '10:00 AM',
      category: 'Work',
      colorValue: 0xFF3B82F6,
      iconCodePoint: 12345,
    );

    // 3. Query items
    final items = await dataSource.getItemsForDate(today);
    expect(items.length, 1);
    expect(items.first.title, 'Review PR & Deploy');
    expect(items.first.category, 'Work');
    expect(items.first.isDone, false);

    // 4. Toggle item done
    await dataSource.toggleItem(items.first.id);
    final toggled = await dataSource.getItemsForDate(today);
    expect(toggled.first.isDone, true);

    // 5. Delete item
    await dataSource.deleteItem(items.first.id);
    final remaining = await dataSource.getItemsForDate(today);
    expect(remaining, isEmpty);
  });
}
