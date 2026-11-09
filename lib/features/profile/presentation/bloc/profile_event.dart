import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class UpdateProfileIdentity extends ProfileEvent {
  final String displayName;
  final String tagline;

  const UpdateProfileIdentity({
    required this.displayName,
    required this.tagline,
  });

  @override
  List<Object?> get props => [displayName, tagline];
}

class SelectAvatarPreset extends ProfileEvent {
  final int presetIndex;

  const SelectAvatarPreset(this.presetIndex);

  @override
  List<Object?> get props => [presetIndex];
}

class PickAvatarPhoto extends ProfileEvent {
  final bool fromCamera;

  const PickAvatarPhoto({required this.fromCamera});

  @override
  List<Object?> get props => [fromCamera];
}

class ClearCustomAvatarPhoto extends ProfileEvent {
  const ClearCustomAvatarPhoto();
}

class ToggleFloatingQuickBall extends ProfileEvent {
  final bool enabled;

  const ToggleFloatingQuickBall(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleQuickLaunchDock extends ProfileEvent {
  final bool enabled;

  const ToggleQuickLaunchDock(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleAudioBriefCard extends ProfileEvent {
  final bool enabled;

  const ToggleAudioBriefCard(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleSafeSpendCard extends ProfileEvent {
  final bool enabled;

  const ToggleSafeSpendCard(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleEveningWrapUpCard extends ProfileEvent {
  final bool enabled;

  const ToggleEveningWrapUpCard(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleAutoPlayBriefing extends ProfileEvent {
  final bool enabled;

  const ToggleAutoPlayBriefing(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleHapticFeedback extends ProfileEvent {
  final bool enabled;

  const ToggleHapticFeedback(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ChangeThemeModePreference extends ProfileEvent {
  final String themeMode; // 'system' | 'light' | 'dark'

  const ChangeThemeModePreference(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class ChangeCurrencyPreference extends ProfileEvent {
  final String currencyCode;

  const ChangeCurrencyPreference(this.currencyCode);

  @override
  List<Object?> get props => [currencyCode];
}

class ChangeDailyFocusGoal extends ProfileEvent {
  final int minutes;

  const ChangeDailyFocusGoal(this.minutes);

  @override
  List<Object?> get props => [minutes];
}

class ResetProfilePreferences extends ProfileEvent {
  const ResetProfilePreferences();
}
