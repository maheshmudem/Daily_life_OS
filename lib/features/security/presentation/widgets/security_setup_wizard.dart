import 'dart:async';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
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
      backgroundColor: AppColors.transparent,
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
      unawaited(HapticFeedback.mediumImpact());
      Navigator.pop(context);
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.topXxl,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: AppSpacing.xxl + AppSpacing.xxs,
                height: AppSpacing.xxs,
                decoration: BoxDecoration(
                  color: palette.divider,
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
              AppSpacing.gapH16,

              _buildCurrentStepContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_step) {
      case _SetupStep.chooseMethod:
        return _buildChooseMethodStep(context);
      case _SetupStep.enterCredential:
        return _buildEnterCredentialStep(context);
      case _SetupStep.confirmCredential:
        return _buildConfirmCredentialStep(context);
      case _SetupStep.biometricsPrompt:
        return _buildBiometricsStep(context);
      case _SetupStep.decoyPrompt:
        return _buildDecoyPromptStep(context);
    }
  }

  // ── Step 1: Choose Lock Method ─────────────────────────────────────────────
  Widget _buildChooseMethodStep(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Container(
          padding: AppSpacing.edgeInsetsAllMd,
          decoration: BoxDecoration(
            color: AppColors.moduleVault.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_rounded,
            size: AppSpacing.xxl + AppSpacing.xxs,
            color: AppColors.moduleVault,
          ),
        ),
        AppSpacing.gapH12,
        AppText(
          'Set Up Vault Security',
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.heading,
          ),
        ),
        AppSpacing.gapH4,
        AppText(
          'Choose your preferred primary lock method:',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: palette.caption),
        ),
        AppSpacing.gapH24,

        // Method 1: PIN
        _buildMethodCard(
          context,
          title: '4-Digit PIN Code',
          subtitle: 'Fast, secure numeric passcode with dialpad',
          icon: Icons.pin_rounded,
          isSelected: _selectedMode == SecurityLockMode.pin,
          onTap: () => setState(() => _selectedMode = SecurityLockMode.pin),
        ),
        AppSpacing.gapH12,

        // Method 2: Pattern Lock
        _buildMethodCard(
          context,
          title: '3x3 Pattern Lock',
          subtitle: 'Draw a connecting touch gesture on a 3x3 dot grid',
          icon: Icons.pattern_rounded,
          isSelected: _selectedMode == SecurityLockMode.pattern,
          onTap: () => setState(() => _selectedMode = SecurityLockMode.pattern),
        ),
        AppSpacing.gapH24,

        SizedBox(
          width: double.infinity,
          height: AppSpacing.xxxl + AppSpacing.xs,
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
              foregroundColor: AppColors.textWhite,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMd,
              ),
            ),
            child: AppText(
              'Continue',
              style: context.text.titleSmall?.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusLg,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: AppSpacing.edgeInsetsAllMd,
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isSelected ? AppColors.moduleVault : palette.border,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.moduleVault.withValues(
                  alpha: palette.isDark ? 0.15 : 0.08,
                )
              : palette.surfaceMuted,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs + AppSpacing.xxxs),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.moduleVault
                    : AppColors.moduleVault.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.textWhite : AppColors.moduleVault,
                size: AppSpacing.lg + AppSpacing.xxxs,
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.heading,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  AppText(
                    subtitle,
                    style: context.text.labelSmall?.copyWith(
                      color: palette.caption,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.moduleVault : palette.border,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Enter Credential ───────────────────────────────────────────────
  Widget _buildEnterCredentialStep(BuildContext context) {
    final palette = context.palette;
    final isPin = _selectedMode == SecurityLockMode.pin;

    return Column(
      children: [
        AppText(
          isPin ? 'Create Master PIN' : 'Draw Master Pattern',
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.heading,
          ),
        ),
        AppSpacing.gapH4,
        AppText(
          isPin
              ? 'Enter a 4-digit passcode for your vault'
              : 'Connect at least 4 dots on the grid',
          style: context.text.bodySmall?.copyWith(color: palette.caption),
        ),
        AppSpacing.gapH20,

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
  Widget _buildConfirmCredentialStep(BuildContext context) {
    final palette = context.palette;
    final isPin = _selectedMode == SecurityLockMode.pin;

    return Column(
      children: [
        AppText(
          isPin ? 'Confirm Master PIN' : 'Redraw Master Pattern',
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.heading,
          ),
        ),
        AppSpacing.gapH4,
        AppText(
          isPin
              ? 'Re-enter your 4-digit passcode to confirm'
              : 'Draw the same pattern again to verify',
          style: context.text.bodySmall?.copyWith(color: palette.caption),
        ),
        AppSpacing.gapH20,

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
                _proceedAfterConfirm();
              } else {
                HapticFeedback.heavyImpact();
                setState(
                  () => _errorMessage = 'Pattern does not match. Try again.',
                );
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
  Widget _buildBiometricsStep(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Container(
          padding: AppSpacing.edgeInsetsAllLg,
          decoration: BoxDecoration(
            color: AppColors.moduleVault.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.fingerprint_rounded,
            size: AppSpacing.huge,
            color: AppColors.moduleVault,
          ),
        ),
        AppSpacing.gapH16,
        AppText(
          'Enable Biometric Unlock?',
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.heading,
          ),
        ),
        AppSpacing.gapH8,
        AppText(
          'Use your device fingerprint scanner or Face ID for instant, seamless unlocking.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: palette.caption),
        ),
        AppSpacing.gapH24,

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: AppSpacing.xxxl + AppSpacing.xs,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _enableBiometrics = false;
                      _step = _SetupStep.decoyPrompt;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                  child: const AppText('Skip'),
                ),
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: SizedBox(
                height: AppSpacing.xxxl + AppSpacing.xs,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _enableBiometrics = true;
                      _step = _SetupStep.decoyPrompt;
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.moduleVault,
                    foregroundColor: AppColors.textWhite,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                  icon: const Icon(
                    Icons.check_rounded,
                    size: AppSpacing.lg - AppSpacing.xxxs,
                  ),
                  label: AppText(
                    'Enable',
                    style: context.text.titleSmall?.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 5: Decoy / Duress Mode Prompt ──────────────────────────────────────
  Widget _buildDecoyPromptStep(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Container(
          padding: AppSpacing.edgeInsetsAllLg,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: AppSpacing.xxxl + AppSpacing.xxs,
            color: AppColors.error,
          ),
        ),
        AppSpacing.gapH16,
        AppText(
          'Optional: Decoy PIN Protection',
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.heading,
          ),
        ),
        AppSpacing.gapH8,
        AppText(
          'Under duress or threat, entering your Decoy PIN displays an innocent empty vault without revealing your real passwords.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: palette.caption),
        ),
        AppSpacing.gapH24,

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: AppSpacing.xxxl + AppSpacing.xs,
                child: OutlinedButton(
                  onPressed: _finalizeSetup,
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                  child: const AppText('Finish Setup'),
                ),
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: SizedBox(
                height: AppSpacing.xxxl + AppSpacing.xs,
                child: FilledButton(
                  onPressed: _showSetDecoyDialog,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.moduleVault,
                    foregroundColor: AppColors.textWhite,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                  child: AppText(
                    'Set Decoy PIN',
                    style: context.text.titleSmall?.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
        title: const AppText('Set 4-Digit Decoy PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Choose a different PIN than your master PIN. Entering this opens safe decoy data.',
              style: context.text.bodySmall?.copyWith(
                color: context.palette.body,
              ),
            ),
            AppSpacing.gapH12,
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
            child: const AppText('Cancel'),
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
            child: const AppText('Save & Finish'),
          ),
        ],
      ),
    );
  }
}
