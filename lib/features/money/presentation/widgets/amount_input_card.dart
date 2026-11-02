import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/validators.dart';

/// Hero amount input card with currency prefix, 2-decimal input formatter, and
/// quick-preset chips that update the current value.
class AmountInputCard extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;
  final List<int>? quickAmounts;

  const AmountInputCard({
    super.key,
    required this.controller,
    this.accentColor = AppColors.moduleMoney,
    this.quickAmounts,
  });

  List<int> _defaultChips() {
    final code = CurrencyUtils.current.code;
    if (code == 'INR' || code == 'JPY') {
      return const [100, 250, 500, 1000, 2000];
    }
    return const [5, 10, 20, 50, 100];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final presets = quickAmounts ?? _defaultChips();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: AppRadius.radiusXl,
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                StringConstants.amountLabel.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, val, _) {
                  if (val.text.isEmpty) return const SizedBox(height: 20);
                  return GestureDetector(
                    onTap: controller.clear,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceSecondary
                            : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                CurrencyUtils.symbol,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: Validators.validateAmount,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color:
                          (isDark
                                  ? AppColors.darkTextCaption
                                  : AppColors.textCaption)
                              .withValues(alpha: 0.35),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: presets.map((val) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () {
                      controller.text = val.toString();
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: isDark ? 0.16 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: accentColor.withValues(
                            alpha: isDark ? 0.3 : 0.2,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${CurrencyUtils.symbol}$val',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
