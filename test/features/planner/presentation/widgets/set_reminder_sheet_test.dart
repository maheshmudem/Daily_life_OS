import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/set_reminder_sheet.dart';

void main() {
  testWidgets('SetReminderSheet renders inputs and calls onSubmit',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? submittedTitle;
    DateTime? submittedDate;
    TimeOfDay? submittedTime;
    String? submittedCategory;
    String? submittedPriority;

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
                  onSubmit: ({
                    required title,
                    required date,
                    required time,
                    required category,
                    required repeatType,
                    required repeatDays,
                    required endDate,
                    required priority,
                    required reminderOffsetMinutes,
                    required checklist,
                    required notes,
                  }) {
                    submittedTitle = title;
                    submittedDate = date;
                    submittedTime = time;
                    submittedCategory = category;
                    submittedPriority = priority;
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
    final importantChip = find.widgetWithText(ChoiceChip, 'Important');
    await tester.ensureVisible(importantChip);
    await tester.tap(importantChip);
    await tester.pumpAndSettle();

    // Tap 'Set Reminder' button
    final submitBtn =
        find.widgetWithText(FilledButton, StringConstants.setReminder);
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify submission callback fired with updated category
    expect(submittedTitle, 'Review Tax Invoices');
    expect(submittedCategory, 'Important');
    expect(submittedDate, isNotNull);
    expect(submittedTime, const TimeOfDay(hour: 14, minute: 30));
    expect(submittedPriority, 'medium');
  });

  testWidgets(
      'SetReminderSheet renders in edit mode, configures recurrence and submits updated values',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? submittedTitle;
    String? submittedCategory;
    String? submittedRepeatType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                SetReminderSheet.show(
                  context,
                  sheetTitle: 'Edit Reminder',
                  submitButtonText: 'Update Reminder',
                  initialTitle: 'Team Sync',
                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                  initialCategory: 'Work',
                  isDark: false,
                  onSubmit: ({
                    required title,
                    required date,
                    required time,
                    required category,
                    required repeatType,
                    required repeatDays,
                    required endDate,
                    required priority,
                    required reminderOffsetMinutes,
                    required checklist,
                    required notes,
                  }) {
                    submittedTitle = title;
                    submittedCategory = category;
                    submittedRepeatType = repeatType;
                  },
                );
              },
              child: const Text('Edit Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Reminder'), findsOneWidget);
    expect(find.text('Update Reminder'), findsOneWidget);
    expect(find.text('Team Sync'), findsOneWidget);

    // Enter new title
    await tester.enterText(find.byType(TextField).first, 'Sprint Planning');
    await tester.pumpAndSettle();

    // Select category 'Personal'
    final personalChip = find.widgetWithText(ChoiceChip, 'Personal');
    await tester.ensureVisible(personalChip);
    await tester.tap(personalChip);
    await tester.pumpAndSettle();

    // Select Repeat Frequency 'Daily'
    final dailyChip = find.widgetWithText(ChoiceChip, 'Daily');
    await tester.ensureVisible(dailyChip);
    await tester.tap(dailyChip);
    await tester.pumpAndSettle();

    // Tap 'Update Reminder'
    final updateBtn = find.widgetWithText(FilledButton, 'Update Reminder');
    await tester.ensureVisible(updateBtn);
    await tester.tap(updateBtn);
    await tester.pumpAndSettle();

    expect(submittedTitle, 'Sprint Planning');
    expect(submittedCategory, 'Personal');
    expect(submittedRepeatType, 'daily');
  });
}
