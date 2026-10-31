import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/string_constants.dart';
import 'money_shell_scope.dart';

/// Dedicated Money bottom navigation bar:
/// `Overview · Activity · Add · Budgets · Insights`.
///
/// Replaces the main 5-tab bar while the user is inside the Money module.
class MoneyBottomNavBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onAddPressed;

  const MoneyBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    required this.onAddPressed,
  });

  int get _visualIndex {
    // BottomNavigationBar has 5 slots (slot 2 is the "+ Add" action).
    if (currentTab >= MoneyTab.budgets) return currentTab + 1;
    return currentTab;
  }

  void _onTap(int visualIdx) {
    if (visualIdx == 2) {
      onAddPressed();
      return;
    }
    final tab = visualIdx > 2 ? visualIdx - 1 : visualIdx;
    onSelectTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        key: const ValueKey('money_bottom_nav_bar'),
        currentIndex: _visualIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark
            ? AppColors.darkTextMuted
            : AppColors.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 23),
            activeIcon: Icon(Icons.home_rounded, size: 23),
            label: StringConstants.moneyNavOverview,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined, size: 23),
            activeIcon: Icon(Icons.receipt_long_rounded, size: 23),
            label: StringConstants.moneyNavActivity,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded, size: 25),
            activeIcon: Icon(Icons.add_circle_rounded, size: 25),
            label: StringConstants.moneyNavAdd,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline_rounded, size: 23),
            activeIcon: Icon(Icons.pie_chart_rounded, size: 23),
            label: StringConstants.moneyNavBudgets,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined, size: 23),
            activeIcon: Icon(Icons.bar_chart_rounded, size: 23),
            label: StringConstants.moneyNavInsights,
          ),
        ],
      ),
    );
  }
}
