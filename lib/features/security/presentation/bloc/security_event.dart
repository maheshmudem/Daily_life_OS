import 'package:equatable/equatable.dart';

import '../../domain/entities/security_config_entity.dart';

abstract class SecurityEvent extends Equatable {
  const SecurityEvent();

  @override
  List<Object?> get props => [];
}

class LoadSecurityStatus extends SecurityEvent {
  const LoadSecurityStatus();
}

class SwitchSecurityLockMode extends SecurityEvent {
  final SecurityLockMode mode;

  const SwitchSecurityLockMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Fired on every dial-pad tap; verification runs automatically once the PIN
/// reaches `SecurityPolicy.pinLength` digits.
class PinInputChanged extends SecurityEvent {
  final String pin;

  const PinInputChanged(this.pin);

  @override
  List<Object?> get props => [pin];
}

class PatternInputStarted extends SecurityEvent {
  const PatternInputStarted();
}

class PatternSubmitted extends SecurityEvent {
  final List<int> pattern;

  const PatternSubmitted(this.pattern);

  @override
  List<Object?> get props => [pattern];
}

class BiometricUnlockRequested extends SecurityEvent {
  const BiometricUnlockRequested();
}

/// Internal: one-second countdown tick while locked out.
class SecurityLockoutTicked extends SecurityEvent {
  const SecurityLockoutTicked();
}

/// One-shot effects emitted by `SecurityBloc`.
sealed class SecurityEffect {
  const SecurityEffect();
}

/// Credentials accepted; [isDecoy] is true for the decoy/panic credential.
final class SecurityUnlocked extends SecurityEffect {
  final bool isDecoy;

  const SecurityUnlocked({required this.isDecoy});
}

/// A wrong credential was entered (used for haptic feedback).
final class SecurityAttemptRejected extends SecurityEffect {
  const SecurityAttemptRejected();
}
