import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';

class PinDialpadWidget extends StatelessWidget {
  final int pinLength;
  final String currentPin;
  final bool hasError;
  final String? errorMessage;
  final bool showBiometrics;
  final ValueChanged<String> onPinChanged;
  final VoidCallback onBiometricTap;
  final VoidCallback? onSubmit;

  const PinDialpadWidget({
    super.key,
    this.pinLength = 4,
    required this.currentPin,
    this.hasError = false,
    this.errorMessage,
    this.showBiometrics = true,
    required this.onPinChanged,
    required this.onBiometricTap,
    this.onSubmit,
  });

  void _onDigitTap(String digit) {
    if (currentPin.length < pinLength) {
      HapticFeedback.lightImpact();
      final updated = currentPin + digit;
      onPinChanged(updated);
    }
  }

  void _onBackspace() {
    if (currentPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      final updated = currentPin.substring(0, currentPin.length - 1);
      onPinChanged(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── PIN Indicators (Dots) ─────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pinLength, (index) {
            final isFilled = index < currentPin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + AppSpacing.xxxs,
              ),
              width: isFilled ? 16 : 13,
              height: isFilled ? 16 : 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasError
                    ? AppColors.error
                    : isFilled
                    ? AppColors.moduleVault
                    : palette.surfaceMuted,
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : isFilled
                      ? AppColors.moduleVault
                      : palette.border,
                  width: 1.8,
                ),
                boxShadow: isFilled && !hasError
                    ? [
                        BoxShadow(
                          color: AppColors.moduleVault.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),

        if (errorMessage != null && errorMessage!.isNotEmpty) ...[
          AppSpacing.gapH12,
          Text(
            errorMessage!,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else
          AppSpacing.gapH20,

        // ── 3x4 Dialpad Grid ──────────────────────────────────────────────
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 272),
          child: Column(
            children: [
              _buildRow(context, ['1', '2', '3']),
              AppSpacing.gapH12,
              _buildRow(context, ['4', '5', '6']),
              AppSpacing.gapH12,
              _buildRow(context, ['7', '8', '9']),
              AppSpacing.gapH12,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (showBiometrics)
                    _buildIconButton(
                      context,
                      icon: Icons.fingerprint_rounded,
                      color: AppColors.moduleVault,
                      onTap: onBiometricTap,
                      tooltip: 'Fingerprint / Biometric',
                    )
                  else
                    const SizedBox(width: 62, height: 62),

                  _buildNumberButton(context, '0'),

                  _buildIconButton(
                    context,
                    icon: Icons.backspace_outlined,
                    color: palette.caption,
                    onTap: _onBackspace,
                    tooltip: 'Backspace',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildNumberButton(context, d)).toList(),
    );
  }

  Widget _buildNumberButton(BuildContext context, String digit) {
    final palette = context.palette;

    return InkWell(
      onTap: () => _onDigitTap(digit),
      borderRadius: AppRadius.radiusFull,
      child: Container(
        width: 62,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.surfaceMuted,
          border: Border.all(color: palette.border),
        ),
        child: Text(
          digit,
          style: context.text.headlineMedium?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: palette.heading,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    final palette = context.palette;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusFull,
        child: Container(
          width: 62,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.surfaceMuted.withValues(alpha: 0.6),
            border: Border.all(color: palette.border.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: color, size: AppSpacing.xl),
        ),
      ),
    );
  }
}
