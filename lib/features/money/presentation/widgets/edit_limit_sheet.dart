import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/category_budget_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/money_bloc.dart';

/// Modal sheet to edit a single category's monthly budget limit.
class EditCategoryLimitSheet extends StatefulWidget {
  final CategoryBudgetEntity budget;

  const EditCategoryLimitSheet({super.key, required this.budget});

  static Future<void> show(
    BuildContext context, {
    required CategoryBudgetEntity budget,
  }) {
    final bloc = context.read<MoneyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EditCategoryLimitSheet(budget: budget),
      ),
    );
  }

  @override
  State<EditCategoryLimitSheet> createState() => _EditCategoryLimitSheetState();
}

class _EditCategoryLimitSheetState extends State<EditCategoryLimitSheet> {
  late final TextEditingController _ctrl;
  String? _error;

  List<int> _presetLimits() {
    final code = CurrencyUtils.current.code;
    if (code == 'INR' || code == 'JPY') {
      return const [1000, 2500, 5000, 10000, 20000];
    }
    return const [100, 200, 300, 500, 1000];
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.budget.monthlyLimit > 0
          ? widget.budget.monthlyLimit.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final text = _ctrl.text.trim().isEmpty ? '0' : _ctrl.text.trim();
    final err = Validators.validateNonNegativeAmount(text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final val = double.parse(text);
    context.read<MoneyBloc>().add(
      SetCategoryLimit(widget.budget.category, val),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final cat = widget.budget.categoryInfo;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl + bottomInset,
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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      cat.label,
                      style: text.titleLarge?.copyWith(color: p.heading),
                    ),
                    AppText(
                      '${StringConstants.currentSpend}: ${CurrencyUtils.format(widget.budget.spent)}',
                      style: text.labelSmall?.copyWith(color: p.caption),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: text.headlineSmall?.copyWith(color: p.heading),
            decoration: InputDecoration(
              labelText: StringConstants.monthlyLimit,
              prefixText: '${CurrencyUtils.symbol} ',
              hintText: '0 (${StringConstants.noLimitSet})',
              errorText: _error,
            ),
          ),
          AppSpacing.gapH12,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _presetLimits().map((preset) {
              return ActionChip(
                label: AppText('${CurrencyUtils.symbol}$preset'),
                onPressed: () {
                  _ctrl.text = preset.toString();
                  if (_error != null) setState(() => _error = null);
                },
              );
            }).toList(),
          ),
          AppSpacing.gapH20,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const AppText(StringConstants.cancel),
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.moduleMoney,
                    foregroundColor: AppColors.textWhite,
                  ),
                  onPressed: _save,
                  child: const AppText(StringConstants.saveLimit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modal sheet to edit the overall Monthly Budget & Fixed Bills (Safe-to-Spend).
class EditSafeSpendSheet extends StatefulWidget {
  final BudgetEntity budget;

  const EditSafeSpendSheet({super.key, required this.budget});

  static Future<void> show(
    BuildContext context, {
    required BudgetEntity budget,
  }) {
    final bloc = context.read<MoneyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EditSafeSpendSheet(budget: budget),
      ),
    );
  }

  @override
  State<EditSafeSpendSheet> createState() => _EditSafeSpendSheetState();
}

class _EditSafeSpendSheetState extends State<EditSafeSpendSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _billsCtrl;

  @override
  void initState() {
    super.initState();
    _budgetCtrl = TextEditingController(
      text: widget.budget.monthlyBudget.toStringAsFixed(0),
    );
    _billsCtrl = TextEditingController(
      text: widget.budget.fixedBills.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _billsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final monthly = double.parse(_budgetCtrl.text.trim());
    final bills = double.parse(_billsCtrl.text.trim());
    context.read<MoneyBloc>().add(UpdateBudget(monthly, bills));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl + bottomInset,
      ),
      decoration: BoxDecoration(color: p.card, borderRadius: AppRadius.topXxl),
      child: Form(
        key: _formKey,
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
            AppText(
              StringConstants.safeSpendSettings,
              style: text.titleLarge?.copyWith(color: p.heading),
            ),
            AppSpacing.gapH16,
            TextFormField(
              controller: _budgetCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: Validators.validateAmount,
              decoration: InputDecoration(
                labelText: StringConstants.monthlyBudget,
                prefixText: '${CurrencyUtils.symbol} ',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _billsCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: Validators.validateNonNegativeAmount,
              decoration: InputDecoration(
                labelText: StringConstants.fixedBills,
                prefixText: '${CurrencyUtils.symbol} ',
              ),
            ),
            AppSpacing.gapH20,
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moduleMoney,
                  foregroundColor: AppColors.textWhite,
                ),
                onPressed: _save,
                child: const AppText(StringConstants.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
