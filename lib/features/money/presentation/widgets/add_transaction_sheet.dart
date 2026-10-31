import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/money_category.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/money_bloc.dart';
import 'amount_input_card.dart';
import 'category_grid_selector.dart';

/// Full-featured Add / Edit transaction bottom sheet (Expense ⇄ Income).
class AddTransactionSheet extends StatefulWidget {
  final TransactionEntity? existing;
  final String initialType;
  final MoneyCategory? initialCategory;

  const AddTransactionSheet({
    super.key,
    this.existing,
    this.initialType = 'expense',
    this.initialCategory,
  });

  static Future<void> show(
    BuildContext context, {
    TransactionEntity? existing,
    String initialType = 'expense',
    MoneyCategory? initialCategory,
  }) {
    final bloc = context.read<MoneyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddTransactionSheet(
          existing: existing,
          initialType: initialType,
          initialCategory: initialCategory,
        ),
      ),
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  static const List<String> _paymentModes = ['UPI', 'Card', 'Cash', 'Bank'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;

  late String _type; // 'expense' | 'income'
  late String _selectedCategoryKey;
  late String _selectedMode;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;
  bool get _isIncome => _type == 'income';

  List<MoneyCategory> get _categories => _isIncome
      ? MoneyCategory.incomeCategories
      : MoneyCategory.expenseCategories;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _type = existing.type;
      _amountCtrl = TextEditingController(
        text: existing.amount.toStringAsFixed(2),
      );
      _titleCtrl = TextEditingController(text: existing.title);
      _noteCtrl = TextEditingController(text: existing.note ?? '');
      _selectedCategoryKey = existing.categoryInfo.key;
      _selectedMode = _paymentModes.contains(existing.mode)
          ? existing.mode
          : 'UPI';
      _selectedDate = existing.dateTime;
    } else {
      _type = widget.initialCategory?.isIncome == true
          ? 'income'
          : widget.initialType;
      _amountCtrl = TextEditingController();
      _titleCtrl = TextEditingController();
      _noteCtrl = TextEditingController();
      _selectedCategoryKey = widget.initialCategory?.key ?? '';
      _selectedMode = 'UPI';
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _amountCtrl.clear();
      _titleCtrl.clear();
      _noteCtrl.clear();
      _selectedCategoryKey = '';
      _selectedMode = 'UPI';
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategoryKey.isEmpty) {
      SnackbarUtils.showError(context, StringConstants.selectCategoryError);
      return;
    }

