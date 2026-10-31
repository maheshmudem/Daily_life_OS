import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_text_styles.dart';

class AudioBriefingSheet extends StatefulWidget {
  const AudioBriefingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AudioBriefingSheet(),
    );
  }

  @override
  State<AudioBriefingSheet> createState() => _AudioBriefingSheetState();
}

class _AudioBriefingSheetState extends State<AudioBriefingSheet>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  double _speed = 1.0;
  late AnimationController _animController;

  final String _briefingScript =
      "Good morning, Alex. Here is your Daily Life OS briefing for today. "
      "You have 3 active routines: hydration is on a 12-day streak. "
      "Your top priority is finalizing the project scope by 4 PM. "
      "Your safe-to-spend budget for today is ₹1,200, with 12 days remaining this month. "
      "Remember, Sarah's birthday is in 3 days. Have a focused and productive day!";

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: AppRadius.topXxl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              borderRadius: AppRadius.radiusFull,
            ),
          ),
          const SizedBox(height: 20),

          // Audio Title & Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Morning Audio Briefing',
                style: AppTextStyles.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Animated Audio Waves
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(16, (i) {
              return AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final height = _isPlaying
                      ? 10.0 +
                            (30.0 *
                                ((_animController.value + (i * 0.12)) % 1.0))
                      : 6.0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 3.5,
                    height: height,
                    decoration: BoxDecoration(
                      color: _isPlaying ? AppColors.primary : AppColors.divider,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 20),

          // Live Transcript Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceSecondary
                  : AppColors.surfaceSecondary,
              borderRadius: AppRadius.radiusLg,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Text(
              _briefingScript,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? AppColors.darkTextBody : AppColors.textBody,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_speed == 1.0) {
                      _speed = 1.25;
                    } else if (_speed == 1.25) {
                      _speed = 1.5;
                    } else {
                      _speed = 1.0;
                    }
                  });
                },
                child: Text(
                  '${_speed}x',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.replay_10_rounded),
                onPressed: () {},
              ),
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: IconButton(
                  iconSize: 30,
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  color: Colors.white,
                  onPressed: () {
                    setState(() => _isPlaying = !_isPlaying);
                  },
                ),
              ),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.forward_10_rounded),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
