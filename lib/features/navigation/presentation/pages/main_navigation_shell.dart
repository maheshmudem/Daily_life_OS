import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../core/constants/string_constants.dart';
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

  bool get _isInMoneyMode => _currentIndex == _moneyTabIndex;

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
      const TodayHubPage(),
      const PlannerPage(),
      MoneyManagerPage(onExitMoney: _exitMoneyMode),
      const NotesPage(),
      const VaultPage(),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.scaffoldBackground,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: pages),

          // Persistent Floating Quick-Capture Bar (hidden while inside Money
          // so only Money's dedicated navigation bar is shown)
          if (!_isInMoneyMode)
            Positioned(
              left: 20,
              right: 20,
              bottom: 12,
              child: _buildFloatingQuickCaptureBar(context, isDark),
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

  Widget _buildFloatingQuickCaptureBar(BuildContext context, bool isDark) {
    return Container(
      height: 52,
      decoration: AppDecorations.floatingBar,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hold to Speak (Voice)
          GestureDetector(
            onTap: () =>
                QuickCaptureSheet.show(context, mode: QuickCaptureMode.voice),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.voiceWaveform.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: AppColors.voiceWaveform,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  StringConstants.holdToSpeak,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          // Quick Type Button
          GestureDetector(
            onTap: () =>
                QuickCaptureSheet.show(context, mode: QuickCaptureMode.text),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_rounded, color: Colors.white70, size: 18),
                SizedBox(width: 6),
                Text(
                  StringConstants.quickType,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          // Scan Bill / OCR
          IconButton(
            tooltip: StringConstants.scanText,
            icon: const Icon(
              Icons.document_scanner_rounded,
              color: AppColors.moduleMoneyLight,
              size: 20,
            ),
            onPressed: () =>
                QuickCaptureSheet.show(context, mode: QuickCaptureMode.scan),
          ),
        ],
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
