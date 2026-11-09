import 'package:equatable/equatable.dart';

import 'security_config_entity.dart';

enum UnlockOutcome { granted, decoy, denied, lockedOut }

/// Result of a single PIN / pattern / biometric unlock attempt.
class UnlockAttemptResult extends Equatable {
  final UnlockOutcome outcome;

  /// Attempts left before lockout (only meaningful for [UnlockOutcome.denied]).
  final int remainingAttempts;

  /// When the lockout ends (only for [UnlockOutcome.lockedOut]).
  final DateTime? lockoutUntil;

  const UnlockAttemptResult._(
    this.outcome, {
    this.remainingAttempts = SecurityPolicy.maxFailedAttempts,
    this.lockoutUntil,
  });

  const UnlockAttemptResult.granted() : this._(UnlockOutcome.granted);
  const UnlockAttemptResult.decoy() : this._(UnlockOutcome.decoy);
  const UnlockAttemptResult.denied({required int remainingAttempts})
    : this._(UnlockOutcome.denied, remainingAttempts: remainingAttempts);
  const UnlockAttemptResult.lockedOut({required DateTime until})
    : this._(
        UnlockOutcome.lockedOut,
        remainingAttempts: 0,
        lockoutUntil: until,
      );

  bool get isUnlocked =>
      outcome == UnlockOutcome.granted || outcome == UnlockOutcome.decoy;

  @override
  List<Object?> get props => [outcome, remainingAttempts, lockoutUntil];
}

/// Everything the lock screen needs to render its initial state.
class SecurityLockStatus extends Equatable {
  final SecurityConfigEntity config;
  final bool biometricsAvailable;
  final DateTime? lockoutUntil;

  const SecurityLockStatus({
    required this.config,
    required this.biometricsAvailable,
    this.lockoutUntil,
  });

  @override
  List<Object?> get props => [config, biometricsAvailable, lockoutUntil];
}
