import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () async {
        final picked = await MonthPickerSheet.show(
          context,
          selectedMonth: selectedMonth,
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.moduleMoney.withValues(alpha: isDark ? 0.2 : 0.1),
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
              style: AppTextStyles.captionBold.copyWith(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i, 1),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.topXxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
                borderRadius: AppRadius.radiusFull,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            StringConstants.selectMonth,
            style: AppTextStyles.headingSmall.copyWith(
              color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                labelStyle: AppTextStyles.captionBold.copyWith(
                  color: selected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextBody : AppColors.textBody),
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
