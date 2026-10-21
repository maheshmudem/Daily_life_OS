import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/features/planner/domain/entities/countdown_item_entity.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/countdown_card.dart';

void main() {
  testWidgets('CountdownCard renders countdown info and responds to actions',
      (WidgetTester tester) async {
    bool addedToPlanner = false;
    bool edited = false;
    bool deleted = false;

    final targetDate = DateTime.now().add(const Duration(days: 10));

    final item = CountdownItemEntity(
      id: 'test_cd',
      title: 'Summer Vacation',
      date: targetDate,
      category: 'Travel',
      colorValue: 0xFF06B6D4,
      iconCodePoint: Icons.flight_takeoff_rounded.codePoint,
      notes: 'Book flights and pack swimsuit',
      remindAdvance: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountdownCard(
            item: item,
            isDark: false,
            onAddToPlanner: () => addedToPlanner = true,
            onEdit: () => edited = true,
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    // Verify UI components
    expect(find.text('Summer Vacation'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.textContaining('Book flights and pack swimsuit'), findsOneWidget);
    expect(find.text('10d left'), findsOneWidget);
    expect(find.text('Add to Planner'), findsOneWidget);

    // Test tap on Add to Planner
    await tester.tap(find.text('Add to Planner'));
    expect(addedToPlanner, isTrue);

    // Test tap on Edit
    await tester.tap(find.byIcon(Icons.edit_outlined));
    expect(edited, isTrue);

    // Test tap on Delete
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    expect(deleted, isTrue);
  });
}
