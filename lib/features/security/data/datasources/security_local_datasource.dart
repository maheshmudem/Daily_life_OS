import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/monitoring/app_monitor.dart';
import '../../domain/entities/security_config_entity.dart';

abstract class SecurityLocalDataSource {
  bool get isMasterSessionUnlocked;
  void lockSession();
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
  SecurityConfigEntity? _cachedConfig;
  bool _isMasterSessionUnlocked = false;

  /// Number of iterated HMAC-SHA256 rounds for credential stretching.
  static const int kKeyDerivationIterations = 2500;
  static const String _hashVersionPrefix = 'v2\$';

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

  @override
  bool get isMasterSessionUnlocked => _isMasterSessionUnlocked;

  @override
  void lockSession() {
    _isMasterSessionUnlocked = false;
    AppMonitor.instance.recordSecurityEvent('vault_session_locked');
  }

  /// Constant-time byte comparison to eliminate timing side-channel leaks.
  @visibleForTesting
  static bool constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    var diff = aBytes.length ^ bBytes.length;
    final maxLen = max(aBytes.length, bBytes.length);
    for (var i = 0; i < maxLen; i++) {
      final byteA = i < aBytes.length ? aBytes[i] : 0;
      final byteB = i < bBytes.length ? bBytes[i] : 0;
      diff |= byteA ^ byteB;
    }
    return diff == 0;
  }

  Future<String> _getOrCreateSalt() async {
    String? salt = await _storage.read(key: _keySalt);
    if (salt == null || salt.isEmpty) {
      final random = Random.secure();
      final values = List<int>.generate(32, (_) => random.nextInt(256));
      salt = base64Url.encode(values);
      await _storage.write(key: _keySalt, value: salt);
    }
    return salt;
  }

  /// Iterated HMAC-SHA256 key derivation (`v2$<hex>`) with domain separation.
  String _deriveHash(String salt, String value) {
    final keyBytes = utf8.encode('DailyLifeOS.Vault.v2:$salt');
    final hmac = Hmac(sha256, keyBytes);
    var digestBytes = hmac.convert(utf8.encode(value)).bytes;
    for (var i = 1; i < kKeyDerivationIterations; i++) {
      digestBytes = hmac.convert(digestBytes).bytes;
    }
    final hex = digestBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '$_hashVersionPrefix$hex';
  }

  String _legacyHash(String salt, String value) {
    return sha256.convert(utf8.encode('$salt:$value')).toString();
  }

  Future<bool> _verifyAndUpgradeIfNeeded({
    required String storageKey,
    required String salt,
    required String candidate,
    required String storedHash,
  }) async {
    if (storedHash.startsWith(_hashVersionPrefix)) {
      final derived = _deriveHash(salt, candidate);
      return constantTimeEquals(derived, storedHash);
    }
    // Legacy v1 migration path
    final legacy = _legacyHash(salt, candidate);
    final matched = constantTimeEquals(legacy, storedHash);
    if (matched) {
      await _storage.write(
        key: storageKey,
        value: _deriveHash(salt, candidate),
      );
    }
    return matched;
  }

  static bool _isValidCredentialInput(String input) {
    return input.isNotEmpty && input.length <= 64 && !input.contains('\x00');
  }

  @override
  Future<SecurityConfigEntity> getConfig() async {
    final cached = _cachedConfig;
    if (cached != null) return cached;

    final values = await Future.wait([
      _storage.read(key: _keySecurityEnabled),
      _storage.read(key: _keyBiometricEnabled),
      _storage.read(key: _keyLockMode),
      _storage.read(key: _keyPinHash),
      _storage.read(key: _keyDecoyPinHash),
      _storage.read(key: _keyPatternHash),
      _storage.read(key: _keyDecoyPatternHash),
    ]);

    final isSecEnabledStr = values[0];
    final isBioEnabledStr = values[1];
    final modeStr = values[2];
    final storedPin = values[3];
    final storedDecoyPin = values[4];
    final storedPattern = values[5];
    final storedDecoyPattern = values[6];

    final hasPin = storedPin != null && storedPin.isNotEmpty;
    final hasPattern = storedPattern != null && storedPattern.isNotEmpty;
    final isConfigured = hasPin || hasPattern;

    // Security is only enabled if the user explicitly set it AND configured a PIN or Pattern
    final isSecurityEnabled = isSecEnabledStr == 'true' && isConfigured;

    final config = SecurityConfigEntity(
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
    _cachedConfig = config;
    return config;
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
    if (updated >= SecurityPolicy.maxFailedAttempts) {
      final lockoutTime = DateTime.now().add(SecurityPolicy.lockoutDuration);
      await _storage.write(
        key: _keyLockoutUntil,
        value: lockoutTime.millisecondsSinceEpoch.toString(),
      );
      AppMonitor.instance.recordSecurityEvent(
        'vault_rate_limit_lockout',
        blocked: true,
        detail: 'attempts=$updated',
      );
    } else {
      AppMonitor.instance.recordSecurityEvent(
        'vault_auth_failed',
        detail: 'attempt=$updated',
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
      final lockout = await getLockoutUntil();
      if (lockout != null) return false;

      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) return false;

      final success = await _localAuth.authenticate(localizedReason: reason);
      if (success) {
        _isMasterSessionUnlocked = true;
        await _resetFailedAttempts();
        AppMonitor.instance.recordSecurityEvent('vault_biometric_unlocked');
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> verifyPin(String pin) async {
    if (!_isValidCredentialInput(pin)) return false;

    final lockout = await getLockoutUntil();
    if (lockout != null) return false;

    final storedHash = await _storage.read(key: _keyPinHash);
    if (storedHash == null || storedHash.isEmpty) {
      return false; // NO hardcoded default pin!
    }
    final salt = await _getOrCreateSalt();
    final isMatch = await _verifyAndUpgradeIfNeeded(
      storageKey: _keyPinHash,
      salt: salt,
      candidate: pin,
      storedHash: storedHash,
    );
    if (isMatch) {
      _isMasterSessionUnlocked = true;
      await _resetFailedAttempts();
      AppMonitor.instance.recordSecurityEvent('vault_pin_unlocked');
    } else {
      await _recordFailedAttempt();
    }
    return isMatch;
  }

  @override
  Future<bool> isDecoyPin(String pin) async {
    if (!_isValidCredentialInput(pin)) return false;

    // Never allow decoy probing during an active brute-force cooldown.
    final lockout = await getLockoutUntil();
    if (lockout != null) return false;

    final storedHash = await _storage.read(key: _keyDecoyPinHash);
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }
    final salt = await _getOrCreateSalt();
    final isMatch = await _verifyAndUpgradeIfNeeded(
      storageKey: _keyDecoyPinHash,
      salt: salt,
      candidate: pin,
      storedHash: storedHash,
    );
    if (isMatch) {
      _isMasterSessionUnlocked = false;
      await _resetFailedAttempts();
      AppMonitor.instance.recordSecurityEvent('vault_decoy_pin_activated');
    }
    return isMatch;
  }

  @override
  Future<bool> verifyPattern(List<int> pattern) async {
    if (pattern.isEmpty || pattern.length > 16) return false;

    final lockout = await getLockoutUntil();
    if (lockout != null) return false;

    final storedHash = await _storage.read(key: _keyPatternHash);
    if (storedHash == null || storedHash.isEmpty) {
      return false; // NO hardcoded default pattern!
    }
    final salt = await _getOrCreateSalt();
    final serialized = pattern.join('-');
    final isMatch = await _verifyAndUpgradeIfNeeded(
      storageKey: _keyPatternHash,
      salt: salt,
      candidate: serialized,
      storedHash: storedHash,
    );
    if (isMatch) {
      _isMasterSessionUnlocked = true;
      await _resetFailedAttempts();
      AppMonitor.instance.recordSecurityEvent('vault_pattern_unlocked');
    } else {
      await _recordFailedAttempt();
    }
    return isMatch;
  }

  @override
  Future<bool> isDecoyPattern(List<int> pattern) async {
    if (pattern.isEmpty || pattern.length > 16) return false;

    // Never allow decoy probing during an active brute-force cooldown.
    final lockout = await getLockoutUntil();
    if (lockout != null) return false;

    final storedHash = await _storage.read(key: _keyDecoyPatternHash);
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }
    final salt = await _getOrCreateSalt();
    final serialized = pattern.join('-');
    final isMatch = await _verifyAndUpgradeIfNeeded(
      storageKey: _keyDecoyPatternHash,
      salt: salt,
      candidate: serialized,
      storedHash: storedHash,
    );
    if (isMatch) {
      _isMasterSessionUnlocked = false;
      await _resetFailedAttempts();
      AppMonitor.instance.recordSecurityEvent('vault_decoy_pattern_activated');
    }
    return isMatch;
  }

  @override
  Future<void> setPin({required String pin, String? decoyPin}) async {
    _cachedConfig = null;
    _isMasterSessionUnlocked = false;
    final salt = await _getOrCreateSalt();
    await _storage.write(key: _keyPinHash, value: _deriveHash(salt, pin));
    await _storage.write(key: _keySecurityEnabled, value: 'true');
    await _storage.write(key: _keyLockMode, value: 'pin');
    if (decoyPin != null && decoyPin.isNotEmpty) {
      await _storage.write(
        key: _keyDecoyPinHash,
        value: _deriveHash(salt, decoyPin),
      );
    }
  }

  @override
  Future<void> setDecoyPin(String decoyPin) async {
    _cachedConfig = null;
    final salt = await _getOrCreateSalt();
    await _storage.write(
      key: _keyDecoyPinHash,
      value: _deriveHash(salt, decoyPin),
    );
  }

  @override
  Future<void> setPattern({
    required List<int> pattern,
    List<int>? decoyPattern,
  }) async {
    _cachedConfig = null;
    _isMasterSessionUnlocked = false;
    final salt = await _getOrCreateSalt();
    await _storage.write(
      key: _keyPatternHash,
      value: _deriveHash(salt, pattern.join('-')),
    );
    await _storage.write(key: _keySecurityEnabled, value: 'true');
    await _storage.write(key: _keyLockMode, value: 'pattern');
    if (decoyPattern != null && decoyPattern.isNotEmpty) {
      await _storage.write(
        key: _keyDecoyPatternHash,
        value: _deriveHash(salt, decoyPattern.join('-')),
      );
    }
  }

  @override
  Future<void> setDecoyPattern(List<int> decoyPattern) async {
    _cachedConfig = null;
    final salt = await _getOrCreateSalt();
    await _storage.write(
      key: _keyDecoyPatternHash,
      value: _deriveHash(salt, decoyPattern.join('-')),
    );
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    _cachedConfig = null;
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  @override
  Future<void> setSecurityEnabled(bool enabled) async {
    _cachedConfig = null;
    if (enabled) {
      _isMasterSessionUnlocked = false;
    }
    await _storage.write(key: _keySecurityEnabled, value: enabled.toString());
  }

  @override
  Future<void> setLockMode(SecurityLockMode mode) async {
    _cachedConfig = null;
    await _storage.write(
      key: _keyLockMode,
      value: mode == SecurityLockMode.pattern ? 'pattern' : 'pin',
    );
  }

  @override
  Future<void> clearAllSecurity() async {
    _cachedConfig = null;
    _isMasterSessionUnlocked = false;
    await Future.wait([
      _storage.delete(key: _keyPinHash),
      _storage.delete(key: _keyDecoyPinHash),
      _storage.delete(key: _keyPatternHash),
      _storage.delete(key: _keyDecoyPatternHash),
      _storage.delete(key: _keySecurityEnabled),
      _storage.delete(key: _keyBiometricEnabled),
      _storage.delete(key: _keyFailedAttempts),
      _storage.delete(key: _keyLockoutUntil),
    ]);
  }
}
