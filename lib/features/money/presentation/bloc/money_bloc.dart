import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/category_budget_entity.dart';
import '../../domain/entities/money_account_entity.dart';
import '../../domain/entities/money_insights.dart';
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
  }

  static DateTime _monthOf(DateTime date) => DateTime(date.year, date.month, 1);

  // ── Loading ─────────────────────────────────────────────────────────────

  Future<void> _onLoad(LoadMoney event, Emitter<MoneyState> emit) async {
    emit(MoneyLoading());
    await _reload(emit);
  }

  Future<void> _reload(Emitter<MoneyState> emit) async {
    try {
      final transactions = await getRecentTransactionsUseCase();
      final budget = await getBudgetUseCase();
      final subscriptions = await getSubscriptionsUseCase();
      final ious = await getIousUseCase();
      final allTransactions = await getAllTransactionsUseCase();
      final limits = await getCategoryLimitsUseCase();
      final accounts = await getAccountsUseCase();
      final settings = await getMoneySettingsUseCase();

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
    await _mutate(emit, () => settleIouUseCase(event.iouId));
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
}
