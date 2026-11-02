import 'package:flutter/widgets.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../bloc/money_state.dart';

/// Maps a [MoneyState] onto the shared [FeatureScaffold] lifecycle.
FeatureStatus moneyFeatureStatus(MoneyState state) {
  if (state is MoneyLoaded) return FeatureStatus.content;
  if (state is MoneyError) return FeatureStatus.error;
  return FeatureStatus.loading;
}

/// Money bottom-bar tab indexes (the centre "+ Add" button is an action, not a tab).
class MoneyTab {
  MoneyTab._();

  static const int overview = 0;
  static const int activity = 1;
  static const int budgets = 2;
  static const int insights = 3;
}

/// Exposes Money-shell navigation to every Money page / widget.
///
/// - [exitMoney]: leave Money mode and restore the main app bottom bar.
/// - [selectTab]: switch the Money bottom-bar tab (see [MoneyTab]).
class MoneyShellScope extends InheritedWidget {
  final int currentTab;
  final VoidCallback exitMoney;
  final ValueChanged<int> selectTab;

  const MoneyShellScope({
    super.key,
    required this.currentTab,
    required this.exitMoney,
    required this.selectTab,
    required super.child,
  });

  static MoneyShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MoneyShellScope>();

  /// Back behaviour used by page app bars: inner tab → Overview, Overview → exit.
  static void handleBack(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      Navigator.of(context).maybePop();
      return;
    }
    if (scope.currentTab != MoneyTab.overview) {
      scope.selectTab(MoneyTab.overview);
    } else {
      scope.exitMoney();
    }
  }

  @override
  bool updateShouldNotify(MoneyShellScope oldWidget) =>
      oldWidget.currentTab != currentTab;
}
