import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../di/injection_container.dart';
import '../../../security/domain/repositories/security_repository.dart';
import '../../../security/presentation/widgets/security_setup_wizard.dart';
import '../../domain/entities/money_account_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../bloc/money_bloc.dart';
import '../widgets/account_transfer_sheet.dart';
import '../widgets/bill_split_sheet.dart';

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
      backgroundColor: AppColors.transparent,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const SubscriptionsSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: palette.scaffold,
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
                  color: palette.divider,
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        StringConstants.subscriptions,
                        style: text.headlineSmall?.copyWith(
                          color: palette.heading,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddSubscriptionDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const AppText(StringConstants.add),
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
          return AlertDialog(
            backgroundColor: ctx.palette.card,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusXl,
            ),
            title: const AppText(StringConstants.addSubscription),
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
                      title: const AppText(StringConstants.renewalDateLabel),
                      subtitle: AppText(AppDateUtils.formatDate(renewal)),
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
                      title: const AppText(StringConstants.autoKillLabel),
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
                child: const AppText(StringConstants.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moduleMoney,
                  foregroundColor: AppColors.textWhite,
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
                child: const AppText(StringConstants.save),
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
    final palette = context.palette;
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.moneyWarning80.withValues(
              alpha: palette.isDark ? 0.15 : 0.08,
            ),
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: AppColors.moneyWarning80.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.moneyWarning80,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppText(
                  'Auto-Kill alerts remind you 2 days prior to auto-debit so you never pay for unused services.',
                  style: text.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.heading,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...subscriptions.map((sub) => _SubscriptionTile(sub: sub)),
        if (onAddTap != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const AppText(StringConstants.addSubscription),
            ),
          ),
      ],
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final SubscriptionEntity sub;

  const _SubscriptionTile({required this.sub});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: palette.divider),
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
                AppText(
                  sub.name,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: palette.heading,
                  ),
                ),
                AppText(
                  'Renews ${sub.renewalLabel}',
                  style: text.labelMedium?.copyWith(
                    fontSize: 12,
                    color: palette.caption,
                  ),
                ),
                if (sub.autoKillEnabled)
                  GestureDetector(
                    onTap: () =>
                        context.read<MoneyBloc>().add(ToggleAutoKill(sub.id)),
                    child: AppText(
                      '⚡ Auto-Kill Protection ON • tap to disable',
                      style: text.labelSmall?.copyWith(
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
                    child: AppText(
                      'Tap to enable Auto-Kill',
                      style: text.labelSmall?.copyWith(
                        fontSize: 11,
                        color: palette.caption,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                '${CurrencyUtils.format(sub.amount)}/mo',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: palette.heading,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    key: ValueKey('sub_pay_${sub.id}'),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.read<MoneyBloc>().add(
                        RecordSubscriptionPayment(sub),
                      );
                      SnackbarUtils.showSuccess(
                        context,
                        StringConstants.subscriptionPaymentLogged,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.moduleMoney.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AppText(
                        StringConstants.payAndAdvanceLabel,
                        style: text.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.moduleMoney,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.read<MoneyBloc>().add(
                      DeleteSubscription(sub.id),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: palette.caption,
                    ),
                  ),
                ],
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
      backgroundColor: AppColors.transparent,
      builder: (_) => BlocProvider.value(value: bloc, child: const IouSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: palette.scaffold,
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
                  color: palette.divider,
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        StringConstants.lendAndBorrow,
                        style: text.headlineSmall?.copyWith(
                          color: palette.heading,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => BillSplitSheet.show(context),
                      icon: const Icon(Icons.call_split_rounded, size: 17),
                      label: const AppText(StringConstants.billSplitShort),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddIouDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const AppText(StringConstants.addIou),
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

  static Future<void> showAddDialog(
    BuildContext context, {
    String initialType = 'lent',
  }) => _showAddIouDialog(context, initialType: initialType);

  static Future<void> _showAddIouDialog(
    BuildContext context, {
    String initialType = 'lent',
  }) async {
    final bloc = context.read<MoneyBloc>();
    final personCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = initialType;
    DateTime? dueDate = DateTime.now().add(const Duration(days: 7));
    bool enableReminder = true;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isLent = type == 'lent';
          final text = ctx.text;
          return AlertDialog(
            backgroundColor: ctx.palette.card,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusXl,
            ),
            title: AppText(
              isLent
                  ? 'Lent Money (To Collect)'
                  : 'Borrowed Money (To Pay Back)',
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const AppText('I Lent (Collect)'),
                            selected: type == 'lent',
                            onSelected: (_) => setState(() => type = 'lent'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const AppText('I Borrowed (Pay)'),
                            selected: type == 'borrowed',
                            onSelected: (_) =>
                                setState(() => type = 'borrowed'),
                          ),
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
                      decoration: InputDecoration(
                        labelText: isLent
                            ? 'Who did you give money to?'
                            : 'Who did you borrow from?',
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
                        hintText: 'e.g. Dinner split bill / Emergency',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.event_available_rounded,
                        color: isLent ? AppColors.moduleMoney : AppColors.error,
                      ),
                      title: AppText(
                        isLent ? 'Collection Due Date' : 'Repayment Due Date',
                        style: text.labelLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: AppText(
                        dueDate != null
                            ? AppDateUtils.formatDate(dueDate!)
                            : 'No due date set',
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate:
                                dueDate ?? now.add(const Duration(days: 7)),
                            firstDate: now.subtract(const Duration(days: 30)),
                            lastDate: now.add(const Duration(days: 730)),
                          );
                          if (picked != null) {
                            setState(() => dueDate = picked);
                          }
                        },
                        child: const AppText('Pick Date'),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: AppText(
                        isLent
                            ? 'Remind me to collect money'
                            : 'Remind me to pay back',
                        style: text.labelMedium?.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: enableReminder,
                      activeThumbColor: AppColors.moduleMoney,
                      onChanged: (v) => setState(() => enableReminder = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const AppText(StringConstants.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moduleMoney,
                  foregroundColor: AppColors.textWhite,
                ),
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final person = personCtrl.text.trim();
                  final amount = double.parse(amountCtrl.text.trim());
                  final formattedNote = IouEntity.formatNoteWithDueDate(
                    noteCtrl.text.trim(),
                    dueDate,
                  );
                  bloc.add(
                    AddIou(
                      person: person,
                      amount: amount,
                      type: type,
                      note: formattedNote,
                    ),
                  );
                  if (enableReminder &&
                      dueDate != null &&
                      sl.isRegistered<NotificationService>()) {
                    try {
                      final scheduled = DateTime(
                        dueDate!.year,
                        dueDate!.month,
                        dueDate!.day,
                        10,
                        0,
                      );
                      if (scheduled.isAfter(DateTime.now())) {
                        await sl<NotificationService>().scheduleNotification(
                          id: person.hashCode.abs() % 90000 + 10000,
                          title: isLent
                              ? 'Collect ${CurrencyUtils.format(amount)} from $person'
                              : 'Pay ${CurrencyUtils.format(amount)} to $person',
                          body: noteCtrl.text.trim().isNotEmpty
                              ? noteCtrl.text.trim()
                              : (isLent
                                    ? 'Reminder: Lent money collection is due today.'
                                    : 'Reminder: Borrowed money repayment is due today.'),
                          scheduledDate: scheduled,
                        );
                      }
                    } catch (_) {}
                  }
                  if (dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop();
                  }
                },
                child: const AppText(StringConstants.save),
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
    final palette = context.palette;
    final text = context.text;
    final totalToCollect = ious
        .where((i) => i.isLent && !i.isSettled)
        .fold<double>(0, (s, i) => s + i.amount);
    final totalToPay = ious
        .where((i) => !i.isLent && !i.isSettled)
        .fold<double>(0, (s, i) => s + i.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Strip: To Collect (Lent) vs To Pay Back (Borrowed)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.moduleMoney.withValues(alpha: 0.10),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: AppColors.moduleMoney.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'TO COLLECT (YOU LENT)',
                      style: text.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.moduleMoney,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AppText(
                        CurrencyUtils.format(totalToCollect),
                        style: text.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: palette.heading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'TO PAY BACK (BORROWED)',
                      style: text.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AppText(
                        CurrencyUtils.format(totalToPay),
                        style: text.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: palette.heading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (ious.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: AppText(
                'No active IOUs. Tap + Add IOU to record lent or borrowed money.',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: palette.caption),
              ),
            ),
          )
        else
          ...ious.map((iou) {
            final color = iou.isLent ? AppColors.moduleMoney : AppColors.error;
            final dueBadge = iou.dueBadgeLabel;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(
                  color: iou.isOverdue
                      ? AppColors.error.withValues(alpha: 0.5)
                      : palette.divider,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          iou.person,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: palette.heading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          '${iou.typeLabel} • ${iou.cleanNote}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelMedium?.copyWith(
                            fontSize: 12,
                            color: palette.caption,
                          ),
                        ),
                        if (dueBadge != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (iou.isOverdue
                                          ? AppColors.error
                                          : AppColors.warning)
                                      .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: AppText(
                              '⏰ $dueBadge',
                              style: text.labelSmall?.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: iou.isOverdue
                                    ? AppColors.error
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        CurrencyUtils.format(iou.amount),
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (sl.isRegistered<NotificationService>()) {
                                try {
                                  await sl<NotificationService>()
                                      .showInstantNotification(
                                        id: iou.id + 40000,
                                        title: iou.isLent
                                            ? 'Reminder: Collect ${CurrencyUtils.format(iou.amount)} from ${iou.person}'
                                            : 'Reminder: Pay ${CurrencyUtils.format(iou.amount)} to ${iou.person}',
                                        body: iou.cleanNote,
                                      );
                                } catch (_) {}
                              }
                              if (context.mounted) {
                                SnackbarUtils.showSuccess(
                                  context,
                                  'Reminder alert set for ${iou.person}!',
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.notifications_active_outlined,
                                size: 15,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          GestureDetector(
                            key: ValueKey('iou_settle_${iou.id}'),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.read<MoneyBloc>().add(
                                SettleIou(iou.id, recordTransaction: true),
                              );
                              SnackbarUtils.showSuccess(
                                context,
                                StringConstants.iouSettledWithCashflow,
                              );
                            },
                            child: AppText(
                              StringConstants.settle,
                              style: text.labelSmall?.copyWith(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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
              label: const AppText(StringConstants.addIou),
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
      backgroundColor: AppColors.transparent,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const MoneyAccountsSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: palette.scaffold,
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
                  color: palette.divider,
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
                          AppText(
                            StringConstants.accounts,
                            style: text.headlineSmall?.copyWith(
                              color: palette.heading,
                            ),
                          ),
                          AppText(
                            '${StringConstants.totalAssets}: ${CurrencyUtils.format(total, decimals: 2)}',
                            style: text.labelSmall?.copyWith(
                              color: palette.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (accounts.length >= 2)
                      TextButton.icon(
                        key: const ValueKey('accounts_sheet_transfer_btn'),
                        onPressed: () => AccountTransferSheet.show(context),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const AppText(StringConstants.transfer),
                      ),
                    TextButton.icon(
                      onPressed: () => _showAccountDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const AppText(StringConstants.addAccount),
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
                          color: palette.card,
                          borderRadius: AppRadius.radiusLg,
                          border: Border.all(color: palette.divider),
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
                                  AppText(
                                    acc.name,
                                    style: text.titleSmall?.copyWith(
                                      color: palette.heading,
                                    ),
                                  ),
                                  AppText(
                                    acc.typeLabel,
                                    style: text.labelSmall?.copyWith(
                                      color: palette.caption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppText(
                              CurrencyUtils.format(acc.balance, decimals: 2),
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: palette.heading,
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
          return AlertDialog(
            backgroundColor: ctx.palette.card,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusXl,
            ),
            title: AppText(
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
                              child: AppText(MoneyAccountType.label(t)),
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
                child: const AppText(StringConstants.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moduleMoney,
                  foregroundColor: AppColors.textWhite,
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
                child: const AppText(StringConstants.save),
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
      backgroundColor: AppColors.transparent,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const MoneySettingsSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: palette.card,
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
                    color: palette.divider,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppText(
                StringConstants.moneySettings,
                style: text.headlineSmall?.copyWith(color: palette.heading),
              ),
              const SizedBox(height: 16),

              // Currency selector
              AppText(
                StringConstants.currencyLabel,
                style: text.titleSmall?.copyWith(color: palette.heading),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CurrencyUtils.supportedCurrencies.map((c) {
                  final selected = c.code == settings.currencyCode;
                  return ChoiceChip(
                    label: AppText('${c.symbol} ${c.code}'),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: AppColors.moduleMoney,
                    labelStyle: text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.textWhite : palette.body,
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
                title: AppText(
                  StringConstants.budgetAlertsLabel,
                  style: text.titleSmall?.copyWith(color: palette.heading),
                ),
                subtitle: AppText(
                  StringConstants.budgetAlertsSubtitle,
                  style: text.labelSmall?.copyWith(color: palette.caption),
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
                title: AppText(
                  StringConstants.moneyLockLabel,
                  style: text.titleSmall?.copyWith(color: palette.heading),
                ),
                subtitle: AppText(
                  StringConstants.moneyLockSubtitle,
                  style: text.labelSmall?.copyWith(color: palette.caption),
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
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restart_alt_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                title: AppText(
                  'Clear All Money Data (Start Fresh)',
                  style: text.titleSmall?.copyWith(color: AppColors.error),
                ),
                subtitle: AppText(
                  'Removes all transactions, IOUs, subscriptions, accounts & resets budgets to 0.',
                  style: text.labelSmall?.copyWith(color: palette.caption),
                ),
                onTap: () async {
                  final bloc = context.read<MoneyBloc>();
                  final confirmed = await ConfirmationDialog.show(
                    context,
                    title: 'Start Fresh?',
                    message:
                        'This will clear all existing Money transactions, lent/borrowed entries, subscriptions, accounts, and reset your budget to 0 so you can enter your own fresh data.',
                    confirmLabel: 'Clear & Start Fresh',
                    cancelLabel: StringConstants.cancel,
                    isDestructive: true,
                  );
                  if (confirmed == true) {
                    bloc.add(const ResetAllMoneyData());
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      SnackbarUtils.showSuccess(
                        context,
                        'All Money data cleared! Ready to start fresh.',
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
