import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    HapticFeedback.selectionClick();
    if (visualIdx == 2) {
      onAddPressed();
      return;
    }
    final tab = visualIdx > 2 ? visualIdx - 1 : visualIdx;
    onSelectTab(tab);
  }

  static Widget _buildNavIcon(
    IconData icon, {
    required bool isActive,
    Color activeColor = AppColors.moduleMoney,
  }) {
    if (!isActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Icon(icon, size: 22),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 22, color: activeColor),
    );
  }

  static Widget _buildAddCtaIcon() {
    return Container(
      width: 40,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.moduleMoney, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.moduleMoney.withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 21),
    );
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
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, -3),
                ),
              ],
      ),
      child: BottomNavigationBar(
        key: const ValueKey('money_bottom_nav_bar'),
        currentIndex: _visualIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        selectedItemColor: AppColors.moduleMoney,
        unselectedItemColor: isDark
            ? AppColors.darkTextMuted
            : AppColors.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.home_outlined, isActive: false),
            activeIcon: _buildNavIcon(Icons.home_rounded, isActive: true),
            label: StringConstants.moneyNavOverview,
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.receipt_long_outlined, isActive: false),
            activeIcon: _buildNavIcon(
              Icons.receipt_long_rounded,
              isActive: true,
            ),
            label: StringConstants.moneyNavActivity,
          ),
          BottomNavigationBarItem(
            icon: _buildAddCtaIcon(),
            activeIcon: _buildAddCtaIcon(),
            label: StringConstants.moneyNavAdd,
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              Icons.pie_chart_outline_rounded,
              isActive: false,
            ),
            activeIcon: _buildNavIcon(Icons.pie_chart_rounded, isActive: true),
            label: StringConstants.moneyNavBudgets,
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.bar_chart_outlined, isActive: false),
            activeIcon: _buildNavIcon(Icons.bar_chart_rounded, isActive: true),
            label: StringConstants.moneyNavInsights,
          ),
        ],
      ),
    );
  }
}
