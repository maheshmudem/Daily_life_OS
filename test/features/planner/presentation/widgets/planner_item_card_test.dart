import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/features/planner/domain/entities/planner_item_entity.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/planner_item_card.dart';

void main() {
  const testItem = PlannerItemEntity(
    id: 1,
    title: 'Standup Meeting',
    date: '2026-10-24',
    startTime: '10:00 AM',
    endTime: '10:30 AM',
    category: 'Work',
    colorValue: 0xFF3B82F6,
    iconCodePoint: 123,
    isDone: false,
    notes: '',
  );

  testWidgets('PlannerItemCard renders correctly and triggers callbacks and dropdown menu',
      (WidgetTester tester) async {
    bool editCalled = false;
    bool deleteCalled = false;
    bool snoozeCalled = false;
    bool duplicateCalled = false;
    bool pushTomorrowCalled = false;
    bool? toggleValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlannerItemCard(
            item: testItem,
            isDark: false,
            onToggle: (val) => toggleValue = val,
            onDelete: () => deleteCalled = true,
            onSnooze: () => snoozeCalled = true,
            onEdit: () => editCalled = true,
            onDuplicate: () => duplicateCalled = true,
            onPushTomorrow: () => pushTomorrowCalled = true,
          ),
        ),
      ),
    );

    // Verify title and details rendered
    expect(find.text('Standup Meeting'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text(testItem.timeRange), findsOneWidget);

    // Test More Actions AppDropdownMenu
    final moreActionsBtn = find.byTooltip('More actions');
    expect(moreActionsBtn, findsOneWidget);
    await tester.tap(moreActionsBtn);
    await tester.pumpAndSettle();

    // Verify dropdown items
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Push to Tomorrow'), findsOneWidget);
    expect(find.text('Delete Reminder'), findsOneWidget);

    // Tap Duplicate
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(duplicateCalled, isTrue);

    // Open dropdown and tap Push to Tomorrow
    await tester.tap(moreActionsBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push to Tomorrow'));
    await tester.pumpAndSettle();
    expect(pushTomorrowCalled, isTrue);

    // Open dropdown and tap Edit Reminder
    await tester.tap(moreActionsBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Reminder'));
    await tester.pumpAndSettle();
    expect(editCalled, isTrue);

    // Reset and tap Edit outlined button at bottom
    editCalled = false;
    final editOutlinedBtn = find.widgetWithText(OutlinedButton, 'Edit');
    expect(editOutlinedBtn, findsOneWidget);
    await tester.tap(editOutlinedBtn);
    expect(editCalled, isTrue);

    // Tap title text to trigger edit
    editCalled = false;
    await tester.tap(find.text('Standup Meeting'));
    expect(editCalled, isTrue);

    // Tap Snooze
    await tester.tap(find.text('Snooze +15m'));
    expect(snoozeCalled, isTrue);

    // Tap Mark Done
    await tester.tap(find.text('Mark Done'));
    expect(toggleValue, isTrue);

    // Open dropdown and tap Delete Reminder
    await tester.tap(moreActionsBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Reminder'));
    await tester.pumpAndSettle();
    expect(deleteCalled, isTrue);
  });

  testWidgets('PlannerItemCard renders priority and recurrence badges',
      (WidgetTester tester) async {
    const recurringItem = PlannerItemEntity(
      id: 2,
      title: 'Weekly Standup',
      date: '2026-10-24',
      startTime: '10:00 AM',
      category: 'Work',
      colorValue: 0xFF3B82F6,
      iconCodePoint: 123,
      isDone: false,
      notes: 'Prepare agenda',
      repeatType: 'daily',
      priority: 'urgent',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlannerItemCard(
            item: recurringItem,
            isDark: false,
            onToggle: (_) {},
            onDelete: () {},
            onSnooze: () {},
          ),
        ),
      ),
    );

    expect(find.text('URGENT'), findsOneWidget);
    expect(find.text('Repeats daily'), findsOneWidget);
    expect(find.text('Prepare agenda'), findsOneWidget);
  });
}
