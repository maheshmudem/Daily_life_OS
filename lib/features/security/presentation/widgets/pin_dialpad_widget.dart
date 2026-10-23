import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: isFilled ? 18 : 14,
              height: isFilled ? 18 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasError
                    ? AppColors.error
                    : isFilled
                        ? AppColors.moduleVault
                        : (isDark ? AppColors.darkDivider : AppColors.surfaceMuted),
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : isFilled
                          ? AppColors.moduleVault
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: 2,
                ),
                boxShadow: isFilled && !hasError
                    ? [
                        BoxShadow(
                          color: AppColors.moduleVault.withValues(alpha: 0.4),
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
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else
          const SizedBox(height: 20),

        // ── 3x4 Dialpad Grid ──────────────────────────────────────────────
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            children: [
              _buildRow(['1', '2', '3'], isDark),
              const SizedBox(height: 12),
              _buildRow(['4', '5', '6'], isDark),
              const SizedBox(height: 12),
              _buildRow(['7', '8', '9'], isDark),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Biometric or empty
                  if (showBiometrics)
                    _buildIconButton(
                      icon: Icons.fingerprint_rounded,
                      color: AppColors.moduleVault,
                      onTap: onBiometricTap,
                      isDark: isDark,
                      tooltip: 'Fingerprint / Biometric',
                    )
                  else
                    const SizedBox(width: 64, height: 64),

                  _buildNumberButton('0', isDark),

                  _buildIconButton(
                    icon: Icons.backspace_outlined,
                    color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
                    onTap: _onBackspace,
                    isDark: isDark,
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

  Widget _buildRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildNumberButton(d, isDark)).toList(),
    );
  }

  Widget _buildNumberButton(String digit, bool isDark) {
    return InkWell(
      onTap: () => _onDigitTap(digit),
      borderRadius: AppRadius.radiusFull,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? AppColors.darkSurfaceSecondary
              : AppColors.surfaceSecondary,
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1,
          ),
        ),
        child: Text(
          digit,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required String tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusFull,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.5)
              : AppColors.surfaceSecondary.withValues(alpha: 0.5),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
