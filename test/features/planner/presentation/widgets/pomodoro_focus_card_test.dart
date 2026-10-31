import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/pomodoro_focus_card.dart';

void main() {
  testWidgets(
    'PomodoroFocusCard renders mode, timer, linked task, and callbacks',
    (WidgetTester tester) async {
      bool toggled = false;
      bool reset = false;
      bool skipped = false;
      bool changedTask = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PomodoroFocusCard(
              focusModeIndex: 0,
              currentRound: 2,
              totalRounds: 4,
              timerProgress: 0.5,
              formattedTime: '12:30',
              isTimerRunning: false,
              linkedTask: 'Write Documentation',
              onToggleTimer: () => toggled = true,
              onResetTimer: () => reset = true,
              onSkipSession: () => skipped = true,
              onChangeTask: () => changedTask = true,
            ),
          ),
        ),
      );

      // Verify elements rendered
      expect(find.text('⚡ DEEP WORK SPRINT'), findsOneWidget);
      expect(find.text('Round 2/4'), findsOneWidget);
      expect(find.text('12:30'), findsOneWidget);
      expect(find.text('Ready to start'), findsOneWidget);
      expect(find.textContaining('Write Documentation'), findsOneWidget);
      expect(find.text('Start Focus'), findsOneWidget);

      // Test tap on Start Focus
      await tester.tap(find.text('Start Focus'));
      expect(toggled, isTrue);

      // Test tap on Reset
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      expect(reset, isTrue);

      // Test tap on Skip
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      expect(skipped, isTrue);

      // Test tap on Linked Task
      await tester.tap(find.textContaining('Write Documentation'));
      expect(changedTask, isTrue);
    },
  );
}
