import 'package:equatable/equatable.dart';

/// Pure-Dart domain entity representing the user's identity and OS preferences.
class UserProfileEntity extends Equatable {
  final String displayName;
  final String tagline;
  final String? avatarPath;
  final int avatarPresetIndex;
  final bool showFloatingQuickBall;
  final bool showQuickLaunchDock;
  final bool showAudioBriefCard;
  final bool showSafeSpendCard;
  final bool showEveningWrapUpCard;
  final bool autoPlayAudioBriefing;
  final bool enableHapticFeedback;
  final String themeMode; // 'system' | 'light' | 'dark'
  final String currencyCode; // 'INR' | 'USD' | 'EUR' | 'GBP' | 'AED' | 'JPY'
  final int dailyFocusGoalMinutes;

  const UserProfileEntity({
    this.displayName = 'Aarav',
    this.tagline = 'Focused Builder • Daily Life OS',
    this.avatarPath,
    this.avatarPresetIndex = 0,
    this.showFloatingQuickBall = true,
    this.showQuickLaunchDock = true,
    this.showAudioBriefCard = true,
    this.showSafeSpendCard = true,
    this.showEveningWrapUpCard = true,
    this.autoPlayAudioBriefing = true,
    this.enableHapticFeedback = true,
    this.themeMode = 'system',
    this.currencyCode = 'INR',
    this.dailyFocusGoalMinutes = 100,
  });

  /// Returns the uppercase monogram initial(s) for the current [displayName].
  String get monogram {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'A';
    return trimmed[0].toUpperCase();
  }

  bool get hasCustomPhoto =>
      avatarPath != null && avatarPath!.trim().isNotEmpty;

  UserProfileEntity copyWith({
    String? displayName,
    String? tagline,
    String? avatarPath,
    bool clearAvatarPath = false,
    int? avatarPresetIndex,
    bool? showFloatingQuickBall,
    bool? showQuickLaunchDock,
    bool? showAudioBriefCard,
    bool? showSafeSpendCard,
    bool? showEveningWrapUpCard,
    bool? autoPlayAudioBriefing,
    bool? enableHapticFeedback,
    String? themeMode,
    String? currencyCode,
    int? dailyFocusGoalMinutes,
  }) {
    return UserProfileEntity(
      displayName: displayName ?? this.displayName,
      tagline: tagline ?? this.tagline,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      avatarPresetIndex: avatarPresetIndex ?? this.avatarPresetIndex,
      showFloatingQuickBall:
          showFloatingQuickBall ?? this.showFloatingQuickBall,
      showQuickLaunchDock: showQuickLaunchDock ?? this.showQuickLaunchDock,
      showAudioBriefCard: showAudioBriefCard ?? this.showAudioBriefCard,
      showSafeSpendCard: showSafeSpendCard ?? this.showSafeSpendCard,
      showEveningWrapUpCard:
          showEveningWrapUpCard ?? this.showEveningWrapUpCard,
      autoPlayAudioBriefing:
          autoPlayAudioBriefing ?? this.autoPlayAudioBriefing,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      themeMode: themeMode ?? this.themeMode,
      currencyCode: currencyCode ?? this.currencyCode,
      dailyFocusGoalMinutes:
          dailyFocusGoalMinutes ?? this.dailyFocusGoalMinutes,
    );
  }

  @override
  List<Object?> get props => [
    displayName,
    tagline,
    avatarPath,
    avatarPresetIndex,
    showFloatingQuickBall,
    showQuickLaunchDock,
    showAudioBriefCard,
    showSafeSpendCard,
    showEveningWrapUpCard,
    autoPlayAudioBriefing,
    enableHapticFeedback,
    themeMode,
    currencyCode,
    dailyFocusGoalMinutes,
  ];
}
