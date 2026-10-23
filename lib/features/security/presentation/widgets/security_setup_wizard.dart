import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/security_config_entity.dart';
import '../../domain/repositories/security_repository.dart';
import 'pattern_lock_grid_widget.dart';
import 'pin_dialpad_widget.dart';

class SecuritySetupWizard extends StatefulWidget {
  final SecurityRepository securityRepository;
  final VoidCallback onCompleted;

  const SecuritySetupWizard({
    super.key,
    required this.securityRepository,
    required this.onCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required SecurityRepository securityRepository,
    required VoidCallback onCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SecuritySetupWizard(
        securityRepository: securityRepository,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<SecuritySetupWizard> createState() => _SecuritySetupWizardState();
}

enum _SetupStep {
  chooseMethod,
  enterCredential,
  confirmCredential,
  biometricsPrompt,
  decoyPrompt,
}

class _SecuritySetupWizardState extends State<SecuritySetupWizard> {
  _SetupStep _step = _SetupStep.chooseMethod;
  SecurityLockMode _selectedMode = SecurityLockMode.pin;

  String _enteredPin = '';
  String _confirmedPin = '';
  List<int>? _enteredPattern;
  List<int>? _confirmedPattern;

  String? _decoyPin;
  List<int>? _decoyPattern;

  bool _enableBiometrics = false;
  bool _biometricsAvailable = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final avail = await widget.securityRepository.isBiometricsAvailable();
    if (mounted) {
      setState(() => _biometricsAvailable = avail);
    }
  }

  Future<void> _finalizeSetup() async {
    if (_selectedMode == SecurityLockMode.pin) {
      await widget.securityRepository.setPin(
        pin: _enteredPin,
        decoyPin: _decoyPin,
      );
    } else {
      await widget.securityRepository.setPattern(
        pattern: _enteredPattern!,
        decoyPattern: _decoyPattern,
      );
    }

    if (_biometricsAvailable) {
      await widget.securityRepository.setBiometricsEnabled(_enableBiometrics);
    }
    await widget.securityRepository.setSecurityEnabled(true);

    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.topXxl,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
              const SizedBox(height: 16),

              _buildCurrentStepContent(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_step) {
      case _SetupStep.chooseMethod:
        return _buildChooseMethodStep(isDark);
      case _SetupStep.enterCredential:
        return _buildEnterCredentialStep(isDark);
      case _SetupStep.confirmCredential:
        return _buildConfirmCredentialStep(isDark);
      case _SetupStep.biometricsPrompt:
        return _buildBiometricsStep(isDark);
      case _SetupStep.decoyPrompt:
        return _buildDecoyPromptStep(isDark);
    }
  }

  // ── Step 1: Choose Lock Method ─────────────────────────────────────────────
  Widget _buildChooseMethodStep(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.moduleVault.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_rounded, size: 36, color: AppColors.moduleVault),
        ),
        const SizedBox(height: 14),
        Text(
          'Set Up Vault Security',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your preferred primary lock method:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          ),
        ),
        const SizedBox(height: 24),

        // Method 1: PIN
        _buildMethodCard(
          title: '4-Digit PIN Code',
          subtitle: 'Fast, secure numeric passcode with dialpad',
          icon: Icons.pin_rounded,
          isSelected: _selectedMode == SecurityLockMode.pin,
          isDark: isDark,
          onTap: () => setState(() => _selectedMode = SecurityLockMode.pin),
        ),
        const SizedBox(height: 12),

