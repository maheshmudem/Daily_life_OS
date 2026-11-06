import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/floating_quick_ball.dart';
import '../../../../core/widgets/quick_capture_sheet.dart';
import '../../../today_hub/presentation/pages/today_hub_page.dart';
import '../../../planner/presentation/pages/planner_page.dart';
import '../../../money/presentation/pages/money_manager_page.dart';
import '../../../notes/presentation/pages/notes_page.dart';
import '../../../vault/presentation/pages/vault_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  static const int _moneyTabIndex = 2;

  int _currentIndex = 0;
  int _previousNonMoneyIndex = 0;
  int _captureRefreshGeneration = 0;

  bool get _isInMoneyMode => _currentIndex == _moneyTabIndex;

  Future<void> _openQuickCapture(
    BuildContext context,
    QuickCaptureMode mode,
  ) async {
    HapticFeedback.selectionClick();
    final result = await QuickCaptureSheet.show(context, mode: mode);
    if (!mounted) return;
    setState(() => _captureRefreshGeneration++);
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${result.summary}'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 74),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.voiceWaveform,
            onPressed: () => _selectMainTab(result.targetTabIndex),
          ),
        ),
      );
    }
  }

  void _selectMainTab(int index) {
    setState(() {
      if (index != _moneyTabIndex) {
        _previousNonMoneyIndex = index;
      }
      _currentIndex = index;
    });
  }

  void _exitMoneyMode() {
    setState(() {
      _currentIndex = _previousNonMoneyIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = <Widget>[
      TodayHubPage(key: ValueKey('today_$_captureRefreshGeneration')),
      PlannerPage(key: ValueKey('planner_$_captureRefreshGeneration')),
      MoneyManagerPage(
        key: ValueKey('money_$_captureRefreshGeneration'),
        onExitMoney: _exitMoneyMode,
      ),
      NotesPage(key: ValueKey('notes_$_captureRefreshGeneration')),
      const VaultPage(),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.scaffoldBackground,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: pages),

          // Movable, minimizable Floating Quick-Capture Ball & Capsule
          // (hidden while inside Money so only Money's dedicated nav is shown)
          if (!_isInMoneyMode)
            Positioned.fill(
              child: FloatingQuickBall(
                onSelectMode: (mode) => _openQuickCapture(context, mode),
              ),
            ),
        ],
      ),
      // Main 5-tab bar closes/hides when entering Money; Money renders its own
      // bottom bar and pressing Back restores the main bar.
      bottomNavigationBar: _isInMoneyMode
          ? null
          : Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                    width: 1,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                key: const ValueKey('main_bottom_nav_bar'),
                currentIndex: _currentIndex,
                onTap: _selectMainTab,
                type: BottomNavigationBarType.fixed,
                backgroundColor: isDark
                    ? AppColors.darkCardBackground
                    : Colors.white,
                selectedItemColor: _getActiveTabColor(_currentIndex),
                unselectedItemColor: isDark
                    ? AppColors.darkTextCaption
                    : AppColors.textCaption,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded),
                    activeIcon: Icon(Icons.dashboard_rounded),
                    label: 'Today',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.schedule_rounded),
                    activeIcon: Icon(Icons.schedule_rounded),
                    label: 'Planner',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.account_balance_wallet_rounded),
                    activeIcon: Icon(Icons.account_balance_wallet_rounded),
                    label: 'Money',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.lightbulb_outline_rounded),
                    activeIcon: Icon(Icons.lightbulb_rounded),
                    label: 'Notes',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.lock_outline_rounded),
                    activeIcon: Icon(Icons.lock_rounded),
                    label: 'Vault',
                  ),
                ],
              ),
            ),
    );
  }

  Color _getActiveTabColor(int index) {
    switch (index) {
      case 0:
        return AppColors.primary;
      case 1:
        return AppColors.moduleTime;
      case 2:
        return AppColors.moduleMoney;
      case 3:
        return AppColors.moduleNotes;
      case 4:
        return AppColors.moduleVault;
      default:
        return AppColors.primary;
    }
  }
}
