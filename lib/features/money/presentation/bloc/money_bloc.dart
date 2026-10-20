import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_transactions_and_budget_usecase.dart';
import '../../domain/usecases/manage_transactions_usecase.dart';
import '../../domain/usecases/manage_subscriptions_and_ious_usecase.dart';
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
  }) : super(MoneyInitial()) {
    on<LoadMoney>(_onLoad);
    on<AddTransaction>(_onAddTransaction);
    on<ToggleAutoKill>(_onToggleAutoKill);
    on<SettleIou>(_onSettleIou);
    on<AddIou>(_onAddIou);
    on<UpdateBudget>(_onUpdateBudget);
  }

  Future<void> _onLoad(LoadMoney event, Emitter<MoneyState> emit) async {
    emit(MoneyLoading());
    try {
      final transactions = await getRecentTransactionsUseCase();
      final budget = await getBudgetUseCase();
      final subscriptions = await getSubscriptionsUseCase();
      final ious = await getIousUseCase();
      emit(MoneyLoaded(
        transactions: transactions,
        budget: budget,
        subscriptions: subscriptions,
        ious: ious,
      ));
    } catch (e) {
      emit(MoneyError(e.toString()));
    }
  }

  Future<void> _reload(Emitter<MoneyState> emit) async {
    try {
      final transactions = await getRecentTransactionsUseCase();
      final budget = await getBudgetUseCase();
      final subscriptions = await getSubscriptionsUseCase();
      final ious = await getIousUseCase();
      emit(MoneyLoaded(
        transactions: transactions,
        budget: budget,
        subscriptions: subscriptions,
        ious: ious,
      ));
    } catch (e) {
      emit(MoneyError(e.toString()));
    }
  }

  Future<void> _onAddTransaction(AddTransaction event, Emitter<MoneyState> emit) async {
    await addTransactionUseCase(
      title: event.title,
      category: event.category,
      amount: event.amount,
      mode: event.mode,
      iconCodePoint: event.iconCodePoint,
    );
    await _reload(emit);
  }

  Future<void> _onToggleAutoKill(ToggleAutoKill event, Emitter<MoneyState> emit) async {
    await toggleAutoKillUseCase(event.subscriptionId);
    await _reload(emit);
  }

  Future<void> _onSettleIou(SettleIou event, Emitter<MoneyState> emit) async {
    await settleIouUseCase(event.iouId);
    await _reload(emit);
  }

  Future<void> _onAddIou(AddIou event, Emitter<MoneyState> emit) async {
    await addIouUseCase(
      person: event.person,
      amount: event.amount,
      type: event.type,
      note: event.note,
    );
    await _reload(emit);
  }

  Future<void> _onUpdateBudget(UpdateBudget event, Emitter<MoneyState> emit) async {
    await updateBudgetUseCase(event.monthlyBudget, event.fixedBills);
    await _reload(emit);
  }
}
