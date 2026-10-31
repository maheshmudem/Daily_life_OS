import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../core/widgets/quick_capture_sheet.dart';
import '../../domain/entities/money_category.dart';
import '../bloc/money_bloc.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/balance_trend_card.dart';
import '../widgets/budget_progress_tile.dart';
import '../widgets/edit_limit_sheet.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => MoneyShellScope.handleBack(context),
        ),
        titleSpacing: 0,
        title: const Text(
          StringConstants.navMoney,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          BlocBuilder<MoneyBloc, MoneyState>(
            builder: (context, state) {
              if (state is! MoneyLoaded) return const SizedBox.shrink();
              return MonthSelectorChip(
                selectedMonth: state.selectedMonth,
                onChanged: (m) => context.read<MoneyBloc>().add(ChangeMonth(m)),
              );
            },
          ),
          IconButton(
            tooltip: StringConstants.quickCaptureTitle,
            icon: const Icon(Icons.bolt_rounded, size: 20),
            onPressed: () =>
                QuickCaptureSheet.show(context, mode: QuickCaptureMode.text),
          ),
          IconButton(
            tooltip: StringConstants.moneySettings,
            icon: const Icon(Icons.tune_rounded, size: 19),
            onPressed: () => MoneySettingsSheet.show(context),
          ),
        ],
      ),
      body: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          if (state is MoneyLoading || state is MoneyInitial) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                AppShimmerLoader.card(height: 180),
                SizedBox(height: 14),
                AppShimmerLoader.card(height: 120),
                SizedBox(height: 14),
                AppShimmerLoader.card(height: 180),
              ],
            );
          }
          if (state is MoneyError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is MoneyLoaded) {
            return Column(
              children: [
                // Sub-view organizer pills so every feature is clearly labeled & 1 tap away
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: _buildSubViewBar(state, isDark),
                ),
                Expanded(child: _buildActiveSubView(context, state, isDark)),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSubViewBar(MoneyLoaded state, bool isDark) {
    final tabs = [
      (icon: Icons.dashboard_outlined, label: 'Dashboard'),
      (
        icon: Icons.autorenew_rounded,
        label: StringConstants.subscriptionsShort,
      ),
      (icon: Icons.swap_horiz_rounded, label: StringConstants.lendAndBorrow),
      (icon: Icons.shield_outlined, label: 'Safe Spend'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
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
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkSurface : AppColors.surface),
                  borderRadius: AppRadius.radiusFull,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.border),
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
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  double _computeSpentToday(MoneyLoaded state) {
    final now = DateTime.now();
    return state.allTransactions
        .where((t) => t.isExpense && AppDateUtils.isSameDay(t.dateTime, now))
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  Widget _buildActiveSubView(
    BuildContext context,
    MoneyLoaded state,
    bool isDark,
  ) {
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
            _buildCategoryPills(context, isDark),
            const SizedBox(height: 18),
            TotalAssetsCard(
              insights: state.insights,
              onManageAccounts: () => MoneyAccountsSheet.show(context),
            ),
            const SizedBox(height: 18),
            const MoneySectionHeader(title: StringConstants.moneyTools),
            _buildCompactToolsGrid(context, state, isDark),
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
                      children: _buildMainColumn(context, state, isDark),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(10, 6, 20, 32),
                      children: _buildSideColumn(context, state, isDark),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
              children: [
                ..._buildMainColumn(context, state, isDark),
                const SizedBox(height: 22),
                ..._buildSideColumn(context, state, isDark),
              ],
            );
          },
        );
    }
  }

  List<Widget> _buildMainColumn(
    BuildContext context,
    MoneyLoaded state,
    bool isDark,
  ) {
    final scope = MoneyShellScope.maybeOf(context);
    final recent = state.transactions.take(6).toList();
    final spentToday = _computeSpentToday(state);

    return [
      // 1. Balance & 14-day Trend LineChart + centered balance + 3 action buttons
      BalanceTrendCard(
        insights: state.insights,
        onAddExpense: () =>
            AddTransactionSheet.show(context, initialType: 'expense'),
        onAddIncome: () =>
            AddTransactionSheet.show(context, initialType: 'income'),
        onOpenInsights: () => scope?.selectTab(MoneyTab.insights),
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

      // 3. Budget & Savings Report (Where you spend most, Savings, How to improve)
      BudgetExpenseReportCard(
        state: state,
        spentToday: spentToday,
        onOpenSalaryPlan: () =>
            SalaryPlanSetupSheet.show(context, state: state),
      ),
      const SizedBox(height: 14),

      // 4. Quick Category Logging horizontal strip
      _buildCategoryPills(context, isDark),
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
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              'No transactions yet. Tap + Add to record one.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ),
        )
      else
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 68,
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
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

  List<Widget> _buildSideColumn(
    BuildContext context,
    MoneyLoaded state,
    bool isDark,
  ) {
    final scope = MoneyShellScope.maybeOf(context);
    return [
      MoneySectionHeader(
        title: state.selectedPeriod.budgetTitle,
        actionLabel: StringConstants.seeAll,
        onAction: () => scope?.selectTab(MoneyTab.budgets),
      ),
      Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            for (var i = 0; i < state.categoryBudgets.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              BudgetProgressTile(
                budget: state.categoryBudgets[i],
                onTap: () => EditCategoryLimitSheet.show(
                  context,
                  budget: state.categoryBudgets[i],
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _buildCategoryPills(BuildContext context, bool isDark) {
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
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: AppRadius.radiusFull,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon, size: 15, color: cat.color),
                  const SizedBox(width: 5),
                  Text(
                    cat.shortLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
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

  Widget _buildCompactToolsGrid(
    BuildContext context,
    MoneyLoaded state,
    bool isDark,
  ) {
    final items = [
      _ToolItem(
        icon: Icons.autorenew_rounded,
        color: AppColors.primary,
        title: StringConstants.subscriptionsShort,
        subtitle:
            '${state.subscriptions.length} • ${CurrencyUtils.format(state.subscriptionsTotal)}/mo',
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
        subtitle: CurrencyUtils.format(state.insights.totalAssets),
        onTap: () => MoneyAccountsSheet.show(context),
      ),
      _ToolItem(
        icon: Icons.tune_rounded,
        color: AppColors.moduleVault,
        title: StringConstants.moneySettings,
        subtitle: '${state.settings.currencyCode} • Alerts',
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
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: AppRadius.borderMd,
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: AppRadius.borderMd,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
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
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
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
