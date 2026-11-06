import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
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
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final isLent = type == 'lent';
          return AlertDialog(
            backgroundColor: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
            title: Text(
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
                            label: const Text('I Lent (Collect)'),
                            selected: type == 'lent',
                            onSelected: (_) => setState(() => type = 'lent'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('I Borrowed (Pay)'),
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
                      title: Text(
                        isLent ? 'Collection Due Date' : 'Repayment Due Date',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
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
                        child: const Text('Pick Date'),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isLent
                            ? 'Remind me to collect money'
                            : 'Remind me to pay back',
                        style: const TextStyle(
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
                child: const Text(StringConstants.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moduleMoney,
                  foregroundColor: Colors.white,
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
                    const Text(
                      'TO COLLECT (YOU LENT)',
                      style: TextStyle(
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
                      child: Text(
                        CurrencyUtils.format(totalToCollect),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
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
                    const Text(
                      'TO PAY BACK (BORROWED)',
                      style: TextStyle(
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
                      child: Text(
                        CurrencyUtils.format(totalToPay),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
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
              child: Text(
                'No active IOUs. Tap + Add IOU to record lent or borrowed money.',
                textAlign: TextAlign.center,
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
            final dueBadge = iou.dueBadgeLabel;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardBackground
                    : AppColors.cardBackground,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(
                  color: iou.isOverdue
                      ? AppColors.error.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkDivider : AppColors.divider),
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
                        Text(
                          iou.person,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${iou.typeLabel} • ${iou.cleanNote}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
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
                            child: Text(
                              '⏰ $dueBadge',
                              style: TextStyle(
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
                      Text(
                        CurrencyUtils.format(iou.amount),
                        style: TextStyle(
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
                            onTap: () => context.read<MoneyBloc>().add(
                              SettleIou(iou.id),
                            ),
                            child: const Text(
                              StringConstants.settle,
                              style: TextStyle(
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
                title: Text(
                  'Clear All Money Data (Start Fresh)',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
                subtitle: Text(
                  'Removes all transactions, IOUs, subscriptions, accounts & resets budgets to 0.',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
                onTap: () async {
                  final bloc = context.read<MoneyBloc>();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Start Fresh?'),
                      content: const Text(
                        'This will clear all existing Money transactions, lent/borrowed entries, subscriptions, accounts, and reset your budget to 0 so you can enter your own fresh data.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(false),
                          child: const Text(StringConstants.cancel),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(dCtx).pop(true),
                          child: const Text('Clear & Start Fresh'),
                        ),
                      ],
                    ),
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
