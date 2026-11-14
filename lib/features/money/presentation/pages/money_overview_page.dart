import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/expandable_text_widget.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../../quick_capture/presentation/widgets/quick_capture_sheet.dart';
import '../../domain/entities/money_category.dart';
import '../bloc/money_bloc.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/account_transfer_sheet.dart';
import '../widgets/balance_trend_card.dart';
import '../widgets/bill_split_sheet.dart';
import '../widgets/budget_progress_tile.dart';
import '../widgets/edit_limit_sheet.dart';
import '../widgets/money_report_sheet.dart';
import '../widgets/money_section_header.dart';
import '../widgets/money_shell_scope.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/safe_to_spend_hero_card.dart';
import '../widgets/salary_plan_coach_card.dart';
import '../widgets/total_assets_card.dart';
import '../widgets/transaction_tile.dart';
import 'money_tools_sheets.dart';

/// Money Tab 0 — Overview:
/// Clean, compact home screen modeled after `docs/expensetracker-main/lib/screens/home_screen.dart`
/// while organizing all existing Daily Life OS features (`Safe-to-Spend Today`,
/// `Quick Category Logging`, `Subscriptions & Auto-Kill`, `Lend & Borrow IOU`,
/// `Accounts`, and `Settings`) into a clear sub-view switcher + grouped cards.
class MoneyOverviewPage extends StatefulWidget {
  const MoneyOverviewPage({super.key});

  @override
  State<MoneyOverviewPage> createState() => _MoneyOverviewPageState();
}

