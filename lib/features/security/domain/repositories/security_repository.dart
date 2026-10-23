import '../entities/security_config_entity.dart';

abstract class SecurityRepository {
  Future<SecurityConfigEntity> getConfig();
  Future<bool> isBiometricsAvailable();
  Future<bool> authenticateBiometrics({String reason});
  Future<bool> verifyPin(String pin);
  Future<bool> isDecoyPin(String pin);
  Future<bool> verifyPattern(List<int> pattern);
  Future<bool> isDecoyPattern(List<int> pattern);
  Future<void> setPin({required String pin, String? decoyPin});
  Future<void> setDecoyPin(String decoyPin);
  Future<void> setPattern({required List<int> pattern, List<int>? decoyPattern});
  Future<void> setDecoyPattern(List<int> decoyPattern);
  Future<void> setBiometricsEnabled(bool enabled);
  Future<void> setSecurityEnabled(bool enabled);
  Future<void> setLockMode(SecurityLockMode mode);
  Future<int> getFailedAttempts();
  Future<DateTime?> getLockoutUntil();
  Future<void> clearAllSecurity();
}
