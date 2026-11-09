import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/string_constants.dart';

/// Domain metadata for the 5 primary Daily Life OS navigation tabs.
class NavigationTabEntity extends Equatable {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color activeColor;

  const NavigationTabEntity({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.activeColor,
  });

  static const int todayIndex = 0;
  static const int plannerIndex = 1;
  static const int moneyIndex = 2;
  static const int notesIndex = 3;
  static const int vaultIndex = 4;

  static const List<NavigationTabEntity> tabs = [
    NavigationTabEntity(
      index: todayIndex,
      label: StringConstants.navTodayTab,
      icon: Icons.dashboard_rounded,
      activeIcon: Icons.dashboard_rounded,
      activeColor: AppColors.primary,
    ),
    NavigationTabEntity(
      index: plannerIndex,
      label: StringConstants.navPlanner,
      icon: Icons.schedule_rounded,
      activeIcon: Icons.schedule_rounded,
      activeColor: AppColors.moduleTime,
    ),
    NavigationTabEntity(
      index: moneyIndex,
      label: StringConstants.navMoney,
      icon: Icons.account_balance_wallet_rounded,
      activeIcon: Icons.account_balance_wallet_rounded,
      activeColor: AppColors.moduleMoney,
    ),
    NavigationTabEntity(
      index: notesIndex,
      label: StringConstants.navNotes,
      icon: Icons.lightbulb_outline_rounded,
      activeIcon: Icons.lightbulb_rounded,
      activeColor: AppColors.moduleNotes,
    ),
    NavigationTabEntity(
      index: vaultIndex,
      label: StringConstants.navVault,
      icon: Icons.lock_outline_rounded,
      activeIcon: Icons.lock_rounded,
      activeColor: AppColors.moduleVault,
    ),
  ];

  static Color activeColorFor(int index) {
    if (index >= 0 && index < tabs.length) {
      return tabs[index].activeColor;
    }
    return AppColors.primary;
  }

  @override
  List<Object?> get props => [index, label, icon, activeIcon, activeColor];
}
