import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/set_reminder_sheet.dart';

void main() {
  testWidgets('SetReminderSheet renders inputs and calls onSubmit',
      (WidgetTester tester) async {
    String? submittedTitle;
    DateTime? submittedDate;
    TimeOfDay? submittedTime;
    String? submittedCategory;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                SetReminderSheet.show(
                  context,
                  initialTitle: 'Review Tax Invoices',
                  initialTime: const TimeOfDay(hour: 14, minute: 30),
                  initialCategory: 'Finance',
                  isDark: false,
                  onSubmit: (title, date, time, category) {
                    submittedTitle = title;
                    submittedDate = date;
                    submittedTime = time;
                    submittedCategory = category;
                  },
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify Title field contains initialTitle
    expect(find.text('Review Tax Invoices'), findsOneWidget);
    expect(find.text('Schedule:'), findsOneWidget);
    expect(find.text('Category:'), findsOneWidget);

    // Select different Category Chip
    await tester.tap(find.widgetWithText(ChoiceChip, 'Important'));
    await tester.pumpAndSettle();

    // Tap 'Set Reminder' button
    await tester.tap(find.widgetWithText(FilledButton, StringConstants.setReminder));
    await tester.pumpAndSettle();

    // Verify submission callback fired with updated category
    expect(submittedTitle, 'Review Tax Invoices');
    expect(submittedCategory, 'Important');
    expect(submittedDate, isNotNull);
    expect(submittedTime, const TimeOfDay(hour: 14, minute: 30));
  });
}
