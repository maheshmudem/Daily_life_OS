import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../money/domain/entities/money_category.dart';
import '../../domain/entities/note_entity.dart';

/// Result returned when converting a note into a Money expense.
class NoteExpenseConversionResult {
  final String title;
  final double amount;
  final MoneyCategory category;
  final String paymentMode;

  const NoteExpenseConversionResult({
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMode,
  });
}

/// Clean Daily Life OS bottom sheet for converting a note into an expense.
class NoteExpenseConverterSheet extends StatefulWidget {
  final NoteEntity note;

  const NoteExpenseConverterSheet({super.key, required this.note});

  static Future<NoteExpenseConversionResult?> show(
    BuildContext context, {
    required NoteEntity note,
  }) {
    return showModalBottomSheet<NoteExpenseConversionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteExpenseConverterSheet(note: note),
    );
  }

  @override
  State<NoteExpenseConverterSheet> createState() =>
      _NoteExpenseConverterSheetState();
}

class _NoteExpenseConverterSheetState extends State<NoteExpenseConverterSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  MoneyCategory _selectedCategory = MoneyCategory.other;
  String _selectedMode = StringConstants.paymentModeUPI;
  String? _errorText;

  static const List<String> _modes = [
    StringConstants.paymentModeUPI,
    StringConstants.paymentModeCard,
    StringConstants.paymentModeCash,
  ];

  @override
  void initState() {
    super.initState();
    final combined = '${widget.note.title} ${widget.note.content}';
    final match = RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(combined);
    final initialAmount = match?.group(1) ?? '';

    _titleCtrl = TextEditingController(
      text: widget.note.title.isNotEmpty ? widget.note.title : 'Note Expense',
    );
    _amountCtrl = TextEditingController(text: initialAmount);
    _selectedCategory = _inferCategory(combined.toLowerCase());
  }

  MoneyCategory _inferCategory(String lower) {
    if (lower.contains('food') ||
        lower.contains('grocery') ||
        lower.contains('coffee') ||
        lower.contains('dinner')) {
      return MoneyCategory.food;
    }
    if (lower.contains('cab') ||
        lower.contains('uber') ||
        lower.contains('metro') ||
        lower.contains('fuel')) {
      return MoneyCategory.transport;
    }
    if (lower.contains('bill') ||
        lower.contains('wifi') ||
        lower.contains('rent') ||
        lower.contains('electr')) {
      return MoneyCategory.bills;
    }
    if (lower.contains('gift') ||
        lower.contains('shop') ||
        lower.contains('buy')) {
      return MoneyCategory.shopping;
    }
    return MoneyCategory.other;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _errorText = StringConstants.invalidAmount);
      return;
    }
    final title = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : 'Note Expense';

    Navigator.of(context).pop(
      NoteExpenseConversionResult(
        title: title,
        amount: amount,
        category: _selectedCategory,
        paymentMode: _selectedMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.pageGutter,
            bottomInset + AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppRadius.topXl,
            border: Border.all(color: palette.divider),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.divider,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
                AppSpacing.gapH12,
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.moduleMoney.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: AppColors.moduleMoney,
                        size: 18,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            StringConstants.convertToExpense,
                            style: text.titleMedium?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: palette.heading,
                            ),
                          ),
                          Text(
                            'Log directly to Money Manager',
                            style: text.labelSmall?.copyWith(
                              fontSize: 11.5,
                              color: palette.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: palette.icon,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH16,

                // Amount input card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted.withValues(
                      alpha: palette.isDark ? 0.45 : 0.65,
                    ),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: _errorText != null
                          ? AppColors.error
                          : palette.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        CurrencyUtils.symbol,
                        style: text.headlineSmall?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.moduleMoney,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          autofocus: _amountCtrl.text.isEmpty,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) {
                            if (_errorText != null) {
                              setState(() => _errorText = null);
                            }
                          },
                          style: text.headlineSmall?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: palette.heading,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            isDense: true,
                            hintText: '0',
                            hintStyle: text.headlineSmall?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: palette.caption,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _errorText!,
                    style: text.labelSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                AppSpacing.gapH12,

                // Merchant input
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted.withValues(
                      alpha: palette.isDark ? 0.45 : 0.65,
                    ),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(color: palette.divider),
                  ),
                  child: TextField(
                    controller: _titleCtrl,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.heading,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      isDense: true,
                      labelText: StringConstants.merchantLabel,
                      labelStyle: text.labelSmall?.copyWith(
                        color: palette.caption,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                AppSpacing.gapH12,

                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MoneyCategory.expenseCategories.map((cat) {
                      final active = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = cat);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? cat.color.withValues(alpha: 0.15)
                                  : palette.surfaceMuted,
                              borderRadius: AppRadius.radiusFull,
                              border: Border.all(
                                color: active ? cat.color : palette.divider,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 14,
                                  color: active ? cat.color : palette.caption,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cat.label,
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 11.5,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: active ? cat.color : palette.body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                AppSpacing.gapH12,

                // Payment mode selector
                Row(
                  children: _modes.map((mode) {
                    final active = _selectedMode == mode;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: mode == _modes.last ? 0 : 8,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedMode = mode);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.moduleMoney.withValues(
                                      alpha: 0.14,
                                    )
                                  : palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: active
                                    ? AppColors.moduleMoney
                                    : palette.divider,
                              ),
                            ),
                            child: Text(
                              mode,
                              style: text.labelMedium?.copyWith(
                                fontSize: 12.5,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: active
                                    ? AppColors.moduleMoney
                                    : palette.body,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.gapH16,

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.body,
                            side: BorderSide(color: palette.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(StringConstants.cancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.moduleMoney,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            StringConstants.save,
                            style: AppTextStyles.buttonText.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