class _MoneyOverviewPageState extends State<MoneyOverviewPage> {
  /// 0 = Dashboard, 1 = Subscriptions, 2 = Lend & Borrow (IOU), 3 = Safe Spend & Tools
  int _subView = 0;
  bool _showAllBudgets = false;
  bool _showAllIous = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoneyBloc, MoneyState>(
      builder: (context, state) => FeatureScaffold(
        title: StringConstants.navMoney,
        onBack: () => MoneyShellScope.handleBack(context),
        accentColor: AppColors.moduleMoney,
        actionsEndPadding: AppSpacing.pageGutter,
        actions: [
          FeatureIconButton(
            tooltip: StringConstants.transfer,
            icon: Icons.swap_horiz_rounded,
            onPressed: () => AccountTransferSheet.show(context),
          ),
          const SizedBox(width: 8),
          FeatureIconButton(
            tooltip: StringConstants.financialStatementTitle,
            icon: Icons.assessment_outlined,
            onPressed: () => MoneyReportSheet.show(context),
          ),
          const SizedBox(width: 8),
          FeatureIconButton(
            tooltip: StringConstants.quickCaptureTitle,
            icon: Icons.bolt_rounded,
            onPressed: () =>
                QuickCaptureSheet.show(context, mode: QuickCaptureMode.text),
          ),
          const SizedBox(width: 8),
          FeatureIconButton(
            tooltip: StringConstants.moneySettings,
            icon: Icons.tune_rounded,
            onPressed: () => MoneySettingsSheet.show(context),
          ),
        ],
        status: moneyFeatureStatus(state),
        errorMessage: state is MoneyError ? state.message : null,
        onRetry: () => context.read<MoneyBloc>().add(const LoadMoney()),
        loading: const FeatureLoadingView(blockHeights: [40, 180, 120, 180]),
        builder: (context) {
          final loaded = state as MoneyLoaded;
          return Column(
            children: [
              // Top control bar: Month selector on left, scrollable sub-view pills on right
              _buildTopControlBar(context, loaded),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey('money_subview_$_subView'),
                    child: _buildActiveSubView(context, loaded),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopControlBar(BuildContext context, MoneyLoaded state) {
    final palette = context.palette;
    final text = context.text;
    final tabs = [
      (icon: Icons.dashboard_outlined, label: 'Dashboard'),
      (
        icon: Icons.autorenew_rounded,
        label: StringConstants.subscriptionsShort,
      ),
      (icon: Icons.swap_horiz_rounded, label: StringConstants.lendAndBorrow),
      (icon: Icons.shield_outlined, label: 'Safe Spend'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        4,
        AppSpacing.pageGutter,
        8,
      ),
      child: Row(
        children: [
          MonthSelectorChip(
            selectedMonth: state.selectedMonth,
            onChanged: (m) => context.read<MoneyBloc>().add(ChangeMonth(m)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (idx) {
                  final isSelected = _subView == idx;
                  final tab = tabs[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _subView = idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : palette.card,
                          borderRadius: AppRadius.radiusFull,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : palette.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : palette.secondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tab.label,
                              style: text.labelMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : palette.heading,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _computeSpentToday(MoneyLoaded state) {
    final now = DateTime.now();
    return state.allTransactions
        .where((t) => t.isExpense && AppDateUtils.isSameDay(t.dateTime, now))
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  Widget _buildActiveSubView(BuildContext context, MoneyLoaded state) {
    final spentToday = _computeSpentToday(state);
    switch (_subView) {
      case 1:
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            MoneySectionHeader(
              title: StringConstants.subscriptions,
              actionLabel: 'Manage / Add',
              onAction: () => SubscriptionsSheet.show(context),
            ),
            SubscriptionsContent(
              subscriptions: state.subscriptions,
              onAddTap: () => SubscriptionsSheet.show(context),
            ),
          ],
        );
      case 2:
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            MoneySectionHeader(
              title: StringConstants.lendAndBorrow,
              actionLabel: StringConstants.addIou,
              onAction: () => IouSheet.show(context),
            ),
            IouContent(
              ious: state.ious,
              onAddTap: () => IouSheet.show(context),
            ),
          ],
        );
      case 3:
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            SafeToSpendHeroCard(
              budget: state.budget,
              spentToday: spentToday,
              weeklySpend: state.insights.currentWeekSpend,
              onOpenSalaryPlan: () =>
                  SalaryPlanSetupSheet.show(context, state: state),
              onEditBudget: () =>
                  EditSafeSpendSheet.show(context, budget: state.budget),
            ),
            const SizedBox(height: 14),
            BudgetExpenseReportCard(
              state: state,
              spentToday: spentToday,
              onOpenSalaryPlan: () =>
                  SalaryPlanSetupSheet.show(context, state: state),
            ),
            const SizedBox(height: 16),
            const MoneySectionHeader(
              title: StringConstants.quickCategoryLogging,
            ),
            _buildCategoryPills(context),
            const SizedBox(height: 18),
            TotalAssetsCard(
              insights: state.insights,
              onManageAccounts: () => MoneyAccountsSheet.show(context),
            ),
            const SizedBox(height: 18),
            const MoneySectionHeader(title: StringConstants.moneyTools),
            _buildCompactToolsGrid(context, state),
          ],
        );
      default:
        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 680;
            if (isTablet) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 6, 10, 32),
                      children: _buildMainColumn(context, state),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(10, 6, 20, 32),
                      children: _buildSideColumn(context, state),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
              children: [
                ..._buildMainColumn(context, state),
                const SizedBox(height: 22),
                ..._buildSideColumn(context, state),
              ],
            );
          },
        );
    }
  }

  List<Widget> _buildMainColumn(BuildContext context, MoneyLoaded state) {
    final palette = context.palette;
    final text = context.text;
    final scope = MoneyShellScope.maybeOf(context);
    final recent = state.transactions.take(6).toList();
    final spentToday = _computeSpentToday(state);

    return [
      // 0. Guided Setup Banner when starting fresh (no salary/budget or transactions yet)
      if (state.transactions.isEmpty && state.budget.monthlyBudget <= 0) ...[
        _buildGuidedSetupCard(context, state),
        const SizedBox(height: 14),
      ],

      // 1. Balance & 14-day Trend LineChart + 2x2 snapshot + action buttons
      BalanceTrendCard(
        insights: state.insights,
        onAddExpense: () =>
            AddTransactionSheet.show(context, initialType: 'expense'),
        onAddIncome: () =>
            AddTransactionSheet.show(context, initialType: 'income'),
        onOpenInsights: () => scope?.selectTab(MoneyTab.insights),
        onOpenAiSimulator: () =>
            AiAffordabilitySheet.show(context, state: state),
        onOpenIou: () => IouSheet.show(context),
      ),
      const SizedBox(height: 14),

      // 2. Compact Safe-to-Spend Today & Daily/7-Day Budget card
      SafeToSpendHeroCard(
        budget: state.budget,
        spentToday: spentToday,
        weeklySpend: state.insights.currentWeekSpend,
        onOpenSalaryPlan: () =>
            SalaryPlanSetupSheet.show(context, state: state),
        onEditBudget: () =>
            EditSafeSpendSheet.show(context, budget: state.budget),
      ),
      const SizedBox(height: 12),

      // 3. Pending Lend & Borrow (To Collect / To Pay) & Due Reminders Card
      _buildPendingIouAndAlertsCard(context, state),
      const SizedBox(height: 12),

      // 4. Budget & Savings Report (Where you spend most, Savings, How to improve)
      BudgetExpenseReportCard(
        state: state,
        spentToday: spentToday,
        onOpenSalaryPlan: () =>
            SalaryPlanSetupSheet.show(context, state: state),
      ),
      const SizedBox(height: 14),

      // 4. Quick Category Logging horizontal strip
      _buildCategoryPills(context),
      const SizedBox(height: 18),

      // 4. Recent Transactions inside ONE grouped card with indented dividers
      MoneySectionHeader(
        title: StringConstants.recentTransactions,
        actionLabel: StringConstants.seeAll,
        onAction: () => scope?.selectTab(MoneyTab.activity),
      ),
      if (recent.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: palette.border),
          ),
          child: Center(
            child: Text(
              'No transactions yet. Tap + Add to record one.',
              style: text.bodySmall?.copyWith(
                fontSize: 13,
                color: palette.caption,
              ),
            ),
          ),
        )
      else
        Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: palette.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, indent: 68, color: palette.border),
                TransactionTile(
                  transaction: recent[i],
                  showCard: false,
                  onTap: () =>
                      AddTransactionSheet.show(context, existing: recent[i]),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildSideColumn(BuildContext context, MoneyLoaded state) {
    final palette = context.palette;
    final text = context.text;
    final scope = MoneyShellScope.maybeOf(context);
    final allBudgets = state.categoryBudgets;
    final visibleBudgets = (_showAllBudgets || allBudgets.length <= 4)
        ? allBudgets
        : allBudgets.take(4).toList();

    return [
      MoneySectionHeader(
        title: state.selectedPeriod.budgetTitle,
        actionLabel: StringConstants.seeAll,
        onAction: () => scope?.selectTab(MoneyTab.budgets),
      ),
      Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: palette.border),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              for (var i = 0; i < visibleBudgets.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: palette.border,
                  ),
                BudgetProgressTile(
                  budget: visibleBudgets[i],
                  onTap: () => EditCategoryLimitSheet.show(
                    context,
                    budget: visibleBudgets[i],
                  ),
                ),
              ],
              if (allBudgets.length > 4) ...[
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: palette.border,
                ),
                InkWell(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  onTap: () =>
                      setState(() => _showAllBudgets = !_showAllBudgets),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showAllBudgets
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showAllBudgets
                              ? 'Show top 4 categories'
                              : 'Show all ${allBudgets.length} categories',
                          style: text.labelMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildGuidedSetupCard(BuildContext context, MoneyLoaded state) {
    final palette = context.palette;
    final text = context.text;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Fresh: 3 Simple Steps',
                      style: text.titleSmall?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: palette.heading,
                      ),
                    ),
                    Text(
                      'Set up your monthly income, budget, expenses & reminders',
                      style: text.labelSmall?.copyWith(
                        fontSize: 11,
                        color: palette.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSetupStepTile(
            context: context,
            step: '1',
            title: 'Add Monthly Salary or Income',
            subtitle: 'Record your salary or incoming money first',
            buttonLabel: '+ Salary',
            color: AppColors.success,
            onTap: () => AddTransactionSheet.show(
              context,
              initialType: 'income',
              initialCategory: MoneyCategory.salary,
            ),
          ),
          const SizedBox(height: 8),
          _buildSetupStepTile(
            context: context,
            step: '2',
            title: 'Set Smart Budget & Fixed Bills',
            subtitle: 'Auto-calculate your daily & weekly safe spend',
            buttonLabel: 'Set Plan',
            color: AppColors.primary,
            onTap: () => SalaryPlanSetupSheet.show(context, state: state),
          ),
          const SizedBox(height: 8),
          _buildSetupStepTile(
            context: context,
            step: '3',
            title: 'Track Lent / Borrowed Money & Reminders',
            subtitle: 'Log money given to collect back or borrowed to pay',
            buttonLabel: '+ Lend/Borrow',
            color: AppColors.moduleTime,
            onTap: () => IouSheet.showAddDialog(context, initialType: 'lent'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStepTile({
    required BuildContext context,
    required String step,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;
    final text = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: text.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  softWrap: true,
                  style: text.labelLarge?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.heading,
                  ),
                ),
                Text(
                  subtitle,
                  softWrap: true,
                  style: text.labelSmall?.copyWith(
                    fontSize: 10.5,
                    color: palette.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                buttonLabel,
                style: text.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingIouAndAlertsCard(
    BuildContext context,
    MoneyLoaded state,
  ) {
    final palette = context.palette;
    final text = context.text;
    final activeIous = state.ious.where((i) => !i.isSettled).toList();
    final lentIous = activeIous.where((i) => i.isLent).toList();
    final borrowedIous = activeIous.where((i) => !i.isLent).toList();
    final totalLent = lentIous.fold<double>(0, (s, i) => s + i.amount);
    final totalBorrowed = borrowedIous.fold<double>(0, (s, i) => s + i.amount);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.moduleTime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: AppColors.moduleTime,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Lend & Borrow Reminders',
                      softWrap: true,
                      style: text.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.heading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track money given (to collect) & borrowed (to pay)',
                      softWrap: true,
                      style: text.labelSmall?.copyWith(
                        fontSize: 11.5,
                        color: palette.caption,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => BillSplitSheet.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    StringConstants.billSplitShort,
                    style: text.labelSmall?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.moduleMoney,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => IouSheet.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    'Manage',
                    style: text.labelSmall?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Summary Row: To Collect vs To Pay Back
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () =>
                      IouSheet.showAddDialog(context, initialType: 'lent'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.moduleMoney.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.moduleMoney.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'To Collect (Lent)',
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.moduleMoney,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 14,
                              color: AppColors.moduleMoney,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyUtils.format(totalLent),
                            style: text.titleSmall?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: palette.heading,
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${lentIous.length} pending • Tap + to add',
                            style: text.labelSmall?.copyWith(
                              fontSize: 9.5,
                              color: palette.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () =>
                      IouSheet.showAddDialog(context, initialType: 'borrowed'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'To Pay (Borrowed)',
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 14,
                              color: AppColors.error,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyUtils.format(totalBorrowed),
                            style: text.titleSmall?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: palette.heading,
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${borrowedIous.length} pending • Tap + to add',
                            style: text.labelSmall?.copyWith(
                              fontSize: 9.5,
                              color: palette.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Active Pending IOUs List (progressive disclosure with ExpandableTextWidget)
          if (activeIous.isNotEmpty) ...[
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Column(
                children: [
                  ...(_showAllIous ? activeIous : activeIous.take(2)).map((
                    iou,
                  ) {
                    final color = iou.isLent
                        ? AppColors.moduleMoney
                        : AppColors.error;
                    final dueBadge = iou.dueBadgeLabel;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              iou.isLent
                                  ? Icons.call_made_rounded
                                  : Icons.call_received_rounded,
                              size: 15,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    iou.isLent
                                        ? 'Collect from ${iou.person}'
                                        : 'Pay back ${iou.person}',
                                    softWrap: true,
                                    style: text.labelLarge?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: palette.heading,
                                    ),
                                  ),
                                  ExpandableTextWidget(
                                    text: dueBadge != null
                                        ? '$dueBadge • ${iou.cleanNote}'
                                        : iou.cleanNote,
                                    collapsedMaxLines: 1,
                                    style: text.labelSmall?.copyWith(
                                      fontSize: 10.5,
                                      color: iou.isOverdue
                                          ? AppColors.error
                                          : palette.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyUtils.format(iou.amount),
                              style: text.labelLarge?.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                context.read<MoneyBloc>().add(
                                  SettleIou(iou.id),
                                );
                                SnackbarUtils.showSuccess(
                                  context,
                                  iou.isLent
                                      ? 'Marked ${CurrencyUtils.format(iou.amount)} collected from ${iou.person}!'
                                      : 'Marked ${CurrencyUtils.format(iou.amount)} paid to ${iou.person}!',
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  iou.isLent ? 'Collected' : 'Paid',
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (activeIous.length > 2)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _showAllIous = !_showAllIous),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showAllIous
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showAllIous
                                  ? 'Show less'
                                  : 'Show all (${activeIous.length} pending)',
                              style: text.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryPills(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MoneyCategory.expenseCategories.map((cat) {
          return GestureDetector(
            onTap: () =>
                AddTransactionSheet.show(context, initialCategory: cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: AppRadius.radiusFull,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon, size: 15, color: cat.color),
                  const SizedBox(width: 5),
                  Text(
                    cat.shortLabel,
                    style: text.labelMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.heading,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactToolsGrid(BuildContext context, MoneyLoaded state) {
    final palette = context.palette;
    final text = context.text;
    final items = [
      _ToolItem(
        icon: Icons.autorenew_rounded,
        color: AppColors.primary,
        title: StringConstants.subscriptionsShort,
        subtitle:
            '${state.subscriptions.length} • ${CurrencyUtils.format(state.subscriptionsTotal, decimals: 0)}/mo',
        onTap: () => SubscriptionsSheet.show(context),
      ),
      _ToolItem(
        icon: Icons.swap_horiz_rounded,
        color: AppColors.moduleTime,
        title: StringConstants.lendAndBorrow,
        subtitle: '${state.ious.length} active IOUs',
        onTap: () => IouSheet.show(context),
      ),
      _ToolItem(
        icon: Icons.account_balance_rounded,
        color: AppColors.moneyAssetCash,
        title: StringConstants.accounts,
        subtitle: CurrencyUtils.format(state.insights.totalAssets, decimals: 0),
        onTap: () => MoneyAccountsSheet.show(context),
      ),
      _ToolItem(
        icon: Icons.compare_arrows_rounded,
        color: AppColors.moduleMoney,
        title: StringConstants.transfer,
        subtitle: '${state.accounts.length} accounts',
        onTap: () => AccountTransferSheet.show(context),
      ),
      _ToolItem(
        icon: Icons.call_split_rounded,
        color: AppColors.moduleTime,
        title: StringConstants.billSplitShort,
        subtitle: 'Split & auto-IOU',
        onTap: () => BillSplitSheet.show(context),
      ),
      _ToolItem(
        icon: Icons.assessment_outlined,
        color: AppColors.primary,
        title: StringConstants.reports,
        subtitle: state.selectedPeriod.label,
        onTap: () => MoneyReportSheet.show(context),
      ),
      _ToolItem(
        icon: Icons.tune_rounded,
        color: AppColors.moduleVault,
        title: StringConstants.moneySettings,
        subtitle: '${state.settings.currencyCode} • Security',
        onTap: () => MoneySettingsSheet.show(context),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 70,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: AppRadius.borderMd,
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: 16, color: item.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.title,
                          style: text.titleSmall?.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: palette.heading,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.subtitle,
                          maxLines: 1,
                          style: text.labelSmall?.copyWith(
                            fontSize: 11.5,
                            color: palette.caption,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ToolItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