        // Method 2: Pattern Lock
        _buildMethodCard(
          title: '3x3 Pattern Lock',
          subtitle: 'Draw a connecting touch gesture on a 3x3 dot grid',
          icon: Icons.pattern_rounded,
          isSelected: _selectedMode == SecurityLockMode.pattern,
          isDark: isDark,
          onTap: () => setState(() => _selectedMode = SecurityLockMode.pattern),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              setState(() {
                _step = _SetupStep.enterCredential;
                _errorMessage = null;
                _enteredPin = '';
                _enteredPattern = null;
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.moduleVault,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
            ),
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusLg,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isSelected
                ? AppColors.moduleVault
                : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.moduleVault.withValues(alpha: isDark ? 0.15 : 0.08)
              : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.moduleVault : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.moduleVault,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.moduleVault : (isDark ? AppColors.darkDivider : AppColors.divider),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Enter Credential ───────────────────────────────────────────────
  Widget _buildEnterCredentialStep(bool isDark) {
    final isPin = _selectedMode == SecurityLockMode.pin;

    return Column(
      children: [
        Text(
          isPin ? 'Create Master PIN' : 'Draw Master Pattern',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isPin
              ? 'Enter a 4-digit passcode for your vault'
              : 'Connect at least 4 dots on the grid',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          ),
        ),
        const SizedBox(height: 20),

        if (isPin)
          PinDialpadWidget(
            pinLength: 4,
            currentPin: _enteredPin,
            showBiometrics: false,
            errorMessage: _errorMessage,
            onBiometricTap: () {},
            onPinChanged: (val) {
              setState(() {
                _enteredPin = val;
                _errorMessage = null;
              });
              if (val.length == 4) {
                Future.delayed(const Duration(milliseconds: 250), () {
                  if (mounted) {
                    setState(() {
                      _step = _SetupStep.confirmCredential;
                      _confirmedPin = '';
                      _errorMessage = null;
                    });
                  }
                });
              }
            },
          )
        else
          Column(
            children: [
              PatternLockGridWidget(
                size: 240,
                errorMessage: _errorMessage,
                onPatternComplete: (pattern) {
                  if (pattern.length < 4) {
                    setState(() => _errorMessage = 'Connect at least 4 dots.');
                    return;
                  }
                  setState(() {
                    _enteredPattern = pattern;
                    _step = _SetupStep.confirmCredential;
                    _confirmedPattern = null;
                    _errorMessage = null;
                  });
                },
              ),
            ],
          ),
      ],
    );
  }

  // ── Step 3: Confirm Credential ─────────────────────────────────────────────
  Widget _buildConfirmCredentialStep(bool isDark) {
    final isPin = _selectedMode == SecurityLockMode.pin;

    return Column(
      children: [
        Text(
          isPin ? 'Confirm Master PIN' : 'Redraw Master Pattern',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isPin ? 'Re-enter your 4-digit passcode to confirm' : 'Draw the same pattern again to verify',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          ),
        ),
        const SizedBox(height: 20),

        if (isPin)
          PinDialpadWidget(
            pinLength: 4,
            currentPin: _confirmedPin,
            showBiometrics: false,
            hasError: _errorMessage != null,
            errorMessage: _errorMessage,
            onBiometricTap: () {},
            onPinChanged: (val) {
              setState(() {
                _confirmedPin = val;
                _errorMessage = null;
              });
              if (val.length == 4) {
                if (val == _enteredPin) {
                  _proceedAfterConfirm();
                } else {
                  HapticFeedback.heavyImpact();
                  setState(() {
                    _errorMessage = 'PINs do not match. Try again.';
                    _confirmedPin = '';
                  });
                }
              }
            },
          )
        else
          PatternLockGridWidget(
            size: 240,
            hasError: _errorMessage != null,
            errorMessage: _errorMessage,
            onPatternComplete: (pattern) {
              if (_listEquals(pattern, _enteredPattern)) {
                _confirmedPattern = pattern;
                _proceedAfterConfirm();
              } else {
                HapticFeedback.heavyImpact();
                setState(() => _errorMessage = 'Pattern does not match. Try again.');
              }
            },
          ),
      ],
    );
  }

  bool _listEquals(List<int>? a, List<int>? b) {
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _proceedAfterConfirm() {
    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = null;
      if (_biometricsAvailable) {
        _step = _SetupStep.biometricsPrompt;
      } else {
        _step = _SetupStep.decoyPrompt;
      }
    });
  }

  // ── Step 4: Biometrics Prompt ──────────────────────────────────────────────
  Widget _buildBiometricsStep(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.moduleVault.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.fingerprint_rounded, size: 48, color: AppColors.moduleVault),
        ),
        const SizedBox(height: 16),
        Text(
          'Enable Biometric Unlock?',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use your device fingerprint scanner or Face ID for instant, seamless unlocking.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          ),
        ),
        const SizedBox(height: 28),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _enableBiometrics = false;
                    _step = _SetupStep.decoyPrompt;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                ),
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _enableBiometrics = true;
                    _step = _SetupStep.decoyPrompt;
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moduleVault,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Enable', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 5: Decoy / Duress Mode Prompt ──────────────────────────────────────
  Widget _buildDecoyPromptStep(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, size: 44, color: AppColors.error),
        ),
        const SizedBox(height: 16),
        Text(
          'Optional: Decoy PIN Protection',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Under duress or threat, entering your Decoy PIN displays an innocent empty vault without revealing your real passwords.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _finalizeSetup,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                ),
                child: const Text('Finish Setup'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  _showSetDecoyDialog();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moduleVault,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                ),
                child: const Text('Set Decoy PIN', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSetDecoyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text('Set 4-Digit Decoy PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a different PIN than your master PIN. Entering this opens safe decoy data.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. 9876',
                counterText: '',
                border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final pin = controller.text.trim();
              if (pin.length == 4 && pin != _enteredPin) {
                _decoyPin = pin;
                Navigator.pop(dlgContext);
                _finalizeSetup();
              }
            },
            child: const Text('Save & Finish'),
          ),
        ],
      ),
    );
  }
}
