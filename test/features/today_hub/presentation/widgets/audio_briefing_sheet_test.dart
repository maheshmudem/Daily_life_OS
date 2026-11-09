import 'package:daily_life_os/config/theme/app_theme.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/features/money/domain/usecases/get_transactions_and_budget_usecase.dart';
import 'package:daily_life_os/features/today_hub/domain/entities/habit_entity.dart';
import 'package:daily_life_os/features/today_hub/domain/entities/timeline_item_entity.dart';
import 'package:daily_life_os/features/today_hub/presentation/widgets/audio_briefing_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioBriefingSheet Widget Tests', () {
    final sampleHabits = [
      const HabitEntity(
        id: 1,
        title: 'Morning Hydration',
        description: 'Drink 500ml water',
        iconCodePoint: 0xe798,
        colorValue: 0xFF6366F1,
        streakDays: 12,
        isDoneToday: true,
        createdAt: '2026-01-01',
        category: 'Health',
      ),
      const HabitEntity(
        id: 2,
        title: 'Deep Reading',
        description: 'Read 20 pages',
        iconCodePoint: 0xe865,
        colorValue: 0xFF10B981,
        streakDays: 5,
        isDoneToday: false,
        createdAt: '2026-01-01',
        category: 'Mind',
      ),
    ];

    final sampleTimeline = [
      const TimelineItemEntity(
        id: 1,
        time: '09:30 AM',
        title: 'Architecture Review',
        category: 'Work',
        action: 'Join',
        iconCodePoint: 0xe8f9,
        colorValue: 0xFF6366F1,
        isDone: false,
        date: '2026-10-25',
      ),
      const TimelineItemEntity(
        id: 2,
        time: '07:00 AM',
        title: 'Morning Mobility',
        category: 'Health',
        action: 'Done',
        iconCodePoint: 0xe566,
        colorValue: 0xFF10B981,
        isDone: true,
        date: '2026-10-25',
      ),
    ];

    const sampleSpend = DailySpendSnapshot(
      spentToday: 450,
      dailySafeLimit: 1500,
      monthlyBudget: 40000,
      daysRemaining: 14,
    );

    testWidgets(
      'renders all 4 activity briefing sections and supports section selection and speed toggle',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => AudioBriefingSheet.show(
                      context,
                      habits: sampleHabits,
                      timelineItems: sampleTimeline,
                      spendSnapshot: sampleSpend,
                    ),
                    child: const Text('Open Brief'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Brief'));
        await tester.pumpAndSettle();

        // Verify sheet header and all 4 activity sections are visible
        expect(
          find.text(StringConstants.audioBriefingSheetTitle),
          findsOneWidget,
        );
        expect(
          find.text(StringConstants.audioBriefOverviewTitle),
          findsOneWidget,
        );
        expect(
          find.text(StringConstants.audioBriefHabitsTitle),
          findsOneWidget,
        );
        expect(
          find.text(StringConstants.audioBriefScheduleTitle),
          findsOneWidget,
        );
        expect(find.text(StringConstants.audioBriefMoneyTitle), findsOneWidget);

        // Verify specific activity details appear in the brief
        expect(find.textContaining('Morning Hydration'), findsWidgets);
        expect(find.textContaining('Deep Reading'), findsWidgets);
        expect(find.textContaining('Architecture Review'), findsWidgets);

        // Tap Habits section to focus on that specific section
        final habitsSectionFinder = find.byKey(
          const ValueKey('audio_brief_section_habits'),
        );
        await tester.ensureVisible(habitsSectionFinder);
        await tester.pumpAndSettle();
        await tester.tap(habitsSectionFinder);
        await tester.pumpAndSettle();

        expect(find.text(StringConstants.audioBriefPlayAll), findsOneWidget);

        // Cycle speed button: 1x -> 1.25x -> 1.5x -> 1x
        final speedBtn = find.byKey(
          const ValueKey('audio_briefing_speed_button'),
        );
        expect(find.text('1x'), findsOneWidget);

        await tester.tap(speedBtn);
        await tester.pumpAndSettle();
        expect(find.text('1.25x'), findsOneWidget);

        await tester.tap(speedBtn);
        await tester.pumpAndSettle();
        expect(find.text('1.5x'), findsOneWidget);

        await tester.tap(speedBtn);
        await tester.pumpAndSettle();
        expect(find.text('1x'), findsOneWidget);
      },
    );
  });
}
