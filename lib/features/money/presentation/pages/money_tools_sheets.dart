import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../di/injection_container.dart';
import '../../../security/domain/repositories/security_repository.dart';
import '../../../security/presentation/widgets/security_setup_wizard.dart';
import '../../domain/entities/money_account_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../bloc/money_bloc.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 1. SUBSCRIPTIONS & AUTO-KILL SHEET
// ═══════════════════════════════════════════════════════════════════════════

class SubscriptionsSheet extends StatelessWidget {
  const SubscriptionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<MoneyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const SubscriptionsSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkScaffoldBackground
            : AppColors.scaffoldBackground,
        borderRadius: AppRadius.topXxl,
      ),
      child: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          final subs = state is MoneyLoaded
              ? state.subscriptions
              : const <SubscriptionEntity>[];
          return Column(
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
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        StringConstants.subscriptions,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddSubscriptionDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(StringConstants.add),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    SubscriptionsContent(
                      subscriptions: subs,
                      onAddTap: () => _showAddSubscriptionDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showAddSubscriptionDialog(BuildContext context) async {
    final bloc = context.read<MoneyBloc>();
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime renewal = DateTime.now().add(const Duration(days: 30));
    bool autoKill = true;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
            title: const Text(StringConstants.addSubscription),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      validator: (v) => Validators.validateRequired(v, 'Name'),
                      decoration: const InputDecoration(
                        labelText: 'Service Name',
                        hintText: 'e.g. Netflix, Spotify',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.validateAmount,
                      decoration: InputDecoration(
                        labelText: '${StringConstants.amountLabel} / month',
                        prefixText: '${CurrencyUtils.symbol} ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.event_rounded,
                        color: AppColors.moduleMoney,
                      ),
                      title: const Text(StringConstants.renewalDateLabel),
                      subtitle: Text(AppDateUtils.formatDate(renewal)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: renewal,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
                        );
                        if (picked != null) {
                          setState(() => renewal = picked);
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(StringConstants.autoKillLabel),
                      value: autoKill,
                      activeThumbColor: AppColors.moduleMoney,
                      onChanged: (v) => setState(() => autoKill = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text(StringConstants.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moduleMoney,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  bloc.add(
                    AddSubscription(
                      name: nameCtrl.text.trim(),
                      amount: double.parse(amountCtrl.text.trim()),
                      renewalDate: renewal,
                      iconCodePoint: Icons.subscriptions_rounded.codePoint,
                      autoKillEnabled: autoKill,
                    ),
                  );
                  Navigator.of(dialogCtx).pop();
                },
                child: const Text(StringConstants.save),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Reusable Subscriptions body (used both inline on Overview and inside [SubscriptionsSheet]).
class SubscriptionsContent extends StatelessWidget {
  final List<SubscriptionEntity> subscriptions;
  final VoidCallback? onAddTap;

  const SubscriptionsContent({
    super.key,
    required this.subscriptions,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.moneyWarning80.withValues(
              alpha: isDark ? 0.15 : 0.08,
            ),
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: AppColors.moneyWarning80.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: AppColors.moneyWarning80,
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Auto-Kill alerts remind you 2 days prior to auto-debit so you never pay for unused services.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...subscriptions.map(
          (sub) => _SubscriptionTile(sub: sub, isDark: isDark),
        ),
        if (onAddTap != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(StringConstants.addSubscription),
            ),
          ),
      ],
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final SubscriptionEntity sub;
  final bool isDark;

  const _SubscriptionTile({required this.sub, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(sub.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Renews ${sub.renewalLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
                if (sub.autoKillEnabled)
                  GestureDetector(
                    onTap: () =>
                        context.read<MoneyBloc>().add(ToggleAutoKill(sub.id)),
                    child: const Text(
                      '⚡ Auto-Kill Protection ON • tap to disable',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.moduleMoney,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () =>
                        context.read<MoneyBloc>().add(ToggleAutoKill(sub.id)),
                    child: Text(
                      'Tap to enable Auto-Kill',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${CurrencyUtils.format(sub.amount)}/mo',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () =>
                    context.read<MoneyBloc>().add(DeleteSubscription(sub.id)),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. LEND & BORROW (IOU) SHEET
// ═══════════════════════════════════════════════════════════════════════════

class IouSheet extends StatelessWidget {
  const IouSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<MoneyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(value: bloc, child: const IouSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkScaffoldBackground
            : AppColors.scaffoldBackground,
        borderRadius: AppRadius.topXxl,
      ),
      child: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          final ious = state is MoneyLoaded ? state.ious : const <IouEntity>[];
          return Column(
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
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        StringConstants.lendAndBorrow,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddIouDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(StringConstants.addIou),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    IouContent(
                      ious: ious,
                      onAddTap: () => _showAddIouDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showAddIouDialog(BuildContext context) async {
    final bloc = context.read<MoneyBloc>();
    final personCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'lent';
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
            title: const Text(StringConstants.addIou),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text(StringConstants.lent),
                          selected: type == 'lent',
                          onSelected: (_) => setState(() => type = 'lent'),
                        ),
                        ChoiceChip(
                          label: const Text(StringConstants.borrowed),
                          selected: type == 'borrowed',
                          onSelected: (_) => setState(() => type = 'borrowed'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: personCtrl,
                      validator: (v) => Validators.validateRequired(
                        v,
                        StringConstants.personLabel,
                      ),
                      decoration: const InputDecoration(
                        labelText: StringConstants.personLabel,
                        hintText: 'e.g. David Kumar',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.validateAmount,
                      decoration: InputDecoration(
                        labelText: StringConstants.amountLabel,
                        prefixText: '${CurrencyUtils.symbol} ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: StringConstants.noteLabel,
                        hintText: 'e.g. Dinner split bill',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text(StringConstants.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moduleMoney,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  bloc.add(
                    AddIou(
                      person: personCtrl.text.trim(),
                      amount: double.parse(amountCtrl.text.trim()),
                      type: type,
                      note: noteCtrl.text.trim(),
                    ),
                  );
                  Navigator.of(dialogCtx).pop();
                },
                child: const Text(StringConstants.save),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Reusable IOU body (used inline and inside [IouSheet]).
class IouContent extends StatelessWidget {
  final List<IouEntity> ious;
  final VoidCallback? onAddTap;

  const IouContent({super.key, required this.ious, this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ious.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No active IOUs.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
              ),
            ),
          )
        else
          ...ious.map((iou) {
            final color = iou.isLent ? AppColors.moduleMoney : AppColors.error;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardBackground
                    : AppColors.cardBackground,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(
                      iou.isLent
                          ? Icons.call_made_rounded
                          : Icons.call_received_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          iou.person,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${iou.typeLabel} • ${iou.note}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyUtils.format(iou.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () =>
                            context.read<MoneyBloc>().add(SettleIou(iou.id)),
                        child: const Text(
                          StringConstants.settle,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        if (onAddTap != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(StringConstants.addIou),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. ACCOUNTS / ASSETS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class MoneyAccountsSheet extends StatelessWidget {
  const MoneyAccountsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<MoneyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const MoneyAccountsSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkScaffoldBackground
            : AppColors.scaffoldBackground,
        borderRadius: AppRadius.topXxl,
      ),
      child: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          final accounts = state is MoneyLoaded
              ? state.accounts
              : const <MoneyAccountEntity>[];
          final total = accounts.fold<double>(0, (s, a) => s + a.balance);

          return Column(
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
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            StringConstants.accounts,
                            style: AppTextStyles.headingSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextHeading
                                  : AppColors.textHeading,
                            ),
                          ),
                          Text(
                            '${StringConstants.totalAssets}: ${CurrencyUtils.format(total, decimals: 2)}',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextCaption
                                  : AppColors.textCaption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAccountDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(StringConstants.addAccount),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    ...accounts.map((acc) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
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
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: acc.color.withValues(alpha: 0.14),
                                borderRadius: AppRadius.radiusMd,
                              ),
                              child: Icon(acc.icon, color: acc.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.name,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextHeading
                                          : AppColors.textHeading,
                                    ),
                                  ),
                                  Text(
                                    acc.typeLabel,
                                    style: AppTextStyles.caption.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextCaption
                                          : AppColors.textCaption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyUtils.format(acc.balance, decimals: 2),
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkTextHeading
                                    : AppColors.textHeading,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () =>
                                  _showAccountDialog(context, existing: acc),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () => context.read<MoneyBloc>().add(
                                DeleteAccount(acc.id),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showAccountDialog(
    BuildContext context, {
    MoneyAccountEntity? existing,
  }) async {
    final bloc = context.read<MoneyBloc>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: existing != null ? existing.balance.toStringAsFixed(0) : '',
    );
    String type = existing?.type ?? MoneyAccountType.cash;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
            title: Text(
              existing == null
                  ? StringConstants.addAccount
                  : StringConstants.editAccount,
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      validator: (v) => Validators.validateRequired(
                        v,
                        StringConstants.accountName,
                      ),
                      decoration: const InputDecoration(
                        labelText: StringConstants.accountName,
                        hintText: 'e.g. HDFC Savings',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: StringConstants.accountType,
                      ),
                      items: MoneyAccountType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(MoneyAccountType.label(t)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: balanceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: Validators.validateNonNegativeAmount,
                      decoration: InputDecoration(
                        labelText: StringConstants.balanceLabel,
                        prefixText: '${CurrencyUtils.symbol} ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text(StringConstants.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moduleMoney,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final bal = double.parse(balanceCtrl.text.trim());
                  if (existing == null) {
                    bloc.add(
                      AddAccount(
                        name: nameCtrl.text.trim(),
                        type: type,
                        balance: bal,
                      ),
                    );
                  } else {
                    bloc.add(
                      UpdateAccount(
                        MoneyAccountEntity(
                          id: existing.id,
                          name: nameCtrl.text.trim(),
                          type: type,
                          balance: bal,
                          colorValue: MoneyAccountType.color(type).toARGB32(),
                          iconCodePoint: MoneyAccountType.icon(type).codePoint,
                        ),
                      ),
                    );
                  }
                  Navigator.of(dialogCtx).pop();
                },
                child: const Text(StringConstants.save),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. MONEY SETTINGS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class MoneySettingsSheet extends StatelessWidget {
  const MoneySettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<MoneyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const MoneySettingsSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.topXxl,
      ),
      child: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          if (state is! MoneyLoaded) return const SizedBox.shrink();
          final settings = state.settings;

          return Column(
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
                StringConstants.moneySettings,
                style: AppTextStyles.headingSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 16),

              // Currency selector
              Text(
                StringConstants.currencyLabel,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CurrencyUtils.supportedCurrencies.map((c) {
                  final selected = c.code == settings.currencyCode;
                  return ChoiceChip(
                    label: Text('${c.symbol} ${c.code}'),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: AppColors.moduleMoney,
                    labelStyle: AppTextStyles.captionBold.copyWith(
                      color: selected
                          ? Colors.white
                          : (isDark
                                ? AppColors.darkTextBody
                                : AppColors.textBody),
                    ),
                    onSelected: (_) {
                      context.read<MoneyBloc>().add(
                        UpdateMoneySettings(currencyCode: c.code),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Budget Alerts toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  StringConstants.budgetAlertsLabel,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                  ),
                ),
                subtitle: Text(
                  StringConstants.budgetAlertsSubtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
                value: settings.budgetAlertsEnabled,
                activeThumbColor: AppColors.moduleMoney,
                onChanged: (v) {
                  context.read<MoneyBloc>().add(
                    UpdateMoneySettings(budgetAlertsEnabled: v),
                  );
                },
              ),

              // Vault Security lock toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  StringConstants.moneyLockLabel,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                  ),
                ),
                subtitle: Text(
                  StringConstants.moneyLockSubtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
                value: settings.moneyLockEnabled,
                activeThumbColor: AppColors.moduleMoney,
                onChanged: (v) async {
                  final bloc = context.read<MoneyBloc>();
                  if (v && sl.isRegistered<SecurityRepository>()) {
                    final repo = sl<SecurityRepository>();
                    final config = await repo.getConfig();
                    if (!config.isSecurityEnabled && context.mounted) {
                      await SecuritySetupWizard.show(
                        context,
                        securityRepository: repo,
                        onCompleted: () {
                          bloc.add(
                            const UpdateMoneySettings(moneyLockEnabled: true),
                          );
                        },
                      );
                      return;
                    }
                  }
                  bloc.add(UpdateMoneySettings(moneyLockEnabled: v));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
