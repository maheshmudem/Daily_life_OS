import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/category_budget_entity.dart';
import '../../domain/entities/money_account_entity.dart';
import '../../domain/entities/money_category.dart';
import '../../domain/entities/money_insights.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/usecases/get_transactions_and_budget_usecase.dart';
import '../../domain/usecases/manage_budgets_and_accounts_usecase.dart';
import '../../domain/usecases/manage_transactions_usecase.dart';
import '../../domain/usecases/manage_subscriptions_and_ious_usecase.dart';
import '../../domain/usecases/money_insights_usecase.dart';
import 'money_event.dart';
import 'money_state.dart';

export 'money_event.dart';
export 'money_state.dart';

class MoneyBloc extends Bloc<MoneyEvent, MoneyState> {
  final GetRecentTransactionsUseCase getRecentTransactionsUseCase;
  final GetBudgetUseCase getBudgetUseCase;
  final GetSubscriptionsUseCase getSubscriptionsUseCase;
  final GetIousUseCase getIousUseCase;
  final AddTransactionUseCase addTransactionUseCase;
  final ToggleAutoKillUseCase toggleAutoKillUseCase;
  final SettleIouUseCase settleIouUseCase;
  final AddIouUseCase addIouUseCase;
  final UpdateBudgetUseCase updateBudgetUseCase;

  // ── v3 ──────────────────────────────────────────────────────────────────
  final GetAllTransactionsUseCase getAllTransactionsUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final GetCategoryLimitsUseCase getCategoryLimitsUseCase;
  final SetCategoryLimitUseCase setCategoryLimitUseCase;
  final GetAccountsUseCase getAccountsUseCase;
  final AddAccountUseCase addAccountUseCase;
  final UpdateAccountUseCase updateAccountUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;
  final AddSubscriptionUseCase addSubscriptionUseCase;
  final UpdateSubscriptionUseCase? updateSubscriptionUseCase;
  final DeleteSubscriptionUseCase deleteSubscriptionUseCase;
  final DeleteIouUseCase deleteIouUseCase;
  final GetMoneySettingsUseCase getMoneySettingsUseCase;
  final UpdateMoneySettingsUseCase updateMoneySettingsUseCase;
  final NotifyBudgetThresholdUseCase notifyBudgetThresholdUseCase;
  final FilterMonthTransactionsUseCase filterMonthTransactionsUseCase;
  final FilterPeriodTransactionsUseCase filterPeriodTransactionsUseCase;
  final BuildCategoryBudgetsUseCase buildCategoryBudgetsUseCase;
  final ComputeMoneyInsightsUseCase computeMoneyInsightsUseCase;

  /// Month currently shown by Activity / Budgets / Insights.
  DateTime _selectedMonth = _monthOf(DateTime.now());

  /// Horizon currently shown by Budgets / Insights.
  MoneyPeriod _selectedPeriod = MoneyPeriod.monthly;

  MoneyBloc({
    required this.getRecentTransactionsUseCase,
    required this.getBudgetUseCase,
    required this.getSubscriptionsUseCase,
    required this.getIousUseCase,
    required this.addTransactionUseCase,
    required this.toggleAutoKillUseCase,
    required this.settleIouUseCase,
    required this.addIouUseCase,
    required this.updateBudgetUseCase,
    required this.getAllTransactionsUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.getCategoryLimitsUseCase,
    required this.setCategoryLimitUseCase,
    required this.getAccountsUseCase,
    required this.addAccountUseCase,
    required this.updateAccountUseCase,
    required this.deleteAccountUseCase,
    required this.addSubscriptionUseCase,
    this.updateSubscriptionUseCase,
    required this.deleteSubscriptionUseCase,
    required this.deleteIouUseCase,
    required this.getMoneySettingsUseCase,
    required this.updateMoneySettingsUseCase,
    required this.notifyBudgetThresholdUseCase,
    this.filterMonthTransactionsUseCase =
        const FilterMonthTransactionsUseCase(),
    this.filterPeriodTransactionsUseCase =
        const FilterPeriodTransactionsUseCase(),
    this.buildCategoryBudgetsUseCase = const BuildCategoryBudgetsUseCase(),
    this.computeMoneyInsightsUseCase = const ComputeMoneyInsightsUseCase(),
  }) : super(MoneyInitial()) {
    on<LoadMoney>(_onLoad);
    on<AddTransaction>(_onAddTransaction);
    on<ToggleAutoKill>(_onToggleAutoKill);
    on<SettleIou>(_onSettleIou);
    on<AddIou>(_onAddIou);
    on<UpdateBudget>(_onUpdateBudget);
    on<ChangeMonth>(_onChangeMonth);
    on<ChangeMoneyPeriod>(_onChangePeriod);
    on<ApplyBudgetPlan>(_onApplyBudgetPlan);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<SetCategoryLimit>(_onSetCategoryLimit);
    on<AddAccount>(_onAddAccount);
    on<UpdateAccount>(_onUpdateAccount);
    on<DeleteAccount>(_onDeleteAccount);
    on<AddSubscription>(_onAddSubscription);
    on<DeleteSubscription>(_onDeleteSubscription);
    on<DeleteIou>(_onDeleteIou);
    on<UpdateMoneySettings>(_onUpdateMoneySettings);
    on<ResetAllMoneyData>(_onResetAllMoneyData);
    on<TransferBetweenAccounts>(_onTransferBetweenAccounts);
    on<RecordSubscriptionPayment>(_onRecordSubscriptionPayment);
  }

