import 'package:bloc_test/bloc_test.dart';
import 'package:daily_life_os/config/theme/app_theme.dart';
import 'package:daily_life_os/features/money/domain/entities/money_account_entity.dart';
import 'package:daily_life_os/features/money/domain/entities/money_settings_entity.dart';
import 'package:daily_life_os/features/money/domain/entities/subscription_entity.dart';
import 'package:daily_life_os/features/money/domain/entities/transaction_entity.dart';
import 'package:daily_life_os/features/money/domain/usecases/get_transactions_and_budget_usecase.dart';
import 'package:daily_life_os/features/money/domain/usecases/manage_budgets_and_accounts_usecase.dart';
import 'package:daily_life_os/features/money/domain/usecases/manage_subscriptions_and_ious_usecase.dart';
import 'package:daily_life_os/features/money/domain/usecases/manage_transactions_usecase.dart';
import 'package:daily_life_os/features/money/presentation/bloc/money_bloc.dart';
import 'package:daily_life_os/features/money/presentation/widgets/account_transfer_sheet.dart';
import 'package:daily_life_os/features/money/presentation/widgets/bill_split_sheet.dart';
import 'package:daily_life_os/features/money/presentation/widgets/money_report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetRecentTransactionsUseCase extends Mock
    implements GetRecentTransactionsUseCase {}

class MockGetBudgetUseCase extends Mock implements GetBudgetUseCase {}

class MockGetSubscriptionsUseCase extends Mock
    implements GetSubscriptionsUseCase {}

class MockGetIousUseCase extends Mock implements GetIousUseCase {}

class MockAddTransactionUseCase extends Mock implements AddTransactionUseCase {}

class MockToggleAutoKillUseCase extends Mock implements ToggleAutoKillUseCase {}

class MockSettleIouUseCase extends Mock implements SettleIouUseCase {}

class MockAddIouUseCase extends Mock implements AddIouUseCase {}

class MockUpdateBudgetUseCase extends Mock implements UpdateBudgetUseCase {}

class MockGetAllTransactionsUseCase extends Mock
    implements GetAllTransactionsUseCase {}

class MockUpdateTransactionUseCase extends Mock
    implements UpdateTransactionUseCase {}

class MockDeleteTransactionUseCase extends Mock
    implements DeleteTransactionUseCase {}

class MockGetCategoryLimitsUseCase extends Mock
    implements GetCategoryLimitsUseCase {}

class MockSetCategoryLimitUseCase extends Mock
    implements SetCategoryLimitUseCase {}

class MockGetAccountsUseCase extends Mock implements GetAccountsUseCase {}

class MockAddAccountUseCase extends Mock implements AddAccountUseCase {}

class MockUpdateAccountUseCase extends Mock implements UpdateAccountUseCase {}

class MockDeleteAccountUseCase extends Mock implements DeleteAccountUseCase {}

class MockAddSubscriptionUseCase extends Mock
    implements AddSubscriptionUseCase {}

class MockUpdateSubscriptionUseCase extends Mock
    implements UpdateSubscriptionUseCase {}

class MockDeleteSubscriptionUseCase extends Mock
    implements DeleteSubscriptionUseCase {}

class MockDeleteIouUseCase extends Mock implements DeleteIouUseCase {}

class MockGetMoneySettingsUseCase extends Mock
    implements GetMoneySettingsUseCase {}

class MockUpdateMoneySettingsUseCase extends Mock
    implements UpdateMoneySettingsUseCase {}

