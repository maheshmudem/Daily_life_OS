import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';

class PomodoroFocusCard extends StatelessWidget {
  final int focusModeIndex;
  final int currentRound;
  final int totalRounds;
  final double timerProgress;
  final String formattedTime;
  final bool isTimerRunning;
  final String linkedTask;
  final VoidCallback onToggleTimer;
  final VoidCallback onResetTimer;
  final VoidCallback onSkipSession;
  final VoidCallback onChangeTask;

  const PomodoroFocusCard({
    super.key,
    required this.focusModeIndex,
    required this.currentRound,
    required this.totalRounds,
    required this.timerProgress,
    required this.formattedTime,
    required this.isTimerRunning,
    required this.linkedTask,
    required this.onToggleTimer,
    required this.onResetTimer,
    required this.onSkipSession,
    required this.onChangeTask,
  });

  @override
  Widget build(BuildContext context) {
    final LinearGradient heroGradient = focusModeIndex == 0
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFB45309)],
          )
        : (focusModeIndex == 1
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF047857),
                    Color(0xFF10B981),
                    Color(0xFF065F46),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0369A1),
                    Color(0xFF0EA5E9),
                    Color(0xFF0284C7),
                  ],
                ));

    final String modeLabel = focusModeIndex == 0
        ? '⚡ DEEP WORK SPRINT'
        : (focusModeIndex == 1 ? '☕ SHORT BREAK' : '🌴 LONG BREAK');

    final Color shadowColor = focusModeIndex == 0
        ? AppColors.moduleTime
        : (focusModeIndex == 1 ? AppColors.success : AppColors.moduleNotes);

    final Color buttonColor = focusModeIndex == 0
        ? AppColors.moduleTimeDark
        : (focusModeIndex == 1
              ? const Color(0xFF047857)
              : const Color(0xFF0284C7));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: heroGradient,
        borderRadius: AppRadius.radiusXl,
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge & Round indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  modeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Round $currentRound/$totalRounds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    children: List.generate(
                      totalRounds,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < currentRound
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Circular Progress Timer
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: timerProgress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedTime,
                        style: AppTextStyles.timerHero.copyWith(
                          color: Colors.white,
                          fontSize: 42,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTimerRunning
                            ? (focusModeIndex == 0
                                  ? 'Stay in the zone...'
                                  : 'Breathe and relax...')
                            : 'Ready to start',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Linked Task Capsule
          GestureDetector(
            onTap: onChangeTask,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: AppRadius.radiusFull,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.track_changes_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Focusing on: "$linkedTask"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.edit_rounded,
                    size: 13,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Timer Action Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset Button
              IconButton.filledTonal(
                onPressed: onResetTimer,
                tooltip: 'Reset Timer',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  fixedSize: const Size.square(48),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
              AppSpacing.gapW16,

              // Main Start/Pause Button
              ElevatedButton.icon(
                onPressed: onToggleTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusFull,
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  isTimerRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 24,
                ),
                label: Text(
                  isTimerRunning ? 'Pause' : 'Start Focus',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              AppSpacing.gapW16,

              // Skip Session Button
              IconButton.filledTonal(
                onPressed: onSkipSession,
                tooltip: 'Skip Session',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  fixedSize: const Size.square(48),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.skip_next_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
