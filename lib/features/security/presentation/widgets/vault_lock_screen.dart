import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/security_config_entity.dart';
import '../../domain/repositories/security_repository.dart';
import 'pattern_lock_grid_widget.dart';
import 'pin_dialpad_widget.dart';

class VaultLockScreen extends StatefulWidget {
  final SecurityRepository securityRepository;
  final Function({required bool isDecoy}) onUnlock;

  const VaultLockScreen({
    super.key,
    required this.securityRepository,
    required this.onUnlock,
  });

  @override
  State<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends State<VaultLockScreen> {
  SecurityLockMode _currentMode = SecurityLockMode.pin;
  SecurityConfigEntity? _config;
  String _enteredPin = '';
  bool _hasError = false;
  String? _errorMessage;
  bool _isChecking = false;
  bool _biometricsAvailable = false;

  Timer? _cooldownTimer;
  int _lockoutSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initSecurity();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSecurity() async {
    final cfg = await widget.securityRepository.getConfig();
    final bioAvail = await widget.securityRepository.isBiometricsAvailable();
    final lockout = await widget.securityRepository.getLockoutUntil();

    if (mounted) {
      setState(() {
        _config = cfg;
        _currentMode = cfg.activeMode;
        _biometricsAvailable = bioAvail && cfg.isBiometricEnabled;
      });

      if (lockout != null) {
        _startLockoutTimer(lockout);
      } else if (_biometricsAvailable) {
        _handleBiometricUnlock();
      }
    }
  }

  void _startLockoutTimer(DateTime lockoutUntil) {
    _cooldownTimer?.cancel();
    final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) return;

    setState(() {
      _lockoutSeconds = remaining;
      _hasError = true;
      _errorMessage =
          'Too many failed attempts. Locked for ${_lockoutSeconds}s';
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutSeconds <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSeconds = 0;
          _hasError = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _lockoutSeconds--;
          _errorMessage =
              'Too many failed attempts. Locked for ${_lockoutSeconds}s';
        });
      }
    });
  }

  Future<void> _handleBiometricUnlock() async {
    if (_lockoutSeconds > 0) return;
    try {
      final authenticated = await widget.securityRepository
          .authenticateBiometrics(
            reason: 'Scan your fingerprint to unlock Secure Vault',
          );
      if (authenticated && mounted) {
        HapticFeedback.lightImpact();
        widget.onUnlock(isDecoy: false);
      }
    } catch (_) {}
  }

  Future<void> _handlePinChanged(String pin) async {
    if (_lockoutSeconds > 0) return;

    setState(() {
      _enteredPin = pin;
      _hasError = false;
      _errorMessage = null;
    });

    if (pin.length == 4 && !_isChecking) {
      _isChecking = true;
      final isDecoy = await widget.securityRepository.isDecoyPin(pin);
      if (isDecoy) {
        HapticFeedback.mediumImpact();
        widget.onUnlock(isDecoy: true);
        _isChecking = false;
        return;
      }

      final isReal = await widget.securityRepository.verifyPin(pin);
      if (isReal) {
        HapticFeedback.lightImpact();
        widget.onUnlock(isDecoy: false);
      } else {
        HapticFeedback.heavyImpact();
        final lockout = await widget.securityRepository.getLockoutUntil();
        if (lockout != null) {
          _startLockoutTimer(lockout);
        } else {
          final attempts = await widget.securityRepository.getFailedAttempts();
          final remaining = 5 - attempts;
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = remaining <= 2
                  ? 'Incorrect PIN. $remaining attempt${remaining == 1 ? '' : 's'} remaining!'
                  : 'Incorrect PIN. Try again.';
              _enteredPin = '';
            });
          }
        }
      }
      _isChecking = false;
    }
  }

  Future<void> _handlePatternComplete(List<int> pattern) async {
    if (_lockoutSeconds > 0 || _isChecking) return;
    _isChecking = true;

    final isDecoy = await widget.securityRepository.isDecoyPattern(pattern);
    if (isDecoy) {
      HapticFeedback.mediumImpact();
      widget.onUnlock(isDecoy: true);
      _isChecking = false;
      return;
    }

    final isReal = await widget.securityRepository.verifyPattern(pattern);
    if (isReal) {
      HapticFeedback.lightImpact();
      widget.onUnlock(isDecoy: false);
    } else {
      HapticFeedback.heavyImpact();
      final lockout = await widget.securityRepository.getLockoutUntil();
      if (lockout != null) {
        _startLockoutTimer(lockout);
      } else {
        final attempts = await widget.securityRepository.getFailedAttempts();
        final remaining = 5 - attempts;
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = remaining <= 2
                ? 'Incorrect pattern. $remaining attempt${remaining == 1 ? '' : 's'} remaining!'
                : 'Pattern does not match. Try again.';
          });
        }
      }
    }
    _isChecking = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showTabs =
        (_config?.hasPin ?? false) && (_config?.hasPattern ?? false);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield Icon Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lockoutSeconds > 0
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.moduleVault.withValues(alpha: 0.14),
                border: Border.all(
                  color: _lockoutSeconds > 0
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.moduleVault.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _lockoutSeconds > 0
                    ? Icons.gpp_bad_rounded
                    : Icons.lock_outline_rounded,
                size: 44,
                color: _lockoutSeconds > 0
                    ? AppColors.error
                    : AppColors.moduleVault,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _lockoutSeconds > 0
                  ? 'Security Cooldown Active'
                  : 'Secure Vault Locked',
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: _lockoutSeconds > 0
                    ? AppColors.error
                    : (isDark
                          ? AppColors.darkTextHeading
                          : AppColors.textHeading),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _lockoutSeconds > 0
                  ? 'Rate-limit triggered. Inputs paused for safety.'
                  : 'Hardware AES-256 encrypted storage',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextCaption
                    : AppColors.textCaption,
              ),
            ),
            const SizedBox(height: 20),

            // Mode Selector (if both methods available)
            if (showTabs && _lockoutSeconds == 0) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.surfaceSecondary,
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabPill(
                      title: 'PIN Code',
                      icon: Icons.pin_rounded,
                      isSelected: _currentMode == SecurityLockMode.pin,
                      isDark: isDark,
                      onTap: () => setState(() {
                        _currentMode = SecurityLockMode.pin;
                        _hasError = false;
                        _errorMessage = null;
                        _enteredPin = '';
                      }),
                    ),
                    _buildTabPill(
                      title: 'Pattern Lock',
                      icon: Icons.pattern_rounded,
                      isSelected: _currentMode == SecurityLockMode.pattern,
                      isDark: isDark,
                      onTap: () => setState(() {
                        _currentMode = SecurityLockMode.pattern;
                        _hasError = false;
                        _errorMessage = null;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Active Lock UI
            if (_lockoutSeconds > 0)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusLg,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_lockoutSeconds',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Seconds remaining until unlock is re-enabled',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ],
                ),
              )
            else if (_currentMode == SecurityLockMode.pin)
              PinDialpadWidget(
                pinLength: 4,
                currentPin: _enteredPin,
                hasError: _hasError,
                errorMessage: _errorMessage,
                showBiometrics: _biometricsAvailable,
                onPinChanged: _handlePinChanged,
                onBiometricTap: _handleBiometricUnlock,
              )
            else
              Column(
                children: [
                  PatternLockGridWidget(
                    size: 240,
                    hasError: _hasError,
                    errorMessage: _errorMessage,
                    onPatternStart: () {
                      if (_hasError) {
                        setState(() {
                          _hasError = false;
                          _errorMessage = null;
                        });
                      }
                    },
                    onPatternComplete: _handlePatternComplete,
                  ),
                  if (_biometricsAvailable) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _handleBiometricUnlock,
                      icon: const Icon(
                        Icons.fingerprint_rounded,
                        color: AppColors.moduleVault,
                      ),
                      label: const Text(
                        'Unlock with Biometrics',
                        style: TextStyle(color: AppColors.moduleVault),
                      ),
                    ),
                  ],
                ],
              ),

            const SizedBox(height: 24),
            // Privacy Security Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_clock_rounded,
                  size: 13,
                  color: isDark
                      ? AppColors.darkTextCaption
                      : AppColors.textCaption,
                ),
                const SizedBox(width: 6),
                Text(
                  'Auto-locks when app is backgrounded',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.moduleVault : Colors.transparent,
          borderRadius: AppRadius.radiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
