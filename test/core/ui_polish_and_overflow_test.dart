import 'package:daily_life_os/config/theme/app_theme.dart';
import 'package:daily_life_os/core/widgets/animated_count_text.dart';
import 'package:daily_life_os/core/widgets/feature_scaffold.dart';
import 'package:daily_life_os/core/widgets/staggered_fade_slide.dart';
import 'package:daily_life_os/features/money/domain/entities/transaction_entity.dart';
import 'package:daily_life_os/features/money/presentation/widgets/safe_to_spend_hero_card.dart';
import 'package:daily_life_os/features/money/presentation/widgets/transaction_tile.dart';
import 'package:daily_life_os/features/navigation/presentation/widgets/os_quick_launch_dock.dart';
import 'package:daily_life_os/features/planner/domain/entities/countdown_item_entity.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/countdown_card.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/pomodoro_focus_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrapNarrow(Widget child, {double width = 320}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('Flagship UI Motion & Zero-Overflow Polish Tests', () {
    testWidgets('AnimatedCountText animates and settles at target value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapNarrow(
          AnimatedCountText(
            value: 1450,
            formatter: (v) => '₹${v.toStringAsFixed(0)}',
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('₹1450'), findsOneWidget);
    });

    testWidgets(
      'StaggeredFadeSlide and PressableScale settle cleanly without pending timers',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          _wrapNarrow(
            Column(
              children: [
                StaggeredFadeSlide(
                  index: 0,
                  child: PressableScale(
                    onTap: () => tapped = true,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Interactive OS Card'),
                    ),
                  ),
                ),
                const StaggeredFadeSlide(
                  index: 2,
                  child: Text('Second Cascading Card'),
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Interactive OS Card'), findsOneWidget);
        expect(find.text('Second Cascading Card'), findsOneWidget);

        await tester.tap(find.text('Interactive OS Card'));
        await tester.pumpAndSettle();
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'FeatureSectionHeader and OsQuickLaunchDock render on 320px width without overflow',
      (tester) async {
        await tester.pumpWidget(
          _wrapNarrow(
            Column(
              children: [
                FeatureSectionHeader(
                  title:
                      'PENDING LEND & BORROW REMINDERS ACROSS ALL LINKED ACCOUNTS',
                  actionLabel: 'Manage All',
                  onAction: () {},
                ),
                OsQuickLaunchDock(
                  onOpenSpotlight: () {},
                  onNavigateTab: (_) {},
                  onQuickCapture: (_) {},
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('dock_spotlight_pill')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'PomodoroFocusCard with strictMode and 8 rounds renders on 320px width without overflow',
      (tester) async {
        await tester.pumpWidget(
          _wrapNarrow(
            PomodoroFocusCard(
              focusModeIndex: 0,
              strictMode: true,
              currentRound: 4,
              totalRounds: 8,
              timerProgress: 0.65,
              isTimerRunning: false,
              focusCategory: 'Deep Work Architecture',
              formattedTime: '16:15',
              selectedAmbience: 'Rain',
              linkedTask:
                  'Complete full-system UI/UX audit and zero-overflow verification across all 5 modules',
              completedTaskPomodoros: 3,
              estimatedPomodoros: 6,
              onToggleTimer: () {},
              onResetTimer: () {},
              onSkipSession: () {},
              onChangeTask: () {},
              onOpenZenMode: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('STRICT'), findsOneWidget);
        expect(find.text('Round 4/8'), findsOneWidget);
      },
    );

    testWidgets(
      'SafeToSpendHeroCard, TransactionTile, and CountdownCard render long text on 320px width without overflow',
      (tester) async {
        final tx = TransactionEntity(
          id: 1,
          title:
              'Annual Cloud Infrastructure & Domain Renewal Subscription Payment',
          amount: 18450.75,
          date: '2026-11-09T14:30:00',
          category: 'Bills',
          type: 'expense',
          mode: 'UPI',
          iconCodePoint: Icons.receipt_long_rounded.codePoint,
          note:
              'Reimbursable business infrastructure expense for Q4 production cluster',
        );

        const budget = BudgetEntity(
          monthlyBudget: 85000,
          totalSpent: 32000,
          fixedBills: 20000,
        );

        final countdown = CountdownItemEntity(
          id: 'cd_1',
          title:
              'Production v2.0 Global App Store & Play Store Launch Milestone',
          date: DateTime.now().add(const Duration(days: 12)),
          category: 'Milestone',
          iconCodePoint: Icons.rocket_launch_rounded.codePoint,
          colorValue: 0xFF6366F1,
          notes:
              'Ensure all 120+ automated tests pass and zero analyzer warnings remain before tagging release.',
        );

        await tester.pumpWidget(
          _wrapNarrow(
            Column(
              children: [
                SafeToSpendHeroCard(
                  budget: budget,
                  spentToday: 1200,
                  weeklySpend: 6400,
                  onEditBudget: () {},
                  onOpenSalaryPlan: () {},
                ),
                const SizedBox(height: 12),
                TransactionTile(transaction: tx),
                const SizedBox(height: 12),
                CountdownCard(
                  item: countdown,
                  isDark: false,
                  onAddToPlanner: () {},
                  onEdit: () {},
                  onDelete: () {},
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('SAFE-TO-SPEND TODAY'), findsOneWidget);
      },
    );
  });
}
