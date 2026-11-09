import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/bloc_status.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/usecases/profile_usecases.dart';
import 'profile_event.dart';
import 'profile_state.dart';

export 'profile_event.dart';
export 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserProfileUseCase getUserProfile;
  final SaveUserProfileUseCase saveUserProfile;
  final PickProfileAvatarUseCase pickProfileAvatar;

  ProfileBloc({
    required this.getUserProfile,
    required this.saveUserProfile,
    required this.pickProfileAvatar,
  }) : super(const ProfileState()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfileIdentity>(_onUpdateIdentity);
    on<SelectAvatarPreset>(_onSelectAvatarPreset);
    on<PickAvatarPhoto>(_onPickAvatarPhoto);
    on<ClearCustomAvatarPhoto>(_onClearCustomAvatarPhoto);
    on<ToggleFloatingQuickBall>(_onToggleFloatingQuickBall);
    on<ToggleQuickLaunchDock>(_onToggleQuickLaunchDock);
    on<ToggleAudioBriefCard>(_onToggleAudioBriefCard);
    on<ToggleSafeSpendCard>(_onToggleSafeSpendCard);
    on<ToggleEveningWrapUpCard>(_onToggleEveningWrapUpCard);
    on<ToggleAutoPlayBriefing>(_onToggleAutoPlayBriefing);
    on<ToggleHapticFeedback>(_onToggleHapticFeedback);
    on<ChangeThemeModePreference>(_onChangeThemeMode);
    on<ChangeCurrencyPreference>(_onChangeCurrency);
    on<ChangeDailyFocusGoal>(_onChangeDailyFocusGoal);
    on<ResetProfilePreferences>(_onResetPreferences);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: BlocStatus.loading, clearError: true));
    final result = await getUserProfile();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BlocStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (profile) => emit(
        state.copyWith(
          status: BlocStatus.success,
          profile: profile,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _persistAndEmit(
    UserProfileEntity updated,
    Emitter<ProfileState> emit,
  ) async {
    // Optimistically update UI state for instant responsiveness
    emit(
      state.copyWith(
        status: BlocStatus.success,
        profile: updated,
        clearError: true,
      ),
    );
    final result = await saveUserProfile(updated);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BlocStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (saved) => emit(
        state.copyWith(
          status: BlocStatus.success,
          profile: saved,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onUpdateIdentity(
    UpdateProfileIdentity event,
    Emitter<ProfileState> emit,
  ) async {
    final next = state.profile.copyWith(
      displayName: event.displayName.trim().isEmpty
          ? 'Aarav'
          : event.displayName.trim(),
      tagline: event.tagline.trim().isEmpty
          ? 'Focused Builder • Daily Life OS'
          : event.tagline.trim(),
    );
    await _persistAndEmit(next, emit);
  }

  Future<void> _onSelectAvatarPreset(
    SelectAvatarPreset event,
    Emitter<ProfileState> emit,
  ) async {
    final next = state.profile.copyWith(
      avatarPresetIndex: event.presetIndex,
      clearAvatarPath: true,
    );
    await _persistAndEmit(next, emit);
  }

  Future<void> _onPickAvatarPhoto(
    PickAvatarPhoto event,
    Emitter<ProfileState> emit,
  ) async {
    final result = await pickProfileAvatar(fromCamera: event.fromCamera);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: BlocStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (path) async {
        if (path != null && path.isNotEmpty) {
          final next = state.profile.copyWith(avatarPath: path);
          await _persistAndEmit(next, emit);
        }
      },
    );
  }

  Future<void> _onClearCustomAvatarPhoto(
    ClearCustomAvatarPhoto event,
    Emitter<ProfileState> emit,
  ) async {
    final next = state.profile.copyWith(clearAvatarPath: true);
    await _persistAndEmit(next, emit);
  }

  Future<void> _onToggleFloatingQuickBall(
    ToggleFloatingQuickBall event,
    Emitter<ProfileState> emit,
  ) async {
    await _persistAndEmit(
      state.profile.copyWith(showFloatingQuickBall: event.enabled),
      emit,
    );
  }

  Future<void> _onToggleQuickLaunchDock(
    ToggleQuickLaunchDock event,
    Emitter<ProfileState> emit,
  ) async {
    await _persistAndEmit(
      state.profile.copyWith(showQuickLaunchDock: event.enabled),
      emit,
    );
  }

  Future<void> _onToggleAudioBriefCard(
    ToggleAudioBriefCard event,
    Emitter<ProfileState> emit,
  ) async {
    await _persistAndEmit(
      state.profile.copyWith(showAudioBriefCard: event.enabled),
      emit,
    );
  }

  Future<void> _onToggleSafeSpendCard(
    ToggleSafeSpendCard event,
    Emitter<ProfileState> emit,
  ) async {
    await _persistAndEmit(
      state.profile.copyWith(showSafeSpendCard: event.enabled),
      emit,
    );
  }

  Future<void> _onToggleEveningWrapUpCard(
    ToggleEveningWrapUpCard event,
    Emitter<ProfileState> emit,
  ) async {
    await _persistAndEmit(
      state.profile.copyWith(showEveningWrapUpCard: event.enabled),
      emit,
    );
  }

  Future<void> _onToggleAutoPlayBriefing(
    ToggleAutoPlayBriefing event,
    Emitter<ProfileState> emit,
  ) async {
    await _persistAndEmit(
      state.profile.copyWith(autoPlayAudioBriefing: event.enabled),
      emit,
    );
  }

  Future<void> _onToggleHapticFeedback(
    ToggleHapticFeedback event,
    Emitter<ProfileState> emit,
  ) async {
    await _persistAndEmit(
      state.profile.copyWith(enableHapticFeedback: event.enabled),
      emit,
    );
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeModePreference event,
    Emitter<ProfileState> emit,
  ) async {
    await _persistAndEmit(
      state.profile.copyWith(themeMode: event.themeMode),
      emit,
    );
  }

  Future<void> _onChangeCurrency(
    ChangeCurrencyPreference event,
    Emitter<ProfileState> emit,
  ) async {
    await _persistAndEmit(
      state.profile.copyWith(currencyCode: event.currencyCode),
      emit,
    );
  }

  Future<void> _onChangeDailyFocusGoal(
    ChangeDailyFocusGoal event,
    Emitter<ProfileState> emit,
  ) async {
    await _persistAndEmit(
      state.profile.copyWith(dailyFocusGoalMinutes: event.minutes),
      emit,
    );
  }

  Future<void> _onResetPreferences(
    ResetProfilePreferences event,
    Emitter<ProfileState> emit,
  ) async {
    final reset = UserProfileEntity(
      displayName: state.profile.displayName,
      tagline: state.profile.tagline,
      avatarPath: state.profile.avatarPath,
      avatarPresetIndex: state.profile.avatarPresetIndex,
    );
    await _persistAndEmit(reset, emit);
  }
}
