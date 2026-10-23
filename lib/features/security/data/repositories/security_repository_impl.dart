import '../../domain/entities/security_config_entity.dart';
import '../../domain/repositories/security_repository.dart';
import '../datasources/security_local_datasource.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  final SecurityLocalDataSource localDataSource;

  SecurityRepositoryImpl(this.localDataSource);

  @override
  Future<SecurityConfigEntity> getConfig() => localDataSource.getConfig();

  @override
  Future<bool> isBiometricsAvailable() => localDataSource.isBiometricsAvailable();

  @override
  Future<bool> authenticateBiometrics({String reason = 'Authenticate to access Secure Vault'}) =>
      localDataSource.authenticateBiometrics(reason: reason);

  @override
  Future<bool> verifyPin(String pin) => localDataSource.verifyPin(pin);

  @override
  Future<bool> isDecoyPin(String pin) => localDataSource.isDecoyPin(pin);

  @override
  Future<bool> verifyPattern(List<int> pattern) => localDataSource.verifyPattern(pattern);

  @override
  Future<bool> isDecoyPattern(List<int> pattern) => localDataSource.isDecoyPattern(pattern);

  @override
  Future<void> setPin({required String pin, String? decoyPin}) =>
      localDataSource.setPin(pin: pin, decoyPin: decoyPin);

  @override
  Future<void> setDecoyPin(String decoyPin) => localDataSource.setDecoyPin(decoyPin);

  @override
  Future<void> setPattern({required List<int> pattern, List<int>? decoyPattern}) =>
      localDataSource.setPattern(pattern: pattern, decoyPattern: decoyPattern);

  @override
  Future<void> setDecoyPattern(List<int> decoyPattern) =>
      localDataSource.setDecoyPattern(decoyPattern);

  @override
  Future<void> setBiometricsEnabled(bool enabled) => localDataSource.setBiometricsEnabled(enabled);

  @override
  Future<void> setSecurityEnabled(bool enabled) => localDataSource.setSecurityEnabled(enabled);

  @override
  Future<void> setLockMode(SecurityLockMode mode) => localDataSource.setLockMode(mode);

  @override
  Future<int> getFailedAttempts() => localDataSource.getFailedAttempts();

  @override
  Future<DateTime?> getLockoutUntil() => localDataSource.getLockoutUntil();

  @override
  Future<void> clearAllSecurity() => localDataSource.clearAllSecurity();
}
