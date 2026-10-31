import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../domain/entities/security_config_entity.dart';

abstract class SecurityLocalDataSource {
  Future<SecurityConfigEntity> getConfig();
  Future<bool> isBiometricsAvailable();
  Future<bool> authenticateBiometrics({String reason});
  Future<bool> verifyPin(String pin);
  Future<bool> isDecoyPin(String pin);
  Future<bool> verifyPattern(List<int> pattern);
  Future<bool> isDecoyPattern(List<int> pattern);
  Future<void> setPin({required String pin, String? decoyPin});
  Future<void> setDecoyPin(String decoyPin);
  Future<void> setPattern({
    required List<int> pattern,
    List<int>? decoyPattern,
  });
  Future<void> setDecoyPattern(List<int> decoyPattern);
  Future<void> setBiometricsEnabled(bool enabled);
  Future<void> setSecurityEnabled(bool enabled);
  Future<void> setLockMode(SecurityLockMode mode);
  Future<int> getFailedAttempts();
  Future<DateTime?> getLockoutUntil();
  Future<void> clearAllSecurity();
}

class SecurityLocalDataSourceImpl implements SecurityLocalDataSource {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  SecurityLocalDataSourceImpl({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _localAuth = localAuth ?? LocalAuthentication();

  static const String _keySalt = 'vault_sec_salt';
  static const String _keyPinHash = 'vault_sec_pin_hash';
  static const String _keyDecoyPinHash = 'vault_sec_decoy_pin_hash';
  static const String _keyPatternHash = 'vault_sec_pattern_hash';
  static const String _keyDecoyPatternHash = 'vault_sec_decoy_pattern_hash';
  static const String _keyBiometricEnabled = 'vault_sec_biometric_enabled';
  static const String _keySecurityEnabled = 'vault_sec_enabled';
  static const String _keyLockMode = 'vault_sec_lock_mode';
  static const String _keyFailedAttempts = 'vault_sec_failed_attempts';
  static const String _keyLockoutUntil = 'vault_sec_lockout_until';

  Future<String> _getOrCreateSalt() async {
    String? salt = await _storage.read(key: _keySalt);
    if (salt == null || salt.isEmpty) {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      salt = base64Url.encode(values);
      await _storage.write(key: _keySalt, value: salt);
    }
    return salt;
  }

  String _hash(String salt, String value) {
    return sha256.convert(utf8.encode('$salt:$value')).toString();
  }

  @override
  Future<SecurityConfigEntity> getConfig() async {
    final isSecEnabledStr = await _storage.read(key: _keySecurityEnabled);
    final isBioEnabledStr = await _storage.read(key: _keyBiometricEnabled);
    final modeStr = await _storage.read(key: _keyLockMode);

    final storedPin = await _storage.read(key: _keyPinHash);
    final storedDecoyPin = await _storage.read(key: _keyDecoyPinHash);
    final storedPattern = await _storage.read(key: _keyPatternHash);
    final storedDecoyPattern = await _storage.read(key: _keyDecoyPatternHash);

    final hasPin = storedPin != null && storedPin.isNotEmpty;
    final hasPattern = storedPattern != null && storedPattern.isNotEmpty;
    final isConfigured = hasPin || hasPattern;

    // Security is only enabled if the user explicitly set it AND configured a PIN or Pattern
    final isSecurityEnabled = isSecEnabledStr == 'true' && isConfigured;

    return SecurityConfigEntity(
      isSecurityEnabled: isSecurityEnabled,
      isBiometricEnabled: isBioEnabledStr == 'true',
      hasPin: hasPin,
      hasPattern: hasPattern,
      hasDecoyPin: storedDecoyPin != null && storedDecoyPin.isNotEmpty,
      hasDecoyPattern:
          storedDecoyPattern != null && storedDecoyPattern.isNotEmpty,
      activeMode: modeStr == 'pattern'
          ? SecurityLockMode.pattern
          : SecurityLockMode.pin,
    );
  }

  @override
  Future<int> getFailedAttempts() async {
    final val = await _storage.read(key: _keyFailedAttempts);
    return int.tryParse(val ?? '0') ?? 0;
  }

  @override
  Future<DateTime?> getLockoutUntil() async {
    final val = await _storage.read(key: _keyLockoutUntil);
    if (val == null) return null;
    final millis = int.tryParse(val);
    if (millis == null) return null;
    final lockoutTime = DateTime.fromMillisecondsSinceEpoch(millis);
    if (DateTime.now().isAfter(lockoutTime)) {
      await _storage.delete(key: _keyLockoutUntil);
      await _storage.delete(key: _keyFailedAttempts);
      return null;
    }
    return lockoutTime;
  }

  Future<void> _recordFailedAttempt() async {
    final current = await getFailedAttempts();
    final updated = current + 1;
    await _storage.write(key: _keyFailedAttempts, value: updated.toString());
    if (updated >= 5) {
      final lockoutTime = DateTime.now().add(const Duration(seconds: 30));
      await _storage.write(
        key: _keyLockoutUntil,
        value: lockoutTime.millisecondsSinceEpoch.toString(),
      );
    }
  }

  Future<void> _resetFailedAttempts() async {
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockoutUntil);
  }

  @override
  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics.timeout(
        const Duration(milliseconds: 500),
      );
      final isSupported = await _localAuth.isDeviceSupported().timeout(
        const Duration(milliseconds: 500),
      );
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticateBiometrics({
    String reason = 'Authenticate to access Secure Vault',
  }) async {
    try {
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) return false;

      final success = await _localAuth.authenticate(localizedReason: reason);
      if (success) {
        await _resetFailedAttempts();
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final lockout = await getLockoutUntil();
    if (lockout != null) return false;

    final storedHash = await _storage.read(key: _keyPinHash);
    if (storedHash == null || storedHash.isEmpty) {
      return false; // NO hardcoded default pin!
    }
    final salt = await _getOrCreateSalt();
    final inputHash = _hash(salt, pin);
    final isMatch = inputHash == storedHash;
    if (isMatch) {
      await _resetFailedAttempts();
    } else {
      await _recordFailedAttempt();
    }
    return isMatch;
  }

  @override
  Future<bool> isDecoyPin(String pin) async {
    final storedHash = await _storage.read(key: _keyDecoyPinHash);
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }
    final salt = await _getOrCreateSalt();
    final inputHash = _hash(salt, pin);
    final isMatch = inputHash == storedHash;
    if (isMatch) {
      await _resetFailedAttempts();
    }
    return isMatch;
  }

  @override
  Future<bool> verifyPattern(List<int> pattern) async {
    final lockout = await getLockoutUntil();
    if (lockout != null) return false;

    final storedHash = await _storage.read(key: _keyPatternHash);
    if (storedHash == null || storedHash.isEmpty) {
      return false; // NO hardcoded default pattern!
    }
    final salt = await _getOrCreateSalt();
    final inputHash = _hash(salt, pattern.join('-'));
    final isMatch = inputHash == storedHash;
    if (isMatch) {
      await _resetFailedAttempts();
    } else {
      await _recordFailedAttempt();
    }
    return isMatch;
  }

  @override
  Future<bool> isDecoyPattern(List<int> pattern) async {
    final storedHash = await _storage.read(key: _keyDecoyPatternHash);
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }
    final salt = await _getOrCreateSalt();
    final inputHash = _hash(salt, pattern.join('-'));
    final isMatch = inputHash == storedHash;
    if (isMatch) {
      await _resetFailedAttempts();
    }
    return isMatch;
  }

