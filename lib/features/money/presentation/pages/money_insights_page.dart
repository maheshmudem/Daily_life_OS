import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../bloc/money_bloc.dart';
import '../widgets/account_transfer_sheet.dart';
import '../widgets/cashflow_overview_cards.dart';
import '../widgets/category_breakdown_card.dart';
import '../widgets/money_report_sheet.dart';
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
    return BlocBuilder<MoneyBloc, MoneyState>(
      builder: (context, moneyState) => FeatureScaffold(
        title: StringConstants.analytics,
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
        ],
        status: moneyFeatureStatus(moneyState),
        errorMessage: moneyState is MoneyError ? moneyState.message : null,
        onRetry: () => context.read<MoneyBloc>().add(const LoadMoney()),
        loading: const FeatureLoadingView(blockHeights: [40, 220, 120, 160]),
        builder: (context) {
          final state = moneyState as MoneyLoaded;
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
                          _buildPeriodHeader(
                            context,
                            state,
                            useShortLabels: true,
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageGutter,
                  8,
                  AppSpacing.pageGutter,
                  32,
                ),
                children: [
                  _buildPeriodHeader(context, state, useShortLabels: false),
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

  Widget _buildPeriodHeader(
    BuildContext context,
    MoneyLoaded state, {
    required bool useShortLabels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              'Analysis Horizon',
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.palette.heading,
              ),
            ),
            MonthSelectorChip(
              selectedMonth: state.selectedMonth,
              onChanged: (m) => context.read<MoneyBloc>().add(ChangeMonth(m)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        PeriodSelectorBar(
          selected: state.selectedPeriod,
          useShortLabels: useShortLabels,
          onChanged: (p) => context.read<MoneyBloc>().add(ChangeMoneyPeriod(p)),
        ),
      ],
    );
  }
}
