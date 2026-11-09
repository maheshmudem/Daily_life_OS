import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/bloc_effect_mixin.dart';
import '../../../../core/bloc/bloc_status.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/security_config_entity.dart';
import '../../domain/entities/unlock_attempt_result.dart';
import '../../domain/repositories/security_repository.dart';
import '../../domain/usecases/security_usecases.dart';
import 'security_event.dart';
import 'security_state.dart';

export 'security_event.dart';
export 'security_state.dart';

class SecurityBloc extends Bloc<SecurityEvent, SecurityState>
    with BlocEffectMixin<SecurityEvent, SecurityState, SecurityEffect> {
  final LoadSecurityLockStatusUseCase _loadStatus;
  final VerifySecurityPinUseCase _verifyPin;
  final VerifySecurityPatternUseCase _verifyPattern;
  final AuthenticateBiometricsUseCase _authenticateBiometrics;
  final DateTime Function() _now;

  Timer? _lockoutTimer;
  DateTime? _lockoutUntil;

  SecurityBloc({
    required LoadSecurityLockStatusUseCase loadSecurityLockStatusUseCase,
    required VerifySecurityPinUseCase verifySecurityPinUseCase,
    required VerifySecurityPatternUseCase verifySecurityPatternUseCase,
    required AuthenticateBiometricsUseCase authenticateBiometricsUseCase,
    DateTime Function()? clock,
  }) : _loadStatus = loadSecurityLockStatusUseCase,
       _verifyPin = verifySecurityPinUseCase,
       _verifyPattern = verifySecurityPatternUseCase,
       _authenticateBiometrics = authenticateBiometricsUseCase,
       _now = clock ?? DateTime.now,
       super(const SecurityState()) {
    on<LoadSecurityStatus>(_onLoad);
    on<SwitchSecurityLockMode>(_onSwitchMode);
    on<PinInputChanged>(_onPinChanged);
    on<PatternInputStarted>(_onPatternStarted);
    on<PatternSubmitted>(_onPatternSubmitted);
    on<BiometricUnlockRequested>(_onBiometricRequested);
    on<SecurityLockoutTicked>(_onLockoutTicked);
  }

  /// Composes the use cases for a given repository. Lets the lock screen
  /// receive its repository through constructor injection (as Vault and Money
  /// already do) while keeping all logic inside the bloc.
  factory SecurityBloc.fromRepository(SecurityRepository repository) {
    return SecurityBloc(
      loadSecurityLockStatusUseCase: LoadSecurityLockStatusUseCase(repository),
      verifySecurityPinUseCase: VerifySecurityPinUseCase(repository),
      verifySecurityPatternUseCase: VerifySecurityPatternUseCase(repository),
      authenticateBiometricsUseCase: AuthenticateBiometricsUseCase(repository),
    );
  }

  Future<void> _onLoad(
    LoadSecurityStatus event,
    Emitter<SecurityState> emit,
  ) async {
    emit(state.copyWith(status: BlocStatus.loading, clearError: true));
    final result = await _loadStatus(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BlocStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (lockStatus) {
        emit(
          state.copyWith(
            status: BlocStatus.success,
            config: lockStatus.config,
            currentMode: lockStatus.config.activeMode,
            biometricsAvailable: lockStatus.biometricsAvailable,
          ),
        );
        final lockout = lockStatus.lockoutUntil;
        if (lockout != null) {
          _startLockout(lockout, emit);
        } else if (lockStatus.biometricsAvailable) {
          add(const BiometricUnlockRequested());
        }
      },
    );
  }

  void _onSwitchMode(
    SwitchSecurityLockMode event,
    Emitter<SecurityState> emit,
  ) {
    emit(
      state.copyWith(currentMode: event.mode, enteredPin: '', clearError: true),
    );
  }

  Future<void> _onPinChanged(
    PinInputChanged event,
    Emitter<SecurityState> emit,
  ) async {
    if (state.isLockedOut || state.isVerifying) return;
    emit(state.copyWith(enteredPin: event.pin, clearError: true));
    if (event.pin.length < SecurityPolicy.pinLength) return;

    emit(state.copyWith(isVerifying: true));
    final result = await _verifyPin(event.pin);
    _handleAttempt(
      result,
      emit,
      deniedPrefix: StringConstants.incorrectPinPrefix,
      deniedDefault: StringConstants.incorrectPin,
    );
  }

  void _onPatternStarted(
    PatternInputStarted event,
    Emitter<SecurityState> emit,
  ) {
    if (state.hasError) emit(state.copyWith(clearError: true));
  }

  Future<void> _onPatternSubmitted(
    PatternSubmitted event,
    Emitter<SecurityState> emit,
  ) async {
    if (state.isLockedOut || state.isVerifying) return;
    emit(state.copyWith(isVerifying: true, clearError: true));
    final result = await _verifyPattern(event.pattern);
    _handleAttempt(
      result,
      emit,
      deniedPrefix: StringConstants.incorrectPatternPrefix,
      deniedDefault: StringConstants.incorrectPattern,
    );
  }

  Future<void> _onBiometricRequested(
    BiometricUnlockRequested event,
    Emitter<SecurityState> emit,
  ) async {
    if (state.isLockedOut || !state.biometricsAvailable) return;
    final result = await _authenticateBiometrics(
      StringConstants.biometricUnlockReason,
    );
    // Cancellation (Right(false)) is a normal user choice: stay on the
    // PIN/pattern screen without showing an error.
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (authenticated) {
        if (authenticated) emitEffect(const SecurityUnlocked(isDecoy: false));
      },
    );
  }

  void _onLockoutTicked(
    SecurityLockoutTicked event,
    Emitter<SecurityState> emit,
  ) {
    final until = _lockoutUntil;
    final remaining = until == null ? 0 : _secondsUntil(until);
    if (remaining <= 0) {
      _cancelLockout();
      emit(state.copyWith(lockoutSeconds: 0, clearError: true));
    } else {
      emit(
        state.copyWith(
          lockoutSeconds: remaining,
          errorMessage: _lockoutMessage(remaining),
        ),
      );
    }
  }

  void _handleAttempt(
    Either<Failure, UnlockAttemptResult> result,
    Emitter<SecurityState> emit, {
    required String deniedPrefix,
    required String deniedDefault,
  }) {
    result.fold(
      (failure) => emit(
        state.copyWith(
          isVerifying: false,
          enteredPin: '',
          errorMessage: failure.message,
        ),
      ),
      (attempt) {
        switch (attempt.outcome) {
          case UnlockOutcome.granted:
          case UnlockOutcome.decoy:
            emit(state.copyWith(isVerifying: false, enteredPin: ''));
            emitEffect(
              SecurityUnlocked(isDecoy: attempt.outcome == UnlockOutcome.decoy),
            );
          case UnlockOutcome.denied:
            final remaining = attempt.remainingAttempts;
            emit(
              state.copyWith(
                isVerifying: false,
                enteredPin: '',
                errorMessage:
                    remaining <= SecurityPolicy.warnWhenRemainingAtMost
                    ? '$deniedPrefix $remaining attempt${remaining == 1 ? '' : 's'} remaining!'
                    : deniedDefault,
              ),
            );
            emitEffect(const SecurityAttemptRejected());
          case UnlockOutcome.lockedOut:
            emit(state.copyWith(isVerifying: false, enteredPin: ''));
            emitEffect(const SecurityAttemptRejected());
            _startLockout(attempt.lockoutUntil!, emit);
        }
      },
    );
  }

  void _startLockout(DateTime until, Emitter<SecurityState> emit) {
    final remaining = _secondsUntil(until);
    if (remaining <= 0) return;
    _cancelLockout();
    _lockoutUntil = until;
    emit(
      state.copyWith(
        lockoutSeconds: remaining,
        errorMessage: _lockoutMessage(remaining),
      ),
    );
    _lockoutTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const SecurityLockoutTicked()),
    );
  }

  int _secondsUntil(DateTime until) =>
      (until.difference(_now()).inMilliseconds / 1000).ceil();

  String _lockoutMessage(int seconds) =>
      '${StringConstants.lockoutMessagePrefix} ${seconds}s';

  void _cancelLockout() {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    _lockoutUntil = null;
  }

  @override
  Future<void> close() {
    _cancelLockout();
    return super.close();
  }
}