  @override
  Future<void> setPin({required String pin, String? decoyPin}) async {
    final salt = await _getOrCreateSalt();
    await _storage.write(key: _keyPinHash, value: _hash(salt, pin));
    await _storage.write(key: _keySecurityEnabled, value: 'true');
    await _storage.write(key: _keyLockMode, value: 'pin');
    if (decoyPin != null && decoyPin.isNotEmpty) {
      await _storage.write(key: _keyDecoyPinHash, value: _hash(salt, decoyPin));
    }
  }

  @override
  Future<void> setDecoyPin(String decoyPin) async {
    final salt = await _getOrCreateSalt();
    await _storage.write(key: _keyDecoyPinHash, value: _hash(salt, decoyPin));
  }

  @override
  Future<void> setPattern({
    required List<int> pattern,
    List<int>? decoyPattern,
  }) async {
    final salt = await _getOrCreateSalt();
    await _storage.write(
      key: _keyPatternHash,
      value: _hash(salt, pattern.join('-')),
    );
    await _storage.write(key: _keySecurityEnabled, value: 'true');
    await _storage.write(key: _keyLockMode, value: 'pattern');
    if (decoyPattern != null && decoyPattern.isNotEmpty) {
      await _storage.write(
        key: _keyDecoyPatternHash,
        value: _hash(salt, decoyPattern.join('-')),
      );
    }
  }

  @override
  Future<void> setDecoyPattern(List<int> decoyPattern) async {
    final salt = await _getOrCreateSalt();
    await _storage.write(
      key: _keyDecoyPatternHash,
      value: _hash(salt, decoyPattern.join('-')),
    );
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  @override
  Future<void> setSecurityEnabled(bool enabled) async {
    await _storage.write(key: _keySecurityEnabled, value: enabled.toString());
  }

  @override
  Future<void> setLockMode(SecurityLockMode mode) async {
    await _storage.write(
      key: _keyLockMode,
      value: mode == SecurityLockMode.pattern ? 'pattern' : 'pin',
    );
  }

  @override
  Future<void> clearAllSecurity() async {
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyDecoyPinHash);
    await _storage.delete(key: _keyPatternHash);
    await _storage.delete(key: _keyDecoyPatternHash);
    await _storage.delete(key: _keySecurityEnabled);
    await _storage.delete(key: _keyBiometricEnabled);
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockoutUntil);
  }
}
