import 'package:bloc_test/bloc_test.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/features/security/domain/entities/security_config_entity.dart';
import 'package:daily_life_os/features/security/domain/repositories/security_repository.dart';
import 'package:daily_life_os/features/security/presentation/bloc/security_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecurityRepository extends Mock implements SecurityRepository {}

void main() {
  late MockSecurityRepository repo;

  setUp(() {
    repo = MockSecurityRepository();
    when(() => repo.getConfig()).thenAnswer(
      (_) async => const SecurityConfigEntity(
        isSecurityEnabled: true,
        hasPin: true,
        hasPattern: true,
      ),
    );
    when(() => repo.isBiometricsAvailable()).thenAnswer((_) async => false);
    when(() => repo.getLockoutUntil()).thenAnswer((_) async => null);
    when(() => repo.isDecoyPin(any())).thenAnswer((_) async => false);
    when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
  });

  SecurityBloc buildBloc() => SecurityBloc.fromRepository(repo);

  Future<List<SecurityEffect>> collectEffects(
    SecurityBloc bloc,
    Future<void> Function() act,
  ) async {
    final effects = <SecurityEffect>[];
    final sub = bloc.effects.listen(effects.add);
    await act();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();
    return effects;
  }

  blocTest<SecurityBloc, SecurityState>(
    'load exposes config and shows mode tabs when PIN + pattern exist',
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadSecurityStatus()),
    verify: (bloc) {
      expect(bloc.state.status.isSuccess, isTrue);
      expect(bloc.state.showModeTabs, isTrue);
    },
  );

  test('decoy PIN is checked first and never verifies the real PIN', () async {
    when(() => repo.isDecoyPin('9999')).thenAnswer((_) async => true);
    final bloc = buildBloc();

    final effects = await collectEffects(
      bloc,
      () async => bloc.add(const PinInputChanged('9999')),
    );

    expect(effects.single, isA<SecurityUnlocked>());
    expect((effects.single as SecurityUnlocked).isDecoy, isTrue);
    verifyNever(() => repo.verifyPin(any()));
    await bloc.close();
  });

  test('real PIN unlocks in standard mode', () async {
    when(() => repo.verifyPin('1234')).thenAnswer((_) async => true);
    final bloc = buildBloc();

    final effects = await collectEffects(
      bloc,
      () async => bloc.add(const PinInputChanged('1234')),
    );

    expect((effects.single as SecurityUnlocked).isDecoy, isFalse);
    await bloc.close();
  });

  test('partial PIN does not trigger verification', () async {
    final bloc = buildBloc();
    bloc.add(const PinInputChanged('12'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.enteredPin, '12');
    verifyNever(() => repo.isDecoyPin(any()));
    await bloc.close();
  });

  test('wrong PIN warns explicitly when few attempts remain', () async {
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 4);
    final bloc = buildBloc();

    final effects = await collectEffects(
      bloc,
      () async => bloc.add(const PinInputChanged('0000')),
    );

    expect(effects.single, isA<SecurityAttemptRejected>());
    expect(
      bloc.state.errorMessage,
      '${StringConstants.incorrectPinPrefix} 1 attempt remaining!',
    );
    expect(bloc.state.enteredPin, isEmpty);
    await bloc.close();
  });

  test('wrong PIN with many attempts left shows the generic message', () async {
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 1);
    final bloc = buildBloc();

    await collectEffects(
      bloc,
      () async => bloc.add(const PinInputChanged('0000')),
    );

    expect(bloc.state.errorMessage, StringConstants.incorrectPin);
    await bloc.close();
  });

  test(
    'reaching the limit starts a lockout countdown and blocks input',
    () async {
      when(() => repo.getLockoutUntil()).thenAnswer((_) async => null);
      final bloc = buildBloc();
      // After the failed attempt the repository reports an active lockout.
      when(() => repo.verifyPin(any())).thenAnswer((_) async {
        when(() => repo.getLockoutUntil()).thenAnswer(
          (_) async => DateTime.now().add(const Duration(seconds: 30)),
        );
        return false;
      });

      await collectEffects(
        bloc,
        () async => bloc.add(const PinInputChanged('0000')),
      );

      expect(bloc.state.isLockedOut, isTrue);
      expect(bloc.state.lockoutSeconds, inInclusiveRange(29, 30));

      clearInteractions(repo);
      bloc.add(const PinInputChanged('1234'));
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => repo.isDecoyPin(any()));
      await bloc.close();
    },
  );

  test('storage errors surface as a message instead of crashing', () async {
    when(() => repo.isDecoyPin(any())).thenThrow(Exception('keystore'));
    final bloc = buildBloc();

    await collectEffects(
      bloc,
      () async => bloc.add(const PinInputChanged('1234')),
    );

    expect(bloc.state.errorMessage, StringConstants.genericError);
    expect(bloc.state.isVerifying, isFalse);
    await bloc.close();
  });

  blocTest<SecurityBloc, SecurityState>(
    'switching mode clears the entered PIN and error',
    build: buildBloc,
    seed: () => const SecurityState(enteredPin: '12', errorMessage: 'x'),
    act: (bloc) =>
        bloc.add(const SwitchSecurityLockMode(SecurityLockMode.pattern)),
    expect: () => const [SecurityState(currentMode: SecurityLockMode.pattern)],
  );
}
