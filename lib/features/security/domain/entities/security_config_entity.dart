import 'package:equatable/equatable.dart';

enum SecurityLockMode { pin, pattern }

/// Brute-force protection policy, shared by the data layer (which enforces
/// it) and the presentation layer (which explains it to the user).
class SecurityPolicy {
  SecurityPolicy._();

  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 30);
  static const int pinLength = 4;

  /// Below this many remaining attempts the UI warns explicitly.
  static const int warnWhenRemainingAtMost = 2;
}

class SecurityConfigEntity extends Equatable {
  final bool isSecurityEnabled;
  final bool isBiometricEnabled;
  final bool hasPin;
  final bool hasPattern;
  final bool hasDecoyPin;
  final bool hasDecoyPattern;
  final SecurityLockMode activeMode;

  const SecurityConfigEntity({
    this.isSecurityEnabled = false,
    this.isBiometricEnabled = false,
    this.hasPin = false,
    this.hasPattern = false,
    this.hasDecoyPin = false,
    this.hasDecoyPattern = false,
    this.activeMode = SecurityLockMode.pin,
  });

  bool get isConfigured => hasPin || hasPattern;

  SecurityConfigEntity copyWith({
    bool? isSecurityEnabled,
    bool? isBiometricEnabled,
    bool? hasPin,
    bool? hasPattern,
    bool? hasDecoyPin,
    bool? hasDecoyPattern,
    SecurityLockMode? activeMode,
  }) {
    return SecurityConfigEntity(
      isSecurityEnabled: isSecurityEnabled ?? this.isSecurityEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      hasPin: hasPin ?? this.hasPin,
      hasPattern: hasPattern ?? this.hasPattern,
      hasDecoyPin: hasDecoyPin ?? this.hasDecoyPin,
      hasDecoyPattern: hasDecoyPattern ?? this.hasDecoyPattern,
      activeMode: activeMode ?? this.activeMode,
    );
  }

  @override
  List<Object?> get props => [
    isSecurityEnabled,
    isBiometricEnabled,
    hasPin,
    hasPattern,
    hasDecoyPin,
    hasDecoyPattern,
    activeMode,
  ];
}
