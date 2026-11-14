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
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/money_account_entity.dart';
import '../bloc/money_bloc.dart';

/// Modal sheet to transfer funds between [MoneyAccountEntity] accounts and
/// log an auditable transfer entry in Money activity.
class AccountTransferSheet extends StatefulWidget {
  const AccountTransferSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<MoneyBloc>();
    HapticFeedback.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const AccountTransferSheet()),
    );
  }

  @override
  State<AccountTransferSheet> createState() => _AccountTransferSheetState();
}

class _AccountTransferSheetState extends State<AccountTransferSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  int? _fromAccountId;
  int? _toAccountId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _ensureDefaultSelection(List<MoneyAccountEntity> accounts) {
    if (accounts.length < 2) return;
    final ids = accounts.map((a) => a.id).toSet();
    if (_fromAccountId == null || !ids.contains(_fromAccountId)) {
      _fromAccountId = accounts.first.id;
    }
    if (_toAccountId == null ||
        !ids.contains(_toAccountId) ||
        _toAccountId == _fromAccountId) {
      _toAccountId = accounts.firstWhere((a) => a.id != _fromAccountId).id;
    }
  }

  void _swapAccounts() {
    HapticFeedback.selectionClick();
    setState(() {
      final tmp = _fromAccountId;
      _fromAccountId = _toAccountId;
      _toAccountId = tmp;
    });
  }

  void _submitTransfer(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fromAccountId == null || _toAccountId == null) return;
    if (_fromAccountId == _toAccountId) {
      SnackbarUtils.showError(
        context,
        StringConstants.transferSameAccountError,
      );
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    HapticFeedback.mediumImpact();
    context.read<MoneyBloc>().add(
      TransferBetweenAccounts(
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amount: amount,
        note: _noteController.text.trim(),
      ),
    );
    Navigator.of(context).pop();
    SnackbarUtils.showSuccess(
      context,
      '${StringConstants.transferSuccessMessage} (${CurrencyUtils.format(amount)})',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.md,
        AppSpacing.pageGutter,
        bottomInset + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.topXxl,
      ),
      child: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          final accounts = state is MoneyLoaded
              ? state.accounts
              : const <MoneyAccountEntity>[];
          _ensureDefaultSelection(accounts);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: AppSpacing.xxxl,
                      height: AppSpacing.xxs,
                      decoration: BoxDecoration(
                        color: palette.border,
                        borderRadius: AppRadius.radiusFull,
                      ),
                    ),
                  ),
                  AppSpacing.gapH12,
                  Row(
                    children: [
                      Container(
                        width: AppSpacing.xxxl,
                        height: AppSpacing.xxxl,
                        decoration: BoxDecoration(
                          color: AppColors.moduleMoney.withValues(alpha: 0.12),
                          borderRadius: AppRadius.borderMd,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.moduleMoney,
                          size: AppSpacing.lg,
                        ),
                      ),
                      AppSpacing.gapW12,
                      Expanded(
                        child: AppText(
                          StringConstants.transferBetweenAccounts,
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.heading,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: palette.caption),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  AppSpacing.gapH16,
                  if (accounts.length < 2)
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.edgeInsetsAllLg,
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: AppRadius.borderLg,
                        border: Border.all(color: palette.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.moduleMoney,
                            size: AppSpacing.xxl,
                          ),
                          AppSpacing.gapH8,
                          AppText(
                            StringConstants.transferInsufficientAccounts,
                            textAlign: TextAlign.center,
                            style: context.text.bodyMedium?.copyWith(
                              color: palette.heading,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Source Account
                    DropdownButtonFormField<int>(
                      key: ValueKey('transfer_from_$_fromAccountId'),
                      initialValue: _fromAccountId,
                      decoration: const InputDecoration(
                        labelText: StringConstants.transferFromLabel,
                        prefixIcon: Icon(
                          Icons.call_made_rounded,
                          color: AppColors.error,
                        ),
                      ),
                      items: accounts
                          .map(
                            (acc) => DropdownMenuItem<int>(
                              value: acc.id,
                              child: AppText(
                                '${acc.name} (${CurrencyUtils.format(acc.balance)})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _fromAccountId = val),
                    ),
                    AppSpacing.gapH8,
                    Center(
                      child: IconButton.filledTonal(
                        key: const ValueKey('transfer_swap_accounts_btn'),
                        tooltip: StringConstants.transfer,
                        onPressed: _swapAccounts,
                        icon: const Icon(Icons.swap_vert_rounded),
                      ),
                    ),
                    AppSpacing.gapH8,
                    // Destination Account
                    DropdownButtonFormField<int>(
                      key: ValueKey('transfer_to_$_toAccountId'),
                      initialValue: _toAccountId,
                      decoration: const InputDecoration(
                        labelText: StringConstants.transferToLabel,
                        prefixIcon: Icon(
                          Icons.call_received_rounded,
                          color: AppColors.moduleMoney,
                        ),
                      ),
                      items: accounts
                          .map(
                            (acc) => DropdownMenuItem<int>(
                              value: acc.id,
                              child: AppText(
                                '${acc.name} (${CurrencyUtils.format(acc.balance)})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _toAccountId = val),
                    ),
                    AppSpacing.gapH12,
                    TextFormField(
                      key: const ValueKey('transfer_amount_input'),
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.validateAmount,
                      decoration: InputDecoration(
                        labelText: StringConstants.amountLabel,
                        prefixText: '${CurrencyUtils.symbol} ',
                      ),
                    ),
                    AppSpacing.gapH12,
                    TextFormField(
                      key: const ValueKey('transfer_note_input'),
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: StringConstants.noteLabel,
                        hintText: StringConstants.noteHint,
                      ),
                    ),
                    AppSpacing.gapH20,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const ValueKey('transfer_submit_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.moduleMoney,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        onPressed: () => _submitTransfer(context),
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const AppText(StringConstants.transfer),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
