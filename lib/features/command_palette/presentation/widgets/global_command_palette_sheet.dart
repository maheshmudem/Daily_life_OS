import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../di/injection_container.dart';
import '../../../profile/presentation/widgets/profile_settings_sheet.dart';
import '../../../quick_capture/domain/entities/quick_capture_entities.dart';
import '../../domain/entities/command_palette_entry_entity.dart';
import '../bloc/command_palette_bloc.dart';
import 'command_palette_filter_bar.dart';
import 'command_palette_result_tile.dart';

/// Raycast / Linear (`⌘K`) / Things 3 inspired Universal Command Palette &
/// Cross-Module Spotlight Search, powered by [CommandPaletteBloc].
class GlobalCommandPaletteSheet extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;
  final ValueChanged<QuickCaptureMode> onOpenQuickCapture;

  const GlobalCommandPaletteSheet({
    super.key,
    required this.onNavigateTab,
    required this.onOpenQuickCapture,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<int> onNavigateTab,
    required ValueChanged<QuickCaptureMode> onOpenQuickCapture,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.card,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topXl),
      builder: (_) => GlobalCommandPaletteSheet(
        onNavigateTab: onNavigateTab,
        onOpenQuickCapture: onOpenQuickCapture,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommandPaletteBloc>(
      create: (_) => sl<CommandPaletteBloc>()..add(const LoadCommandPalette()),
      child: _CommandPaletteView(
        onNavigateTab: onNavigateTab,
        onOpenQuickCapture: onOpenQuickCapture,
      ),
    );
  }
}

class _CommandPaletteView extends StatefulWidget {
  final ValueChanged<int> onNavigateTab;
  final ValueChanged<QuickCaptureMode> onOpenQuickCapture;

  const _CommandPaletteView({
    required this.onNavigateTab,
    required this.onOpenQuickCapture,
  });

  @override
  State<_CommandPaletteView> createState() => _CommandPaletteViewState();
}

class _CommandPaletteViewState extends State<_CommandPaletteView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  QuickCaptureMode? _resolveCaptureMode(String? modeName) {
    return switch (modeName) {
      'text' => QuickCaptureMode.text,
      'voice' => QuickCaptureMode.voice,
      'scan' => QuickCaptureMode.scan,
      _ => null,
    };
  }

  void _handleSelectEntry(CommandPaletteEntryEntity entry) {
    HapticFeedback.mediumImpact();
    final navContext = Navigator.of(context).context;
    Navigator.of(context).pop();
    if (entry.id == 'cmd_profile') {
      ProfileSettingsSheet.show(navContext);
      return;
    }
    final mode = _resolveCaptureMode(entry.captureModeName);
    if (mode != null) {
      widget.onOpenQuickCapture(mode);
      return;
    }
    final tab = entry.targetTabIndex;
    if (tab != null) widget.onNavigateTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mediaQuery = MediaQuery.of(context);
    final bloc = context.read<CommandPaletteBloc>();

    return BlocBuilder<CommandPaletteBloc, CommandPaletteState>(
      builder: (context, state) {
        final filtered = state.filteredEntries;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.86),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              AppSpacing.md,
              AppSpacing.pageGutter,
              mediaQuery.viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: AppSpacing.xxxl,
                    height: AppSpacing.xxs,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
                AppSpacing.gapH12,

                _PaletteHeader(totalIndexed: state.allEntries.length),
                AppSpacing.gapH12,

                // 44px Spotlight Search Input
                Container(
                  height: AppSpacing.xxxl + AppSpacing.xxs,
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: palette.border),
                  ),
                  child: TextField(
                    key: const ValueKey('command_palette_search_input'),
                    controller: _searchController,
                    onChanged: (val) =>
                        bloc.add(UpdateCommandPaletteQuery(val)),
                    style: context.text.bodyMedium?.copyWith(
                      color: palette.heading,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      hintText: StringConstants.commandPaletteHint,
                      hintStyle: context.text.bodySmall?.copyWith(
                        color: palette.caption,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: AppSpacing.lg,
                        color: palette.caption,
                      ),
                      suffixIcon: state.query.isNotEmpty
                          ? IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _searchController.clear();
                                bloc.add(const ClearCommandPaletteQuery());
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                size: AppSpacing.md,
                                color: palette.caption,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapH12,

                // 36px Module Filter Pills with Counts
                CommandPaletteFilterBar(
                  selectedModule: state.selectedModule,
                  moduleCounts: state.moduleCounts,
                  onSelectModule: (mod) =>
                      bloc.add(SelectCommandPaletteModule(mod)),
                ),
                AppSpacing.gapH12,

                if (state.status.isSuccess && state.isPartial) ...[
                  _PartialIndexBanner(failedModules: state.failedModules),
                  AppSpacing.gapH8,
                ],

                // Results
                Flexible(
                  child: switch (state.status) {
                    _ when state.status.isBusy => const Center(
                      child: Padding(
                        padding: AppSpacing.edgeInsetsAllXl,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    _ when state.status.isFailure => _PaletteMessageCard(
                      icon: Icons.error_outline_rounded,
                      iconColor: AppColors.error,
                      title: StringConstants.loadFailed,
                      subtitle:
                          state.failure?.message ??
                          StringConstants.genericError,
                      actionLabel: StringConstants.retry,
                      onAction: () => bloc.add(const LoadCommandPalette()),
                    ),
                    _ when filtered.isEmpty => const _PaletteMessageCard(
                      icon: Icons.search_off_rounded,
                      iconColor: AppColors.primary,
                      title: StringConstants.commandPaletteEmptyTitle,
                      subtitle: StringConstants.commandPaletteEmptySubtitle,
                    ),
                    _ => ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: palette.border),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return CommandPaletteResultTile(
                          key: ValueKey(item.id),
                          entry: item,
                          onTap: () => _handleSelectEntry(item),
                        );
                      },
                    ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaletteHeader extends StatelessWidget {
  final int totalIndexed;

  const _PaletteHeader({required this.totalIndexed});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Container(
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: AppRadius.borderSm,
          ),
          child: const Icon(
            Icons.terminal_rounded,
            size: AppSpacing.md,
            color: AppColors.primary,
          ),
        ),
        AppSpacing.gapW12,
        Expanded(
          child: Text(
            StringConstants.commandPaletteTitle,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.heading,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxxs,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: AppRadius.borderSm,
            border: Border.all(color: palette.border),
          ),
          child: Text(
            '${StringConstants.commandPaletteShortcutPrefix} • $totalIndexed ${StringConstants.commandPaletteIndexedSuffix}',
            style: AppTextStyles.monoCode.copyWith(color: palette.caption),
          ),
        ),
      ],
    );
  }
}

class _PartialIndexBanner extends StatelessWidget {
  final List<String> failedModules;

  const _PartialIndexBanner({required this.failedModules});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: AppSpacing.md,
            color: AppColors.warning,
          ),
          AppSpacing.gapW8,
          Expanded(
            child: Text(
              '${StringConstants.partialIndexWarning}: ${failedModules.join(', ')}',
              style: context.text.bodySmall?.copyWith(
                color: context.palette.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteMessageCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PaletteMessageCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: AppSpacing.edgeInsetsAllXl,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.xxl, color: iconColor),
          AppSpacing.gapH8,
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleSmall?.copyWith(
              color: palette.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapH4,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: palette.caption),
          ),
          if (actionLabel != null && onAction != null) ...[
            AppSpacing.gapH12,
            OutlinedButton.icon(
              key: const ValueKey('command_palette_retry'),
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: AppSpacing.md),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
