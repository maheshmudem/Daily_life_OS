import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/user_profile_entity.dart';

abstract class ProfileLocalDataSource {
  Future<UserProfileEntity> getProfile();
  Future<UserProfileEntity> saveProfile(UserProfileEntity profile);
  Future<String?> pickAvatarImage({required bool fromCamera});
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  static const _kDisplayName = 'os_profile_display_name';
  static const _kTagline = 'os_profile_tagline';
  static const _kAvatarPath = 'os_profile_avatar_path';
  static const _kAvatarPresetIndex = 'os_profile_avatar_preset_idx';
  static const _kShowQuickBall = 'os_pref_show_floating_quick_ball';
  static const _kShowQuickLaunchDock = 'os_pref_show_quick_launch_dock';
  static const _kShowAudioBriefCard = 'os_pref_show_audio_brief_card';
  static const _kShowSafeSpendCard = 'os_pref_show_safe_spend_card';
  static const _kShowEveningWrapUpCard = 'os_pref_show_evening_wrap_up_card';
  static const _kAutoPlayBriefing = 'os_pref_auto_play_audio_briefing';
  static const _kEnableHaptics = 'os_pref_enable_haptics';
  static const _kThemeMode = 'os_pref_theme_mode';
  static const _kCurrencyCode = 'os_pref_currency_code';
  static const _kDailyFocusGoal = 'os_pref_daily_focus_goal_mins';

  final ImagePicker _imagePicker;

  ProfileLocalDataSourceImpl({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<UserProfileEntity> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString(_kCurrencyCode) ?? 'INR';
    CurrencyUtils.setCurrency(currency);

    final rawAvatarPath = prefs.getString(_kAvatarPath);
    return UserProfileEntity(
      displayName: prefs.getString(_kDisplayName) ?? 'Aarav',
      tagline: prefs.getString(_kTagline) ?? 'Focused Builder • Daily Life OS',
      avatarPath: (rawAvatarPath != null && rawAvatarPath.isNotEmpty)
          ? rawAvatarPath
          : null,
      avatarPresetIndex: prefs.getInt(_kAvatarPresetIndex) ?? 0,
      showFloatingQuickBall: prefs.getBool(_kShowQuickBall) ?? true,
      showQuickLaunchDock: prefs.getBool(_kShowQuickLaunchDock) ?? true,
      showAudioBriefCard: prefs.getBool(_kShowAudioBriefCard) ?? true,
      showSafeSpendCard: prefs.getBool(_kShowSafeSpendCard) ?? true,
      showEveningWrapUpCard: prefs.getBool(_kShowEveningWrapUpCard) ?? true,
      autoPlayAudioBriefing: prefs.getBool(_kAutoPlayBriefing) ?? true,
      enableHapticFeedback: prefs.getBool(_kEnableHaptics) ?? true,
      themeMode: prefs.getString(_kThemeMode) ?? 'system',
      currencyCode: currency,
      dailyFocusGoalMinutes: prefs.getInt(_kDailyFocusGoal) ?? 100,
    );
  }

  @override
  Future<UserProfileEntity> saveProfile(UserProfileEntity profile) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanName = profile.displayName.trim().isEmpty
        ? 'Aarav'
        : profile.displayName.trim();
    final cleanTagline = profile.tagline.trim().isEmpty
        ? 'Focused Builder • Daily Life OS'
        : profile.tagline.trim();

    await prefs.setString(_kDisplayName, cleanName);
    await prefs.setString(_kTagline, cleanTagline);
    if (profile.avatarPath != null && profile.avatarPath!.isNotEmpty) {
      await prefs.setString(_kAvatarPath, profile.avatarPath!);
    } else {
      await prefs.remove(_kAvatarPath);
    }
    await prefs.setInt(_kAvatarPresetIndex, profile.avatarPresetIndex);
    await prefs.setBool(_kShowQuickBall, profile.showFloatingQuickBall);
    await prefs.setBool(_kShowQuickLaunchDock, profile.showQuickLaunchDock);
    await prefs.setBool(_kShowAudioBriefCard, profile.showAudioBriefCard);
    await prefs.setBool(_kShowSafeSpendCard, profile.showSafeSpendCard);
    await prefs.setBool(_kShowEveningWrapUpCard, profile.showEveningWrapUpCard);
    await prefs.setBool(_kAutoPlayBriefing, profile.autoPlayAudioBriefing);
    await prefs.setBool(_kEnableHaptics, profile.enableHapticFeedback);
    await prefs.setString(_kThemeMode, profile.themeMode);
    await prefs.setString(_kCurrencyCode, profile.currencyCode);
    await prefs.setInt(_kDailyFocusGoal, profile.dailyFocusGoalMinutes);

    CurrencyUtils.setCurrency(profile.currencyCode);

    return profile.copyWith(displayName: cleanName, tagline: cleanTagline);
  }

  @override
  Future<String?> pickAvatarImage({required bool fromCamera}) async {
    final XFile? picked = await _imagePicker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) return null;
    return base64Encode(bytes);
  }
}
