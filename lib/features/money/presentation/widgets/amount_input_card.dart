import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/validators.dart';

/// Hero amount input card with currency prefix, 2-decimal input formatter, and
/// quick-preset chips that replace the current value.
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusXl,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StringConstants.amountLabel.toUpperCase(),
            style: AppTextStyles.overline.copyWith(
              color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                CurrencyUtils.symbol,
                style: AppTextStyles.displayLarge.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
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
                  style: AppTextStyles.currencyHero.copyWith(
                    fontSize: 38,
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: AppTextStyles.currencyHero.copyWith(
                      fontSize: 38,
                      color:
                          (isDark
                                  ? AppColors.darkTextCaption
                                  : AppColors.textCaption)
                              .withValues(alpha: 0.45),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
                  child: ActionChip(
                    label: Text(
                      '${CurrencyUtils.symbol}$val',
                      style: AppTextStyles.captionBold.copyWith(
                        color: accentColor,
                      ),
                    ),
                    backgroundColor: accentColor.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: accentColor.withValues(alpha: 0.25),
                    ),
                    shape: const StadiumBorder(),
                    onPressed: () {
                      controller.text = val.toStringAsFixed(2);
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                    },
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
