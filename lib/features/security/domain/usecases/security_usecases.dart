import 'package:dartz/dartz.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/security_config_entity.dart';
import '../entities/unlock_attempt_result.dart';
import '../repositories/security_repository.dart';

// The shared `SecurityRepository` predates the `Either` contract and is also
// used by the setup wizard and settings sheet, so these use cases form the
// Either boundary for the lock flow via `guardRepositoryCall`.

/// Loads config, biometric availability and any active lockout.
class LoadSecurityLockStatusUseCase
    implements UseCase<SecurityLockStatus, NoParams> {
  final SecurityRepository _repository;

  const LoadSecurityLockStatusUseCase(this._repository);

  @override
  Future<Either<Failure, SecurityLockStatus>> call(NoParams params) {
    return guardRepositoryCall(context: 'Security.loadStatus', () async {
      final config = await _repository.getConfig();
      final biometricsAvailable = await _repository.isBiometricsAvailable();
      final lockoutUntil = await _repository.getLockoutUntil();
      return SecurityLockStatus(
        config: config,
        biometricsAvailable: biometricsAvailable && config.isBiometricEnabled,
        lockoutUntil: lockoutUntil,
      );
    });
  }
}

/// Shared outcome resolution for a wrong credential.
Future<UnlockAttemptResult> _resolveDenied(SecurityRepository repo) async {
  final lockout = await repo.getLockoutUntil();
  if (lockout != null) return UnlockAttemptResult.lockedOut(until: lockout);
  final attempts = await repo.getFailedAttempts();
  final remaining = (SecurityPolicy.maxFailedAttempts - attempts).clamp(
    0,
    SecurityPolicy.maxFailedAttempts,
  );
  return UnlockAttemptResult.denied(remainingAttempts: remaining);
}

/// Verifies a PIN. The decoy PIN is checked **first** so that entering it
/// never counts as a failed attempt against the real PIN.
class VerifySecurityPinUseCase implements UseCase<UnlockAttemptResult, String> {
  final SecurityRepository _repository;

  const VerifySecurityPinUseCase(this._repository);

  @override
  Future<Either<Failure, UnlockAttemptResult>> call(String pin) {
    return guardRepositoryCall(context: 'Security.verifyPin', () async {
      if (await _repository.isDecoyPin(pin)) {
        return const UnlockAttemptResult.decoy();
      }
      if (await _repository.verifyPin(pin)) {
        return const UnlockAttemptResult.granted();
      }
      return _resolveDenied(_repository);
    });
  }
}

/// Verifies a pattern (decoy checked first, same as PIN).
class VerifySecurityPatternUseCase
    implements UseCase<UnlockAttemptResult, List<int>> {
  final SecurityRepository _repository;

  const VerifySecurityPatternUseCase(this._repository);

  @override
  Future<Either<Failure, UnlockAttemptResult>> call(List<int> pattern) {
    return guardRepositoryCall(context: 'Security.verifyPattern', () async {
      if (await _repository.isDecoyPattern(pattern)) {
        return const UnlockAttemptResult.decoy();
      }
      if (await _repository.verifyPattern(pattern)) {
        return const UnlockAttemptResult.granted();
      }
      return _resolveDenied(_repository);
    });
  }
}

/// Prompts the OS biometric sheet; `Right(false)` means the user cancelled.
class AuthenticateBiometricsUseCase implements UseCase<bool, String> {
  final SecurityRepository _repository;

  const AuthenticateBiometricsUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(String reason) {
    return guardRepositoryCall(
      context: 'Security.biometrics',
      () => _repository.authenticateBiometrics(reason: reason),
    );
  }
}
