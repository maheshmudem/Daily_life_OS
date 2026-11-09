import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/staggered_fade_slide.dart';
import '../../../quick_capture/domain/entities/quick_capture_entities.dart';

/// Cross-Module Quick-Launch OS Dock (Spotlight, Focus, Capture, Scratchpad).
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
    final palette = context.palette;

    return Container(
      padding: AppSpacing.edgeInsetsAllSm,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: palette.border),
      ),
      child: Row(
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
      ),
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

    return PressableScale(
      onTap: onTap,
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: palette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSpacing.xl + AppSpacing.xxs,
                height: AppSpacing.xl + AppSpacing.xxs,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(icon, size: AppSpacing.md, color: color),
              ),
              AppSpacing.gapH4,
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: context.text.labelMedium?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: palette.heading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
