import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/date_utils.dart';

/// Pill showing the selected month; tap opens [MonthPickerSheet].
class MonthSelectorChip extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onChanged;

  const MonthSelectorChip({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: () async {
        final picked = await MonthPickerSheet.show(
          context,
          selectedMonth: selectedMonth,
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: AppColors.moduleMoney.withValues(alpha: p.isDark ? 0.2 : 0.1),
          borderRadius: AppRadius.radiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: AppColors.moduleMoney,
            ),
            const SizedBox(width: 6),
            Text(
              AppDateUtils.formatMonthYear(selectedMonth),
              style: context.text.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.moduleMoney,
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: AppColors.moduleMoney,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing the last 12 months as chips. Returns the picked month.
class MonthPickerSheet extends StatelessWidget {
  final DateTime selectedMonth;

  const MonthPickerSheet({super.key, required this.selectedMonth});

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime selectedMonth,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MonthPickerSheet(selectedMonth: selectedMonth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final now = DateTime.now();
    final months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i, 1),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        28,
      ),
      decoration: BoxDecoration(color: p.card, borderRadius: AppRadius.topXxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: p.divider,
                borderRadius: AppRadius.radiusFull,
              ),
            ),
          ),
          AppSpacing.gapH16,
          Text(
            StringConstants.selectMonth,
            style: text.titleLarge?.copyWith(color: p.heading),
          ),
          AppSpacing.gapH16,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: months.map((m) {
              final selected = AppDateUtils.isSameMonth(m, selectedMonth);
              final label = m.year == now.year
                  ? AppDateUtils.formatMonthShort(m)
                  : '${AppDateUtils.formatMonthShort(m)} ${m.year}';
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.moduleMoney,
                labelStyle: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.textWhite : p.body,
                ),
                onSelected: (_) => Navigator.of(context).pop(m),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
