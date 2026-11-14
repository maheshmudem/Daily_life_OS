import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';

import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/command_palette_entry_entity.dart';

class CommandPaletteResultTile extends StatelessWidget {
  final CommandPaletteEntryEntity entry;
  final VoidCallback onTap;

  const CommandPaletteResultTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  IconData _resolveIcon(CommandPaletteIconType type) {
    return switch (type) {
      CommandPaletteIconType.bolt => Icons.bolt_rounded,
      CommandPaletteIconType.mic => Icons.mic_rounded,
      CommandPaletteIconType.scanner => Icons.document_scanner_rounded,
      CommandPaletteIconType.timer => Icons.timer_rounded,
      CommandPaletteIconType.wallet => Icons.account_balance_wallet_rounded,
      CommandPaletteIconType.lightbulb => Icons.lightbulb_rounded,
      CommandPaletteIconType.security => Icons.security_rounded,
      CommandPaletteIconType.repeat => Icons.repeat_rounded,
      CommandPaletteIconType.schedule => Icons.schedule_rounded,
      CommandPaletteIconType.eventAvailable => Icons.event_available_rounded,
      CommandPaletteIconType.northEast => Icons.north_east_rounded,
      CommandPaletteIconType.southWest => Icons.south_west_rounded,
      CommandPaletteIconType.autorenew => Icons.autorenew_rounded,
      CommandPaletteIconType.handshake => Icons.handshake_outlined,
      CommandPaletteIconType.pushPin => Icons.push_pin_rounded,
      CommandPaletteIconType.stickyNote => Icons.sticky_note_2_outlined,
      CommandPaletteIconType.key => Icons.key_rounded,
      CommandPaletteIconType.verifiedUser => Icons.verified_user_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = Color(entry.accentColorValue);
    final iconData = _resolveIcon(entry.iconType);

    return InkWell(
      borderRadius: AppRadius.borderMd,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xxxl,
              height: AppSpacing.xxxl,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.borderMd,
              ),
              child: Icon(iconData, color: accent, size: AppSpacing.lg),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.heading,
                    ),
                  ),
                  AppSpacing.gapH4,
                  AppText(
                    entry.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: palette.caption,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapW8,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxxs,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.radiusFull,
              ),
              child: AppText(
                entry.badgeText,
                style: context.text.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AppSpacing.gapW4,
            Icon(
              Icons.chevron_right_rounded,
              size: AppSpacing.lg,
              color: palette.caption,
            ),
          ],
        ),
      ),
    );
  }
}
