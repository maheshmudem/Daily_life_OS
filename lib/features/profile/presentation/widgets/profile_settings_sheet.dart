import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../di/injection_container.dart';
import '../../../money/presentation/bloc/money_bloc.dart';
import '../../../notes/presentation/bloc/notes_bloc.dart';
import '../../../planner/presentation/bloc/planner_bloc.dart';
import '../../../today_hub/presentation/bloc/today_hub_bloc.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../bloc/profile_bloc.dart';
import 'user_avatar_widget.dart';

class ProfileSettingsSheet extends StatefulWidget {
  const ProfileSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<ProfileBloc>.value(
        value: sl<ProfileBloc>(),
        child: const ProfileSettingsSheet(),
      ),
    );
  }

  @override
  State<ProfileSettingsSheet> createState() => _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends State<ProfileSettingsSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _taglineController;

  @override
  void initState() {
    super.initState();
    final current = sl<ProfileBloc>().state.profile;
    _nameController = TextEditingController(text: current.displayName);
    _taglineController = TextEditingController(text: current.tagline);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  void _saveIdentity(BuildContext context, UserProfileEntity current) {
    if (current.enableHapticFeedback) {
      unawaited(HapticFeedback.lightImpact());
    }
    context.read<ProfileBloc>().add(
      UpdateProfileIdentity(
        displayName: _nameController.text,
        tagline: _taglineController.text,
      ),
    );
    FocusScope.of(context).unfocus();
    SnackbarUtils.showSuccess(
      context,
      '${StringConstants.profileSavedMessage}: ${_nameController.text.trim().isEmpty ? 'Aarav' : _nameController.text.trim()}',
    );
  }

  Future<void> _copyWorkspaceBackupSummary(
    BuildContext context,
    UserProfileEntity profile,
  ) async {
    final buffer = StringBuffer()
      ..writeln('═══════════════════════════════════════════')
      ..writeln('  DAILY LIFE OS — WORKSPACE BACKUP SUMMARY')
      ..writeln('═══════════════════════════════════════════')
      ..writeln('Owner      : ${profile.displayName} (${profile.tagline})')
      ..writeln('Currency   : ${profile.currencyCode}')
      ..writeln('Theme Mode : ${profile.themeMode}')
      ..writeln('Focus Goal : ${profile.dailyFocusGoalMinutes} mins/day')
      ..writeln(
        'Quick Ball : ${profile.showFloatingQuickBall ? "Enabled" : "Hidden"}',
      );

    if (sl.isRegistered<TodayHubBloc>()) {
      final todayState = sl<TodayHubBloc>().state;
      if (todayState is TodayHubLoaded) {
        buffer
          ..writeln('───────────────────────────────────────────')
          ..writeln(
            'Today Hub  : ${todayState.completedHabits}/${todayState.habits.length} habits • ${todayState.timelineItems.length} timeline tasks',
          );
      }
    }

    if (sl.isRegistered<PlannerBloc>()) {
      final plannerState = sl<PlannerBloc>().state;
      if (plannerState is PlannerLoaded) {
        buffer.writeln(
          'Planner    : ${plannerState.completedCount}/${plannerState.items.length} scheduled items completed',
        );
      }
    }

    if (sl.isRegistered<MoneyBloc>()) {
      final moneyState = sl<MoneyBloc>().state;
      if (moneyState is MoneyLoaded) {
        buffer.writeln(
          'Money      : ${moneyState.allTransactions.length} transactions • '
          '${moneyState.accounts.length} accounts • '
          '${moneyState.subscriptions.length} subscriptions • '
          '${moneyState.ious.length} IOUs',
        );
      }
    }

    if (sl.isRegistered<NotesBloc>()) {
      final notesState = sl<NotesBloc>().state;
      if (notesState is NotesLoaded) {
        buffer.writeln(
          'Notes      : ${notesState.notes.length} notes & checklists',
        );
      }
    }

    buffer.writeln('═══════════════════════════════════════════');
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    if (profile.enableHapticFeedback) {
      unawaited(HapticFeedback.lightImpact());
    }
    SnackbarUtils.showSuccess(
      context,
      StringConstants.workspaceBackupCopiedMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final media = MediaQuery.of(context);

    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = state.profile;

        return Container(
          key: const ValueKey('profile_settings_sheet'),
          constraints: BoxConstraints(maxHeight: media.size.height * 0.90),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.xs,
            AppSpacing.pageGutter,
            AppSpacing.md + media.viewInsets.bottom + media.padding.bottom,
          ),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppRadius.topXl,
            border: Border.all(color: palette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              AppSpacing.gapH16,

              // Sheet Header
              Row(
                children: [
                  UserAvatarWidget(
                    profile: profile,
                    size: 44,
                    borderRadius: 13,
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StringConstants.profileTitle,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: palette.heading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          StringConstants.profileSubtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: palette.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: palette.caption,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              AppSpacing.gapH16,

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Identity & Profile Picture Card
                      _SectionCard(
                        title: StringConstants.avatarSectionTitle,
                        icon: Icons.badge_rounded,
                        accentColor: AppColors.primary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo Picker & Avatar Preset Selector
                            Row(
                              children: [
                                UserAvatarWidget(
                                  profile: profile,
                                  size: 58,
                                  borderRadius: 16,
                                  showEditBadge: true,
                                  onTap: () => context.read<ProfileBloc>().add(
                                    const PickAvatarPhoto(fromCamera: false),
                                  ),
                                ),
                                AppSpacing.gapW12,
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _ActionChipButton(
                                        icon: Icons.photo_library_rounded,
                                        label: StringConstants.pickFromGallery,
                                        color: AppColors.primary,
                                        onTap: () =>
                                            context.read<ProfileBloc>().add(
                                              const PickAvatarPhoto(
                                                fromCamera: false,
                                              ),
                                            ),
                                      ),
                                      _ActionChipButton(
                                        icon: Icons.photo_camera_rounded,
                                        label: StringConstants.takeCameraPhoto,
                                        color: AppColors.secondary,
                                        onTap: () =>
                                            context.read<ProfileBloc>().add(
                                              const PickAvatarPhoto(
                                                fromCamera: true,
                                              ),
                                            ),
                                      ),
                                      if (profile.hasCustomPhoto)
                                        _ActionChipButton(
                                          icon: Icons.palette_rounded,
                                          label: StringConstants.removePhoto,
                                          color: AppColors.warning,
                                          onTap: () =>
                                              context.read<ProfileBloc>().add(
                                                const ClearCustomAvatarPhoto(),
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapH12,

                            // 6 Curated Avatar Gradient Presets
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                  UserAvatarWidget.presets.length,
                                  (index) {
                                    final preset =
                                        UserAvatarWidget.presets[index];
                                    final isSelected =
                                        !profile.hasCustomPhoto &&
                                        profile.avatarPresetIndex == index;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        key: ValueKey(
                                          'avatar_preset_chip_$index',
                                        ),
                                        onTap: () {
                                          if (profile.enableHapticFeedback) {
                                            unawaited(
                                              HapticFeedback.selectionClick(),
                                            );
                                          }
                                          context.read<ProfileBloc>().add(
                                            SelectAvatarPreset(index),
                                          );
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? preset.gradientColors.first
                                                      .withValues(
                                                        alpha: palette.isDark
                                                            ? 0.24
                                                            : 0.12,
                                                      )
                                                : palette.card,
                                            borderRadius: AppRadius.radiusFull,
                                            border: Border.all(
                                              color: isSelected
                                                  ? preset.gradientColors.first
                                                  : palette.border,
                                              width: isSelected ? 1.5 : 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors:
                                                        preset.gradientColors,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                preset.label,
                                                style: text.labelSmall
                                                    ?.copyWith(
                                                      fontSize: 11,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                      color: isSelected
                                                          ? preset
                                                                .gradientColors
                                                                .first
                                                          : palette.body,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            AppSpacing.gapH16,

                            // Display Name Input
                            Text(
                              StringConstants.displayNameLabel,
                              style: text.labelSmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: palette.heading,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              key: const ValueKey('profile_name_input'),
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              style: text.bodyMedium?.copyWith(
                                color: palette.heading,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: StringConstants.displayNameHint,
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 18,
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: palette.card,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.radiusSm,
                                  borderSide: BorderSide(color: palette.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.radiusSm,
                                  borderSide: BorderSide(color: palette.border),
                                ),
                              ),
                            ),
                            AppSpacing.gapH12,

                            // Tagline Input
                            Text(
                              StringConstants.taglineLabel,
                              style: text.labelSmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: palette.heading,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              key: const ValueKey('profile_tagline_input'),
                              controller: _taglineController,
                              style: text.bodyMedium?.copyWith(
                                color: palette.heading,
                              ),
                              decoration: InputDecoration(
                                hintText: StringConstants.taglineHint,
                                prefixIcon: const Icon(
                                  Icons.workspace_premium_outlined,
                                  size: 18,
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: palette.card,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.radiusSm,
                                  borderSide: BorderSide(color: palette.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.radiusSm,
                                  borderSide: BorderSide(color: palette.border),
                                ),
                              ),
                            ),
                            AppSpacing.gapH12,

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                key: const ValueKey(
                                  'save_profile_identity_btn',
                                ),
                                onPressed: () =>
                                    _saveIdentity(context, profile),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.radiusSm,
                                  ),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text(StringConstants.save),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapH12,

                      // 2. Workspace & Quick-Access Controls Section
                      _SectionCard(
                        title: StringConstants.workspaceControlsSection,
                        icon: Icons.tune_rounded,
                        accentColor: AppColors.secondary,
                        child: Column(
                          children: [
                            _PreferenceToggleTile(
                              switchKey: const ValueKey(
                                'toggle_quick_access_ball',
                              ),
                              icon: Icons.radio_button_checked_rounded,
                              iconColor: AppColors.primary,
                              title: StringConstants.quickAccessBallTitle,
                              subtitle: StringConstants.quickAccessBallSubtitle,
                              value: profile.showFloatingQuickBall,
                              onChanged: (val) => context
                                  .read<ProfileBloc>()
                                  .add(ToggleFloatingQuickBall(val)),
                            ),
                            Divider(height: 16, color: palette.border),
                            _PreferenceToggleTile(
                              switchKey: const ValueKey(
                                'toggle_quick_launch_dock',
                              ),
                              icon: Icons.rocket_launch_rounded,
                              iconColor: AppColors.moduleTime,
                              title: StringConstants.quickLaunchDockToggleTitle,
                              subtitle:
                                  StringConstants.quickLaunchDockToggleSubtitle,
                              value: profile.showQuickLaunchDock,
                              onChanged: (val) => context
                                  .read<ProfileBloc>()
                                  .add(ToggleQuickLaunchDock(val)),
                            ),
                            Divider(height: 16, color: palette.border),
                            _PreferenceToggleTile(
                              switchKey: const ValueKey(
                                'toggle_audio_brief_card',
                              ),
                              icon: Icons.graphic_eq_rounded,
                              iconColor: AppColors.primaryLight,
                              title:
                                  StringConstants.audioBriefBannerToggleTitle,
                              subtitle: StringConstants
                                  .audioBriefBannerToggleSubtitle,
                              value: profile.showAudioBriefCard,
                              onChanged: (val) => context
                                  .read<ProfileBloc>()
                                  .add(ToggleAudioBriefCard(val)),
                            ),
                            Divider(height: 16, color: palette.border),
                            _PreferenceToggleTile(
                              switchKey: const ValueKey(
                                'toggle_safe_spend_card',
                              ),
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: AppColors.moduleMoney,
                              title: StringConstants.safeSpendBannerToggleTitle,
                              subtitle:
                                  StringConstants.safeSpendBannerToggleSubtitle,
                              value: profile.showSafeSpendCard,
                              onChanged: (val) => context
                                  .read<ProfileBloc>()
                                  .add(ToggleSafeSpendCard(val)),
                            ),
                            Divider(height: 16, color: palette.border),
                            _PreferenceToggleTile(
                              switchKey: const ValueKey(
                                'toggle_evening_wrap_up_card',
                              ),
                              icon: Icons.nights_stay_rounded,
                              iconColor: AppColors.focusPomodoro,
                              title: StringConstants.eveningWrapUpToggleTitle,
                              subtitle:
                                  StringConstants.eveningWrapUpToggleSubtitle,
                              value: profile.showEveningWrapUpCard,
                              onChanged: (val) => context
                                  .read<ProfileBloc>()
                                  .add(ToggleEveningWrapUpCard(val)),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapH12,

                      // 3. Voice, Appearance & Regional Settings Section
                      _SectionCard(
                        title: StringConstants.voiceAndSystemSection,
                        icon: Icons.settings_suggest_rounded,
                        accentColor: AppColors.moduleTime,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Theme Mode Selector
                            Text(
                              StringConstants.appearanceModeTitle,
                              style: text.labelSmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: palette.heading,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _ThemeModeOption(
                                  label: StringConstants.themeSystem,
                                  icon: Icons.brightness_auto_rounded,
                                  selected: profile.themeMode == 'system',
                                  onTap: () => context.read<ProfileBloc>().add(
                                    const ChangeThemeModePreference('system'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ThemeModeOption(
                                  label: StringConstants.themeLight,
                                  icon: Icons.light_mode_rounded,
                                  selected: profile.themeMode == 'light',
                                  onTap: () => context.read<ProfileBloc>().add(
                                    const ChangeThemeModePreference('light'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ThemeModeOption(
                                  label: StringConstants.themeDark,
                                  icon: Icons.dark_mode_rounded,
                                  selected: profile.themeMode == 'dark',
                                  onTap: () => context.read<ProfileBloc>().add(
                                    const ChangeThemeModePreference('dark'),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapH16,

                            // Primary Currency Selector
                            Text(
                              StringConstants.activeCurrencyTitle,
                              style: text.labelSmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: palette.heading,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: CurrencyUtils.supportedCurrencies.map((
                                curr,
                              ) {
                                final active =
                                    profile.currencyCode == curr.code;
                                return GestureDetector(
                                  key: ValueKey('currency_chip_${curr.code}'),
                                  onTap: () => context.read<ProfileBloc>().add(
                                    ChangeCurrencyPreference(curr.code),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.primary
                                          : palette.card,
                                      borderRadius: AppRadius.radiusFull,
                                      border: Border.all(
                                        color: active
                                            ? AppColors.primary
                                            : palette.border,
                                      ),
                                    ),
                                    child: Text(
                                      '${curr.symbol.trim()} ${curr.code}',
                                      style: text.labelSmall?.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? Colors.white
                                            : palette.heading,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            AppSpacing.gapH16,

                            // Daily Deep-Work Focus Target
                            Text(
                              StringConstants.dailyFocusGoalTitle,
                              style: text.labelSmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: palette.heading,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [50, 100, 150, 200].map((mins) {
                                final active =
                                    profile.dailyFocusGoalMinutes == mins;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: GestureDetector(
                                      onTap: () => context
                                          .read<ProfileBloc>()
                                          .add(ChangeDailyFocusGoal(mins)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 7,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: active
                                              ? AppColors.focusPomodoro
                                              : palette.card,
                                          borderRadius: AppRadius.radiusSm,
                                          border: Border.all(
                                            color: active
                                                ? AppColors.focusPomodoro
                                                : palette.border,
                                          ),
                                        ),
                                        child: Text(
                                          '${mins}m',
                                          style: text.labelSmall?.copyWith(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: active
                                                ? Colors.white
                                                : palette.heading,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            Divider(height: 22, color: palette.border),

                            _PreferenceToggleTile(
                              switchKey: const ValueKey(
                                'toggle_auto_play_briefing',
                              ),
                              icon: Icons.record_voice_over_rounded,
                              iconColor: AppColors.primary,
                              title: StringConstants.autoPlayBriefingTitle,
                              subtitle:
                                  StringConstants.autoPlayBriefingSubtitle,
                              value: profile.autoPlayAudioBriefing,
                              onChanged: (val) => context
                                  .read<ProfileBloc>()
                                  .add(ToggleAutoPlayBriefing(val)),
                            ),
                            Divider(height: 16, color: palette.border),
                            _PreferenceToggleTile(
                              switchKey: const ValueKey(
                                'toggle_haptic_feedback',
                              ),
                              icon: Icons.vibration_rounded,
                              iconColor: AppColors.secondary,
                              title: StringConstants.hapticFeedbackTitle,
                              subtitle: StringConstants.hapticFeedbackSubtitle,
                              value: profile.enableHapticFeedback,
                              onChanged: (val) => context
                                  .read<ProfileBloc>()
                                  .add(ToggleHapticFeedback(val)),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapH12,

                      // ── 4. Workspace Data & Backup Summary ───────────────
                      _SectionCard(
                        title: StringConstants.workspaceBackupSectionTitle,
                        icon: Icons.cloud_done_outlined,
                        accentColor: AppColors.moduleMoney,
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey('copy_workspace_backup_btn'),
                            onPressed: () =>
                                _copyWorkspaceBackupSummary(context, profile),
                            icon: const Icon(Icons.copy_all_rounded, size: 17),
                            label: const Text(
                              StringConstants.copyWorkspaceBackupLabel,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapH12,

                      // Reset Preferences Button
                      Center(
                        child: TextButton.icon(
                          key: const ValueKey('reset_profile_preferences_btn'),
                          onPressed: () => context.read<ProfileBloc>().add(
                            const ResetProfilePreferences(),
                          ),
                          icon: const Icon(Icons.restore_rounded, size: 16),
                          label: const Text(StringConstants.resetDefaultsLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceMuted.withValues(
          alpha: palette.isDark ? 0.55 : 0.75,
        ),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: palette.isDark ? 0.24 : 0.14,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.heading,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,
          child,
        ],
      ),
    );
  }
}

class _PreferenceToggleTile extends StatelessWidget {
  final Key? switchKey;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceToggleTile({
    this.switchKey,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: palette.isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.titleSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.heading,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: text.labelSmall?.copyWith(
                  fontSize: 11,
                  height: 1.3,
                  color: palette.caption,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          key: switchKey,
          value: value,
          activeTrackColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: text.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.heading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : palette.card,
            borderRadius: AppRadius.radiusSm,
            border: Border.all(
              color: selected ? AppColors.primary : palette.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : palette.heading,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : palette.heading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
