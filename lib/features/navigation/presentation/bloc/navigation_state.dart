import 'package:equatable/equatable.dart';

import '../../domain/entities/navigation_tab_entity.dart';

class NavigationState extends Equatable {
  final int currentIndex;
  final int previousNonMoneyIndex;
  final int captureRefreshGeneration;

  const NavigationState({
    this.currentIndex = NavigationTabEntity.todayIndex,
    this.previousNonMoneyIndex = NavigationTabEntity.todayIndex,
    this.captureRefreshGeneration = 0,
  });

  bool get isInMoneyMode => currentIndex == NavigationTabEntity.moneyIndex;

  NavigationState copyWith({
    int? currentIndex,
    int? previousNonMoneyIndex,
    int? captureRefreshGeneration,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      previousNonMoneyIndex:
          previousNonMoneyIndex ?? this.previousNonMoneyIndex,
      captureRefreshGeneration:
          captureRefreshGeneration ?? this.captureRefreshGeneration,
    );
  }

  @override
  List<Object?> get props => [
    currentIndex,
    previousNonMoneyIndex,
    captureRefreshGeneration,
  ];
}
