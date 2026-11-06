import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/features/planner/domain/entities/planner_item_entity.dart';
import 'package:daily_life_os/features/planner/domain/entities/pomodoro_entities.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/pomodoro_analytics_card.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/pomodoro_focus_card.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/pomodoro_mode_selector.dart';

void main() {
  testWidgets(
    'PomodoroFocusCard renders mode, timer, linked task, and callbacks',
    (WidgetTester tester) async {
      bool toggled = false;
      bool reset = false;
      bool skipped = false;
      bool changedTask = false;
      int boostedMinutes = 0;

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
              strictMode: true,
              onToggleTimer: () => toggled = true,
              onResetTimer: () => reset = true,
              onSkipSession: () => skipped = true,
              onChangeTask: () => changedTask = true,
              onAddMinutes: (m) => boostedMinutes += m,
            ),
          ),
        ),
      );

      // Verify elements rendered
      expect(find.text('⚡ DEEP WORK SPRINT'), findsOneWidget);
      expect(find.text('STRICT'), findsOneWidget);
      expect(find.text('Round 2/4'), findsOneWidget);
      expect(find.text('12:30'), findsOneWidget);
      expect(find.text('Ready to start'), findsOneWidget);
      expect(find.textContaining('Write Documentation'), findsOneWidget);
      expect(find.text('Start Focus'), findsOneWidget);

      // Test tap on +5m boost
      await tester.tap(find.text('+5m'));
      expect(boostedMinutes, 5);

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

  testWidgets(
    'PomodoroFocusCard supports Flowtime Stopwatch mode and linked subtasks',
    (WidgetTester tester) async {
      bool finishedFlow = false;
      ChecklistItem? toggledSubtask;

      final linkedTaskEntity = PlannerItemEntity(
        id: 42,
        title: 'Build Pomodoro 2.0',
        date: '2026-11-06',
        category: 'Work',
        colorValue: 0xFFF59E0B,
        iconCodePoint: Icons.bolt_rounded.codePoint,
        isDone: false,
        notes: '',
        checklist: const [
          ChecklistItem(id: 'sub1', title: 'Design radial dial', isDone: true),
          ChecklistItem(
            id: 'sub2',
            title: 'Add 7-day trend chart',
            isDone: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  PomodoroModeSelector(
                    selectedIndex: 3,
                    workMinutes: 25,
                    shortBreakMinutes: 5,
                    longBreakMinutes: 15,
                    onModeSelected: (_) {},
                    isDark: false,
                  ),
                  PomodoroFocusCard(
                    focusModeIndex: 3,
                    currentRound: 1,
                    totalRounds: 4,
                    timerProgress: 0.25,
                    formattedTime: '15:00',
                    isTimerRunning: false,
                    linkedTask: 'Build Pomodoro 2.0',
                    linkedPlannerItem: linkedTaskEntity,
                    onToggleTimer: () {},
                    onResetTimer: () {},
                    onSkipSession: () {},
                    onChangeTask: () {},
                    onFinishStopwatch: () => finishedFlow = true,
                    onToggleSubtask: (sub) => toggledSubtask = sub,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('♾️ FLOW STOPWATCH'), findsOneWidget);
      expect(find.text('Flow ⏱'), findsOneWidget);
      expect(find.text('Finish & Log Flow'), findsOneWidget);
      expect(find.text('Subtasks 1/2'), findsOneWidget);

      await tester.tap(find.text('Finish & Log Flow'));
      expect(finishedFlow, isTrue);

      // Expand subtasks and toggle one
      await tester.tap(find.text('Subtasks 1/2'));
      await tester.pumpAndSettle();
      expect(find.text('Add 7-day trend chart'), findsOneWidget);

      await tester.tap(find.text('Add 7-day trend chart'));
      expect(toggledSubtask?.id, 'sub2');
    },
  );

  testWidgets(
    'PomodoroAnalyticsDashboard renders 7-day trend, distraction pad, and session history',
    (WidgetTester tester) async {
      String? addedDistraction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PomodoroAnalyticsDashboard(
                sessions: FocusSessionEntity.defaultSeedSessions(),
                distractions: [
                  FocusDistractionItem(
                    id: 'd1',
                    text: 'Reply to design feedback',
                    createdAt: DateTime.now(),
                  ),
                ],
                dailyGoalSessions: 4,
                workMinutes: 25,
                isDark: false,
                onOpenManualLog: () {},
                onDeleteSession: (_) {},
                onAddDistraction: (txt) => addedDistraction = txt,
                onConvertDistractionToTask: (_) {},
                onDeleteDistraction: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Daily Focus Activity'), findsOneWidget);
      expect(find.text('7-Day Focus Trend & Categories'), findsOneWidget);
      expect(find.text('Distraction Blocker & Brain Dump'), findsOneWidget);
      expect(find.text('Reply to design feedback'), findsOneWidget);
      expect(find.text('Recent Focus Sessions'), findsOneWidget);
      expect(find.textContaining('more sessions)'), findsOneWidget);

      await tester.ensureVisible(find.text('Park'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Check flight tickets');
      await tester.tap(find.text('Park'));
      expect(addedDistraction, 'Check flight tickets');

      // Scroll to and tap "Show more (... more sessions)" to expand all sessions
      final showMoreFinder = find.textContaining('more sessions)');
      await tester.ensureVisible(showMoreFinder);
      await tester.pumpAndSettle();
      await tester.tap(showMoreFinder);
      await tester.pumpAndSettle();
      expect(find.text('Show less sessions'), findsOneWidget);
    },
  );
}
