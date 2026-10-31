import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/transaction_entity.dart';

/// Compact transaction row matching `docs/expensetracker-main/lib/widgets/transaction_tile.dart`:
/// 40x40 category icon circle, merchant title, date subtitle, signed amount,
/// and a single category badge.
class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;

  /// When true the tile draws its own card. When false it renders flat so it
  /// can sit inside a grouped card with indented dividers (`indent: 68`).
  final bool showCard;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = transaction.categoryInfo;
    final isIncome = transaction.isIncome;
    final amountColor = isIncome
        ? AppColors.success
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    final captionColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final content = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(category.icon, color: category.color, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${transaction.formattedDate} · ${transaction.mode}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: captionColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyUtils.signed(
                transaction.amount,
                isCredit: isIncome,
                decimals: 2,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: amountColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (isIncome ? AppColors.success : category.color)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category.shortLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isIncome ? AppColors.success : category.color,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: content,
    );

    if (!showCard) {
      return InkWell(onTap: onTap, child: padded);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: onTap,
          child: padded,
        ),
      ),
    );
  }
}
