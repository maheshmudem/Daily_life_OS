import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/features/planner/domain/entities/countdown_item_entity.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/countdown_sheet.dart';

void main() {
  testWidgets(
    'CountdownSheet creates new countdown entity with advance alerts',
    (WidgetTester tester) async {
      CountdownItemEntity? savedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CountdownSheet.show(
                    context,
                    isDark: false,
                    onSave: (entity) {
                      savedResult = entity;
                    },
                  );
                },
                child: const Text('Open Countdown Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Countdown Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Create Countdown'), findsWidgets);
      expect(find.text('Advance Alert Reminders'), findsOneWidget);

      // Enter title & notes
      final titleFinder = find.widgetWithText(
        TextField,
        'e.g., Mom\'s 50th Birthday, Trip to Paris',
      );
      await tester.enterText(titleFinder, 'Summer Vacation');

      // Switch category to Travel
      await tester.tap(find.widgetWithText(ChoiceChip, 'Travel'));
      await tester.pumpAndSettle();

      // Tap 'Create Countdown'
      await tester.tap(find.widgetWithText(FilledButton, 'Create Countdown'));
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(savedResult!.title, 'Summer Vacation');
      expect(savedResult!.category, 'Travel');
      expect(savedResult!.remindAdvance, isTrue);
    },
  );
}
