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
  bool _isCategoryGrid = false;
  bool _aiAutoCategorized = false;

  bool get _isEditing => widget.existing != null;
  bool get _isIncome => _type == 'income';

  static MoneyCategory? _inferCategoryFromTitle(
    String rawTitle, {
    required bool isIncome,
  }) {
    final q = rawTitle.toLowerCase().trim();
    if (q.length < 3) return null;
    if (isIncome) {
      if (q.contains('salary') ||
          q.contains('paycheck') ||
          q.contains('stipend')) {
        return MoneyCategory.salary;
      }
      if (q.contains('freelance') ||
          q.contains('client') ||
          q.contains('invoice') ||
          q.contains('project')) {
        return MoneyCategory.business;
      }
      if (q.contains('dividend') ||
          q.contains('interest') ||
          q.contains('stock') ||
          q.contains('mutual')) {
        return MoneyCategory.investmentReturn;
      }
      if (q.contains('gift') ||
          q.contains('cashback') ||
          q.contains('refund')) {
        return MoneyCategory.gift;
      }
      return null;
    }

    if (q.contains('swiggy') ||
        q.contains('zomato') ||
        q.contains('coffee') ||
        q.contains('cafe') ||
        q.contains('dinner') ||
        q.contains('lunch') ||
        q.contains('breakfast') ||
        q.contains('grocery') ||
        q.contains('blinkit') ||
        q.contains('zepto') ||
        q.contains('restaurant')) {
      return MoneyCategory.food;
    }
    if (q.contains('uber') ||
        q.contains('ola') ||
        q.contains('rapido') ||
        q.contains('metro') ||
        q.contains('petrol') ||
        q.contains('fuel') ||
        q.contains('cab') ||
        q.contains('auto') ||
        q.contains('parking')) {
      return MoneyCategory.transport;
    }
    if (q.contains('amazon') ||
        q.contains('flipkart') ||
        q.contains('myntra') ||
        q.contains('clothes') ||
        q.contains('shoes') ||
        q.contains('headphone') ||
        q.contains('mall')) {
      return MoneyCategory.shopping;
    }
    if (q.contains('rent') ||
        q.contains('electric') ||
        q.contains('wifi') ||
        q.contains('broadband') ||
        q.contains('airtel') ||
        q.contains('jio') ||
        q.contains('water') ||
        q.contains('gas') ||
        q.contains('emi')) {
      return MoneyCategory.bills;
    }
    if (q.contains('netflix') ||
        q.contains('spotify') ||
        q.contains('movie') ||
        q.contains('pvr') ||
        q.contains('inox') ||
        q.contains('game') ||
        q.contains('youtube')) {
      return MoneyCategory.entertainment;
    }
    if (q.contains('pharmacy') ||
        q.contains('apollo') ||
        q.contains('doctor') ||
        q.contains('hospital') ||
        q.contains('medicine') ||
        q.contains('gym') ||
        q.contains('cult')) {
      return MoneyCategory.health;
    }
    if (q.contains('flight') ||
        q.contains('indigo') ||
        q.contains('hotel') ||
        q.contains('airbnb') ||
        q.contains('irctc') ||
        q.contains('train') ||
        q.contains('trip')) {
      return MoneyCategory.travel;
    }
    return null;
  }

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

  void _repeatToday() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.parse(_amountCtrl.text.trim());
    final title = _titleCtrl.text.trim();
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final cat = MoneyCategory.resolve(
      _selectedCategoryKey,
      isIncome: _isIncome,
    );
    context.read<MoneyBloc>().add(
      AddTransaction(
        title: title,
        category: cat.key,
        amount: amount,
        mode: _selectedMode,
        iconCodePoint: cat.icon.codePoint,
        type: _type,
        date: DateTime.now(),
        note: note,
      ),
    );
    Navigator.of(context).pop();
    SnackbarUtils.showSuccess(
      context,
      '${StringConstants.repeatedTodayMessage}: $title',
    );
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
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
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
          // Drag handle
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isEditing
                            ? StringConstants.editTransaction
                            : (_isIncome
                                  ? StringConstants.addIncome
                                  : StringConstants.addExpense),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isEditing
                            ? 'Update transaction details'
                            : (_isIncome
                                  ? 'Log incoming money or salary'
                                  : 'Track where your money went'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isEditing) ...[
                  TextButton.icon(
                    key: const ValueKey('repeat_today_tx_btn'),
                    onPressed: _repeatToday,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(Icons.copy_rounded, size: 14, color: accent),
                    label: Text(
                      StringConstants.repeatTodayLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ] else ...[
                  TextButton(
                    onPressed: _resetForm,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.surfaceSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextBody
                          : AppColors.textHeading,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expense / Income Segmented Switcher
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardBackground
                            : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTypeSegment(
                            icon: Icons.arrow_outward_rounded,
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
                            icon: Icons.south_west_rounded,
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
                    const SizedBox(height: 14),

                    // Amount input card
                    AmountInputCard(
                      controller: _amountCtrl,
                      accentColor: accent,
                    ),
                    const SizedBox(height: 16),

                    // Category header with view toggle (Strip ⇄ Grid) & active selection tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              StringConstants.categoryLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextCaption
                                    : AppColors.textCaption,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(
                                () => _isCategoryGrid = !_isCategoryGrid,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceSecondary
                                      : AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isCategoryGrid
                                          ? Icons.view_carousel_rounded
                                          : Icons.grid_view_rounded,
                                      size: 13,
                                      color: isDark
                                          ? AppColors.darkTextCaption
                                          : AppColors.textCaption,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isCategoryGrid ? 'Strip' : 'Grid',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.darkTextCaption
                                            : AppColors.textCaption,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedCategoryKey.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              MoneyCategory.resolve(
                                _selectedCategoryKey,
                                isIncome: _isIncome,
                              ).label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Category Selector (Fluid horizontal strip by default, expandable to 4-column grid)
                    CategoryGridSelector(
                      categories: _categories,
                      selectedKey: _selectedCategoryKey,
                      isGrid: _isCategoryGrid,
                      onSelect: (c) => setState(() {
                        _selectedCategoryKey = c.key;
                        _aiAutoCategorized = false;
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Details Section Header
                    Text(
                      StringConstants.detailsLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Details card: Merchant, Date & Mode row, Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardBackground
                            : Colors.white,
                        borderRadius: AppRadius.radiusLg,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Merchant / Payee (with AI smart auto-categorization)
                          TextFormField(
                            controller: _titleCtrl,
                            onChanged: (val) {
                              final inferred = _inferCategoryFromTitle(
                                val,
                                isIncome: _isIncome,
                              );
                              if (inferred != null &&
                                  (_selectedCategoryKey.isEmpty ||
                                      _aiAutoCategorized)) {
                                setState(() {
                                  _selectedCategoryKey = inferred.key;
                                  _aiAutoCategorized = true;
                                });
                              }
                            },
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

                          // Date & Payment mode side-by-side row
                          Row(
                            children: [
                              // Date Picker Pill
                              Expanded(
                                flex: 5,
                                child: InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurfaceSecondary
                                          : AppColors.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkDivider
                                            : AppColors.divider,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 16,
                                          color: accent,
                                        ),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(
                                            AppDateUtils.formatDate(
                                              _selectedDate,
                                            ),
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.textHeading,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Payment Mode Pill Selector
                              Expanded(
                                flex: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceSecondary
                                        : AppColors.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkDivider
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Row(
                                    children: _paymentModes.map((m) {
                                      final isSelected = _selectedMode == m;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _selectedMode = m),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 140,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? accent
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: isSelected && !isDark
                                                  ? [
                                                      BoxShadow(
                                                        color: accent
                                                            .withValues(
                                                              alpha: 0.25,
                                                            ),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              m,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isDark
                                                          ? AppColors
                                                                .darkTextCaption
                                                          : AppColors.textBody),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
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

                    // Primary Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.check_rounded, size: 20),
                        label: AnimatedSwitcher(
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
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
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
    required IconData icon,
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
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected && !isDark
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? Colors.white
                    : (isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextBody : AppColors.textBody),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
