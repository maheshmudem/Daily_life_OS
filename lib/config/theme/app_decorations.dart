import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'theme_context.dart';

/// Predefined modern visual decorations, gradients, shadows, and glassmorphism.
class AppDecorations {
  AppDecorations._();

  // Standard Card with crisp border and subtle ambient shadow
  static BoxDecoration card(BuildContext context) {
    final palette = context.palette;
    return BoxDecoration(
      color: palette.card,
      borderRadius: AppRadius.radiusLg,
      border: Border.all(color: palette.divider, width: 1),
      boxShadow: [
        BoxShadow(
          color: (palette.isDark ? AppColors.black : AppColors.shadowColor)
              .withValues(alpha: palette.isDark ? 0.35 : 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Elevated Card for Heroes and Modals
  static BoxDecoration cardElevated(BuildContext context) {
    final palette = context.palette;
    return BoxDecoration(
      color: palette.isDark ? palette.surfaceMuted : palette.card,
      borderRadius: AppRadius.radiusXl,
      border: Border.all(color: palette.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withValues(
            alpha: palette.isDark ? 0.45 : 0.08,
          ),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Persistent Floating Quick-Capture Bar Decoration (Raycast/Things 3 style)
  static BoxDecoration get floatingBar => BoxDecoration(
    color: AppColors.floatingBarSurface,
    borderRadius: AppRadius.radiusFull,
    border: Border.all(
      color: AppColors.textWhite.withValues(alpha: 0.15),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.35),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Today Hub Primary Hero Gradient
  static BoxDecoration get heroPrimaryGradient => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primaryDeep, AppColors.primary, AppColors.primaryDark],
    ),
    borderRadius: AppRadius.radiusXl,
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.32),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Money Manager Hero Gradient (Safe Spend)
  static BoxDecoration get heroMoneyGradient => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.moduleMoneyDeep,
        AppColors.moduleMoney,
        AppColors.moduleMoneyDarkest,
      ],
    ),
    borderRadius: AppRadius.radiusXl,
    boxShadow: [
      BoxShadow(
        color: AppColors.moduleMoney.withValues(alpha: 0.28),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Pomodoro / Time Hero Gradient
  static BoxDecoration get heroTimeGradient => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.moduleTimeDark,
        AppColors.moduleTime,
        AppColors.moduleTimeDarkest,
      ],
    ),
    borderRadius: AppRadius.radiusXl,
    boxShadow: [
      BoxShadow(
        color: AppColors.moduleTime.withValues(alpha: 0.28),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Vault Hero Gradient
  static BoxDecoration get heroVaultGradient => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.moduleVaultDark,
        AppColors.moduleVault,
        AppColors.moduleVaultDarkest,
      ],
    ),
    borderRadius: AppRadius.radiusXl,
    boxShadow: [
      BoxShadow(
        color: AppColors.moduleVault.withValues(alpha: 0.28),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Standard BoxShadows
  static BoxShadow get defaultShadow => BoxShadow(
    color: AppColors.black.withValues(alpha: 0.05),
    blurRadius: 14,
    offset: const Offset(0, 3),
  );

  static BoxShadow get elevatedShadow => BoxShadow(
    color: AppColors.black.withValues(alpha: 0.12),
    blurRadius: 22,
    offset: const Offset(0, 6),
  );
}
