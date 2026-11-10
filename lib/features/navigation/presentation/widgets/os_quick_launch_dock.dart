import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/staggered_fade_slide.dart';
import '../../../quick_capture/domain/entities/quick_capture_entities.dart';

/// Cross-Module Quick-Launch OS Dock (Spotlight, Focus, Capture, Scratchpad).
///
/// Four equal tiles sitting directly on the page background (no outer card),
/// the "quick actions" row pattern used by most banking / productivity apps.
class OsQuickLaunchDock extends StatelessWidget {
  final VoidCallback onOpenSpotlight;
  final ValueChanged<int> onNavigateTab;
  final ValueChanged<QuickCaptureMode> onQuickCapture;

  const OsQuickLaunchDock({
    super.key,
    required this.onOpenSpotlight,
    required this.onNavigateTab,
    required this.onQuickCapture,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OsDockPill(
            key: const ValueKey('dock_spotlight_pill'),
            icon: Icons.search_rounded,
            label: StringConstants.dockSpotlightTitle,
            color: AppColors.primary,
            onTap: onOpenSpotlight,
          ),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: _OsDockPill(
            key: const ValueKey('dock_focus_pill'),
            icon: Icons.timer_rounded,
            label: StringConstants.dockFocusTitle,
            color: AppColors.moduleTime,
            onTap: () {
              HapticFeedback.selectionClick();
              onNavigateTab(1);
            },
          ),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: _OsDockPill(
            key: const ValueKey('dock_capture_pill'),
            icon: Icons.bolt_rounded,
            label: StringConstants.dockCaptureTitle,
            color: AppColors.moduleMoney,
            onTap: () => onQuickCapture(QuickCaptureMode.text),
          ),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: _OsDockPill(
            key: const ValueKey('dock_notes_pill'),
            icon: Icons.lightbulb_outline_rounded,
            label: StringConstants.dockNotesTitle,
            color: AppColors.moduleNotes,
            onTap: () {
              HapticFeedback.selectionClick();
              onNavigateTab(3);
            },
          ),
        ),
      ],
    );
  }
}

class _OsDockPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OsDockPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(16);

    return PressableScale(
      onTap: onTap,
      child: Material(
        color: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: palette.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: palette.isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: context.text.labelMedium?.copyWith(
                      fontSize: 11.5,
                      letterSpacing: -0.2,
                      fontWeight: FontWeight.w600,
                      color: palette.heading,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