  static DateTime _monthOf(DateTime date) => DateTime(date.year, date.month, 1);

  // ── Loading ─────────────────────────────────────────────────────────────

  Future<void> _onLoad(LoadMoney event, Emitter<MoneyState> emit) async {
    if (state is! MoneyLoaded) {
      emit(MoneyLoading());
    }
    await _reload(emit);
  }

  Future<void> _reload(Emitter<MoneyState> emit) async {
    try {
      final txFuture = getRecentTransactionsUseCase();
      final budgetFuture = getBudgetUseCase();
      final subsFuture = getSubscriptionsUseCase();
      final iousFuture = getIousUseCase();
      final allTxFuture = getAllTransactionsUseCase();
      final limitsFuture = getCategoryLimitsUseCase();
      final accountsFuture = getAccountsUseCase();
      final settingsFuture = getMoneySettingsUseCase();

      await Future.wait([
        txFuture,
        budgetFuture,
        subsFuture,
        iousFuture,
        allTxFuture,
        limitsFuture,
        accountsFuture,
        settingsFuture,
      ]);

      final transactions = await txFuture;
      final budget = await budgetFuture;
      final subscriptions = await subsFuture;
      final ious = await iousFuture;
      final allTransactions = await allTxFuture;
      final limits = await limitsFuture;
      final accounts = await accountsFuture;
      final settings = await settingsFuture;

      CurrencyUtils.setCurrency(settings.currencyCode);

      final monthTransactions = filterMonthTransactionsUseCase(
        allTransactions,
        _selectedMonth,
      );
      final periodTransactions = filterPeriodTransactionsUseCase(
        allTransactions,
        anchorMonth: _selectedMonth,
        period: _selectedPeriod,
      );
      final categoryBudgets = buildCategoryBudgetsUseCase(
        limits: limits,
        monthTransactions: periodTransactions,
        period: _selectedPeriod,
      );
      final insights = computeMoneyInsightsUseCase(
        transactions: allTransactions,
        month: _selectedMonth,
        categoryBudgets: categoryBudgets,
        accounts: accounts,
        fallbackMonthlyBudget: budget.monthlyBudget,
        period: _selectedPeriod,
      );

      emit(
        MoneyLoaded(
          transactions: transactions,
          budget: budget,
          subscriptions: subscriptions,
          ious: ious,
          allTransactions: allTransactions,
          selectedMonth: _selectedMonth,
          selectedPeriod: _selectedPeriod,
          monthTransactions: monthTransactions,
          periodTransactions: periodTransactions,
          categoryBudgets: categoryBudgets,
          categoryLimits: limits,
          accounts: accounts,
          insights: insights,
          settings: settings,
        ),
      );
    } catch (e) {
      emit(MoneyError(e.toString()));
    }
  }

  /// Runs a write, reloads, and keeps the current UI on failure (one-shot
  /// [MoneyLoaded.actionError] instead of replacing the screen with an error).
  Future<void> _mutate(
    Emitter<MoneyState> emit,
    Future<void> Function() action, {
    bool checkBudgetAlerts = false,
  }) async {
    final before = checkBudgetAlerts ? _currentMonthBudgets() : null;
    try {
      await action();
    } catch (e) {
      final current = state;
      if (current is MoneyLoaded) {
        emit(current.copyWith(actionError: e.toString()));
      } else {
        emit(MoneyError(e.toString()));
      }
      return;
    }
    await _reload(emit);

    final current = state;
    if (before != null &&
        current is MoneyLoaded &&
        current.settings.budgetAlertsEnabled) {
      final after = _currentMonthBudgets();
      if (after != null) {
        try {
          await notifyBudgetThresholdUseCase(before: before, after: after);
        } catch (_) {
          // Notifications are best-effort; never block a successful save.
        }
      }
    }
  }

  /// Category budgets for the *calendar* month (alerts always track "now").
  List<CategoryBudgetEntity>? _currentMonthBudgets() {
    final current = state;
    if (current is! MoneyLoaded) return null;
    final monthTx = filterMonthTransactionsUseCase(
      current.allTransactions,
      DateTime.now(),
    );
    return buildCategoryBudgetsUseCase(
      limits: current.categoryLimits,
      monthTransactions: monthTx,
      period: MoneyPeriod.monthly,
    );
  }

