import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
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
    final p = context.palette;
    final text = context.text;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: p.isDark ? p.card : p.surfaceMuted,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: p.border),
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
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (p.isDark ? AppColors.primary : p.card)
                      : Colors.transparent,
                  borderRadius: AppRadius.borderSm,
                  boxShadow: isSelected && !p.isDark
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
                    style: text.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? (p.isDark ? AppColors.textWhite : AppColors.primary)
                          : p.secondary,
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
