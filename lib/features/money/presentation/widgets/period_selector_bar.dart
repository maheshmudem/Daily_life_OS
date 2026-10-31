import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/money_insights.dart';

/// Compact segmented selector for switching between Weekly, Monthly,
/// 6-Month, and Yearly horizons (`1W · 1M · 6M · 1Y`).
class PeriodSelectorBar extends StatelessWidget {
  final MoneyPeriod selected;
  final ValueChanged<MoneyPeriod> onChanged;
  final bool useShortLabels;

  const PeriodSelectorBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.useShortLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceElevated,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: MoneyPeriod.values.map((period) {
          final isSelected = period == selected;
          final label = useShortLabels
              ? '${period.label} (${period.shortTag})'
              : period.label;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.primary : AppColors.surface)
                      : Colors.transparent,
                  borderRadius: AppRadius.borderSm,
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primary)
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
