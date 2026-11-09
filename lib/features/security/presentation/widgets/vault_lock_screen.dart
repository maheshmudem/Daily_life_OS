import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/bloc_effect_listener.dart';
import '../../domain/entities/security_config_entity.dart';
import '../../domain/repositories/security_repository.dart';
import '../bloc/security_bloc.dart';
import 'pattern_lock_grid_widget.dart';
import 'pin_dialpad_widget.dart';

/// PIN / pattern / biometric lock screen.
///
/// All verification, lockout and decoy logic lives in [SecurityBloc]; this
/// widget only renders state and forwards user input.
class VaultLockScreen extends StatefulWidget {
  final SecurityRepository securityRepository;
  final void Function({required bool isDecoy}) onUnlock;

  const VaultLockScreen({
    super.key,
    required this.securityRepository,
    required this.onUnlock,
  });

  @override
  State<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends State<VaultLockScreen> {
  late final SecurityBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = SecurityBloc.fromRepository(widget.securityRepository)
      ..add(const LoadSecurityStatus());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _onEffect(BuildContext context, SecurityEffect effect) {
    switch (effect) {
      case SecurityUnlocked(:final isDecoy):
        isDecoy ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
        widget.onUnlock(isDecoy: isDecoy);
      case SecurityAttemptRejected():
        HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SecurityBloc>.value(
      value: _bloc,
      child: BlocEffectListener<SecurityEffect>(
        effects: _bloc.effects,
        listener: _onEffect,
        child: BlocBuilder<SecurityBloc, SecurityState>(
          builder: (context, state) => _LockView(state: state, bloc: _bloc),
        ),
      ),
    );
  }
}

class _LockView extends StatelessWidget {
  final SecurityState state;
  final SecurityBloc bloc;

  const _LockView({required this.state, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isLockedOut = state.isLockedOut;
    final accent = isLockedOut ? AppColors.error : AppColors.moduleVault;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield Icon Header
            Container(
              padding: AppSpacing.edgeInsetsAllLg,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: isLockedOut ? 0.15 : 0.14),
                border: Border.all(
                  color: accent.withValues(alpha: isLockedOut ? 0.4 : 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                isLockedOut
                    ? Icons.gpp_bad_rounded
                    : Icons.lock_outline_rounded,
                size: AppSpacing.xxxl + AppSpacing.xxs,
                color: accent,
              ),
            ),
            AppSpacing.gapH16,
            Text(
              isLockedOut
                  ? StringConstants.securityCooldownTitle
                  : StringConstants.secureVaultLockedTitle,
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: isLockedOut ? AppColors.error : palette.heading,
              ),
            ),
            AppSpacing.gapH4,
            Text(
              isLockedOut
                  ? StringConstants.securityCooldownSubtitle
                  : StringConstants.secureVaultLockedSubtitle,
              style: context.text.bodySmall?.copyWith(color: palette.caption),
            ),
            AppSpacing.gapH20,

            // Mode Selector (if both methods available)
            if (state.showModeTabs) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TabPill(
                      title: StringConstants.pinCodeTab,
                      icon: Icons.pin_rounded,
                      isSelected: state.currentMode == SecurityLockMode.pin,
                      onTap: () => bloc.add(
                        const SwitchSecurityLockMode(SecurityLockMode.pin),
                      ),
                    ),
                    _TabPill(
                      title: StringConstants.patternLockTab,
                      icon: Icons.pattern_rounded,
                      isSelected: state.currentMode == SecurityLockMode.pattern,
                      onTap: () => bloc.add(
                        const SwitchSecurityLockMode(SecurityLockMode.pattern),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH20,
            ],

            // Active Lock UI
            if (isLockedOut)
              _LockoutCountdown(seconds: state.lockoutSeconds)
            else if (state.currentMode == SecurityLockMode.pin)
              PinDialpadWidget(
                pinLength: SecurityPolicy.pinLength,
                currentPin: state.enteredPin,
                hasError: state.hasError,
                errorMessage: state.errorMessage,
                showBiometrics: state.biometricsAvailable,
                onPinChanged: (pin) => bloc.add(PinInputChanged(pin)),
                onBiometricTap: () =>
                    bloc.add(const BiometricUnlockRequested()),
              )
            else
              Column(
                children: [
                  PatternLockGridWidget(
                    size: 240,
                    hasError: state.hasError,
                    errorMessage: state.errorMessage,
                    onPatternStart: () => bloc.add(const PatternInputStarted()),
                    onPatternComplete: (pattern) =>
                        bloc.add(PatternSubmitted(pattern)),
                  ),
                  if (state.biometricsAvailable) ...[
                    AppSpacing.gapH12,
                    TextButton.icon(
                      onPressed: () =>
                          bloc.add(const BiometricUnlockRequested()),
                      icon: const Icon(
                        Icons.fingerprint_rounded,
                        color: AppColors.moduleVault,
                      ),
                      label: Text(
                        StringConstants.unlockWithBiometrics,
                        style: context.text.labelLarge?.copyWith(
                          color: AppColors.moduleVault,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

            AppSpacing.gapH24,
            // Privacy Security Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_clock_rounded,
                  size: AppSpacing.sm + AppSpacing.xxxs,
                  color: palette.caption,
                ),
                AppSpacing.gapW8,
                Text(
                  StringConstants.autoLockFooter,
                  style: context.text.labelSmall?.copyWith(
                    color: palette.caption,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LockoutCountdown extends StatelessWidget {
  final int seconds;

  const _LockoutCountdown({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      padding: AppSpacing.edgeInsetsAllLg,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$seconds',
            style: AppTextStyles.currencyHero.copyWith(color: AppColors.error),
          ),
          AppSpacing.gapH4,
          Text(
            StringConstants.lockoutSecondsCaption,
            style: context.text.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPill({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = isSelected ? AppColors.textWhite : palette.caption;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.moduleVault : Colors.transparent,
          borderRadius: AppRadius.radiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.md, color: foreground),
            AppSpacing.gapW8,
            Text(
              title,
              style: context.text.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
