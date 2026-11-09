import 'package:equatable/equatable.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class SelectNavigationTab extends NavigationEvent {
  final int index;

  const SelectNavigationTab(this.index);

  @override
  List<Object?> get props => [index];
}

class ExitMoneyNavigationMode extends NavigationEvent {
  const ExitMoneyNavigationMode();
}

class RefreshCapturedModules extends NavigationEvent {
  const RefreshCapturedModules();
}