class MockNotifyBudgetThresholdUseCase extends Mock
    implements NotifyBudgetThresholdUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MoneyAccountEntity(
        id: 1,
        name: 'Main',
        type: 'bank',
        balance: 0,
        colorValue: 0xFF000000,
        iconCodePoint: 0xe000,
      ),
    );
    registerFallbackValue(
      const SubscriptionEntity(
        id: 1,
        name: 'Netflix',
        amount: 499,
        renewalDate: '2026-12-01',
        autoKillEnabled: true,
        iconCodePoint: 0xe000,
      ),
    );
  });

  group('Money Power Workflows', () {
    late MockGetRecentTransactionsUseCase getRecentTx;
    late MockGetBudgetUseCase getBudget;
    late MockGetSubscriptionsUseCase getSubs;
    late MockGetIousUseCase getIous;
    late MockAddTransactionUseCase addTx;
    late MockToggleAutoKillUseCase toggleAutoKill;
    late MockSettleIouUseCase settleIou;
    late MockAddIouUseCase addIou;
    late MockUpdateBudgetUseCase updateBudget;
    late MockGetAllTransactionsUseCase getAllTx;
    late MockUpdateTransactionUseCase updateTx;
    late MockDeleteTransactionUseCase deleteTx;
    late MockGetCategoryLimitsUseCase getLimits;
    late MockSetCategoryLimitUseCase setLimit;
    late MockGetAccountsUseCase getAccounts;
    late MockAddAccountUseCase addAccount;
    late MockUpdateAccountUseCase updateAccount;
    late MockDeleteAccountUseCase deleteAccount;
    late MockAddSubscriptionUseCase addSub;
    late MockUpdateSubscriptionUseCase updateSub;
    late MockDeleteSubscriptionUseCase deleteSub;
    late MockDeleteIouUseCase deleteIou;
    late MockGetMoneySettingsUseCase getSettings;
    late MockUpdateMoneySettingsUseCase updateSettings;
    late MockNotifyBudgetThresholdUseCase notifyThreshold;

    const sampleAccounts = [
      MoneyAccountEntity(
        id: 1,
        name: 'Main Bank',
        type: 'bank',
        balance: 10000,
        colorValue: 0xFF10B981,
        iconCodePoint: 0xe040,
      ),
      MoneyAccountEntity(
        id: 2,
        name: 'Savings Vault',
        type: 'savings',
        balance: 5000,
        colorValue: 0xFF6366F1,
        iconCodePoint: 0xe041,
      ),
    ];

    const sampleSub = SubscriptionEntity(
      id: 10,
      name: 'Spotify Premium',
      amount: 199,
      renewalDate: '2026-12-15',
      autoKillEnabled: true,
      iconCodePoint: 0xe042,
    );

    const sampleLentIou = IouEntity(
      id: 20,
      person: 'Rohan',
      amount: 1200,
      type: 'lent',
      note: 'Dinner split',
      date: '2026-11-01',
      isSettled: false,
    );

    MoneyBloc createBloc() {
      return MoneyBloc(
        getRecentTransactionsUseCase: getRecentTx,
        getBudgetUseCase: getBudget,
        getSubscriptionsUseCase: getSubs,
        getIousUseCase: getIous,
        addTransactionUseCase: addTx,
        toggleAutoKillUseCase: toggleAutoKill,
        settleIouUseCase: settleIou,
        addIouUseCase: addIou,
        updateBudgetUseCase: updateBudget,
        getAllTransactionsUseCase: getAllTx,
        updateTransactionUseCase: updateTx,
        deleteTransactionUseCase: deleteTx,
        getCategoryLimitsUseCase: getLimits,
        setCategoryLimitUseCase: setLimit,
        getAccountsUseCase: getAccounts,
        addAccountUseCase: addAccount,
        updateAccountUseCase: updateAccount,
        deleteAccountUseCase: deleteAccount,
        addSubscriptionUseCase: addSub,
        updateSubscriptionUseCase: updateSub,
        deleteSubscriptionUseCase: deleteSub,
        deleteIouUseCase: deleteIou,
        getMoneySettingsUseCase: getSettings,
        updateMoneySettingsUseCase: updateSettings,
        notifyBudgetThresholdUseCase: notifyThreshold,
      );
    }

    setUp(() {
      getRecentTx = MockGetRecentTransactionsUseCase();
      getBudget = MockGetBudgetUseCase();
      getSubs = MockGetSubscriptionsUseCase();
      getIous = MockGetIousUseCase();
      addTx = MockAddTransactionUseCase();
      toggleAutoKill = MockToggleAutoKillUseCase();
      settleIou = MockSettleIouUseCase();
      addIou = MockAddIouUseCase();
      updateBudget = MockUpdateBudgetUseCase();
      getAllTx = MockGetAllTransactionsUseCase();
      updateTx = MockUpdateTransactionUseCase();
      deleteTx = MockDeleteTransactionUseCase();
      getLimits = MockGetCategoryLimitsUseCase();
      setLimit = MockSetCategoryLimitUseCase();
      getAccounts = MockGetAccountsUseCase();
      addAccount = MockAddAccountUseCase();
      updateAccount = MockUpdateAccountUseCase();
      deleteAccount = MockDeleteAccountUseCase();
      addSub = MockAddSubscriptionUseCase();
      updateSub = MockUpdateSubscriptionUseCase();
      deleteSub = MockDeleteSubscriptionUseCase();
      deleteIou = MockDeleteIouUseCase();
      getSettings = MockGetMoneySettingsUseCase();
      updateSettings = MockUpdateMoneySettingsUseCase();
      notifyThreshold = MockNotifyBudgetThresholdUseCase();

      when(() => getRecentTx()).thenAnswer((_) async => const []);
      when(() => getAllTx()).thenAnswer((_) async => const []);
      when(() => getBudget()).thenAnswer(
        (_) async => const BudgetEntity(
          monthlyBudget: 50000,
          fixedBills: 10000,
          totalSpent: 5000,
        ),
      );
      when(() => getSubs()).thenAnswer((_) async => const [sampleSub]);
      when(() => getIous()).thenAnswer((_) async => const [sampleLentIou]);
      when(() => getLimits()).thenAnswer((_) async => const {});
      when(() => getAccounts()).thenAnswer((_) async => sampleAccounts);
      when(() => getSettings()).thenAnswer(
        (_) async => const MoneySettingsEntity(
          currencyCode: 'INR',
          budgetAlertsEnabled: false,
          moneyLockEnabled: false,
        ),
      );
      when(() => updateAccount(any())).thenAnswer((_) async {});
      when(() => updateSub(any())).thenAnswer((_) async {});
      when(() => settleIou(any())).thenAnswer((_) async {});
      when(
        () => addIou(
          person: any(named: 'person'),
          amount: any(named: 'amount'),
          type: any(named: 'type'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => addTx(
          title: any(named: 'title'),
          category: any(named: 'category'),
          amount: any(named: 'amount'),
          mode: any(named: 'mode'),
          iconCodePoint: any(named: 'iconCodePoint'),
          type: any(named: 'type'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async {});
    });

    test('SubscriptionEntity.nextCycleDate advances by 1 month', () {
      const sub = SubscriptionEntity(
        id: 1,
        name: 'Test',
        amount: 100,
        renewalDate: '2027-03-15',
        autoKillEnabled: false,
        iconCodePoint: 0xe000,
      );
      expect(sub.nextCycleDate, DateTime(2027, 4, 15));
    });

    blocTest<MoneyBloc, MoneyState>(
      'TransferBetweenAccounts updates both account balances and logs transfer',
      build: createBloc,
      act: (bloc) => bloc.add(
        const TransferBetweenAccounts(
          fromAccountId: 1,
          toAccountId: 2,
          amount: 2500,
          note: 'Monthly savings',
        ),
      ),
      verify: (_) {
        verify(
          () => updateAccount(
            const MoneyAccountEntity(
              id: 1,
              name: 'Main Bank',
              type: 'bank',
              balance: 7500,
              colorValue: 0xFF10B981,
              iconCodePoint: 0xe040,
            ),
          ),
        ).called(1);
        verify(
          () => updateAccount(
            const MoneyAccountEntity(
              id: 2,
              name: 'Savings Vault',
              type: 'savings',
              balance: 7500,
              colorValue: 0xFF6366F1,
              iconCodePoint: 0xe041,
            ),
          ),
        ).called(1);
        verify(
          () => addTx(
            title: 'Transfer: Main Bank → Savings Vault',
            category: any(named: 'category'),
            amount: 2500,
            mode: 'Transfer',
            iconCodePoint: any(named: 'iconCodePoint'),
            type: 'transfer',
            date: any(named: 'date'),
            note: 'Main Bank → Savings Vault • Monthly savings',
          ),
        ).called(1);
      },
    );

    blocTest<MoneyBloc, MoneyState>(
      'RecordSubscriptionPayment logs expense and rolls renewalDate forward',
      build: createBloc,
      act: (bloc) => bloc.add(const RecordSubscriptionPayment(sampleSub)),
      verify: (_) {
        verify(
          () => addTx(
            title: 'Spotify Premium Subscription',
            category: 'bills',
            amount: 199,
            mode: 'Card',
            iconCodePoint: sampleSub.iconCodePoint,
            type: 'expense',
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        ).called(1);
        verify(() => updateSub(any())).called(1);
      },
    );

    blocTest<MoneyBloc, MoneyState>(
      'SettleIou with recordTransaction=true logs income for lent IOU',
      build: createBloc,
      act: (bloc) async {
        bloc.add(const LoadMoney());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SettleIou(20, recordTransaction: true));
      },
      verify: (_) {
        verify(() => settleIou(20)).called(1);
        verify(
          () => addTx(
            title: 'Collected IOU • Rohan',
            category: 'other_income',
            amount: 1200,
            mode: 'UPI',
            iconCodePoint: any(named: 'iconCodePoint'),
            type: 'income',
            date: any(named: 'date'),
            note: 'Dinner split',
          ),
        ).called(1);
      },
    );

    testWidgets('AccountTransferSheet and MoneyReportSheet render cleanly', (
      tester,
    ) async {
      final bloc = createBloc()..add(const LoadMoney());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(
              body: Column(
                children: [
                  Expanded(child: AccountTransferSheet()),
                  Expanded(child: MoneyReportSheet()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transfer Between Accounts'), findsOneWidget);
      expect(find.text('Financial Statement & Report'), findsOneWidget);
    });

    test('TransactionEntity.isTransfer returns true and signedAmount is 0', () {
      const tx = TransactionEntity(
        id: 99,
        title: 'Transfer: Bank → Savings',
        category: 'other_expense',
        amount: 2500,
        mode: 'Transfer',
        iconCodePoint: 0xe000,
        date: '2026-11-09T10:00:00.000',
        type: 'transfer',
      );
      expect(tx.isTransfer, isTrue);
      expect(tx.signedAmount, 0.0);
    });

    testWidgets(
      'BillSplitSheet logs user share expense and creates Lent IOUs for friends',
      (tester) async {
        final bloc = createBloc()..add(const LoadMoney());
        addTearDown(bloc.close);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: BlocProvider.value(
              value: bloc,
              child: const Scaffold(body: BillSplitSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('bill_split_amount_field')),
          '300',
        );
        await tester.tap(find.byKey(const ValueKey('bill_split_plus_btn')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('bill_split_friends_field')),
          'Rahul, Priya',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('bill_split_submit_btn')));
        await tester.pumpAndSettle();

        verify(
          () => addTx(
            title: 'Dinner Split (My Share 1/3)',
            category: 'food',
            amount: 100.0,
            mode: 'UPI',
            iconCodePoint: any(named: 'iconCodePoint'),
            type: 'expense',
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        ).called(1);

        verify(
          () => addIou(
            person: 'Rahul',
            amount: 100.0,
            type: 'lent',
            note: any(named: 'note'),
          ),
        ).called(1);

        verify(
          () => addIou(
            person: 'Priya',
            amount: 100.0,
            type: 'lent',
            note: any(named: 'note'),
          ),
        ).called(1);
      },
    );
  });
}
