import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/command_palette_entry_entity.dart';

class CommandPaletteFilterBar extends StatelessWidget {
  final String selectedModule;
  final Map<String, int> moduleCounts;
  final ValueChanged<String> onSelectModule;

  const CommandPaletteFilterBar({
    super.key,
    required this.selectedModule,
    required this.moduleCounts,
    required this.onSelectModule,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const modules = CommandPaletteModules.ordered;

    return SizedBox(
      height: AppSpacing.xxl + AppSpacing.xxs,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modules.length,
        separatorBuilder: (_, _) => AppSpacing.gapW8,
        itemBuilder: (context, index) {
          final mod = modules[index];
          final isSelected = mod == selectedModule;
          final count = moduleCounts[mod] ?? 0;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelectModule(mod);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: AppSpacing.edgeInsetsHSm,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : palette.card,
                borderRadius: AppRadius.radiusFull,
                border: Border.all(
                  color: isSelected ? AppColors.primary : palette.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    mod,
                    style: context.text.labelMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected ? AppColors.textWhite : palette.body,
                    ),
                  ),
                  AppSpacing.gapW4,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs + AppSpacing.xxxs,
                      vertical: AppSpacing.xxxs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.textWhite.withValues(alpha: 0.22)
                          : palette.surfaceMuted,
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: AppText(
                      '$count',
                      style: context.text.labelSmall?.copyWith(
                        color: isSelected
                            ? AppColors.textWhite
                            : palette.caption,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