    setState(() => _isSubmitting = true);
    final amount = double.parse(_amountCtrl.text.trim());
    final title = _titleCtrl.text.trim();
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final cat = MoneyCategory.resolve(
      _selectedCategoryKey,
      isIncome: _isIncome,
    );
    final bloc = context.read<MoneyBloc>();

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        title: title,
        category: cat.key,
        amount: amount,
        mode: _selectedMode,
        iconCodePoint: cat.icon.codePoint,
        date: _selectedDate.toIso8601String(),
        type: _type,
        note: note,
      );
      bloc.add(UpdateTransaction(updated));
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackbarUtils.showSuccess(context, StringConstants.transactionUpdated);
      return;
    }

    bloc.add(
      AddTransaction(
        title: title,
        category: cat.key,
        amount: amount,
        mode: _selectedMode,
        iconCodePoint: cat.icon.codePoint,
        type: _type,
        date: _selectedDate,
        note: note,
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    final addMore = await _showAddedDialog(amount: amount, category: cat);
    if (!mounted) return;
    if (addMore == true) {
      _resetForm();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showAddedDialog({
    required double amount,
    required MoneyCategory category,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkCardBackground
            : AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.moduleMoney.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.moduleMoney,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _isIncome
                  ? StringConstants.incomeAdded
                  : StringConstants.expenseAdded,
              style: AppTextStyles.headingSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextHeading
                    : AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${CurrencyUtils.format(amount, decimals: 2)} in ${category.label} has been logged.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextBody : AppColors.textBody,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                    child: const Text(StringConstants.addAnother),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.moduleMoney,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                    child: const Text(StringConstants.done),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accent = _isIncome ? AppColors.success : AppColors.moduleMoney;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkScaffoldBackground
            : AppColors.scaffoldBackground,
        borderRadius: AppRadius.topXxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              borderRadius: AppRadius.radiusFull,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing
                        ? StringConstants.editTransaction
                        : (_isIncome
                              ? StringConstants.addIncome
                              : StringConstants.addExpense),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextHeading
                          : AppColors.textHeading,
                    ),
                  ),
                ),
                if (!_isEditing)
                  TextButton.icon(
                    onPressed: _resetForm,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(StringConstants.resetTimer),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expense / Income toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardBackground
                            : AppColors.surfaceSecondary,
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: Row(
                        children: [
                          _buildTypeSegment(
                            label: StringConstants.expense,
                            selected: !_isIncome,
                            color: AppColors.moduleMoney,
                            onTap: () => setState(() {
                              _type = 'expense';
                              if (MoneyCategory.resolve(
                                _selectedCategoryKey,
                              ).isIncome) {
                                _selectedCategoryKey = '';
                              }
                            }),
                          ),
                          _buildTypeSegment(
                            label: StringConstants.income,
                            selected: _isIncome,
                            color: AppColors.success,
                            onTap: () => setState(() {
                              _type = 'income';
                              if (!MoneyCategory.resolve(
                                _selectedCategoryKey,
                                isIncome: true,
                              ).isIncome) {
                                _selectedCategoryKey = MoneyCategory.salary.key;
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    AmountInputCard(
                      controller: _amountCtrl,
                      accentColor: accent,
                    ),
                    const SizedBox(height: 18),

                    Text(
                      StringConstants.categoryLabel,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CategoryGridSelector(
                      categories: _categories,
                      selectedKey: _selectedCategoryKey,
                      onSelect: (c) =>
                          setState(() => _selectedCategoryKey = c.key),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      StringConstants.detailsLabel,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Details card: Merchant, Payment mode, Date, Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardBackground
                            : AppColors.cardBackground,
                        borderRadius: AppRadius.radiusLg,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _titleCtrl,
                            validator: (v) => Validators.validateRequired(
                              v,
                              _isIncome
                                  ? StringConstants.incomeSourceLabel
                                  : StringConstants.merchantLabel,
                            ),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextHeading
                                  : AppColors.textHeading,
                            ),
                            decoration: InputDecoration(
                              labelText: _isIncome
                                  ? StringConstants.incomeSourceLabel
                                  : StringConstants.merchantLabel,
                              hintText: _isIncome
                                  ? StringConstants.incomeSourceHint
                                  : StringConstants.merchantHint,
                              prefixIcon: const Icon(
                                Icons.storefront_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Payment mode chips
                          Text(
                            StringConstants.paymentModeLabel,
                            style: AppTextStyles.captionBold.copyWith(
                              color: isDark
                                  ? AppColors.darkTextCaption
                                  : AppColors.textCaption,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _paymentModes.map((m) {
                              final selected = _selectedMode == m;
                              return ChoiceChip(
                                label: Text(m),
                                selected: selected,
                                showCheckmark: false,
                                selectedColor: accent,
                                labelStyle: AppTextStyles.captionBold.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.darkTextBody
                                            : AppColors.textBody),
                                ),
                                onSelected: (_) =>
                                    setState(() => _selectedMode = m),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Date row
                          InkWell(
                            borderRadius: AppRadius.radiusMd,
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceSecondary
                                    : AppColors.surfaceSecondary,
                                borderRadius: AppRadius.radiusMd,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      AppDateUtils.formatLongDate(
                                        _selectedDate,
                                      ),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextHeading
                                            : AppColors.textHeading,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.expand_more_rounded,
                                    color: isDark
                                        ? AppColors.darkTextCaption
                                        : AppColors.textCaption,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Optional note
                          TextFormField(
                            controller: _noteCtrl,
                            maxLines: 2,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextHeading
                                  : AppColors.textHeading,
                            ),
                            decoration: const InputDecoration(
                              labelText: StringConstants.noteLabel,
                              hintText: StringConstants.noteHint,
                              prefixIcon: Icon(Icons.notes_rounded, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd,
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEditing
                                      ? StringConstants.save
                                      : (_isIncome
                                            ? StringConstants.addIncome
                                            : StringConstants.addExpense),
                                  style: AppTextStyles.buttonText.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: AppRadius.radiusSm,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.titleSmall.copyWith(
              color: selected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextBody : AppColors.textBody),
            ),
          ),
        ),
      ),
    );
  }
}
