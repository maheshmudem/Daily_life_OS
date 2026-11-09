import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/navigation_tab_entity.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

export 'navigation_event.dart';
export 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<SelectNavigationTab>(_onSelectTab);
    on<ExitMoneyNavigationMode>(_onExitMoneyMode);
    on<RefreshCapturedModules>(_onRefreshCapturedModules);
  }

  void _onSelectTab(SelectNavigationTab event, Emitter<NavigationState> emit) {
    final prevNonMoney = event.index != NavigationTabEntity.moneyIndex
        ? event.index
        : state.previousNonMoneyIndex;
    emit(
      state.copyWith(
        currentIndex: event.index,
        previousNonMoneyIndex: prevNonMoney,
      ),
    );
  }

  void _onExitMoneyMode(
    ExitMoneyNavigationMode event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(currentIndex: state.previousNonMoneyIndex));
  }

  void _onRefreshCapturedModules(
    RefreshCapturedModules event,
    Emitter<NavigationState> emit,
  ) {
    emit(
      state.copyWith(
        captureRefreshGeneration: state.captureRefreshGeneration + 1,
      ),
    );
  }
}