  // ── Existing handlers ───────────────────────────────────────────────────

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(
      emit,
      () => addTransactionUseCase(
        title: event.title,
        category: event.category,
        amount: event.amount,
        mode: event.mode,
        iconCodePoint: event.iconCodePoint,
        type: event.type,
        date: event.date,
        note: event.note,
      ),
      checkBudgetAlerts: event.type == 'expense',
    );
  }

  Future<void> _onToggleAutoKill(
    ToggleAutoKill event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(emit, () => toggleAutoKillUseCase(event.subscriptionId));
  }

  Future<void> _onSettleIou(SettleIou event, Emitter<MoneyState> emit) async {
    final current = state;
    IouEntity? matchingIou;
    if (event.recordTransaction && current is MoneyLoaded) {
      for (final i in current.ious) {
        if (i.id == event.iouId) {
          matchingIou = i;
          break;
        }
      }
    }
    await _mutate(
      emit,
      () async {
        await settleIouUseCase(event.iouId);
        if (event.recordTransaction && matchingIou != null) {
          final isLent = matchingIou.isLent;
          final cat = isLent ? MoneyCategory.otherIncome : MoneyCategory.other;
          await addTransactionUseCase(
            title: isLent
                ? 'Collected IOU • ${matchingIou.person}'
                : 'Settled IOU • ${matchingIou.person}',
            category: cat.key,
            amount: matchingIou.amount,
            mode: 'UPI',
            iconCodePoint: cat.icon.codePoint,
            type: isLent ? 'income' : 'expense',
            date: DateTime.now(),
            note: matchingIou.cleanNote,
          );
        }
      },
      checkBudgetAlerts:
          event.recordTransaction && matchingIou != null && !matchingIou.isLent,
    );
  }

  Future<void> _onAddIou(AddIou event, Emitter<MoneyState> emit) async {
    await _mutate(
      emit,
      () => addIouUseCase(
        person: event.person,
        amount: event.amount,
        type: event.type,
        note: event.note,
      ),
    );
  }

  Future<void> _onUpdateBudget(
    UpdateBudget event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(
      emit,
      () => updateBudgetUseCase(event.monthlyBudget, event.fixedBills),
    );
  }

  // ── v3 handlers ─────────────────────────────────────────────────────────

  Future<void> _onChangeMonth(
    ChangeMonth event,
    Emitter<MoneyState> emit,
  ) async {
    _selectedMonth = _monthOf(event.month);
    await _reload(emit);
  }

  Future<void> _onChangePeriod(
    ChangeMoneyPeriod event,
    Emitter<MoneyState> emit,
  ) async {
    _selectedPeriod = event.period;
    await _reload(emit);
  }

  Future<void> _onApplyBudgetPlan(
    ApplyBudgetPlan event,
    Emitter<MoneyState> emit,
  ) async {
    final current = state;
    final fixedBills =
        event.fixedBills ??
        (current is MoneyLoaded ? current.budget.fixedBills : 0.0);
    await _mutate(emit, () async {
      await updateBudgetUseCase(event.monthlyBudget, fixedBills);
      final allocations = event.preset.allocateMonthlyLimits(
        event.monthlyBudget,
      );
      for (final entry in allocations.entries) {
        await setCategoryLimitUseCase(entry.key, entry.value);
      }
    });
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(
      emit,
      () => updateTransactionUseCase(event.transaction),
      checkBudgetAlerts: event.transaction.isExpense,
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(emit, () => deleteTransactionUseCase(event.transactionId));
  }

  Future<void> _onSetCategoryLimit(
    SetCategoryLimit event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(
      emit,
      () => setCategoryLimitUseCase(event.category, event.limit),
    );
  }

  Future<void> _onAddAccount(AddAccount event, Emitter<MoneyState> emit) async {
    await _mutate(
      emit,
      () => addAccountUseCase(
        name: event.name,
        type: event.type,
        balance: event.balance,
        colorValue: MoneyAccountType.color(event.type).toARGB32(),
        iconCodePoint: MoneyAccountType.icon(event.type).codePoint,
      ),
    );
  }

  Future<void> _onUpdateAccount(
    UpdateAccount event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(emit, () => updateAccountUseCase(event.account));
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(emit, () => deleteAccountUseCase(event.accountId));
  }

  Future<void> _onAddSubscription(
    AddSubscription event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(
      emit,
      () => addSubscriptionUseCase(
        name: event.name,
        amount: event.amount,
        renewalDate: event.renewalDate,
        iconCodePoint: event.iconCodePoint,
        autoKillEnabled: event.autoKillEnabled,
      ),
    );
  }

  Future<void> _onDeleteSubscription(
    DeleteSubscription event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(emit, () => deleteSubscriptionUseCase(event.subscriptionId));
  }

  Future<void> _onDeleteIou(DeleteIou event, Emitter<MoneyState> emit) async {
    await _mutate(emit, () => deleteIouUseCase(event.iouId));
  }

  Future<void> _onUpdateMoneySettings(
    UpdateMoneySettings event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(
      emit,
      () => updateMoneySettingsUseCase(
        currencyCode: event.currencyCode,
        budgetAlertsEnabled: event.budgetAlertsEnabled,
        moneyLockEnabled: event.moneyLockEnabled,
      ),
    );
  }

  Future<void> _onResetAllMoneyData(
    ResetAllMoneyData event,
    Emitter<MoneyState> emit,
  ) async {
    await _mutate(emit, () async {
      final allTx = await getAllTransactionsUseCase();
      for (final tx in allTx) {
        await deleteTransactionUseCase(tx.id);
      }
      final subs = await getSubscriptionsUseCase();
      for (final sub in subs) {
        await deleteSubscriptionUseCase(sub.id);
      }
      final ious = await getIousUseCase();
      for (final iou in ious) {
        await deleteIouUseCase(iou.id);
      }
      final accounts = await getAccountsUseCase();
      for (final acc in accounts) {
        await deleteAccountUseCase(acc.id);
      }
      for (final cat in MoneyCategory.expenseCategories) {
        await setCategoryLimitUseCase(cat.key, 0);
      }
      await updateBudgetUseCase(0, 0);
    });
  }

  Future<void> _onTransferBetweenAccounts(
    TransferBetweenAccounts event,
    Emitter<MoneyState> emit,
  ) async {
    if (event.fromAccountId == event.toAccountId || event.amount <= 0) return;
    await _mutate(emit, () async {
      final accounts = await getAccountsUseCase();
      MoneyAccountEntity? fromAcc;
      MoneyAccountEntity? toAcc;
      for (final acc in accounts) {
        if (acc.id == event.fromAccountId) fromAcc = acc;
        if (acc.id == event.toAccountId) toAcc = acc;
      }
      if (fromAcc == null || toAcc == null) return;

      await updateAccountUseCase(
        MoneyAccountEntity(
          id: fromAcc.id,
          name: fromAcc.name,
          type: fromAcc.type,
          balance: (fromAcc.balance - event.amount).clamp(0.0, double.infinity),
          colorValue: fromAcc.colorValue,
          iconCodePoint: fromAcc.iconCodePoint,
        ),
      );
      await updateAccountUseCase(
        MoneyAccountEntity(
          id: toAcc.id,
          name: toAcc.name,
          type: toAcc.type,
          balance: toAcc.balance + event.amount,
          colorValue: toAcc.colorValue,
          iconCodePoint: toAcc.iconCodePoint,
        ),
      );

      final customNote = event.note?.trim();
      final transferNote = customNote != null && customNote.isNotEmpty
          ? '${fromAcc.name} → ${toAcc.name} • $customNote'
          : '${fromAcc.name} → ${toAcc.name}';
      await addTransactionUseCase(
        title: 'Transfer: ${fromAcc.name} → ${toAcc.name}',
        category: MoneyCategory.other.key,
        amount: event.amount,
        mode: 'Transfer',
        iconCodePoint: Icons.swap_horiz_rounded.codePoint,
        type: 'transfer',
        date: DateTime.now(),
        note: transferNote,
      );
    });
  }

  Future<void> _onRecordSubscriptionPayment(
    RecordSubscriptionPayment event,
    Emitter<MoneyState> emit,
  ) async {
    final sub = event.subscription;
    final nextRenewal = sub.nextCycleDate;
    await _mutate(emit, () async {
      await addTransactionUseCase(
        title: '${sub.name} Subscription',
        category: MoneyCategory.bills.key,
        amount: sub.amount,
        mode: 'Card',
        iconCodePoint: sub.iconCodePoint,
        type: 'expense',
        date: DateTime.now(),
        note: 'Next renewal: ${nextRenewal.toIso8601String().split('T').first}',
      );
      final updated = SubscriptionEntity(
        id: sub.id,
        name: sub.name,
        amount: sub.amount,
        renewalDate: nextRenewal.toIso8601String(),
        autoKillEnabled: sub.autoKillEnabled,
        iconCodePoint: sub.iconCodePoint,
      );
      if (updateSubscriptionUseCase != null) {
        await updateSubscriptionUseCase!(updated);
      } else {
        await deleteSubscriptionUseCase(sub.id);
        await addSubscriptionUseCase(
          name: sub.name,
          amount: sub.amount,
          renewalDate: nextRenewal,
          iconCodePoint: sub.iconCodePoint,
          autoKillEnabled: sub.autoKillEnabled,
        );
      }
    }, checkBudgetAlerts: true);
  }
}
