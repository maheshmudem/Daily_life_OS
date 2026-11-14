import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../bloc/money_bloc.dart';

/// Interactive & copyable Monthly Financial Statement & Report sheet.
class MoneyReportSheet extends StatelessWidget {
  const MoneyReportSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<MoneyBloc>();
    HapticFeedback.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const MoneyReportSheet()),
    );
  }

  String _buildPlainTextStatement(MoneyLoaded state) {
    final insights = state.insights;
    final netCashflow = insights.monthIncome - insights.monthExpense;
    final periodLabel = state.selectedPeriod.label;
    final totalAssets = state.accounts.fold<double>(
      0,
      (sum, acc) => sum + acc.balance,
    );
    final totalSubs = state.subscriptions.fold<double>(
      0,
      (sum, sub) => sum + sub.amount,
    );
    final buffer = StringBuffer()
      ..writeln('=== DAILY LIFE OS • FINANCIAL STATEMENT ($periodLabel) ===')
      ..writeln(
        'Income: ${CurrencyUtils.format(insights.monthIncome)} | '
        'Expenses: ${CurrencyUtils.format(insights.monthExpense)}',
      )
      ..writeln(
        'Net Cashflow: ${CurrencyUtils.format(netCashflow)} | '
        'Safe-to-Spend Today: ${CurrencyUtils.format(state.budget.dailySafeSpend)}',
      )
      ..writeln('Total Assets: ${CurrencyUtils.format(totalAssets)}')
      ..writeln(
        'Active Subscriptions: ${state.subscriptions.length} (${CurrencyUtils.format(totalSubs)}/mo)',
      );

    if (insights.categorySpend.isNotEmpty) {
      buffer.writeln('\nTop Spending Categories:');
      for (final item in insights.categorySpend.take(5)) {
        buffer.writeln(
          '- ${item.category.label}: ${CurrencyUtils.format(item.amount)} (${(item.share * 100).round()}%)',
        );
      }
    }

    if (state.accounts.isNotEmpty) {
      buffer.writeln('\nAccount Balances:');
      for (final acc in state.accounts) {
        buffer.writeln('- ${acc.name}: ${CurrencyUtils.format(acc.balance)}');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.md,
        AppSpacing.pageGutter,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.topXxl,
      ),
      child: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          if (state is! MoneyLoaded) {
            return const SizedBox.shrink();
          }

          final insights = state.insights;
          final netCashflow = insights.monthIncome - insights.monthExpense;
          final totalAssets = state.accounts.fold<double>(
            0,
            (sum, acc) => sum + acc.balance,
          );
          final savingsRate = insights.monthIncome > 0
              ? ((netCashflow / insights.monthIncome) * 100)
                    .clamp(-100.0, 100.0)
                    .round()
              : 0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppSpacing.xxxl,
                  height: AppSpacing.xxs,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              AppSpacing.gapH12,
              Row(
                children: [
                  Container(
                    width: AppSpacing.xxxl,
                    height: AppSpacing.xxxl,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: const Icon(
                      Icons.assessment_rounded,
                      color: AppColors.primary,
                      size: AppSpacing.lg,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          StringConstants.financialStatementTitle,
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.heading,
                          ),
                        ),
                        AppText(
                          StringConstants.financialStatementSubtitle,
                          style: context.text.bodySmall?.copyWith(
                            color: palette.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: palette.caption),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              AppSpacing.gapH16,
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI Grid
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: StringConstants.income,
                              value: CurrencyUtils.format(insights.monthIncome),
                              color: AppColors.moduleMoney,
                            ),
                          ),
                          AppSpacing.gapW8,
                          Expanded(
                            child: _MetricTile(
                              label: StringConstants.expenses,
                              value: CurrencyUtils.format(
                                insights.monthExpense,
                              ),
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH8,
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: StringConstants.netCashflow,
                              value:
                                  '${CurrencyUtils.format(netCashflow)} ($savingsRate%)',
                              color: netCashflow >= 0
                                  ? AppColors.moduleMoney
                                  : AppColors.error,
                            ),
                          ),
                          AppSpacing.gapW8,
                          Expanded(
                            child: _MetricTile(
                              label: StringConstants.totalAssets,
                              value: CurrencyUtils.format(totalAssets),
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH16,
                      AppText(
                        StringConstants.topCategories,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.heading,
                        ),
                      ),
                      AppSpacing.gapH8,
                      if (insights.categorySpend.isEmpty)
                        AppText(
                          StringConstants.noTransactionsTitle,
                          style: context.text.bodySmall?.copyWith(
                            color: palette.caption,
                          ),
                        )
                      else
                        ...insights.categorySpend.take(5).map((item) {
                          final pct = (item.share * 100).round();
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.category.icon,
                                  size: AppSpacing.md,
                                  color: item.category.color,
                                ),
                                AppSpacing.gapW8,
                                Expanded(
                                  child: AppText(
                                    item.category.label,
                                    style: context.text.bodyMedium?.copyWith(
                                      color: palette.body,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                AppText.monoCode(
                                  '${CurrencyUtils.format(item.amount)} ($pct%)',
                                  color: palette.heading,
                                  fontWeight: FontWeight.w700,
                                ),
                              ],
                            ),
                          );
                        }),
                      AppSpacing.gapH16,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: const ValueKey('copy_financial_statement_btn'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          onPressed: () {
                            final text = _buildPlainTextStatement(state);
                            Clipboard.setData(ClipboardData(text: text));
                            HapticFeedback.mediumImpact();
                            SnackbarUtils.showSuccess(
                              context,
                              StringConstants.statementCopiedMessage,
                            );
                          },
                          icon: const Icon(Icons.copy_all_rounded),
                          label: const AppText(
                            StringConstants.copyStatementLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: AppSpacing.edgeInsetsAllMd,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            style: context.text.labelSmall?.copyWith(
              color: palette.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapH4,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppText(
              value,
              style: context.text.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
