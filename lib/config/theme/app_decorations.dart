import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

/// Predefined modern visual decorations, gradients, shadows, and glassmorphism.
class AppDecorations {
  AppDecorations._();

  // Standard Card with crisp border and subtle ambient shadow
  static BoxDecoration card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
      borderRadius: AppRadius.radiusLg,
      border: Border.all(
        color: isDark ? AppColors.darkDivider : AppColors.divider,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: (isDark ? Colors.black : AppColors.shadowColor).withValues(
            alpha: isDark ? 0.35 : 0.05,
          ),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Elevated Card for Heroes and Modals
  static BoxDecoration cardElevated(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.darkSurfaceSecondary : AppColors.cardBackground,
      borderRadius: AppRadius.radiusXl,
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.border,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Persistent Floating Quick-Capture Bar Decoration (Raycast/Things 3 style)
  static BoxDecoration get floatingBar => BoxDecoration(
    color: const Color(0xF20F172A), // Translucent Dark Slate
    borderRadius: AppRadius.radiusFull,
    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
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
      colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF4338CA)],
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
      colors: [Color(0xFF047857), Color(0xFF10B981), Color(0xFF065F46)],
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
      colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFB45309)],
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
      colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6), Color(0xFF5B21B6)],
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
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 14,
    offset: const Offset(0, 3),
  );

  static BoxShadow get elevatedShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 22,
    offset: const Offset(0, 6),
  );
}
