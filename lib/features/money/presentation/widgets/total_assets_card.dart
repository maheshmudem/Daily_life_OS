import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/money_account_entity.dart';
import '../../domain/entities/money_insights.dart';

/// Total Assets card matching `docs/expensetracker-main/lib/widgets/reports_widgets.dart`
/// (`TotalAssetsCard`): header row with title + total amount, animated 10px
/// segmented bar (Cash / Savings / Investments), and compact legend.
class TotalAssetsCard extends StatelessWidget {
  final MoneyInsights insights;
  final VoidCallback? onManageAccounts;

  const TotalAssetsCard({
    super.key,
    required this.insights,
    this.onManageAccounts,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final total = insights.totalAssets;
    final cash = insights.assetsByType[MoneyAccountType.cash] ?? 0;
    final savings = insights.assetsByType[MoneyAccountType.savings] ?? 0;
    final invest = insights.assetsByType[MoneyAccountType.investment] ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  StringConstants.totalAssets,
                  style: text.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: p.secondary,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: AppText(
                  CurrencyUtils.format(total, decimals: 2),
                  style: text.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: p.heading,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (onManageAccounts != null) ...[
                AppSpacing.gapW8,
                InkWell(
                  onTap: onManageAccounts,
                  borderRadius: AppRadius.radiusSm,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          AppSpacing.gapH12,

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, anim, _) {
              if (total <= 0) {
                return Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: p.surfaceSubtle,
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }
              final cashFlex = ((cash / total) * 1000 * anim).round().clamp(
                0,
                1000,
              );
              final savingsFlex = ((savings / total) * 1000 * anim)
                  .round()
                  .clamp(0, 1000);
              final investFlex = ((invest / total) * 1000 * anim).round().clamp(
                0,
                1000,
              );
              final remainder = (1000 - cashFlex - savingsFlex - investFlex)
                  .clamp(0, 1000);

              return ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      if (cashFlex > 0)
                        Flexible(
                          flex: cashFlex,
                          child: Container(color: AppColors.moneyAssetCash),
                        ),
                      if (savingsFlex > 0)
                        Flexible(
                          flex: savingsFlex,
                          child: Container(color: AppColors.moneyAssetSavings),
                        ),
                      if (investFlex > 0)
                        Flexible(
                          flex: investFlex,
                          child: Container(color: AppColors.moneyAssetInvest),
                        ),
                      if (remainder > 0)
                        Flexible(
                          flex: remainder,
                          child: Container(color: p.surfaceSubtle),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          AppSpacing.gapH12,

          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _AssetLegend(
                color: AppColors.moneyAssetCash,
                label: StringConstants.cash,
                amount: CurrencyUtils.format(cash),
              ),
              _AssetLegend(
                color: AppColors.moneyAssetSavings,
                label: StringConstants.savings,
                amount: CurrencyUtils.format(savings),
              ),
              _AssetLegend(
                color: AppColors.moneyAssetInvest,
                label: StringConstants.investments,
                amount: CurrencyUtils.format(invest),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;

  const _AssetLegend({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        AppText(
          '$label ',
          style: text.labelSmall?.copyWith(fontSize: 11.5, color: p.secondary),
        ),
        AppText(
          amount,
          style: text.labelSmall?.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: p.heading,
          ),
        ),
      ],
    );
  }
}
