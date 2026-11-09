import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/money_category.dart';
import '../../domain/entities/subscription_entity.dart';
import '../bloc/money_bloc.dart';

/// Interactive Bill Split & IOU Calculator sheet.
/// Computes per-person share (with optional tip/tax %), logs the user's share
/// as an expense, and creates Lent IOUs for each friend's share in one tap.
class BillSplitSheet extends StatefulWidget {
  const BillSplitSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<MoneyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const BillSplitSheet()),
    );
  }

  @override
  State<BillSplitSheet> createState() => _BillSplitSheetState();
}

class _BillSplitSheetState extends State<BillSplitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController(text: 'Dinner Split');
  final _amountCtrl = TextEditingController();
  final _friendsCtrl = TextEditingController();

  int _peopleCount = 2;
  int _tipPercent = 0;

  static const List<int> _tipOptions = [0, 5, 10, 15, 18];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _friendsCtrl.dispose();
    super.dispose();
  }

  double get _baseAmount => double.tryParse(_amountCtrl.text.trim()) ?? 0.0;

  double get _totalWithTip => _baseAmount * (1.0 + (_tipPercent / 100.0));

  double get _perPersonShare =>
      _peopleCount > 0 ? _totalWithTip / _peopleCount : 0.0;

  double get _friendsTotal => _perPersonShare * (_peopleCount - 1);

  List<String> _resolveFriendNames() {
    final friendSlots = (_peopleCount - 1).clamp(1, 20);
    final rawParts = _friendsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final result = <String>[];
    for (var i = 0; i < friendSlots; i++) {
      if (i < rawParts.length) {
        result.add(rawParts[i]);
      } else {
        result.add('Friend ${i + 1}');
      }
    }
    return result;
  }

  void _submitSplit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final total = _totalWithTip;
    if (total <= 0) {
      SnackbarUtils.showError(context, StringConstants.invalidAmount);
      return;
    }

    final share = double.parse(_perPersonShare.toStringAsFixed(2));
    final title = _titleCtrl.text.trim().isEmpty
        ? 'Bill Split'
        : _titleCtrl.text.trim();
    final friends = _resolveFriendNames();
    final bloc = context.read<MoneyBloc>();

    // 1. Log user's own share as an expense
    bloc.add(
      AddTransaction(
        title: '$title (My Share 1/$_peopleCount)',
        category: MoneyCategory.food.key,
        amount: share,
        mode: 'UPI',
        iconCodePoint: MoneyCategory.food.icon.codePoint,
        type: 'expense',
        date: DateTime.now(),
        note:
            'Total bill ${CurrencyUtils.format(total, decimals: 2)} split $_peopleCount ways',
      ),
    );

    // 2. Create Lent IOUs for each friend
    final due = DateTime.now().add(const Duration(days: 7));
    for (final friend in friends) {
      bloc.add(
        AddIou(
          person: friend,
          amount: share,
          type: 'lent',
          note: IouEntity.formatNoteWithDueDate(
            '$title split (1/$_peopleCount)',
            due,
          ),
        ),
      );
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    SnackbarUtils.showSuccess(context, StringConstants.billSplitSuccessMessage);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: palette.scaffold,
        borderRadius: AppRadius.topXxl,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageGutter,
          AppSpacing.sm,
          AppSpacing.pageGutter,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.moduleTime.withValues(
                        alpha: palette.isDark ? 0.22 : 0.12,
                      ),
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: const Icon(
                      Icons.call_split_rounded,
                      color: AppColors.moduleTime,
                      size: 20,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StringConstants.billSplitTitle,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.heading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          StringConstants.billSplitSubtitle,
                          style: text.labelSmall?.copyWith(
                            color: palette.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              AppSpacing.gapH16,

              // Bill Title & Total Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      key: const ValueKey('bill_split_title_field'),
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Occasion / Place',
                        hintText: 'e.g. Pizza Night',
                        prefixIcon: Icon(Icons.restaurant_rounded, size: 18),
                      ),
                    ),
                  ),
                  AppSpacing.gapW8,
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      key: const ValueKey('bill_split_amount_field'),
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final parsed = double.tryParse((v ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter bill';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Total Bill (${CurrencyUtils.symbol})',
                        hintText: '0.00',
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,

              // People Count Stepper & Pills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Split Between ($_peopleCount People)',
                    style: text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.heading,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton.outlined(
                        key: const ValueKey('bill_split_minus_btn'),
                        visualDensity: VisualDensity.compact,
                        onPressed: _peopleCount > 2
                            ? () => setState(() => _peopleCount--)
                            : null,
                        icon: const Icon(Icons.remove_rounded, size: 16),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_peopleCount',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        key: const ValueKey('bill_split_plus_btn'),
                        visualDensity: VisualDensity.compact,
                        onPressed: _peopleCount < 12
                            ? () => setState(() => _peopleCount++)
                            : null,
                        icon: const Icon(Icons.add_rounded, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.gapH12,

              // Tip / Tax % Selector
              Text(
                'Add Tip / Service Charge',
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.heading,
                ),
              ),
              AppSpacing.gapH8,
              Row(
                children: _tipOptions.map((tip) {
                  final selected = _tipPercent == tip;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _tipPercent = tip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : palette.card,
                            borderRadius: AppRadius.radiusSm,
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : palette.border,
                            ),
                          ),
                          child: Text(
                            tip == 0 ? 'None' : '+$tip%',
                            style: text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : palette.heading,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              AppSpacing.gapH16,

              // Friends' Names Input
              TextFormField(
                key: const ValueKey('bill_split_friends_field'),
                controller: _friendsCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText:
                      'Friends (${_peopleCount - 1}) — comma-separated names',
                  hintText: 'e.g. Rahul, Priya (optional)',
                  prefixIcon: const Icon(Icons.group_outlined, size: 18),
                ),
              ),
              AppSpacing.gapH16,

              // Live Split Preview Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.moduleMoney.withValues(
                    alpha: palette.isDark ? 0.15 : 0.08,
                  ),
                  borderRadius: AppRadius.radiusLg,
                  border: Border.all(
                    color: AppColors.moduleMoney.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SplitMetric(
                            label: 'PER PERSON (1/$_peopleCount)',
                            value: CurrencyUtils.format(
                              _perPersonShare,
                              decimals: 2,
                            ),
                            color: AppColors.moduleMoney,
                          ),
                        ),
                        Container(width: 1, height: 30, color: palette.divider),
                        Expanded(
                          child: _SplitMetric(
                            label:
                                'TO COLLECT (${_peopleCount - 1} ${(_peopleCount - 1) == 1 ? "FRIEND" : "FRIENDS"})',
                            value: CurrencyUtils.format(
                              _friendsTotal,
                              decimals: 2,
                            ),
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_baseAmount > 0) ...[
                      Divider(height: 18, color: palette.divider),
                      Text(
                        'Creates 1 Expense (${CurrencyUtils.format(_perPersonShare, decimals: 2)}) + '
                        '${_peopleCount - 1} Lent IOU(s) for ${_resolveFriendNames().join(", ")}',
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(
                          color: palette.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapH16,

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  key: const ValueKey('bill_split_submit_btn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.moduleMoney,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                  onPressed: _submitSplit,
                  icon: const Icon(Icons.call_split_rounded, size: 19),
                  label: const Text(
                    StringConstants.billSplitLogAction,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SplitMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: text.labelSmall?.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.palette.heading,
            ),
          ),
        ),
      ],
    );
  }
}
