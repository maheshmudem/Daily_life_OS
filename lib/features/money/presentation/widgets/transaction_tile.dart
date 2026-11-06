import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/expandable_text_widget.dart';
import '../../domain/entities/transaction_entity.dart';

/// Modern Fintech Transaction Row inspired by Copilot Money & Monarch:
/// - 42x42 category squircle icon with subtle tint border
/// - Merchant title, date & payment-mode pill (`UPI`, `Card`, `Cash`, `Bank`)
/// - Optional expandable transaction note (`ExpandableTextWidget`)
/// - Tabular signed amount + category pill badge
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
    final note = transaction.note?.trim() ?? '';

    final content = Row(
      crossAxisAlignment: note.isNotEmpty
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: isDark ? 0.16 : 0.11),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: category.color.withValues(alpha: 0.22)),
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
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      transaction.formattedDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: captionColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceMuted
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Text(
                      transaction.mode,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 4),
                ExpandableTextWidget(
                  text: note,
                  collapsedMaxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                CurrencyUtils.signed(
                  transaction.amount,
                  isCredit: isIncome,
                  decimals: 2,
                ),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 4),
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
