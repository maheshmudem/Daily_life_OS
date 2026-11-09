import 'package:bloc_test/bloc_test.dart';
import 'package:daily_life_os/features/navigation/domain/entities/navigation_tab_entity.dart';
import 'package:daily_life_os/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  blocTest<NavigationBloc, NavigationState>(
    'selecting a non-money tab records it as the return target',
    build: NavigationBloc.new,
    act: (bloc) =>
        bloc.add(const SelectNavigationTab(NavigationTabEntity.plannerIndex)),
    expect: () => const [
      NavigationState(
        currentIndex: NavigationTabEntity.plannerIndex,
        previousNonMoneyIndex: NavigationTabEntity.plannerIndex,
      ),
    ],
  );

  blocTest<NavigationBloc, NavigationState>(
    'exiting Money returns to the last non-money tab',
    build: NavigationBloc.new,
    act: (bloc) => bloc
      ..add(const SelectNavigationTab(NavigationTabEntity.notesIndex))
      ..add(const SelectNavigationTab(NavigationTabEntity.moneyIndex))
      ..add(const ExitMoneyNavigationMode()),
    verify: (bloc) {
      expect(bloc.state.currentIndex, NavigationTabEntity.notesIndex);
      expect(bloc.state.isInMoneyMode, isFalse);
    },
  );

  blocTest<NavigationBloc, NavigationState>(
    'RefreshCapturedModules bumps the refresh generation',
    build: NavigationBloc.new,
    act: (bloc) => bloc
      ..add(const RefreshCapturedModules())
      ..add(const RefreshCapturedModules()),
    verify: (bloc) => expect(bloc.state.captureRefreshGeneration, 2),
  );
}
