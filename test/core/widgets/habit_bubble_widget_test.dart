import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/config/theme/app_theme.dart';
import 'package:daily_life_os/core/widgets/habit_bubble_widget.dart';

/// Renders the compact habit row at a given logical width and default font
/// scale, the way it appears inside the Today Hub grouped card.
Future<void> _pumpRow(
  WidgetTester tester, {
  required double width,
  bool isDone = false,
  String? reminderTime,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Padding(
          // Same 20dp page gutter the Today Hub uses around its cards.
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: HabitBubbleWidget(
            title: 'Drink 3L Water',
            description: 'Stay hydrated throughout the day.',
            icon: Icons.water_drop_rounded,
            streakDays: 14,
            isDone: isDone,
            tintColor: Colors.blue,
            category: 'Health',
            scheduleLabel: 'Every day',
            reminderEnabled: reminderTime != null,
            reminderTime: reminderTime,
            recentWeekDots: const [true, true, true, true, true, true, true],
            onTap: () {},
            onDetailTap: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

RenderParagraph _metaParagraph(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (w) => w is Text && w.textSpan != null && w.maxLines == 1,
  );
  expect(finder, findsOneWidget);
  return tester.renderObject<RenderParagraph>(finder);
}

void main() {
  // Load the app's real font so text metrics match the device; the test
  // fallback font draws every glyph as a full-width square, which would make
  // the "fits on one line" assertions meaningless.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final data = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final loader = FontLoader('Inter')..addFont(Future.value(data));
    await loader.load();
  });

  testWidgets('meta line fits on one line at 360dp without truncation', (
    tester,
  ) async {
    await _pumpRow(tester, width: 360, isDone: true);

    expect(tester.takeException(), isNull);
    expect(find.text('Drink 3L Water'), findsOneWidget);
    expect(_metaParagraph(tester).didExceedMaxLines, isFalse);
    expect(find.textContaining('Done today'), findsOneWidget);
  });

  testWidgets('streak pill and 7-day dots stack in the trailing column', (
    tester,
  ) async {
    await _pumpRow(tester, width: 360);

    final pill = tester.getRect(find.text('14d'));
    final title = tester.getRect(find.text('Drink 3L Water'));
    // The streak pill sits to the right of the title on the same first line.
    expect(pill.left, greaterThan(title.right));
    expect(pill.top, lessThan(title.bottom));

    // Row stays compact: at most three lines of text.
    final row = tester.getSize(find.byType(HabitBubbleWidget));
    expect(row.height, lessThan(84));
  });

  testWidgets('lays out without overflow on a 320dp viewport', (tester) async {
    await _pumpRow(tester, width: 320, reminderTime: '07:00 AM');

    expect(tester.takeException(), isNull);
    expect(find.text('Drink 3L Water'), findsOneWidget);
    expect(find.text('14d'), findsOneWidget);
  });
}
