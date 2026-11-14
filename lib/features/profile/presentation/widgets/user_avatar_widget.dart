import 'dart:convert';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/user_profile_entity.dart';

class AvatarPresetStyle {
  final String label;
  final List<Color> gradientColors;
  final IconData badgeIcon;

  const AvatarPresetStyle({
    required this.label,
    required this.gradientColors,
    required this.badgeIcon,
  });
}

class UserAvatarWidget extends StatelessWidget {
  final UserProfileEntity profile;
  final double size;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatarWidget({
    super.key,
    required this.profile,
    this.size = 38,
    this.borderRadius = 12,
    this.onTap,
    this.showEditBadge = false,
  });

  static const List<AvatarPresetStyle> presets = [
    AvatarPresetStyle(
      label: 'Indigo Core',
      gradientColors: [AppColors.primary, AppColors.primaryLight],
      badgeIcon: Icons.auto_awesome_rounded,
    ),
    AvatarPresetStyle(
      label: 'Emerald Flow',
      gradientColors: [AppColors.secondaryDark, AppColors.secondary],
      badgeIcon: Icons.bolt_rounded,
    ),
    AvatarPresetStyle(
      label: 'Sunset Focus',
      gradientColors: [AppColors.focusPomodoro, AppColors.warning],
      badgeIcon: Icons.local_fire_department_rounded,
    ),
    AvatarPresetStyle(
      label: 'Ocean Mind',
      gradientColors: [AppColors.info, AppColors.primaryLight],
      badgeIcon: Icons.psychology_rounded,
    ),
    AvatarPresetStyle(
      label: 'Royal Vault',
      gradientColors: [AppColors.primaryDark, AppColors.moduleVault],
      badgeIcon: Icons.shield_rounded,
    ),
    AvatarPresetStyle(
      label: 'Crimson Pulse',
      gradientColors: [AppColors.error, AppColors.focusPomodoro],
      badgeIcon: Icons.favorite_rounded,
    ),
  ];

  Uint8List? _decodeAvatarBytes() {
    if (!profile.hasCustomPhoto) return null;
    try {
      return base64Decode(profile.avatarPath!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final preset = presets[profile.avatarPresetIndex % presets.length];
    final photoBytes = _decodeAvatarBytes();

    Widget avatarContent;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      avatarContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          photoBytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildMonogramBox(preset),
        ),
      );
    } else {
      avatarContent = _buildMonogramBox(preset);
    }

    final stacked = Stack(
      clipBehavior: Clip.none,
      children: [
        avatarContent,
        if (showEditBadge)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: size * 0.36,
              height: size * 0.36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: palette.scaffold, width: 1.5),
              ),
              child: Icon(
                Icons.edit_rounded,
                size: size * 0.2,
                color: AppColors.textWhite,
              ),
            ),
          )
        else if (photoBytes == null && profile.avatarPresetIndex > 0)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.38,
              height: size * 0.38,
              decoration: BoxDecoration(
                color: preset.gradientColors.first,
                shape: BoxShape.circle,
                border: Border.all(color: palette.scaffold, width: 1.4),
              ),
              child: Icon(
                preset.badgeIcon,
                size: size * 0.22,
                color: AppColors.textWhite,
              ),
            ),
          ),
      ],
    );

    if (onTap == null) return stacked;

    return Semantics(
      button: true,
      label: 'User Profile Avatar',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: stacked,
        ),
      ),
    );
  }

  Widget _buildMonogramBox(AvatarPresetStyle preset) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: preset.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: AppText.labelLarge(
        profile.monogram,
        color: AppColors.textWhite,
        fontWeight: FontWeight.w800,
        fontSize: size * 0.42,
      ),
    );
  }
}
