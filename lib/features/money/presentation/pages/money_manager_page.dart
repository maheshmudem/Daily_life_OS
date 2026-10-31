import 'package:flutter/material.dart';
import 'money_shell_page.dart';

/// Entry point for the Money module.
///
/// Renders [MoneyShellPage], which provides the dedicated Money bottom
/// navigation bar (`Overview · Activity · (+ Add) · Budgets · Insights`) and
/// restores the main app navigation bar when [onExitMoney] is triggered.
class MoneyManagerPage extends StatelessWidget {
  final VoidCallback? onExitMoney;

  const MoneyManagerPage({super.key, this.onExitMoney});

  @override
  Widget build(BuildContext context) {
    return MoneyShellPage(onExitMoney: onExitMoney);
  }
}
