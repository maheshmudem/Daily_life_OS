import 'package:flutter/material.dart';

/// Centralized Design System Colors for Daily Life OS.
/// Incorporates module-specific color codes according to the PRD:
/// - Core / Today Hub: Electric Indigo
/// - Planner & Focus: Sunrise Amber & Tangerine
/// - Money Manager: Emerald & Mint
/// - Notes & Mind: Sky & Cyan (Voice Pulse: Pink)
/// - Secure Vault: Royal Violet & Purple
class AppColors {
  AppColors._();

  // ==========================================
  // MODULE 1: TODAY HUB (Core Command Center)
  // ==========================================
  static const Color primary = Color(0xFF6366F1); // Electric Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryContainer = Color(0xFFEEF2FF);
  static const Color darkPrimaryContainer = Color(0xFF1E1B4B);

  // ==========================================
  // MODULE 2: PLANNER & FOCUS (Time Management)
  // ==========================================
  static const Color moduleTime = Color(0xFFF59E0B); // Amber
  static const Color moduleTimeLight = Color(0xFFFBBF24);
  static const Color moduleTimeDark = Color(0xFFD97706);
  static const Color focusPomodoro = Color(0xFFF97316); // Tangerine Focus
  static const Color focusBreak = Color(0xFF10B981); // Emerald Rest

  // ==========================================
  // MODULE 3: MONEY MANAGER (Wealth & Expenses)
  // ==========================================
  static const Color moduleMoney = Color(0xFF10B981); // Emerald
  static const Color moduleMoneyLight = Color(0xFF34D399);
  static const Color moduleMoneyDark = Color(0xFF059669);
  static const Color moneyWarning80 = Color(0xFFF59E0B); // 80% Budget alert
  static const Color moneyLimit100 = Color(0xFFEF4444); // 100% Limit reached
  static const Color safeSpendPositive = Color(0xFF10B981);
  static const Color safeSpendNegative = Color(0xFFEF4444);

  // ==========================================
  // MODULE 4: NOTES & IDEAS (Mind & Thoughts)
  // ==========================================
  static const Color moduleNotes = Color(0xFF0EA5E9); // Electric Sky / Cyan
  static const Color moduleNotesLight = Color(0xFF38BDF8);
  static const Color moduleNotesDark = Color(0xFF0284C7);
  static const Color voiceWaveform = Color(0xFFEC4899); // Pulse Magenta

  // ==========================================
  // MODULE 5: SECURE VAULT (Security & Privacy)
  // ==========================================
  static const Color moduleVault = Color(0xFF8B5CF6); // Royal Violet
  static const Color moduleVaultLight = Color(0xFFA78BFA);
  static const Color moduleVaultDark = Color(0xFF6D28D9);
  static const Color panicDecoy = Color(0xFFDC2626); // Decoy / Panic Mode

  // ==========================================
  // SECONDARY & ACCENT
  // ==========================================
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryDark = Color(0xFF0284C7);

  static const Color accent = Color(0xFF10B981);
  static const Color accentLight = Color(0xFF34D399);
  static const Color accentDark = Color(0xFF059669);

  // ==========================================
  // SURFACES & BACKGROUNDS (LIGHT THEME)
  // ==========================================
  static const Color scaffoldBackground = Color(0xFFF8FAFC); // Slate-50
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // Slate-100
  static const Color surfaceMuted = Color(0xFFE2E8F0); // Slate-200

  // ==========================================
  // SURFACES & BACKGROUNDS (DARK THEME)
  // ==========================================
  static const Color darkScaffoldBackground = Color(0xFF0B0F19); // Ultra-deep Slate
  static const Color darkCardBackground = Color(0xFF151D2C); // Elevation 1
  static const Color darkSurfaceColor = Color(0xFF151D2C);
  static const Color darkSurfaceSecondary = Color(0xFF1E293B); // Elevation 2
  static const Color darkSurfaceMuted = Color(0xFF334155); // Slate-700

  // ==========================================
  // TYPOGRAPHY & TEXT COLORS
  // ==========================================
  static const Color textHeading = Color(0xFF0F172A); // Slate-900
  static const Color textBody = Color(0xFF334155); // Slate-700
  static const Color textCaption = Color(0xFF64748B); // Slate-500
  static const Color textWhite = Colors.white;

  static const Color darkTextHeading = Color(0xFFF8FAFC); // Slate-50
  static const Color darkTextBody = Color(0xFFE2E8F0); // Slate-200
  static const Color darkTextCaption = Color(0xFF94A3B8); // Slate-400

  // ==========================================
  // STATUS & SEMANTIC FEEDBACK
  // ==========================================
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // ==========================================
  // DIVIDERS, BORDERS & SHADOWS
  // ==========================================
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);
  static const Color darkDivider = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color iconColor = Color(0xFF475569);
  static const Color darkIconColor = Color(0xFF94A3B8);
  static const Color shadowColor = Color(0x140F172A);

  // Quick Action & Floating Bar
  static const Color floatingBarBackground = Color(0xEE0F172A);
  static const Color floatingBarGlassBorder = Color(0x33FFFFFF);

  // Routines Time of Day
  static const Color routineMorning = Color(0xFFF59E0B);
  static const Color routineAfternoon = Color(0xFF0EA5E9);
  static const Color routineEvening = Color(0xFF8B5CF6);
  static const Color routineNight = Color(0xFF4338CA);
}
