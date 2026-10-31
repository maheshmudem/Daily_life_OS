import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../bloc/money_bloc.dart';
import '../widgets/cashflow_overview_cards.dart';
import '../widgets/category_breakdown_card.dart';
import '../widgets/money_section_header.dart';
import '../widgets/money_shell_scope.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/period_selector_bar.dart';
import '../widgets/salary_plan_coach_card.dart';
import '../widgets/spent_summary_chart_card.dart';
import '../widgets/total_assets_card.dart';
import 'money_tools_sheets.dart';

/// Money Tab 3 — Analytics / Insights:
/// Matches `docs/expensetracker-main/lib/screens/reports_screen.dart` with
/// multi-period selector (`Weekly · Monthly · 6 Months · Yearly`), Spent
/// Summary BarChart, Total Assets segmented bar, Cashflow Overview mini-charts,
/// KPIs, Period Spending vs Budget card, Top Categories, and By-Category breakdown.
class MoneyInsightsPage extends StatelessWidget {
  const MoneyInsightsPage({super.key});

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
          StringConstants.analytics,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          BlocBuilder<MoneyBloc, MoneyState>(
            builder: (context, state) {
              if (state is! MoneyLoaded) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: MonthSelectorChip(
                  selectedMonth: state.selectedMonth,
                  onChanged: (m) =>
                      context.read<MoneyBloc>().add(ChangeMonth(m)),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          if (state is! MoneyLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final insights = state.insights;

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
                        padding: const EdgeInsets.fromLTRB(20, 8, 10, 32),
                        children: [
                          PeriodSelectorBar(
                            selected: state.selectedPeriod,
                            useShortLabels: true,
                            onChanged: (p) => context.read<MoneyBloc>().add(
                              ChangeMoneyPeriod(p),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SpentSummaryChartCard(insights: insights),
                          const SizedBox(height: 14),
                          const MoneySectionHeader(title: 'Cashflow Overview'),
                          CashflowOverviewCards(insights: insights),
                          const SizedBox(height: 14),
                          MoneyKpiRow(insights: insights),
                          const SizedBox(height: 14),
                          MonthlySpendingSummaryCard(insights: insights),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(10, 8, 20, 32),
                        children: [
                          TotalAssetsCard(
                            insights: insights,
                            onManageAccounts: () =>
                                MoneyAccountsSheet.show(context),
                          ),
                          const SizedBox(height: 14),
                          TopSpendingCategoriesCard(
                            items: insights.categorySpend,
                          ),
                          const SizedBox(height: 18),
                          const MoneySectionHeader(
                            title: StringConstants.byCategory,
                          ),
                          CategoryBreakdownCard(
                            categoryBudgets: state.categoryBudgets,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  PeriodSelectorBar(
                    selected: state.selectedPeriod,
                    useShortLabels: false,
                    onChanged: (p) =>
                        context.read<MoneyBloc>().add(ChangeMoneyPeriod(p)),
                  ),
                  const SizedBox(height: 12),
                  SpentSummaryChartCard(insights: insights),
                  const SizedBox(height: 12),
                  TotalAssetsCard(
                    insights: insights,
                    onManageAccounts: () => MoneyAccountsSheet.show(context),
                  ),
                  const SizedBox(height: 16),
                  const MoneySectionHeader(title: 'Cashflow Overview'),
                  CashflowOverviewCards(insights: insights),
                  const SizedBox(height: 14),
                  MoneyKpiRow(insights: insights),
                  const SizedBox(height: 14),
                  MonthlySpendingSummaryCard(insights: insights),
                  const SizedBox(height: 14),
                  BudgetExpenseReportCard(
                    state: state,
                    spentToday: state.allTransactions
                        .where(
                          (t) =>
                              t.isExpense &&
                              AppDateUtils.isSameDay(
                                t.dateTime,
                                DateTime.now(),
                              ),
                        )
                        .fold<double>(0, (s, t) => s + t.amount),
                  ),
                  if (insights.categorySpend.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    TopSpendingCategoriesCard(items: insights.categorySpend),
                  ],
                  const SizedBox(height: 18),
                  const MoneySectionHeader(title: StringConstants.byCategory),
                  CategoryBreakdownCard(categoryBudgets: state.categoryBudgets),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
