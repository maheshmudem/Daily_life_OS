import 'package:equatable/equatable.dart';

import '../../../../core/bloc/bloc_status.dart';
import '../../domain/entities/security_config_entity.dart';

class SecurityState extends Equatable {
  final BlocStatus status;
  final SecurityConfigEntity config;
  final SecurityLockMode currentMode;
  final bool biometricsAvailable;
  final String enteredPin;
  final String? errorMessage;
  final int lockoutSeconds;
  final bool isVerifying;

  const SecurityState({
    this.status = BlocStatus.initial,
    this.config = const SecurityConfigEntity(),
    this.currentMode = SecurityLockMode.pin,
    this.biometricsAvailable = false,
    this.enteredPin = '',
    this.errorMessage,
    this.lockoutSeconds = 0,
    this.isVerifying = false,
  });

  bool get isLockedOut => lockoutSeconds > 0;
  bool get hasError => errorMessage != null;

  /// Show the PIN / Pattern switcher only when both are configured.
  bool get showModeTabs => config.hasPin && config.hasPattern && !isLockedOut;

  SecurityState copyWith({
    BlocStatus? status,
    SecurityConfigEntity? config,
    SecurityLockMode? currentMode,
    bool? biometricsAvailable,
    String? enteredPin,
    String? errorMessage,
    bool clearError = false,
    int? lockoutSeconds,
    bool? isVerifying,
  }) {
    return SecurityState(
      status: status ?? this.status,
      config: config ?? this.config,
      currentMode: currentMode ?? this.currentMode,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
      enteredPin: enteredPin ?? this.enteredPin,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lockoutSeconds: lockoutSeconds ?? this.lockoutSeconds,
      isVerifying: isVerifying ?? this.isVerifying,
    );
  }

  @override
  List<Object?> get props => [
    status,
    config,
    currentMode,
    biometricsAvailable,
    enteredPin,
    errorMessage,
    lockoutSeconds,
    isVerifying,
  ];
}
