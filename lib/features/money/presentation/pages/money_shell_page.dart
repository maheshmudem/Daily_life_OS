import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../di/injection_container.dart';
import '../../../security/domain/repositories/security_repository.dart';
import '../../../security/presentation/widgets/vault_lock_screen.dart';
import '../bloc/money_bloc.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/money_bottom_nav_bar.dart';
import '../widgets/money_shell_scope.dart';
import 'money_activity_page.dart';
import 'money_budgets_page.dart';
import 'money_insights_page.dart';
import 'money_overview_page.dart';

/// Host shell for the Money module with its own bottom navigation bar, shared
/// [MoneyBloc], optional Vault security lock, and back-button handling.
class MoneyShellPage extends StatefulWidget {
  final VoidCallback? onExitMoney;

  const MoneyShellPage({super.key, this.onExitMoney});

  @override
  State<MoneyShellPage> createState() => _MoneyShellPageState();
}

class _MoneyShellPageState extends State<MoneyShellPage>
    with WidgetsBindingObserver {
  int _currentTab = MoneyTab.overview;
  bool _isUnlocked = false;

  static const List<Widget> _pages = [
    MoneyOverviewPage(),
    MoneyActivityPage(),
    MoneyBudgetsPage(),
    MoneyInsightsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (mounted && _isUnlocked) {
        setState(() => _isUnlocked = false);
      }
    }
  }

  void _exitMoney() {
    if (widget.onExitMoney != null) {
      widget.onExitMoney!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _selectTab(int tab) {
    if (tab == _currentTab) return;
    setState(() => _currentTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<MoneyBloc>(
      create: (_) => sl<MoneyBloc>()..add(const LoadMoney()),
      child: BlocConsumer<MoneyBloc, MoneyState>(
        listenWhen: (prev, curr) =>
            curr is MoneyLoaded &&
            curr.actionError != null &&
            (prev is! MoneyLoaded || prev.actionError != curr.actionError),
        listener: (context, state) {
          if (state is MoneyLoaded && state.actionError != null) {
            SnackbarUtils.showError(context, state.actionError!);
          }
        },
        builder: (context, state) {
          final lockEnabled =
              state is MoneyLoaded &&
              state.settings.moneyLockEnabled &&
              sl.isRegistered<SecurityRepository>();

          if (lockEnabled && !_isUnlocked) {
            return Scaffold(
              backgroundColor: isDark
                  ? AppColors.darkScaffoldBackground
                  : AppColors.scaffoldBackground,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: _exitMoney,
                ),
              ),
              body: VaultLockScreen(
                securityRepository: sl<SecurityRepository>(),
                onUnlock: ({required bool isDecoy}) {
                  setState(() => _isUnlocked = true);
                },
              ),
            );
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (_currentTab != MoneyTab.overview) {
                setState(() => _currentTab = MoneyTab.overview);
              } else {
                _exitMoney();
              }
            },
            child: MoneyShellScope(
              currentTab: _currentTab,
              exitMoney: _exitMoney,
              selectTab: _selectTab,
              child: Scaffold(
                backgroundColor: isDark
                    ? AppColors.darkScaffoldBackground
                    : AppColors.scaffoldBackground,
                body: IndexedStack(index: _currentTab, children: _pages),
                bottomNavigationBar: MoneyBottomNavBar(
                  currentTab: _currentTab,
                  onSelectTab: _selectTab,
                  onAddPressed: () => AddTransactionSheet.show(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
